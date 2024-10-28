# k3s Monitroring and Logging

## TODO:  Logging

### Reference

- <https://docs.k3s.io/advanced#additional-network-policy-logging>
- <https://ranchermanager.docs.rancher.com/v2.6/integrations-in-rancher/logging/logging-architecture>
- <https://github.com/kube-logging/logging-operator>
- <https://kube-logging.dev/docs/quickstarts/single/>
- <https://kube-logging.dev/docs/examples/kafka-nginx/>

### CLI

Example Kafka setup

```sh
# Install Logging Generator
helm upgrade --install --wait --create-namespace --namespace logging log-generator oci://ghcr.io/kube-logging/helm-charts/log-generator

# Install Kafka consumer
kubectl -n kafka run kafka-consumer -it --image=banzaicloud/kafka:2.13-2.4.0 --rm=true --restart=Never -- /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka-headless:29092 --topic topic --from-beginning
```

## TODO: Monitoring

<!-- markdownlint-disable MD024 -->
### Reference
<!-- markdownlint-enable MD024 -->

- <https://docs.k3s.io/advanced>

<!-- markdownlint-disable MD024 -->
### CLI
<!-- markdownlint-enable MD024 -->

```sh
#
```