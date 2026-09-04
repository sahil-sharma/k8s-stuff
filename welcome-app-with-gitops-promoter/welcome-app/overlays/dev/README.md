# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/sahil-sharma/k8s-stuff
# cd into the cloned directory
git checkout 5088227335c70013881f4d6c90233152569ad232
kustomize build ./welcome-app-with-gitops-promoter/welcome-app/overlays/dev
```
