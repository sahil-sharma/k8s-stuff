## Install and manage Kafka clusters via Strimzi Kafka Operator

> Make sure Kafka Operator CRDs and controller is already installed. Check [kafka-operator](https://github.com/sahil-sharma/k8s-stuff/tree/main/kafka-operator) folder for installation.

### Cluster with Oauth support

If you want to install kafka-cluster with Oauth support with Keycloak then install kafka cluster from cluster-with-oauth folder

> Make sure Keycloak is configure for Kafka realm. Check [keycloak-kafka-terraform](https://github.com/sahil-sharma/k8s-stuff/tree/main/keycloak-kafka-terraform) folder for installation.

```bash
cd cluster-with-oauth

# Install Kafka Cluster
kubectl kustomize cluster --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# Install Kafka Bridge
kubectl kustomize bridge --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# Install Kafka Connect
kubectl kustomize connect --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# Install Kafka kafbat UI
kubectl kustomize kafka-ui --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

### Cluster without Oauth support

```bash
cd cluster-with-oauth

# Install Kafka Cluster
kubectl kustomize cluster --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# Install Kafka Bridge
kubectl kustomize bridge --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# Install Kafka Connect
kubectl kustomize connect --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# Install Kafka kafbat UI
kubectl kustomize kafka-ui --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```