# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/sahil-sharma/k8s-stuff
# cd into the cloned directory
git checkout 7dcead66a79ffbd4dc9cdaca3f6e9d62a655d65f
kustomize build ./welcome-app-with-gitops-promoter/welcome-app/overlays/prod
```
