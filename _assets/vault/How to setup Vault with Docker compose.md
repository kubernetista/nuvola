# How to setup Vault with Docker compose for the Nuvola environment

```sh
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

vault operator init
vault operator unseal

export VAULT_TOKEN='your-root-token'
vault login

```

```sh
# set vault
export VAULT_ADDR='<http://127.0.0.1:8200>'

# Enable KV secrets engine version 2
# Using a container
docker exec -it vault vault secrets enable -path=secret kv-v2

# Using a local vault CLI
vault secrets enable -path=secret kv-v2

# Create policy file
cat > vault-policy.hcl << EOF
path "secret/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "secret/metadata/*" {
  capabilities = ["list"]
}
EOF

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

## Updaste policy

```sh
# Read the current default policy, and add the new policy at the end
vault policy read default > ./tmp/vault-default-policy.hcl
cat ./tmp/vault-default-policy.hcl ./vault-policy-addendum.hcl > ./tmp/vault-new-policy.hcl

# Write the new policy to vault
vault policy write default ./tmp/vault-new-policy.hcl
```

# Create kubernetes resources

```sh
# Create the resources for Extrenal Secrets Operator and the ESO test app
kubectl apply -f ./yaml/

# Restart external secrets to speed up the process
kubectl rollout restart -n external-secrets external-secrets

# Restart the test app to speed up the process
kubectl rollout restart deployment vault-eso-test-app -n default

# check logs
stern -t -n external-secrets external-secrets

# check update in the vault-test-app (with http, viddy and htmltidy CLI tools)
viddy -n 5 -ds 'http https://vault-test.localtest.me/ | tidy -qi -w 0 --tidy-mark no -f /dev/null'

```
