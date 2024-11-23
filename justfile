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

alias step-0 := k3d-cluster-delete
alias step-1 := k3d-cluster-create
# add wait for argocd to be ready
alias step-2 := argocd-login-sync
# add wait for external-secrets namespace to be ready
alias step-3 := vault-create-main-secret
alias step-4 := argocd-sync-status
# add runners registration

# Import the act-runner recipes
import './_assets/act-runner/justfile'

alias step-5 := full-runner-lifecycle

# Full Nuvola ☁️ setup
full-setup: k3d-cluster-create argocd-login-sync vault-create-main-secret argocd-sync-status full-runner-lifecycle

# 4. get runners token and start act-runners
# 5. add the secret for the pipelines

# # Create main Vault secret (Vault_Token) from 1Password
# create-main-vault-secret:
#     @cat ${SECRET_VAULT_TEMPORARY_TOKEN} | envsubst | op inject | kubectl apply -f -


# ❓ Create main Vault secret (Vault_Token) from 1Password
apply-k8s-resources:
    kubectl apply -k k8s/

# ❓ Deploy the application to the k3d cluster
secrets-tls-deploy:
    #!/usr/bin/env bash
    echo "Creating TLS secret for wildcard-localtest-me"

    # Switch to the directory containing the certs
    cd ./_assets/secrets

    # Create the secret containing the TLS certificate and its key
    export CERT_NAME="wildcard-localtest-me"
    pwd
    kubectl apply -f secret-tls-${CERT_NAME}.yaml

    # Restart Traefik to load the new cert
    kubectl rollout restart deployment traefik -n traefik

# Push the git repo to the local remote, creating the repository if it doesn't exist
git-push-local:
    git push -o repo.private=false -u local main

# Watch the Vault secret update propagate to the test app
monitor-vault-test-app:
    @viddy -n 5 -bds 'http https://vault-test.localtest.me/ | tidy -qi -w 0 --tidy-mark no -f /dev/null | bat -pP --color=always'
