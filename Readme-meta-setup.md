# k3d bootstrap

### Reference

- <https://k3d.io/v5.7.3/usage/configfile/>
- <https://docs.k3s.io/installation/packaged-components>
- <https://docs.k3s.io/helm#automatically-deploying-manifests-and-helm-charts>
- <https://docs.k3s.io/advanced>

## Keep the bootstrap manifests updated

```sh
# ArgoCD
helm template argocd argo/argo-cd -n argocd --create-namespace --values argocd/values.yaml > k3d/bootstrap/argocd-manifests.yaml

# Traefik
helm template traefik traefik/traefik -n traefik --create-namespace -f ./traefik/values.yaml > k3d/bootstrap/traefik-manifests.yaml

# App of apps
cp ./apps/apps.yaml ./k3d/bootstrap/
```
