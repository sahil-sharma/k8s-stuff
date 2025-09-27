# Kubernetes Deployment with Helm

This guide walks you through deploying **PostgreSQL**,**Nginx Ingress**, **pgAdmin**, **Keycloak**, **Prometheus**, **Promtail**, **Loki**, **Tempo**, **OTEL-Collector**, **Grafana**, **Flask CRUD Application**, **Reloader**, and **ArgoCD**  in a Kubernetes cluster using Helm with custom `values.yaml` configuration files.

---

## Prerequisites

- A running Kubernetes cluster (`kind` or `VM using kubeadm`)
- `kubectl` configured to access your cluster
- [Helm 3.x](https://helm.sh/docs/intro/install/)

- Custom `values.yaml` files:
  - `postgres-values.yaml`
  - `pgadmin-values.yaml`
  - `prometheus-values.yaml`
  - `loki-values.yaml`
  - `promtail-values.yaml`
  - `blackbox-values.yaml`
  - `tempo-values.yaml`
  - `otel-values.yaml`
  - `grafana-values.yaml`
  - `keycloak-values.yaml`
  - `nginx-ingress-values.yaml`
  - `argocd-values.yaml`
  - `argo-workflows-values.yaml`
  - `argo-rollouts-values.yaml`
  - `mysql-values.yaml`
  - `oauth2-proxy-values.yaml`
  - `phpmyadmin-values.yaml`
  - `vault-values.yaml`
  - `mysql-keycloak-values.yaml`
---

## Links

```bash
Keycloak: https://sso.local.io:32443
Argo CD: http://cd.local.io:32080
Argo Workflows: http://jobs.local.io:32080
Argo Rollouts: http://rollouts.local.io:32080
Grafana: http://dashboards.local.io:32080
Loki: http://logs.local.io:32080
Prometheus: http://metrics.local.io:32080
Tempo: http://traces.local.io:32080
OAuth: http://auth.local.io:32080
PgAdmin: http://pgadmin.local.io:32080
PhpMyAdmin: http://phpmyadmin.local.io:32080
MySQL: http://mysql.local.io:32306
PGSQL: http://pgsql.local.io:32432
Blackbox: http://blackbox.local.io:32432
```

## Step 1: Add Helm Repositories

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add runix https://helm.runix.net
helm repo add argocd https://argoproj.github.io/argo-helm
helm repo add oauth2-proxy https://oauth2-proxy.github.io/manifests
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update
```

## Step 2: Install PostgreSQL

```bash
helm upgrade --install postgres bitnami/postgresql -f postgres-values.yaml --namespace postgres --create-namespace

# Check PGSQL Pod is running
kubectl get po,svc -n postgres
```
As Bitnami Images have been moved behind paywall so we will use CloudNative PG Operator to install postgres.

```bash
# Install the Helm Repo and update helm locally

# Install CRDs
helm upgrade --install cnpg cnpg/cloudnative-pg -n cnpg-system --create-namespace

# Create DB secret
kubectl create secret generic kc-db-secret --from-literal=username=keycloak_admin --from-literal=password=admin123 -n postgres

# Create Keycloak DB
k apply -f pg.yaml
```

## Step 3: Install Nginx Ingress

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -f nginx-ingress-values.yaml --set tcp.5432="postgres/postgresql:5432" --set tcp.3306="mysql/mysql:3306" --namespace ingress-nginx --create-namespace

# Check Nginx Ingress Pod is running
kubectl get po,svc,cm -n ingress-nginx
```

## Step 4: Install pgAdmin

```bash
helm upgrade --install pgadmin4 runix/pgadmin4 -f pgadmin-values.yaml --namespace pgadmin4 --create-namespace

# Check pgAdmin Pod is running
kubectl get po,svc -n pgadmin4
```

## Step 5: Install Keycloak

```bash
helm upgrade --install keycloak bitnami/keycloak -f keycloak-values.yaml --namespace keycloak --create-namespace

# Check Keycloak Pod is running
kubectl get po,svc,cm -n keycloak
```

## Step 6: Install ArgoCD

```bash
helm upgrade --install argocd argocd/argo-cd -f argocd-values.yaml --namespace argocd --create-namespace

# Check ArgoCD Pod is running
kubectl get po,svc -n arogcd
```

## Step 7: Install Argo Workflows

```bash
helm upgrade --install argo-workflows argocd/argo-workflows -f argo-workflows-values.yaml --namespace argo-workflows --create-namespace

# Check Argo Workflows Pod is running
kubectl get po,svc -n arog-workflows
```

## Step 8: Install Prometheus

```bash
helm upgrade --install prometheus prometheus-community/prometheus -n prometheus -f prometheus-values.yaml --create-namespace

# Check Prometheus Pod is running
kubectl get po,svc,ing -n prometheus
```

## Step 9: Install Loki

```bash
# You need to install local-path-storage as StorageClass for Loki:

kubectl apply -f local-path-storage.yaml

helm upgrade --install loki grafana/loki -n loki -f loki-values.yaml --create-namespace

# Check Loki Pod is running
kubectl get po,svc,ing -n loki
```

## Step 10: Install Promtail

```bash
helm upgrade --install promtail grafana/promtail -n promtail -f promtail-values.yaml --create-namespace

# Check Promtail Pod is running
kubectl get po,svc -n promtail
```

## Step 11: Install Grafana

```bash
helm upgrade --install grafana grafana/grafana -n grafana -f grafana-values.yaml --create-namespace

# Check Grafana Pod is running
kubectl get po,svc,ing -n grafana
```

## Step 12: Install MySQL

```bash
helm upgrade --install mysql bitnami/mysql -f mysql-values.yaml -n mysql --create-namespace

# Check MySQL Pod is running
kubectl get po,svc,ing -n mysql
```

## Step 13: Install Keycloak (for MySQL)

```bash
helm upgrade --install keycloak bitnami/keycloak -f mysql-keycloak-values.yaml --namespace mysql-keycloak --create-namespace

# Check Keycloak Pod is running
kubectl get po,svc,ing -n mysql-keycloak
```

## Step 14: Install PhpMyAdmin

```bash
helm upgrade --install phpmyadmin bitnami/phpmyadmin -f phpmyadmin-values.yaml -n phpmyadmin --create-namespace

# Check PhpMyAdmin Pod is running
kubectl get po,svc,ing -n phpmyadmin
```

## Step 15: Install Vault

```bash
helm upgrade --install vault hashicorp/vault -f vault-values.yaml -n vault --create-namespace

# Check Vault Pod is running
kubectl get po,svc,ing -n vault
```

## Step 16: Install Blackbox

```bash
helm upgrade --install blackbox-exporter prometheus-community/prometheus-blackbox-exporter -n blackbox --create-namespace -f blackbox-values.yaml

# Check Vault Pod is running
kubectl get po,svc,ing -n blackbox
```

## Step 17: Install OAuth2-Proxy

```bash
# Create Cookie Secret
dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 | tr -d -- '\n' | tr -- '+/' '-_' ; echo

helm upgrade --install oauth2 oauth2-proxy/oauth2-proxy -n oauth --create-namespace -f oauth2-proxy-values.yaml

# Check OAuth2-Proxy Pod is running
kubectl get po,svc,ing -n oauth2
```

## Step 18: Install Istio

```bash
# Create namespace
kubectl create ns istio-system

# Install CRDs
helm install istio-base istio/base -n istio-system --set defaultRevision=default

# Install Istio Control-plane
helm upgrade --install istiod istio/istiod -n istio-system -f istiod-values.yaml

# Check Vault Pod is running
kubectl get po,svc,ing -n istio-system

# Label namespaces to have sidecar and rollout deployments to have sidecar
kubectl label ns ingress-nginx istio-injection=enabled
kubectl label ns welcome-app istio-injection=enabled

# Enforce mesh-wide mTLS
kubectl apply -f istio-mtls.yaml
```

## Step 19: Install Reloader

```bash
helm upgrade --install reloader stakater/reloader --create-namspace -n reloader

kubectl get po -n reloader
```

<details>

<summary>⚠️ Notes and Attention (click to expand)</summary>

- ✅ **My set-up is 3 Virtual nodes using vagrant**: Check [this](https://github.com/techiescamp/vagrant-kubeadm-kubernetes/tree/main)

- ✅ **Pass TCP port to Nginx Ingress during installation**: Nginx Ingress Chart does not respect tcp port in values file
(read [this](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/exposing-tcp-udp-services.md) and [this](https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml#L1218))

```bash
tcp:
  "5432": "<postgres-namespace>/<postgres-service>:5432"
```

Error you will get if you define tcp block in values.yaml file

```bash
Error: INSTALLATION FAILED: 3 errors occurred:
* ConfigMap in version "v1" cannot be handled as a ConfigMap: json: cannot unmarshal object into Go struct field ConfigMap.data of type string
* Service in version "v1" cannot be handled as a Service: json: cannot unmarshal string into Go struct field ServicePort.spec.ports.port of type int32
* Deployment in version "v1" cannot be handled as a Deployment: json: cannot unmarshal string into Go struct field ContainerPort.spec.template.spec.containers.ports.containerPort of type int32
```

- ✅ **Kind Cluster**: If you're using Kind Cluster then you can use Metallb to expose your Nginx Ingress. (Check [this](https://metallb.universe.tf/installation/#installation-with-helm)). It comes up with its own complexity.

</details>

# Install all the above charts with Helmfile

## Step 1: Download the Latest Release

```bash
curl -LO https://github.com/helmfile/helmfile/releases/latest/download/helmfile_linux_amd64
```

## Step 2: Make It Executable
```bash
chmod +x helmfile_linux_amd64
```

## Step 3: Move It to a Directory in Your `PATH`
```bash
sudo mv helmfile_linux_amd64 /usr/local/bin/helmfile
```

## Step 4: Verify Installation
```bash
helmfile --version
```

## Step 5: Install All Charts Defined in Your helmfile.yaml
```bash
helmfile apply
```
> **ℹ️ Note:**  
> Running `helmfile apply` will:
>
> - Add the chart repositories.
> - Sync each release (performs `helm upgrade --install` behavior).
> - Create namespaces if they don’t already exist.
> - Apply each custom `values.yaml` file and any `--set` overrides.
> - Dry Run with `helmfile diff`