# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/sahil-sharma/k8s-stuff
# cd into the cloned directory
git checkout dafca3633735180189a94f078e967c27fc0e0096
kustomize build ./welcome-app-with-gitops-promoter/welcome-app/overlays/dev
```
