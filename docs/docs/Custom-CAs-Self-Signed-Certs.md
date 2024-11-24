# Use self-signed Certs or custom CA

For git, docker, etc.

Reference:

- <https://stackoverflow.com/questions/9072376/configure-git-to-accept-a-particular-self-signed-server-certificate-for-a-partic>
- Gitlab: Self-signed certificates or custom Certification Authorities
  - <https://docs.gitlab.com/runner/configuration/tls-self-signed.html>

```sh
GIT_HOST="git.localtest.me"

# Show the custom cert
openssl s_client -showcerts -connect ${GIT_HOST}:443 -servername ${GIT_HOST} < /dev/null 2>/dev/null | \
    openssl x509 -outform PEM

# Save it (i.e. for a gitlab-runnner in this case)
openssl s_client -showcerts -connect ${GIT_HOST}:443 -servername ${GIT_HOST} < /dev/null 2>/dev/null | \
    openssl x509 -outform PEM > > /etc/gitlab-runner/certs/${GIT_HOST}.crt

```
