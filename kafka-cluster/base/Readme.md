## Install and manage Kafka clusters via Strimzi Kafka Operator with External Secrets support

> Ensure External Secret and Strimzi Kafka Operator is already installed

> Kafka cluster broker: http://kafka.local.io:32080

```bash
# Install Kafka cluster
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f -

# Delete Kafka cluster
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f -
```