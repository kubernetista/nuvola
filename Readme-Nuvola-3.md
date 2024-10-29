# Nuvola 3/4: Setup & Problems

# Setup

Do I still need port 2222 (✅) and 3000 (❌) ❓❓

```sh
# Create (with the config already created and updated)
cd nuvola/
echo ${K3D_CLUSTER}
just k3d-cluster-create
kubectl apply -f secrets/
argocd admin initial-password -n argocd | head -n 1

# Test
cd fastapi-uv
git push local
dagger call test-publish-local --registry git.localhost

cd nuvola
git push local

cd fastapi-demo
git push local

docker push git.localhost/aruba-demo/alpine:latest

```

# Check http/https access

```sh
#
http --verify no https://git.localhost
```

## Verify Certificate

```sh
#
openssl s_client -showcerts -connect git.localhost:443 </dev/null | bat -l yaml
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
git remote add local https://git.localhost/aruba-demo/$(basename "${PWD}").git

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

Reference:

- How to do it with Docker compose
  - <https://medium.com/@clintcolding/use-your-own-certificates-with-traefik-a31d785a6441>

### Option 1: update Traefik and make it use the mkcert custom CA

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

### Option 2: generate a certificate with mkcert, and add it to the Gitea Ingress

Reference:

- <https://chatgpt.com/share/672100f4-3d68-8006-8965-ba2211fbfeb0>

```sh
# The certs are in the project `traefik-mkcert-docker`
cd traefik-mkcert-docker/certs

# Generate kubernetes secret
kubectl create -n git secret tls git-localhost-tls \
    --cert=git.localhost.pem --key=git.localhost-key.pem \
    --dry-run=client -o yaml | kubectl neat > secret-tls-git-localhost.yaml

# Create
kubectl apply -f secret-tls-git-localhost.yaml

# Update the gitea helm chart

```

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
