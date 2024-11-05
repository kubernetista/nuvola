# Justfile

# Variables
# IMAGE_NAME := "fastapi-uv:latest"

# List 📜 all recipes (default)
help:
    @just --list

# Generate k3d cluster config from template
k3d-cluster-generate-config:
    @#rm -fv ./k3d/cluster/k3d-nuvola-cluster-config.yaml
    @cat ./k3d/template/k3d-nuvola-cluster-config_TEMPLATE.yaml | envsubst >./k3d/cluster/k3d-${K3D_CLUSTER}-cluster-config.yaml
    @ls -1 ./k3d/cluster/k3d-${K3D_CLUSTER}-cluster-config.yaml

# Create k3d cluster using configuration file
k3d-cluster-create:
    k3d cluster create ${K3D_CLUSTER} --config=./k3d/cluster/k3d-${K3D_CLUSTER}-cluster-config.yaml
    @kubectl cluster-info

# Push the git repo to the local remote, creating the repository if it doesn't exist
git-push-local:
    git push -o repo.private=false -u local main

# Deploy the application to the k3d cluster
secrets-tls-deploy:
    #!/usr/bin/env bash
    echo "Creating TLS secret for wildcard-localtest-me"

    # Switch to the directory containing the certs
    cd ./_assets/secrets

    # Create the secret containing the TLS certificate and its key
    export CERT_NAME="wildcard-localtest-me"
    pwd
    kubectl apply -f secret-tls-${CERT_NAME}.yaml

    # Restart Traefik to load the new cert
    kubectl rollout restart deployment traefik -n traefik
