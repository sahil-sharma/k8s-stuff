# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/sahil-sharma/k8s-stuff
# cd into the cloned directory
git checkout 4b04f1cfa41501df75abaf650d5c559e06a02647
kustomize build ./welcome-app-with-gitops-promoter/welcome-app/overlays/prod
```
