## Install OTEL Collector

> Hostname: http://collector.local.io:32080

```bash
# Add OTEL Collector Helm Repo
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts

# Update Helm Repo
helm repo update

# Install OTEL Collector
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f -

# Uninstall OTEL Collector
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f -
```