## Install Prometheus

> Hostname: http://metrics.local.io:32080

```bash
# Add Prometheus Community Helm Repo
helm repo add prometheus https://prometheus-community.github.io/helm-charts

# Update Helm Repo
helm repo update

# Install Prometheus
helm upgrade --install prometheus prometheus/prometheus -n prometheus -f values.yaml --create-namespace

# Uninstall Prometheus
helm uninstall prometheus -n prometheus
```