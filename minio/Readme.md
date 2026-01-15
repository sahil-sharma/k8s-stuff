## Install MinIO with External Secrets support

> Ensure External Secret is already installed

> Service Hostname: http://storage.local.io:32080

> Web Console Hostname: http://console.storage.local.io:32080

```bash
# Add External Secret Helm repo
helm repo add external-secrets https://charts.external-secrets.io

# Add MinIO Helm Repo
helm repo add minio https://charts.min.io/

# Update Helm Repo
helm repo update

# Install External Secret
helm upgrade --install external-secrets external-secrets/external-secrets --set image.crds.systemAuthDelegator=true --set installCRDs=true --namespace external-secrets --create-namespace

# Install MinIO
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f - -n minio

# Uninstall MinIO
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f - -n minio
```