# Set up Nuvola environment

## Install ArgoCD with Helm

```sh
# Set up Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# ✅ Install with Helm
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --wait \
  --values argocd/values.yaml

# 🔎 Get password
argocd admin initial-password -n argocd | head -n 1
# Or
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ;  echo

# Login from CLI
argocd login --insecure --grpc-web --username admin argocd.localhost:8443
# argocd login --insecure --username admin argocd.localhost:8443

```

## Add ArgoCD apps

```sh
# Add ArgoCD and Traefik apps
kubectl apply -f argocd/argocd.yaml -f apps/traefik.yaml
# Add all the other apps/
kubectl apply -f apps/apps.yaml
```

## 🛑 Continue the setup in Readme1-ArgoCD, inside project ArgoCD-Setup

## Push image used by the whoami app to the k3d-registry

```sh
docker tag traefik/whoami registry.localhost:5000/traefik-whoami
docker push registry.localhost:5000/traefik-whoami
```

## Push this git repo to local Gitea

```sh
# add Gitea remote (execute from the git repo base directory)
git remote add local http://git.localhost:8000/aruba-demo/$(basename "${PWD}").git

# Push and create a public repo
git push -o repo.private=false -u local main
```

## Configure Gitea Runner

Get the Runner Registration Token

```sh
# for the gitea instance
open <http://git.localhost:8000/admin/actions/runners>

# or for the current user
open <http://git.localhost:8000/user/settings/actions/runners>

# Click 🖱️ on "Create new Runner" and copy 📑 the REGISTRATION TOKEN


# Set the RUNNER_TOKEN env variable
export RUNNER_TOKEN="<token>"
echo ${RUNNER_TOKEN}

# Base64 encode the token
# export RUNNER_TOKEN_B64=$(echo ${RUNNER_TOKEN} | base64)
# echo ${RUNNER_TOKEN_B64}

# Update 📋  the token in the Runner deployment
./scripts/gitea-runner.sh
# yq

# Commmit the updated token deployment
git add gitea-runner/rootless.yaml
git commit -m "update gitea-runner token"

# Git push, either to the remote repo or to the local gitea instance
git push local main
# git push origin main

```
