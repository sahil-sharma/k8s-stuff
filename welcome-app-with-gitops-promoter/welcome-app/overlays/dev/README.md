# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/sahil-sharma/k8s-stuff
# cd into the cloned directory
git checkout 64655199d8011a35b2ae30c54b2a12dc6f10296b
kustomize build ./welcome-app-with-gitops-promoter/welcome-app/overlays/dev
```
