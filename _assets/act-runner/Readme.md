# Act Runner

## token

```sh
#gitea --config /etc/gitea/app.ini actions generate-runner-token
kubectl exec --stdin=true --tty=true $(k match-name debug-shell) -- /bin/sh -c "gitea actions generate-runner-token"

```

## Configuration in Docker

- <https://docs.gitea.com/usage/actions/act-runner#install-with-the-docker-image>

## Fixing problem in the log below

- <https://forum.gitea.com/t/cannot-checkout-a-repository-hosted-on-a-gitea-instance-using-self-signed-certificate-server-certificate-verification-failed/7903/4>

```log
level=info msg="Starting runner daemon"
level=error msg="fail to invoke Declare" error="unavailable: tls: failed to verify certificate: x509: certificate signed by unknown authority"
Error: unavailable: tls: failed to verify certificate: x509: certificate signed by unknown authority
act-runner-root exited with code 1
```

The problem was fixed by updating the config.yaml file

```yaml
  # Whether skip verifying the TLS certificate of the Gitea instance.
  # insecure: false
  insecure: true
```

## Other

```log
2024-11-17 00:48:56 level=info msg="Registering runner, arch=amd64, os=linux, version=v0.2.11."
2024-11-17 00:48:56 level=error msg="Invalid input, please re-run act command." error="instance address is empty"
2024-11-17 00:48:56 Waiting to retry ...
```
