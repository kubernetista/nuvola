# Gitea Runner

## Reference

- <https://gitea.com/gitea/act_runner/src/branch/main/examples/kubernetes>

### Fix 1

- <https://namesny.com/blog/gitea_actions_k3s_docker/>
- <https://github.com/catthehacker/docker_images/pkgs/container/ubuntu/282279167?tag=act-latest-20241001>

### Other fixes

- <https://gitea.com/gitea/act_runner/issues/280>
- <https://hub.docker.com/_/docker/tags?name=dind>
- <https://forum.gitea.com/t/act-runner-in-k8s-fail-to-connect-to-docker-daemon/8736/8>

## catthehacker act runner docker images

<https://github.com/catthehacker/docker_images/tree/master>
<https://github.com/catthehacker/docker_images/pkgs/container/ubuntu/versions?filters%5Bversion_type%5D=tagged>

## Run the act-runner locally

```sh
# generate a config file
act_runner generate-config > ./gitea-runner/config/runner-config.yaml

# edit the file

# start act_runner with the new config file
sudo act_runner daemon --config ./gitea-runner/config/runner-config.yaml
```

### Get the certificates from Traefik

To be able to push to the Gitea container registry, it's needed to access it via HTTPS (why❓❓), so the easiest way is to build the container using docker inside the act_runner container
<!-- - ghcr.io/catthehacker/ubuntu:act-latest -->
- ghcr.io/catthehacker/ubuntu:runner-latest

 My customized version actually, running the root user, built with the dockerfile `../fastapi-demo/runner-root.dockerfile`

- ghcr.io/kubernetista/runner-root:v2

This works and has been tested already, I'm able to build a container inside the local act runner, it still creates another container in docker, where the docker client actually runs and all the good stuff.

But I still need to add the certificates to be able to push to the Gitea Container Registry.

To make it work, follow the instructions:

- <https://forum.gitea.com/t/cannot-checkout-a-repository-hosted-on-a-gitea-instance-using-self-signed-certificate-server-certificate-verification-failed/7903>

```sh
#
kubectl get configmap kube-root-ca.crt -n traefik -o jsonpath='{.data.ca\.crt}' > ca.crt
```
