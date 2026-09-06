# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/sahil-sharma/k8s-stuff
# cd into the cloned directory
git checkout fa07951c1379e68c76bf95634f5aae63a1686cb3
kustomize build ./welcome-app-with-gitops-promoter/welcome-app/overlays/prod
```
