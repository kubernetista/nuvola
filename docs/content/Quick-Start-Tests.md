## Test

```sh
# GITEA_HOST="git.localhost"
GITEA_HOST="git.localtest.me"

# Test
cd fastapi-uv
git push local
dagger call test-publish-local --registry ${GITEA_HOST}

cd nuvola
git push local

cd fastapi-demo
git push local

docker push ${GITEA_HOST}/aruba-demo/alpine:latest

```

# Check http/https access

```sh
#
http --verify no https://${GITEA_HOST}
```

## Verify Certificate

```sh
# check ${GITEA_HOST} certificate
openssl s_client -showcerts -connect ${GITEA_HOST}:443 </dev/null | bat -l yaml
```

## Git Push

Reference:

Configure git with self-signed CA and Certs

- <https://stackoverflow.com/questions/11621768/how-can-i-make-git-accept-a-self-signed-certificate>

```sh
# Check remote
git remote -v
git remote remove local

# Set "local" remote
git remote add local https://${GITEA_HOST}/aruba-demo/$(basename "${PWD}").git

# Set upstream and push
git -c http.sslVerify=false push -u local main
# same as
GIT_SSL_NO_VERIFY=true git push -u local main
# or
export GIT_SSL_NO_VERIFY=true
git push -u local main

# Subsequent push to local
git -c http.sslVerify=false push local
```
