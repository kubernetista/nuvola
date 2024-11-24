# Secrets in Vault


## Get a temporary Vault token (24h) to access Vault via CLI

```sh
export VAULT_TOKEN="$(vault token create -ttl=24h -format=json | jq -r .auth.client_token)"
```

## List all the Vault (KV) secrets

```sh
vault kv list secret
# descend the available paths
vault kv list secret/gitea

# get a secret below the root level
vault kv get -mount="secret" "tls/wildcard-localtest-me"
# this should work too, but sometimes fails with access denied, perhaps due to metadata access missing (check the policy or create a new one)?
vault kv get secrets/tls/wildcard-localtest-me


# Base64 encode of a field with yq
vault kv get -format=json -mount="secret" "fake-db-credentials" | yq '.data.data.password | @base64'
vault kv get -format=json -mount="secret" "fake-db-credentials" | yq '.data.data.password |= @base64' | jq

```

## List of secrets

Name: `gitea/runner-registration-token`
OLD Name: `act-runner`
Path: `/v1/secret/data/gitea/runner-registration-token`
CLI get: `vault kv get -mount="secret" "gitea/runner-registration-token"`
CLI set: `vault kv put secret/gitea/runner-registration-token GITEA_RUNNER_REGISTRATION_TOKEN="  <token>  "`
Content:

Procedure to extract the value and save it to Vault after Gitea reinstall

```sh
export GITEA_RUNNER_REGISTRATION_TOKEN=$(kubectl exec -n git --stdin=true --tty=true $(kubectl match-name -n git gitea) -c gitea -- /bin/sh -c "gitea actions generate-runner-token")

# Save the updated Gitea runner registration token in Vault:
vault kv put secret/gitea/runner-registration-token GITEA_RUNNER_REGISTRATION_TOKEN="${GITEA_RUNNER_REGISTRATION_TOKEN}"

```

```json
{
  "GITEA_RUNNER_REGISTRATION_TOKEN": "KxKgUy419jnwAkkaBhu73PqD7VPbN7nhkKuE8eyY"
}
```

Name: `gitea/admin-credentials`
OLD Name: `gitea-admin-secret`
Path: `/v1/secret/data/gitea/admin-credentials`
CLI get: `vault kv get -mount="secret" "gitea/admin-credentials"`
CLI set: `vault kv put secret/gitea/admin-credentials username="aruba-demo" password="K4g6@8AtD@V9-7dpiaDv"`
Content:

```json
{
  "username": "YXJ1YmEtZGVtbw==",
  "password": "TmVPemVyc0NocU45ZnlkbA=="
}
```

Name: `tls/wildcard-localtest-me`
OLD Name: `wildcard-localtest-me-tls`
Path: `/v1/secret/data/tls/wildcard-localtest-me`
CLI Get: `vault kv get -mount="secret" "tls/wildcard-localtest-me"`
CLI Set: `vault kv put secret/tls/wildcard-localtest-me tls.crt=@certs/wildcard-localtest-me.pem tls.key=@certs/wildcard-localtest-me-key.pem`
Content:

```json
{
  "username": "...",
  "password": "..."
}
```
