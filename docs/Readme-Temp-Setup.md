# Temporary startup procedure for Nuvola

## Startup

```sh
# Start Nuvola cluster
k3d cluster start nuvola-2

# Start external Traefik + Dagger Engine Custom (with mkcert CA)
cd /_projects/Aruba-DevOps/_dagger/dagger-publish-to-local-registry
docker compose --profile full up

# Start macOS act-runner
cd ~/_projects/Aruba-DevOps/_nuvola/nuvola/_assets
sudo act_runner daemon --config ./runner-config.yaml
```

## Test Dagger on FastAPI demo application

```sh
cd ~/_projects/Aruba-DevOps/fastapi-demo

dagger functions

dagger build

dagger publish-local

dagger publish-gitea
```
