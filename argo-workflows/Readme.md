## Install Argo Workflow with External Secrets suppot

> Ensure External Secret is already installed

> Hostname: http://jobs.local.io:32080

```bash
# Add External Secret Helm repo
helm repo add external-secrets https://charts.external-secrets.io

# Add Argo Workflow Helm Repo
helm repo add argo-workflow https://argoproj.github.io/argo-helm

# Update Helm Repo
helm repo update

# Install Argo Workflow
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f -

# Delete Argo Workflow
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k delete -f -
```