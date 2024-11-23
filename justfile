# Justfile

# Variables
# IMAGE_NAME := "fastapi-uv:latest"

# List 📜 all recipes (default)
help:
    @just --list

# Generate k3d cluster config from template
k3d-cluster-generate-config:
    @#rm -fv ./k3d/cluster/k3d-nuvola-cluster-config.yaml
    @cat ./k3d/template/k3d-nuvola-cluster-config_TEMPLATE.yaml | envsubst >./k3d/cluster/k3d-${K3D_CLUSTER}-cluster-config.yaml
    @ls -1 ./k3d/cluster/k3d-${K3D_CLUSTER}-cluster-config.yaml

# Create k3d cluster using configuration file
k3d-cluster-create:
    k3d cluster create ${K3D_CLUSTER} --config=./k3d/cluster/k3d-${K3D_CLUSTER}-cluster-config.yaml
    @kubectl cluster-info

# Delete the k3d cluster
k3d-cluster-delete:
    k3d cluster delete ${K3D_CLUSTER}

argocd-get-password:
    argocd admin initial-password -n argocd | head -n 1

# Wait until the 'external-secrets' namespace is available
wait-for-external-secrets-namespace:
    @echo "Waiting for the 'external-secrets' namespace to be ready..."
    @until kubectl get namespace external-secrets >/dev/null 2>&1; do sleep 2; done && echo "Namespace 'external-secrets' is ready!"

# Create main Vault secret (${VAULT_TOKEN}) from 1Password
vault-create-main-secret: wait-for-external-secrets-namespace
    @yq '.data.token |= envsubst()' < ${SECRET_VAULT_TEMPORARY_TOKEN} | op inject | kubectl apply -f -

wait-for-argocd-server:
    #!/usr/bin/env bash
    echo "Waiting for the 'argocd' namespace to be ready..."
    until kubectl get namespace argocd >/dev/null 2>&1; do sleep 2; done && echo "Namespace 'argocd' is ready!"
    sleep 30
    kubectl wait -n argocd --for=condition=ready --timeout=600s pod -l "app.kubernetes.io/instance=argocd,app.kubernetes.io/component=server"

# ✅
# argocd login --insecure --grpc-web --username admin argocd.localhost --password $(op read "op://Nuvola/ArgoCD UI/password")
# argocd login --insecure --grpc-web --username admin argocd.localhost --password $(op read ${ARGOCD_ADMIN_PASSWORD})

# 🛑
# #❓ argocd login --insecure --grpc-web --username admin argocd.localhost --password "${ARGOCD_ADMIN_PASSWORD}"
# #❓ op run -- argocd login --insecure --grpc-web --username admin argocd.localhost --password "op://Nuvola/argocd.localhost/password"

# Login and start first argocd sync
argocd-login: wait-for-argocd-server
    argocd login --insecure --grpc-web --username admin argocd.localhost --password $(op read "${ARGOCD_ADMIN_PASSWORD}")

# ArgoCD sync main application
argocd-sync:
    @argocd app sync apps --async
    @echo "ArgoCD sync started!"

argocd-login-sync: argocd-login argocd-sync

# View the ArgoCD application status
argocd-sync-status:
    @argocd app wait apps --health --sync


# Import the act-runner recipes
# import './_assets/act-runner/justfile'

################# BEGIN 🈷️ act-runners justflile #################

# Variables
IMAGE_NAME := "act-runner-nuvola:latest"
# COMPOSE_CONFIG := "compose-scale.yaml"
COMPOSE_CONFIG := './_assets/act-runner/compose-double.yaml'
ACT_RUNNERS_VOLUME_DIR := './_assets/act-runner'

##start-runner:
##    env $(teller env) docker compose -f {{COMPOSE_CONFIG}} up

start-runner:
    #!/usr/bin/env bash
    export GITEA_RUNNER_REGISTRATION_TOKEN=$(vault kv get -field GITEA_RUNNER_REGISTRATION_TOKEN -mount="secret" "gitea/runner-registration-token")
    docker compose -f {{COMPOSE_CONFIG}} up

# start-runner-detached:
#     env $(teller env) teller run -- docker compose -f {{COMPOSE_CONFIG}} up --detach

start-runner-detached:
    #!/usr/bin/env bash
    export GITEA_RUNNER_REGISTRATION_TOKEN=$(vault kv get -field GITEA_RUNNER_REGISTRATION_TOKEN -mount="secret" "gitea/runner-registration-token")
    docker compose -f {{COMPOSE_CONFIG}} up --detach

## stop-runner:
##     env $(teller env) teller run -- docker compose -f {{COMPOSE_CONFIG}} down

stop-runner:
    docker compose -f {{COMPOSE_CONFIG}} down

# Build the container image
build-container:
    docker compose -f {{COMPOSE_CONFIG}} build --build-arg GITEA_HOSTNAME="${GITEA_HOSTNAME}"

# Get runner registration token 🔑 from Gitea
get-runner-token:
    #!/usr/bin/env bash
    GITEA_RUNNER_REGISTRATION_TOKEN=$(kubectl exec -n git --stdin=true --tty=true $(kubectl get pods -n git -l 'app.kubernetes.io/name=gitea,app.kubernetes.io/component!=token-job,app.kubernetes.io/instance=gitea' -o name) -c gitea -- /bin/sh -c "gitea actions generate-runner-token" | tr -d '\r\n')
    echo ${GITEA_RUNNER_REGISTRATION_TOKEN} | tr -d '\n'

# Save the runner registration token 🔑 from Gitea to 🏦 Vault
save-runner-token:
    #!/usr/bin/env bash
    GITEA_RUNNER_REGISTRATION_TOKEN=$(kubectl exec -n git --stdin=true --tty=true $(kubectl get pods -n git -l 'app.kubernetes.io/name=gitea,app.kubernetes.io/component!=token-job,app.kubernetes.io/instance=gitea' -o name) -c gitea -- /bin/sh -c "gitea actions generate-runner-token" | tr -d '\r\n')
    vault kv put secret/gitea/runner-registration-token GITEA_RUNNER_REGISTRATION_TOKEN="${GITEA_RUNNER_REGISTRATION_TOKEN}"

# Unregister the local Gitea Runners
unregister-runners:
    @fd -u .runner {{ACT_RUNNERS_VOLUME_DIR}}/data-{0,1,2}/ | xargs rm -fv
    @echo "Runners unregistered"

# Wait until the 'git' namespace is available
wait-for-gitea-server:
    #!/usr/bin/env bash
    GITEA_POD=$(kubectl get pods -n git -l 'app.kubernetes.io/name=gitea,app.kubernetes.io/component!=token-job,app.kubernetes.io/instance=gitea' -o name)
    echo "Waiting for the Gitea server to be ready..."
    kubectl wait --timeout=600s -n git --for=condition=ready ${GITEA_POD}
    # @until kubectl get namespace git >/dev/null 2>&1; do sleep 2; done && echo "Namespace 'git' is ready!"

# Force the full lifecycle of the Gitea Runner
full-runner-lifecycle: stop-runner unregister-runners wait-for-gitea-server save-runner-token start-runner-detached

################# 🈷️ END act-runners justflile #################


# Get the Gitea auth token
# gitea-get-auth-token:

# Push the fastapi-uv repo to the local remote, creating the repository if it doesn't exist
git-push-fastapi-uv:
    @cd ../../fastapi-uv && git push -o repo.private=false -u local main

# Create the secret for the pipelines
gitea-create-secret:
    #!/usr/bin/env bash

    # Set the Gitea hostname, username, and password
    GITEA_HOSTNAME="git.localtest.me"
    GITEA_USERNAME="$(op read 'op://Private/ujfrvzi2gwbjozczjg2cjl27v4/username')"
    GITEA_PASSWORD="$(op read 'op://Private/ujfrvzi2gwbjozczjg2cjl27v4/password')"

    # Generate a random token suffix
    TOKEN_SUFFIX=$(openssl rand -base64 48 | tr -dc 'a-z0-9' | head -c 6)

    # Get the Gitea auth token
    GITEA_AUTH_TOKEN=$(curl -s -H "Content-Type: application/json" \
    -d "{\"name\":\"curl-api-${TOKEN_SUFFIX}\",\"scopes\":[\"write:repository\",\"write:user\"]}" \
    -u "${GITEA_USERNAME}:${GITEA_PASSWORD}" \
    "https://${GITEA_HOSTNAME}/api/v1/users/${GITEA_USERNAME}/tokens" | yq '.sha1' -r)

    # Set the secret name and value
    GITEA_SECRET_NAME="REGISTRY_PASSWORD"
    GITEA_SECRET_VALUE="${GITEA_PASSWORD}"

    # Repo specific secret
    ENDPOINT="https://${GITEA_HOSTNAME}/api/v1/repos/${GITEA_USERNAME}/fastapi-uv/actions/secrets/${GITEA_SECRET_NAME}"
    # Global secret (not verified)
    # ENDPOINT="https://${GITEA_HOSTNAME}/api/v1/user/actions/secrets/${GITEA_SECRET_NAME}"

    # Create the secret
    curl -s -X PUT \
    "${ENDPOINT}" \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: token ${GITEA_AUTH_TOKEN}" \
    -d "{\"data\": \"${GITEA_SECRET_VALUE}\"}"

    echo "Done, but check above for any error."



alias step-0 := k3d-cluster-delete
alias step-1 := k3d-cluster-create

alias step-2 := argocd-login-sync

alias step-3 := vault-create-main-secret
alias step-4 := argocd-sync-status

alias step-5 := full-runner-lifecycle

alias step-6 := git-push-fastapi-uv
alias step-7 := gitea-create-secret

# Full Nuvola ☁️ setup
full-setup: k3d-cluster-create argocd-login-sync vault-create-main-secret argocd-sync-status full-runner-lifecycle git-push-local git-push-fastapi-uv gitea-create-secret


# # Create main Vault secret (Vault_Token) from 1Password
# create-main-vault-secret:
#     @cat ${SECRET_VAULT_TEMPORARY_TOKEN} | envsubst | op inject | kubectl apply -f -

# Push the git repo to the local remote, creating the repository if it doesn't exist
git-push-local:
    git push -o repo.private=false -u local main

# Watch the Vault secret update propagate to the test app
monitor-vault-test-app:
    @viddy -n 5 -bds 'http https://vault-test.localtest.me/ | tidy -qi -w 0 --tidy-mark no -f /dev/null | bat -pP --color=always'
