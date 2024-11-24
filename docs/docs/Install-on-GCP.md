# Install on GCP

## Option A: Using ./gcp/bootstrap/

```sh
# Create namespaces first
kubectl apply -f ./gcp/bootstrap/ns-traefik.yaml -f ./gcp/bootstrap/ns-argocd.yaml

# Create the rest of the resources
kubectl apply -f ./gcp/bootstrap/
```

## Option B: with Helm

```sh
# Install Traefik
helm upgrade --install traefik traefik/traefik --namespace traefik --create-namespace -f ./traefik/values.yaml

# Install ArgoCD
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --values argocd/values.yaml
```
