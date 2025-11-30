## Install Strimzi Kafka Operator

```bash
# Install Strimzi Kafka Operator
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f -

# Delete Strimzi Kafka Operator
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f -
```