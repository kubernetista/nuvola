# Use Nuvola

## Argo Workflows

```sh
# Submit a job
argo submit --serviceaccount argo-workflow https://raw.githubusercontent.com/argoproj/argo-workflows/master/examples/hello-world.yaml --watch
```

## Argo Events

```sh
# Deploy the default (NatsStreaming based) EventBus
kubectl apply -n ${RESOURCE_NS} -f eventBus.yaml
```

## TODO: Dagger
