## Install Prometheus

> Hostname: http://metrics.local.io:32080

```bash
# Add Prometheus Community Helm Repo
helm repo add prometheus https://prometheus-community.github.io/helm-charts

# Update Helm Repo
helm repo update

# Install Prometheus
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f -

# Uninstall Prometheus
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f -
```