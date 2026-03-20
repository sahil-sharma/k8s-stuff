## Install CNPG CRDs for PGSQL

```bash
# Install CRDs
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f -

# Uninstall CRDs
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f -
```