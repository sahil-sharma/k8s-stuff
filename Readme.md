# Cloud-Native Platform Deployment Guide

This repository contains the manifests and Terraform configurations to bootstrap a complete cloud-native ecosystem on a **Kind** cluster. The stack includes CNPG, Istio, Keycloak, Argo, Kafka, Vault, Chaos Testing Framework and a full Observability suite with few applications like online boutique app, welcome app, echo-server and echo-client.

---

## Platform Service URLs

| Service | URL |
| :--- | :--- |
| **Identity & Access (SSO)** | [http://sso.local.io](http://sso.local.io) |
| **Vault Secrets** | [http://secrets.local.io](http://secrets.local.io) |
| **OAuth2 Proxy** | [http://auth.local.io](http://auth.local.io) |
| **Grafana Dashboards** | [http://dashboards.local.io](http://dashboards.local.io) |
| **Prometheus Metrics** | [http://metrics.local.io](http://metrics.local.io) |
| **Loki Logs** | [http://logs.local.io](http://logs.local.io) |
| **Tempo Traces** | [http://traces.local.io](http://traces.local.io) |
| **Kiali (Mesh Traffic)** | [http://traffic.local.io](http://traffic.local.io) |
| **ArgoCD** | [http://cd.local.io](http://cd.local.io) |
| **Argo Workflows** | [http://jobs.local.io](http://jobs.local.io) |
| **Argo Rollouts** | [http://rollouts.local.io](http://rollouts.local.io) |
| **Kafka UI** | [http://kafka-ui.local.io](http://kafka-ui.local.io) |
| **Kafka Cluster (Bridge)** | [http://kafka-bridge.local.io](http://kafka-bridge.local.io) |
| **Kafka Connect** | [http://kafka-connect.local.io](http://kafka-connect.local.io) |
| **Kafka Cruise Control** | [http://cruise-control.local.io](http://cruise-control.local.io) |
| **Litmus Chaos** | [http://chaos.local.io](http://chaos.local.io) |
| **OTEL Collector** | [http://collector.local.io](http://collector.local.io) |
| **MinIO Storage** | [http://storage.local.io](http://storage.local.io) |
| **MinIO Console** | [http://console.storage.local.io](http://console.storage.local.io) |
| **Backstage (IDP)** | [http://idp.local.io](http://idp.local.io) |
| **Boutique App** | [http://store.local.io](http://store.local.io) |
| **Echo Server** | [http://echo-server.local.io](http://echo-server.local.io) |

---

## Phase 1: Cluster Setup & Networking

First, we initialize the local Kubernetes environment and configure core DNS and local host resolution.

1.  **Create Cluster**
    ```bash
    kind create cluster --config kind-config.yaml
    ```
2.  **Update and Restart CoreDNS**
    ```bash
    kubectl apply -f coredns-cm.yaml
    kubectl -n kube-system rollout restart deployment coredns
    ```
3.  **Local DNS Resolution**
    Ensure your `/etc/hosts` contains entries for your application domains pointing to the Kind cluster node IPs.
    ```bash
    # Get node IPs
    kubectl get nodes -o wide
    cat /etc/hosts
    ```

---

## Phase 2: Core Infrastructure (Prometheus CRDs & Istio & External Secrets)

Deploy monitoring CRDs, service mesh and external secret management layers.

1. **Prometheus CRDs**
```bash
kubectl create ns monitoring --dry-run=client -o yaml
kubectl apply -f - && kubectl label namespace monitoring istio-injection=enabled --overwrite && for i in alertmanagerconfigs alertmanagers podmonitors probes prometheusagents prometheuses prometheusrules scrapeconfigs servicemonitors thanosrulers; do kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-community/helm-charts/refs/tags/kube-prometheus-stack-81.2.2/charts/kube-prometheus-stack/charts/crds/crds/crd-${i}.yaml -n monitoring; done
```

2. **Istio Service Mesh**
```bash
# Install Base, Control Plane (istiod), and Gateway
kubectl kustomize istio/base --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
kubectl kustomize istio/istiod --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
kubectl kustomize istio/gateway --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

3. **External Secrets Operator**
```bash
helm upgrade --install external-secrets external-secrets/external-secrets \
  --set image.crds.systemAuthDelegator=true \
  --set installCRDs=true --namespace external-secrets --create-namespace
```

---

## Phase 3: Install Services

1. **Install Prometheus**

> Note: Please ensure you have Slack Webhook secret secret created in monitoring namespace before applying the Prometheus manifests, otherwise the Prometheus Operator will keep trying to create the Alertmanager instance and fail due to missing secret, which will cause the whole installation to fail.

```bash
	kubectl kustomize prometheus/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

2. **Install CNPG CRDs (required for PGSQL)**
```bash
kubectl kustomize cloudnative-pgsql/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply --server-side -f -
```

3. **Install Keycloak Postgres Cluster**
```bash
kubectl kustomize keycloak-postgres/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

4. **Install Keycloak**
```bash
kubectl kustomize keycloak/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

5.  **Conigure Keycloak with Terraform**

> Note: Make sure you have `terraform.tfvars` file updated with correct values before applying the Terraform configuration.

```bash
cd keycloak-terraform
terraform init
terraform plan
terraform apply -auto-approve
```

6. **Install Vault**
```bash
kubectl kustomize vault/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

7. **Configure Vault with Terraform**

> Note: Make sure you have `terraform.tfvars` file updated with correct values before applying the Terraform configuration.

```bash
cd vault-terraform
terraform init
terraform plan
terraform apply -auto-approve
```

8. **Install Grafana Postgres Cluster**
```bash
kubectl kustomize grafana-postgres/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

9. **Install Grafana**
```bash
kubectl kustomize grafana/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

10. **Install Kafka Operator**
```bash
kubectl kustomize kafka-operator/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

11. **Configure Keycloak with Terraform for Oauth in Kafka and Kafka-UI

> Note: Make sure you have `terraform.tfvars` file updated with correct values before applying the Terraform configuration.

```bash
cd keycloak-kafka-terraform
terraform init
terraform plan
terraform apply -auto-approve
```

12. **Install Kafka cluster with Oauth**
```bash
kubectl kustomize kafka-cluster/cluster-with-oauth --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

13. **Install Kafka UI with Oauth**
```bash
kubectl kustomize kafka-ui/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

14. **Install Kafka cluster without Oauth**
```bash
kubectl kustomize kafka-cluster/cluster-without-oauth --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

15. **Install Kafka UI without Oauth**
```bash
kubectl kustomize kafka-cluster/cluster-without-oauth/kafka-ui --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

16. **Install Keda Operator**
```bash
kubectl kustomize /keda/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply --server-side --force-conflicts -f -
```

17. **Install Kiali Operator**
```bash
kubectl kustomize kiali/operator --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

18. **Install Kiali Server**
```bash
kubectl kustomize kiali/server --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

19. **Install Loki**
```bash
kubectl kustomize loki/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

20. **Install OpenTelemetry Collector**
```bash
kubectl kustomize otel/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

21. **Install Tempo**
```bash
kubectl kustomize tempo/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

22. **Install Litmus Chaos**
```bash
kubectl kustomize litmus/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

23. **Install Vault with Terraform for PKI set-up**

> Note: Make sure you have `terraform.tfvars` file updated with correct values before applying the Terraform configuration.

```bash
cd vault-pki-with-terraform
terraform init
terraform plan
terraform apply -auto-approve
```

24. **Install Cert-Manager**
```bash
kubectl kustomize cert-manager/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

25. **Install Trust-Manager**
```bash
kubectl kustomize trust-manager/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```