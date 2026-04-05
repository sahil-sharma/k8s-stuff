# Vault OIDC Secrets Management

This Terraform configuration automates the provisioning of OIDC client credentials and application-specific secrets into **HashiCorp Vault KV-v2** paths.

## Overview

The configuration uses a "Dynamic Map" approach to bridge Keycloak client data with Vault storage. It iterates over a list of client names and pulls sensitive values from a corresponding map.

### Key Features:
1.  **Key Normalization:** Automatically transforms keys to **UPPERCASE** (e.g., `client_id` → `CLIENT_ID`).
2.  **Dynamic Filtering:** Automatically filters out `null` values, ensuring secrets only contain the data they actually need.
3.  **App-Specific Secrets:** Supports optional fields per-application (e.g., `DB_PASSWORD` for Grafana or `COOKIE_SECRET` for Auth).

---

## Configuration (`terraform.tfvars`)

```hcl
vault_addr         = "http://secrets.local.io:32080"
oidc_discovery_url = "http://sso.local.io:32080/realms/platform"

oidc_client_names = [
  "argo-workflow",
  "argocd",
  "backstage",
  "auth",
  "grafana",
  "kafka-authz-idp-broker",
  "kiali",
  "secrets",
  "storage",
  "kafka",
  "kafka-bridge",
  "kafka-cli",
  "kafka-connect",
  "kafka-cruise-control",
  "kafka-ui",
  "team-a-client",
  "team-b-client"
]

oidc_clients = {
  "argo-workflow"          = { client_id = "argo-workflow", client_secret = "DezhNkdjbDqhZ18RiJH2bA50Zl2PUfCg" }
  "argocd"                 = { client_id = "argocd", client_secret = "AxOfyWWRm9YAGlLFWRxtDfWszHCtoOJT" }
  "auth"                   = { client_id = "auth", client_secret = "VbRKCDug3MldqGM0MJ3sr8pUKwwacSl6", cookie_secret = "j5/se9YQuZPbvGiVlV2wfKlgCg3R7R66P+H4r0IkUtg=" }
  "backstage"              = { client_id = "backstage", client_secret = "lT2Z7FhBIovWlfwbfYos8YpSj6bCI5Cp" }
  "grafana"                = { client_id = "grafana", client_secret = "LrgQ1HY1IAs6hNrr30lqsm3D46D5W64T", db_password = "admin123" }
  "kafka-authz-idp-broker" = { client_id = "kafka-authz-idp-broker", client_secret = "SqWVb5DrS2K0H5lhmQqaaTkK4NhF8Tml" },
  "kiali"                  = { client_id = "kiali", client_secret = "2xlB2ebOMI0uVCB2qFEEXzahLfywfHK9" }
  "secrets"                = { client_id = "secrets", client_secret = "nICNIAgB3M1v15gg7JREJuXxClvlE0rU" }
  "storage"                = { client_id = "storage", client_secret = "oHmS3QHVHiV5v5yHVN6V1egliQkiVIL8" }
  "kafka"                  = { client_id = "kafka", client_secret = "AcCikcN3TdWLyyEidDmc3XL2co34CRiC" }
  "kafka-bridge"           = { client_id = "kafka-bridge", client_secret = "e3MAjh1HSDAehRGppaByUuofDdnF9PXn" }
  "kafka-cli"              = { client_id = "kafka-cli", client_secret = "vkFU92SdJc7N1nE8v6gLav6KbScjateE" }
  "kafka-connect"          = { client_id = "kafka-connect", client_secret = "SoroUqYOVwMSlGIXrCe6xpf6AH8YBwUp" }
  "kafka-cruise-control"   = { client_id = "kafka-cruise-control", client_secret = "y8hb6Siz60VjEYSHlLdalSFcASIgvGRw" }
  "kafka-ui"               = { client_id = "kafka-ui", client_secret = "QCFDk3I8maegK4dT5eS95moRNnuUEOyO" }
  "team-a-client"          = { client_id = "team-a-client", client_secret = "3aX5Lj1sB3YqJSwlhbcVIpuAavhveqyx" }
  "team-b-client"          = { client_id = "team-b-client", client_secret = "vclXF7C18GZnEXtp3nXyO1uJN2ESLb0h" }
}
```

## Execution

Vault must be up and running and `UNSEALED`.

```bash
kubectl exec -it vault-0 -n vault -- vault operator init -key-shares=1 -key-threshold=1 -format=json > /tmp/cluster-keys.json
export VAULT_TOKEN=$(jq -r ".root_token" /tmp/cluster-keys.json)
export UNSEAL_KEY=$(jq -r ".unseal_keys_hex[0]" /tmp/cluster-keys.json)
kubectl exec -it vault-0 -n vault -- vault operator unseal $UNSEAL_KEY

terraform init
terraform plan
terraform apply
```