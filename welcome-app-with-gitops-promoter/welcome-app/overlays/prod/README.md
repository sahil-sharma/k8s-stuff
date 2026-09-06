# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/sahil-sharma/k8s-stuff
# cd into the cloned directory
git checkout bae7a6f10a677ac6de46ccffd4f9cd4090642847
kustomize build ./welcome-app-with-gitops-promoter/welcome-app/overlays/prod
```
