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

## Build a cvustom act-runner image

- <https://docs.gitea.com/usage/actions/act-runner#install-with-the-docker-image>

To be able to bypass problems with the self-signed CA and the generated TLS certificates
it's necessary to build a custom runner, starting from

`ghcr.io/catthehacker/ubuntu:runner-latest`

- <https://github.com/catthehacker/docker_images?tab=readme-ov-file>

And customizing it to add the certificates, but also to make it more similar to the official
act-runner from gitea

`gitea/act_runner:latest`

- <https://hub.docker.com/r/gitea/act_runner/tags>

Add tini:

- <https://github.com/krallin/tini>

Reference:

- <https://gitea.com/gitea/act_runner/src/commit/f17cad1bbe0d4a84308a37fb4a5e64211ada7e8a/examples/kubernetes/rootless-docker.yaml>
- <https://namesny.com/blog/gitea_actions_k3s_docker/>
- <https://forum.gitea.com/t/cannot-checkout-a-repository-hosted-on-a-gitea-instance-using-self-signed-certificate-server-certificate-verification-failed/7903/1>
- <https://github.com/nodiscc/xsrv/tree/master/roles/gitea_act_runner>
- <https://gitea.com/gitea/act_runner/issues/280>
- <https://forum.gitea.com/t/act-runner-in-k8s-fail-to-connect-to-docker-daemon/8736/3>
- <https://gist.github.com/mariusrugan/911f5da923c93f3c795d3e84bed9e256>
