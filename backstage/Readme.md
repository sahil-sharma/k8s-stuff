## Install Backstage with External Secrets support

> Ensure External Secret and Grafana PostgreSQL is already installed

> Hostname: http://dev-portal.local.io:32080

```bash
# Install Backstage
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f -

# Uninstall Backstage
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f -
```