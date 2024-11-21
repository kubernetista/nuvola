# Act Runner

## Update token in Vault

```sh
#gitea --config /etc/gitea/app.ini actions generate-runner-token

# After a Gitea reinstallation, get the current (old) token from Vault
# using tr to remove both newline and carriage return
GITEA_RUNNER_REGISTRATION_TOKEN=$(kubectl exec -n git --stdin=true --tty=true $(kubectl get pods -n git -l 'app.kubernetes.io/name=gitea,app.kubernetes.io/component!=token-job,app.kubernetes.io/instance=gitea' -o name) -c gitea -- /bin/sh -c "gitea actions generate-runner-token" | tr -d '\r\n')

echo ${GITEA_RUNNER_REGISTRATION_TOKEN}

# Verify no newline
echo -n "$GITEA_RUNNER_REGISTRATION_TOKEN" | hexdump -C

# Eventually clean the existing variable
GITEA_RUNNER_REGISTRATION_TOKEN=$(echo -n "$GITEA_RUNNER_REGISTRATION_TOKEN" | tr -d '\r\n')

# Check if there is already a Vault token
echo $VAULT_TOKEN

# Get a Vault token to save the current token in Vault:
export VAULT_TOKEN="$(vault token create -ttl=24h -format=json | jq -r .auth.client_token)"

# Save the updated Gitea runner registration token in Vault:
vault kv put secret/gitea/runner-registration-token GITEA_RUNNER_REGISTRATION_TOKEN="${GITEA_RUNNER_REGISTRATION_TOKEN}"

# Check
vault kv get -format=json -mount="secret" "gitea/runner-registration-token" | jq

```

## Start the runners

```sh
# Check that the env var is present (via direnv and teller, requires VAULT_TOKEN to be set)
teller env
echo ${GITEA_RUNNER_REGISTRATION_TOKEN}

# Start and register the runners
just start-runner

# In case the env var is not present you can also invoke teller directly
teller run -- just start-runner

```

## Configuration in Docker

- <https://docs.gitea.com/usage/actions/act-runner#install-with-the-docker-image>

## Start with docker for debug

```sh
# start the container
docker run -it --network host \
  -v ./data-1:/data \
  -v ./config.yaml:/config.yaml \
  -v ./run.sh:/opt/act/run.sh  \
  ghcr.io/kubernetista/act-runner-nuvola:latest bash

# export the required vars
export GITEA_RUNNER_NAME=test
export GITEA_RUNNER_LABELS=docker
# export GITEA_RUNNER_LABELS=macos
export CONFIG_FILE=/config.yaml
export GITEA_HOSTNAME=git.localtest.me
export GITEA_INSTANCE_URL=https://${GITEA_HOSTNAME}/
export GITEA_RUNNER_REGISTRATION_TOKEN=eOrMkkIqEmbO4SplU9WNLv3TxsBc5E5R2l9nd9DN

# start the entrypoint script
/opt/act/run.sh

```

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

## Build a custom act-runner image

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
