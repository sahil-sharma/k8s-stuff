# Cloud-Native Platform Deployment Guide

This repository contains the manifests and Terraform configurations to bootstrap a complete cloud-native ecosystem on a **Kind** cluster. The stack includes CNPG, Istio, Keycloak, Argo, Kafka, Vault, Chaos Testing Framework and a full Observability suite with few applications like online boutique app, welcome app, echo-server and echo-client.

---

## Platform Service URLs

| Service | URL |
| :--- | :--- |
| **Identity & Access (SSO)** | [https://sso.local.io](https://sso.local.io) |
| **Vault Secrets** | [https://secrets.local.io](https://secrets.local.io) |
| **OAuth2 Proxy** | [https://auth.local.io](https://auth.local.io) |
| **Grafana Dashboards** | [https://dashboards.local.io](https://dashboards.local.io) |
| **Prometheus Metrics** | [https://metrics.local.io](https://metrics.local.io) |
| **Loki Logs** | [https://logs.local.io](https://logs.local.io) |
| **Tempo Traces** | [https://traces.local.io](https://traces.local.io) |
| **Kiali (Mesh Traffic)** | [https://traffic.local.io](https://traffic.local.io) |
| **ArgoCD** | [https://cd.local.io](https://cd.local.io) |
| **Argo Workflows** | [https://jobs.local.io](https://jobs.local.io) |
| **Argo Rollouts** | [https://rollouts.local.io](https://rollouts.local.io) |
| **Kafka UI** | [https://kafka-ui.local.io](https://kafka-ui.local.io) |
| **Kafka Cluster (Bridge)** | [https://kafka-bridge.local.io](https://kafka-bridge.local.io) |
| **Kafka Connect** | [https://kafka-connect.local.io](https://kafka-connect.local.io) |
| **Kafka Cruise Control** | [https://cruise-control.local.io](https://cruise-control.local.io) |
| **Litmus Chaos** | [https://chaos.local.io](https://chaos.local.io) |
| **OTEL Collector** | [https://collector.local.io](https://collector.local.io) |
| **MinIO Storage** | [https://storage.local.io](https://storage.local.io) |
| **MinIO Console** | [https://console.storage.local.io](https://console.storage.local.io) |
| **Backstage (IDP)** | [https://idp.local.io](https://idp.local.io) |
| **Boutique App** | [https://store.local.io](https://store.local.io) |
| **Echo Server** | [https://echo-server.local.io](https://echo-server.local.io) |
| **Welcome App** | [https://welcome.local.io](https://welcome.local.io) |

---

## Phase 0: Setting up [mkcert](https://github.com/filosottile/mkcert) to generate locally trusted SSL certificates

1. **Install mkcert** 
Follow the official mkcert GH [page](https://github.com/filosottile/mkcert) for its installation.

2. **Install the Local Certificate Authority (CA)**

```bash
mkcert -install
```
This command:

> Creates a local CA if one doesn't already exist.
>
> Installs the CA certificate into your operating system's trust store.
>
> Configures supported browser trust stores.

Verify the CA location:

```bash
mkcert -CAROOT
rootCA.pem is the public root CA certificate
rootCA-key.pem is the private CA key
```

Never commit or share rootCA-key.pem. Anyone with access to this private key can generate certificates trusted by machines that trust this CA.

3. **Generate the Wildcard Certificate**

```bash
mkdir -p $HOME/local-io-certs
cd $HOME/local-io-certs
mkcert "*.local.io" local.io
```

The command generates two files:

```bash
local.io+1.pem
local.io+1-key.pem
```

For consistency, you can explicitly name the output files:

```bash
mkcert \
  -cert-file local-wildcard.pem \
  -key-file local-wildcard-key.pem \
  "*.local.io" local.io
```

The resulting files will be:

```bash
ls $HOME/local-io-certs
├── local-wildcard.pem (SSL certificate)
└── local-wildcard-key.pem (Private key)
```

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

13. **Install Kafka cluster without Oauth**
```bash
kubectl kustomize kafka-cluster/cluster-without-oauth --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

14. **Install Keda Operator**
```bash
kubectl kustomize /keda/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply --server-side --force-conflicts -f -
```

15. **Install Kiali Operator**
```bash
kubectl kustomize kiali/operator --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

16. **Install Kiali Server**
```bash
kubectl kustomize kiali/server --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

17. **Install Loki**
```bash
kubectl kustomize loki/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

18. **Install OpenTelemetry Collector**
```bash
kubectl kustomize otel/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

19. **Install Tempo**
```bash
kubectl kustomize tempo/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

20. **Install Litmus Chaos**
```bash
kubectl kustomize litmus/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

21. **Install Vault with Terraform for PKI set-up**

> Note: Make sure you have `terraform.tfvars` file updated with correct values before applying the Terraform configuration.

```bash
cd vault-pki-with-terraform
terraform init
terraform plan
terraform apply -auto-approve
```

22. **Install Cert-Manager**
```bash
kubectl kustomize cert-manager/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

23. **Install Trust-Manager**
```bash
kubectl kustomize trust-manager/ --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

24. **Install Boutique Shop application**
```bash
kubectl kustomize boutique-app --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

25. **Install Kyverno**
```bash
kubectl kustomize kyverno --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

26. **Install Kyverno Policy Reporter**
```bash
kubectl kustomize kyverno/policy-reporter --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```
