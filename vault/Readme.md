## Install Vault

> Hostname: http://secrets.local.io:32080

> Please ensure you have `local-path-storage` installed for storage. See [here](https://github.com/rancher/local-path-provisioner) for more details.

```bash
# Add Hashicorp Vault Helm Repo
helm repo add hashicorp https://helm.releases.hashicorp.com

# Update Helm Repo
helm repo update

# Install Vault
helm upgrade --install vault hashicorp/vault -n vault -f values.yaml --create-namespace

# Uninstall Vault
helm uninstall vault -n vault && echo "" && kubectl get pvc -n vault && echo "" && sleep 3s && kubectl delete pvc -n vault --all
```

## Vault configuration

We are configuring vault with an `extraContainer` that unseal Vault at first boot-up and set-up OIDC auth method, roles, policies, secret KV stores. Please check that section in `vaules.yaml` file for more information.