# Demo

## Create nuvola

```sh
# delete current cluster
k3d cluster delete nuvola-5

# 👉🏻 Quick Start 👈🏻

# Watch pod creation, until ArgoCD is deployed
kubectl get pod -A -w

# Get the ArgoCD initial password
argocd admin initial-password -n argocd | head -n 1

# Login to ArgoCD
argocd login --insecure --grpc-web --username admin argocd.localtest.me

# Refresh the app-of-apps (to speed up the process)
argocd app get <appName> --hard-refresh

# Check progress
argocd app wait apps --health --sync

```

## fastapi-uv

```sh
# test push
j dagger-test-push-local

# show recipes
j dagger-
j dagger-test
j dagger-build

# CI
j dagger-ci
```

## nuvola-docs

```sh
# serve docs
j serve

# build container
j cnt-build-push-restart
```

## nuvola/_assets

```sh
# register
j register-runner <token>

# start
j start-runner
```

## Go back to Nuvola 4

```sh
# Stop current cluster
k3d cluster stop ${K3D_CLUSTER}

# Start old cluster
k3d cluster start nuvola-4

# Merge kubeconfig
k3d kubeconfig merge -d nuvola-4

# check
kubectl get po -A

```
