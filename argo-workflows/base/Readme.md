## Install Argo Workflows with External Secrets suppot

```bash
k kustomize . --enable-helm --load-restrictor=LoadRestrictionsNone | k apply -f -
```