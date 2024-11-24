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
