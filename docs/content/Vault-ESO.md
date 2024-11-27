# Vault & External Secrets configuration step by step

Reference:

- <https://medium.com/containers-101/gitops-secrets-with-argo-cd-hashicorp-vault-and-the-external-secret-operator-eb1eec1dab0d>

## Install

```sh
# Add helm repo
helm repo add external-secrets https://charts.external-secrets.io

# Install
helm upgrade --install external-secrets external-secrets/external-secrets \
    -n external-secrets --create-namespace --wait

# helm upgrade --install external-secrets external-secrets/external-secrets \
    # -n external-secrets --create-namespace -f vault.yaml --wait
```

## Setup test application

Use the scripts:

```sh
# set up ExternalSecrets + Vault integration, and the test app
./setup-vault-eso-test-app.sh

# To reset Vault secrets and configuration, and also remove the ESO integration and the test app
./reset-vault-eso-test-app.sh

# Update the vault secret to check it's being propagated to the test app
./increment-vault-secret-version.sh

```

___Alternatively, do it step by step by following the instructions below.___

### Create test secrets

```sh
# Set vault address
export VAULT_ADDR="https://vault.localtest.me"

# Create a secret named `mysql_credentials` containing url, username and password
vault kv put secret/mysql_credentials url="https://test.example.com" username="test-username" password="test-password"

```

### Enable vault Kubernetes authentication

Oneliner

```sh
# Oneliner to configure vault via the vault container shell
kubectl exec --stdin=true --tty=true -n vault vault-0 -- /bin/sh -c "vault auth enable kubernetes ; sleep 1 ; vault write auth/kubernetes/config kubernetes_host=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT ; sleep 1 ; vault write auth/kubernetes/role/demo \
  bound_service_account_names=* \
  bound_service_account_namespaces=* \
  policies=default \
  ttl=1h"

# Set the vault address
export VAULT_ADDR='https://vault.localtest.me'

# Get the kubernetes service url from the vault container env vars (🚨 doesn't work)
# export KUBERNETES_SERVICE_URL=$(kubectl exec --stdin=true --tty=true -n vault vault-0 -- /bin/sh -c "echo https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT")

# Get the kubernetes service url using kubectl service
export KUBERNETES_SERVICE_URL=$(kubectl get svc kubernetes -o json | jq -r '.spec | "https://\(.clusterIP):\(.ports[] | select(.name == "https").port)"')
echo ${KUBERNETES_SERVICE_URL}

# Configure vault
vault auth enable kubernetes ; sleep 1
vault write auth/kubernetes/config kubernetes_host=${KUBERNETES_SERVICE_URL} ; sleep 1
vault write auth/kubernetes/role/demo \
  'bound_service_account_names=*' \
  'bound_service_account_namespaces=*' \
  'policies=default' \
  'ttl=1h'

# Read the default policy, and add the new policy at the end
vault policy read default > vault-default-policy.hcl
cat vault-default-policy.hcl vault-policy-addendum.hcl > vault-new-policy.hcl

# Write the new policy
vault policy write default vault-new-policy.hcl

# Create a secret named `mysql_credentials` containing url, username and password
# PREFIX is used to test the changes
PREFIX="11-"
# Set the secret in vault
vault kv put secret/mysql_credentials url="https://${PREFIX}test.example.com" username="${PREFIX}test-username" password="${PREFIX}test-password"
```

Set up vault-ESO test application

```sh
# Deploy test application
kubectl apply -f ./vault-test-app/
```

Checks, or debugging

```sh
# check logs
stern -t -n external-secrets external-secrets

# check update in the vault-test-app (with http, viddy and htmltidy CLI tools)
viddy -n 5 -ds 'http https://vault-test.localtest.me/ | tidy -qi -w 0 --tidy-mark no -f /dev/null'

# Eventually restart external-secrets to speed up the update, or just wait a bit
kubectl -n external-secrets rollout restart deployment/external-secrets

# Eventually restart the test app
kubectl -n default rollout restart deployment/vault-eso-test-app

# Check the vault-test-app pod output
alias tidycat='tidy -qi -w 0 --tidy-mark no'
http https://vault-test.localtest.me/ | tidycat -f /dev/null | bat -pP

# Restarting vault will remove all the secrets and the configuration above
kubectl delete -n vault pod vault-0
```

Or, open a shell into the vault container and do it step by step

```sh
kubectl exec --stdin=true --tty=true -n vault vault-0 -- /bin/sh

# Execute the commands below inside the vault container to enable Kubernetes auth and configure it
vault auth enable kubernetes
vault write auth/kubernetes/config \
  kubernetes_host=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT

vault write auth/kubernetes/role/demo \
  bound_service_account_names=* \
  bound_service_account_namespaces=* \
  policies=default \
  ttl=1h
```

### Configure the policy to allow access

With the CLI

```sh
# Set the vault address
export VAULT_ADDR='https://vault.localtest.me'

# Read the default policy, and add the new policy at the end
vault policy read default > vault-default-policy.hcl
cat vault-default-policy.hcl vault-policy-addendum.hcl > vault-new-policy.hcl

# Write the new policy
vault policy write default vault-new-policy.hcl

```

Or, open the the vault UI (Token = "root")

- <https://vault.localtest.me/>

Navigate to the test policy

- <https://vault.localtest.me/ui/vault/policy/acl/default>

Edit the policy, adding at the bottom:

```hcl
# access for test apps
path "secret/*" {
  capabilities = [ "read", "list" ]
}
```

Save.

Check the test application:

- <http://test-vault.localtest.me/>

If it works you should see the secrets you created.

## Other configurations

```sh
# Create a Kubernetes secret to store the Vault credentials (the Vault token)

VAULT_TOKEN="test"

kubectl create secret generic vault-token --from-literal=token=${VAULT_TOKEN} \
  --namespace external-secrets
```
