# Nuvola Quick setup (& problems) - Mark 3

## Setup

Do I still need port 2222 (✅) and 3000 (❌) ❓❓

```sh
# Create (with the config already created and updated)
cd nuvola

#
echo ${K3D_CLUSTER}

#
just k3d-cluster-generate-config

#
just k3d-cluster-create

#
kubectl apply -f secrets/

#
argocd admin initial-password -n argocd | head -n 1
```

## Generate a certificate with mkcert, and add it to the Gitea Ingress

```sh
# Generate the certs with expiration in 20gg using kixelated/mkcert
cd kixelated-mkcert/

# Generate
./mkcert -days=20 '*.localtest.me'

# Check
openssl x509 -in _wildcard.localtest.me.pem -noout -text | bat -l yaml

# Copy the files to the nuvola repo, in a directory excluded from git
cp _wildcard.localtest.me* ../_nuvola/nuvola/_assets/secrets/

# Eventually the other certs are in the project `traefik-mkcert-docker`
cd traefik-mkcert-docker/certs

# Switch to the directory containing the certs
cd nuvola/_assets/secrets

# Rename
CERT_NAME="wildcard-localtest-me"
mv _wildcard.localtest.me.pem  ${CERT_NAME}.pem
mv _wildcard.localtest.me-key.pem  ${CERT_NAME}-key.pem

# Generate kubernetes secret with the cert ${CERT_NAME}.pem
kubectl create -n default secret tls ${CERT_NAME}-tls \
    --cert=${CERT_NAME}.pem --key=${CERT_NAME}-key.pem \
    --dry-run=client -o yaml | kubectl neat > secret-tls-${CERT_NAME}.yaml

# Create
kubectl apply -f secret-tls-${CERT_NAME}.yaml

# Restart Traefik to load the new cert
kubectl rollout restart deployment traefik -n traefik

# Get the ArgoCD initial password and open the web UI
argocd admin initial-password -n argocd | head -n 1

```

### Next steps: check the Vault-ESO Readme

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

## Traefik

See above for Option 1

### Option 2: update Traefik and make it use the mkcert custom CA

Reference:

- How to do it with Docker compose
  - <https://medium.com/@clintcolding/use-your-own-certificates-with-traefik-a31d785a6441>

Relevant part of Helm values:

```yaml
# -- Add volumes to the traefik pod. The volume name will be passed to tpl.
# This can be used to mount a cert pair or a configmap that holds a config.toml file.
# After the volume has been mounted, add the configs into traefik by using the `additionalArguments` list below, eg:
`additionalArguments:
- "--providers.file.filename=/config/dynamic.toml"
# - "--ping"
# - "--ping.entrypoint=web"`
volumes:
- name: public-cert
  mountPath: "/certs"
  type: secret
- name: '{{ printf "%s-configs" .Release.Name }}'
  mountPath: "/config"
  type: configMap
```

---

## Old docs snippets

Other certs

```sh
# ArgoCD
kubectl create -n argocd secret tls argocd-server-tls \
    --cert=argocd.localhost.pem --key=argocd.localhost-key.pem \
    --dry-run=client -o yaml | kubectl neat > secret-tls-argocd-server-tls.yaml

# Create
kubectl apply -f secret-tls-argocd-server-tls.yaml

# Wildcard
kubectl create -n traefik secret tls wildcard-localhost-tls \
    --cert=_wildcard.localhost.pem --key=_wildcard.localhost-key.pem \
    --dry-run=client -o yaml | kubectl neat > secret-tls-wildcard-localhost.yaml

```
