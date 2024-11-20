# How to setup Vault with Docker compose for the Nuvola environment

```sh
cd _assets/vault/

mkdir -p volumes/{logs,file,config}

touch volumes/{logs,file,config}/.gitkeep

cat <<EOF > volumes/config/vault.json
{
  "backend": {
    "file": {
      "path": "/vault/file"
    }
  },
  "listener": {
    "tcp": {
      "address": "0.0.0.0:8200",
      "tls_disable": 1
    }
  },
  "ui": true
}
EOF

cat <<EOF > compose.yaml
name: vault
services:
  vault:
    image: hashicorp/vault:latest
    container_name: vault

    environment:
      - VAULT_ADDR=http://127.0.0.1:8200
      - VAULT_API_ADDR=http://127.0.0.1:8200
    entrypoint: vault server -config=/vault/config/vault.json
    volumes:
      - ./volumes/logs:/vault/logs
      - ./volumes/file:/vault/file
      - ./volumes/config:/vault/config

    ports:
      - "8200:8200"
    cap_add:
      - IPC_LOCK
    restart: unless-stopped

    networks:
      - vault-net
    hostname: vault.docker.internal

networks:
  vault-net:
    name: vault-net

EOF

#export VAULT_ADDR='<http://localhost:8200>'
export VAULT_ADDR='<http:///127.0.0.1:8200>'

docker compose up -d


# Check status
http http://127.0.0.1:8200/v1/sys/health

vault status

vault operator init
vault operator unseal

export VAULT_TOKEN='your-root-token'
vault login

```

```sh
# set vault
export VAULT_ADDR='<http://127.0.0.1:8200>'

# 🛑 Already done with the config file
## Enable KV secrets engine version 2
## Using a container
# docker exec -it vault vault secrets enable -path=secret kv-v2
## Using a local vault CLI
# vault secrets enable -path=secret kv-v2
# vault secrets enable kv-v2


# Create long-lived token
VAULT_ADDR='<http://127.0.0.1:8200>'
vault token create \
    -policy=external-secrets \
    -no-default-policy \
    -format=json | jq -r ".auth.client_token"

# Create policy file
cat > vault-policy.hcl << EOF
path "secret/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "secret/metadata/*" {
  capabilities = ["list"]
}
EOF

❯❯ cat kv-read-policy.hcl
path "secret/data/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata/*" {
  capabilities = ["read", "list"]
}

❯❯ cat vault-policy-addendum.hcl
# NUVOLA: access for test apps
path "secret/*" {
  capabilities = [ "read", "list" ]
}


# Create policy
VAULT_ADDR='<http://127.0.0.1:8200>'
vault policy write external-secrets-policy vault-policy.hcl

# Create token with policy
VAULT_ADDR='<http://127.0.0.1:8200>'
vault token create -policy="external-secrets-policy" -format=json | jq -r .auth.client_token

# Create kubernetes secret
kubectl create secret generic vault-token \
    --from-literal=token=<TOKEN_FROM_ABOVE> \
    -n external-secrets

```

## Update policy

```sh
# Read the current default policy, and add the new policy at the end
vault policy read default > ./tmp/vault-default-policy.hcl
cat ./tmp/vault-default-policy.hcl ./vault-policy-addendum.hcl > ./tmp/vault-new-policy.hcl

# Write the new policy to vault
vault policy write default ./tmp/vault-new-policy.hcl
```

# Test access with teller

```sh
cat <<EOF > .teller.yml
project: test
providers:
  hashicorp_vault:
    env_sync:
      path: secret/data/test
EOF

#vault token create -ttl=24h -format=json | jq -r .auth.client_token
export VAULT_TOKEN="$(vault token create -ttl=24h -format=json | jq -r .auth.client_token)"
export VAULT_ADDR="http://127.0.0.1:8200"
teller show
teller env
```

# Create a policy for Vault access

In case of need.

```sh
# Create policy file
cat > kv-read-policy.hcl << 'EOF'
path "secret/data/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/*" {
  capabilities = ["read", "list"]
}
EOF

# Write policy to Vault
VAULT_ADDR='http://127.0.0.1:8200' vault policy write kv-reader kv-read-policy.hcl

# Verify policy
VAULT_ADDR='http://127.0.0.1:8200' vault policy read kv-reader

# Create token with policy
VAULT_ADDR='http://127.0.0.1:8200' vault token create -policy=kv-reader -format=json | jq -r .auth.client_token
```

## Create kubernetes resources

For the vault-eso-test-app

```sh
# Create the resources for Extrenal Secrets Operator and the ESO test app
kubectl apply -f ./yaml/

# Update the secret in Vault to see if it's propagated to the test app
./increment-vault-secret-version.sh

# Restart external secrets to speed up the process
kubectl rollout restart -n external-secrets external-secrets

# Restart the test app to speed up the process
kubectl rollout restart deployment vault-eso-test-app -n default

# check logs
stern -t -n external-secrets external-secrets

# check update in the vault-test-app (with http, viddy and htmltidy CLI tools)
viddy -n 5 -dbs 'http https://vault-test.localtest.me/ | tidy -qi -w 0 --tidy-mark no -f /dev/null | bat -pP --color=always'

```
