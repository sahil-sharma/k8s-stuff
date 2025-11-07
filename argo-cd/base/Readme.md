## Install ArgoCD with External Secrets support

```bash
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f - -n argo-cd
```