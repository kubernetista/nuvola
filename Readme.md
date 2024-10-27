# Set up Nuvola environment

## Create k3d cluster

```sh
# Check Clusters and Registries already present
k3d cluster list
k3d registry list

# 📚 Create Registry
# k3d registry create registry --port ${K3D_REGISTRY_PORT}

# Check latest k3s version available
k3d version list k3s | head

# Create k3d configuration from template
envsubst < ./k3d/template/k3d-nuvola-cluster-config_TEMPLATE.yaml > ./k3d/cluster/k3d-nuvola-cluster-config.yaml

# Just ⚖️
just k3d-cluster-generate-config

# Just ⚖️
just k3d-cluster-create

#

```

## Install Traefik

```sh
# Add helm repo and update
helm repo add traefik https://traefik.github.io/charts
helm repo update

# ✅ Install Traefik
helm upgrade --install traefik traefik/traefik -n traefik --create-namespace --wait  -f ./traefik/values.yaml

```

## Install ArgoCD

```sh
# Set up Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# ✅ Install with Helm
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --wait --values ./argocd/values.yaml

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
