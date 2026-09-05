# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/sahil-sharma/k8s-stuff
# cd into the cloned directory
git checkout ee4b8b945d0099df481c0d95f638dfdd7b36b49a
kustomize build ./welcome-app-with-gitops-promoter/welcome-app/overlays/staging
```
