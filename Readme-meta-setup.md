# k3d bootstrap

## Keep the k3d bootstrap manifests updated

### Reference

- <https://k3d.io/v5.7.4/usage/configfile/>
- <https://docs.k3s.io/installation/packaged-components>
- <https://docs.k3s.io/helm>
- <https://docs.k3s.io/advanced>
- <https://docs.k3s.io/installation/configuration#configuration-file>

HelmCharts and HelmChartsConfig are *__k3s native__* alternatives to the rendered helm manifests used below.

### CLI

```sh
# ArgoCD
helm template argocd argo/argo-cd -n argocd --create-namespace --values argocd/values.yaml > k3d/bootstrap/argocd-manifests.yaml

# Traefik
helm template traefik traefik/traefik -n traefik --create-namespace -f ./traefik/values.yaml > k3d/bootstrap/traefik-manifests.yaml

# App of apps
cp ./apps/apps.yaml ./k3d/bootstrap/
```

## Certificates

<!-- markdownlint-disable MD024 -->
### Reference
<!-- markdownlint-enable MD024 -->

- <https://docs.k3s.io/cli/certificate>
- <https://github.com/k3s-io/k3s/blob/master/contrib/util/generate-custom-ca-certs.sh>

```sh
#
```
