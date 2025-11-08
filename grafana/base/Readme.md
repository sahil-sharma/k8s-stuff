## Install Grafana with External Secrets support

> Ensure External Secret and Grafana PostgreSQL is already installed

```bash
# Add External Secret Helm repo
helm repo add external-secrets https://charts.external-secrets.io

# Add Grafana Helm Repo
helm repo add grafana https://grafana.github.io/helm-charts

# Update Helm Repo
helm repo update

# Install Grafana
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f -

# Delete Grafana
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f -
```