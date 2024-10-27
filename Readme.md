# Set up Nuvola environment

```sh
# Check Clusters and Registries
k3d cluster list
k3d registry list

# 📚 Create Registry
k3d registry create registry --port ${K3D_REGISTRY_PORT}

# Check latest k3s version available
k3d version list k3s | head

# Create k3d configuration from template
envsubst < ./k3d/template/k3d-nuvola-cluster-config_TEMPLATE.yaml > ./k3d/cluster/k3d-nuvola-cluster-config.yaml
