# Justfile

# Variables
# IMAGE_NAME := "fastapi-uv:latest"

# default:
#     echo 'Hello, world!'

# List 📜 all recipes (default)
help:
    @just --list

# Generate k3d cluster config from template
k3d-cluster-generate-config:
    @rm -fv ./k3d/cluster/k3d-nuvola-cluster-config.yaml
    @cat ./k3d/template/k3d-nuvola-cluster-config_TEMPLATE.yaml | envsubst >./k3d/cluster/k3d-nuvola-cluster-config.yaml

# Create k3d cluster using configuration file
k3d-cluster-create:
    k3d cluster create ${K3D_CLUSTER} --config=./k3d/cluster/k3d-nuvola-cluster-config.yaml
    @kubectl cluster-info
