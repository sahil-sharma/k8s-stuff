## Install Prometheus

> Hostname: http://traces.local.io:32080

```bash
# Install Tempo
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f -

# Uninstall Tempo
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f -
```