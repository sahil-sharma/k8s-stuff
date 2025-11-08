## Install Keycloak

> Ensure Keycloak PG is already installed

```bash
# Add Keycloak Helm Repo
helm repo add keycloak https://codecentric.github.io/helm-charts

# Update Helm Repo
helm repo update

# Install Keycloak
helm upgrade --install keycloak codecentric/keycloakx -f values.yaml --namespace keycloak --create-namespace'

# Delete Keycloak
helm uninstall keycloak -n keycloak'
```