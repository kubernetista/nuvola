# ArgoCD generate admin password

It can be set before deployment in the Helm values at:
`config.secret.argocdServerAdminPassword`

Reference:

- <https://github.com/argoproj/argo-cd/issues/829>
- <https://unix.stackexchange.com/questions/307994/compute-bcrypt-hash-from-command-line>
- <https://stackoverflow.com/questions/15733196/where-2x-prefix-are-used-in-bcrypt/36225192#36225192>

```sh
# Generate a new password
ARGOCD_ADMIN_PASS=$(pwgen -s1 20 -n 1)
echo "ArgoCD new admin password: ${ARGOCD_ADMIN_PASS}"
ARGOCD_ADMIN_PASS_MTIME=$(date -u +'%Y-%m-%dT%H:%M:%SZ' | tr -d '\n')
ARGOCD_ADMIN_PASS=$(htpasswd -nbBC 10 "" "${ARGOCD_ADMIN_PASS}" | tr -d ':\n' | sed 's/$2y/$2a/'

# Update the secret (the values will be base64-encoded on the fly)
kubectl patch secret -n argocd argocd-secret \
  -p '{"stringData": { "admin.password": "'${ARGOCD_ADMIN_PASS}'" , "admin.passwordMtime": "'${ARGOCD_ADMIN_PASS_MTIME}'" }}'

echo "ArgoCD admin password updated."
```
