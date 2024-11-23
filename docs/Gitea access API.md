# Gitea: access the API

Reference:

- <https://docs.gitea.com/development/api-usage#api-guide>
- <https://gitea.com/api/swagger#/repository/updateRepoSecret>
- <https://docs.gitea.com/usage/usage/secrets>

```sh
# Set vars
GITEA_USERNAME="aruba-demo"

GITEA_HOSTNAME="git.localtest.me"
GITEA_USERNAME="$(op read 'op://Private/ujfrvzi2gwbjozczjg2cjl27v4/username')"
GITEA_PASSWORD="$(op read 'op://Private/ujfrvzi2gwbjozczjg2cjl27v4/password')"

# Starting point
curl -H "Content-Type: application/json" -d '{"name":"test"}' -u ${GITEA_USERNAME}:${GITEA_PASSWORD} \
  https://${GITEA_HOSTNAME}/api/v1/users/${GITEA_USERNAME}/tokens

# Updated command
curl -H "Content-Type: application/json" \
  -d '{"name":"test","scopes":["write:repository","write:user"]}' \
  -u ${GITEA_USERNAME}:${GITEA_PASSWORD} \
  https://${GITEA_HOSTNAME}/api/v1/users/${GITEA_USERNAME}/tokens

# Successful response with token
{"id":1,"name":"test","sha1":"9fcb1158165773dd010fca5f0cf7174316c3e37d","token_last_eight":"16c3e37d"}

# ✅ Automated
GITEA_AUTH_TOKEN=$(curl -s -H "Content-Type: application/json" \
  -d '{"name":"test","scopes":["write:repository","write:user"]}' \
  -u ${GITEA_USERNAME}:${GITEA_PASSWORD} \
  https://${GITEA_HOSTNAME}/api/v1/users/${GITEA_USERNAME}/tokens | yq '.sha1' -r)
echo ${GITEA_AUTH_TOKEN}

# Create a secret (with the op secret reference)
curl -v -X PUT \
  "https://${GITEA_HOSTNAME}/api/v1/repos/${GITEA_USERNAME}/fastapi-uv/actions/secrets/REGISTRY_PASSWORD" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: token caaa8dd79d5b9372b4f4e15eddc9008773327c92" \
  -d "{
  \"data\": \"$(op read 'op://Private/ujfrvzi2gwbjozczjg2cjl27v4/password')\"
}"

# ✅ Create a secret using the GITEA_PASSWORD env var
curl -v -X PUT \
  "https://${GITEA_HOSTNAME}/api/v1/repos/${GITEA_USERNAME}/fastapi-uv/actions/secrets/REGISTRY_PASSWORD" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: token ${GITEA_AUTH_TOKEN}" \
  -d "{
  \"data\": \"${GITEA_PASSWORD}\"
}"

```
