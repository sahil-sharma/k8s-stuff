## Install KEDA for scaling deployments based on some events

```bash
# Install Kafka cluster
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply --server-side -f -

# Delete Kafka cluster
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f -
```