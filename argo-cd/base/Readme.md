## Install ArgoCD with External Secrets support

> Ensure External Secret is already installed

> Hostname: http://cd.local.io:32080

```bash
# Add External Secret Helm repo
helm repo add external-secrets https://charts.external-secrets.io

# Add ArgoCD Helm Repo
helm repo add argo-cd https://argoproj.github.io/argo-helm

# Update Helm Repo
helm repo update

# Install ArgoCD
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f -

# Delete ArgoCD
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f -
```