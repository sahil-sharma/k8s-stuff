## Install ArgoCD with External Secrets support

> Ensure External Secret is already installed

```bash
# Add Grafana Helm Repo
helm repo add argocd https://argoproj.github.io/argo-helm

# Update Helm Repo
helm repo update

# Install ArgoCD
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f -

# Delete ArgoCD
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f -
```