# Dagger

## TODO:  Dagger in Kubernetes and Argo Workflows

### Reference

- <https://docs.dagger.io/integrations/kubernetes/>
- <https://docs.dagger.io/integrations/argo-workflows>

### CLI

Dagger setup in Kubernetes

```sh
#
helm upgrade --install --namespace=dagger --create-namespace \
    dagger oci://registry.dagger.io/dagger-helm
```
