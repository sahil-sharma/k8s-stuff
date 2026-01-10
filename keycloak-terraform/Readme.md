# Keycloak Terraform Configuration

This Terraform project bootstraps a complete Keycloak realm setup for use with Argo CD and Argo Workflows SSO, including:

- Custom Realm: `platform`
- Three Groups: `devops`, `engineering`, `data`
- One or more users per group with initial password (`demo123`, temporary)
- Two Clients: `argo-cd`, `argo-workflow`
- Custom OIDC Client Scope: `groups`
- Groups-to-token mapper for SSO
- Assignment of `groups`, `email`, and `profile` to each client’s default scopes

---

## Features

- Automates full Keycloak setup with `terraform-provider-keycloak`
- Uses a self-hosted Keycloak instance (e.g., `http://sso.local.io:32080`)
- Supports secrets via Terraform variables or `.tfvars` file
- SSO-ready for applications that supports OIDC

---

## Structure

```bash
.
├── main.tf                 # Entry point, includes all modules
├── providers.tf            # Keycloak provider config
├── realm.tf                # Realm creation
├── groups-and-users.tf     # Groups and user assignments
├── clients.tf              # Clients and client secrets
├── client_scope.tf         # Custom 'groups' scope and mapping
├── variables.tf            # Required input variables
├── terraform.tfvars        # Your secret config (gitignored)
├── outputs.tf              # Sensitive outputs (e.g., client secrets)
└── README.md               # This file
```
---

## Prerequisites

```bash
Keycloak running and accessible via HTTP (e.g., via NodePort or Ingress)
Admin credentials (username/password or client credentials)
Terraform >= 1.12
DNS resolution to sso.local.io inside the cluster (Update CoreDNS for appications to reach Keycloak over hostname)
```
---

## Setup

### 1. Create terraform.tfvars
```bash
keycloak_url                  = "http://sso.local.io:32080"
keycloak_admin_login_username = "admin"
keycloak_admin_login_password = "admin123"

realm_config = {
  realm        = "platform",
  display_name = "Platform Realm by Terraform",
  enabled      = true,
  ssl_required = "external"
}

clients = [
  {
    client_id                       = "argocd"
    name                            = "ArgoCD Client"
    root_url                        = "http://cd.local.io:32080"
    valid_redirect_uris             = ["http://cd.local.io:32080/auth/callback"]
    valid_post_logout_redirect_uris = ["http://cd.local.io:32080"]
    roles                           = ["admin", "readwrite", "readonly"]
    web_origins                     = ["+"]
    enable_authorization            = true
    enable_direct_grant             = true
    enable_service_account          = true
    enable_standard_flow            = true
  },
  {
    client_id                       = "secrets"
    name                            = "Vault Client"
    root_url                        = "http://secrets.local.io:32080"
    valid_redirect_uris             = ["http://secrets.local.io:32080/ui/vault/auth/oidc/oidc/callback", "http://secrets.local.io:32080/oidc/oidc/callback"]
    valid_post_logout_redirect_uris = ["http://secrets.local.io:32080"]
    roles                           = ["admin", "readwrite", "readonly"]
    web_origins                     = ["+"]
    enable_authorization            = true
    enable_direct_grant             = true
    enable_service_account          = true
    enable_standard_flow            = true
  },
  {
    client_id                       = "argo-workflow"
    name                            = "Argo Workflow Client"
    root_url                        = "http://jobs.local.io:32080"
    valid_redirect_uris             = ["http://jobs.local.io:32080/oauth2/callback"]
    valid_post_logout_redirect_uris = ["http://jobs.local.io:32080/workflows"]
    roles                           = ["admin", "readwrite", "readonly"]
    web_origins                     = ["+"]
    enable_authorization            = true
    enable_direct_grant             = true
    enable_service_account          = true
    enable_standard_flow            = true

  },
  {
    client_id                       = "grafana"
    name                            = "grafana client"
    root_url                        = "http://dashboards.local.io:32080"
    valid_redirect_uris             = ["http://dashboards.local.io:32080/login/generic_oauth"]
    valid_post_logout_redirect_uris = ["http://dashboards.local.io:32080"]
    roles                           = ["admin", "readwrite", "readonly"]
    web_origins                     = ["+"]
    enable_authorization            = true
    enable_direct_grant             = true
    enable_service_account          = true
    enable_standard_flow            = true
  },
  {
    client_id                       = "auth"
    name                            = "OAuth2 Proxy Client"
    root_url                        = "http://auth.local.io:32080"
    valid_redirect_uris             = ["http://auth.local.io:32080/oauth2/callback"]
    valid_post_logout_redirect_uris = ["http://auth.local.io:32080"]
    roles                           = ["admin", "readwrite", "readonly"]
    web_origins                     = ["+"]
    enable_authorization            = true
    enable_direct_grant             = true
    enable_service_account          = true
    enable_standard_flow            = true
  },
  {
    client_id                       = "storage"
    name                            = "Storage Minio"
    root_url                        = "http://console.storage.local.io:32080"
    valid_redirect_uris             = ["*"]
    valid_post_logout_redirect_uris = ["http://console.storage.local.io:32080"]
    roles                           = ["consoleAdmin", "readwrite", "readonly"]
    web_origins                     = ["+"]
    token_claim_name                = "storage"
    enable_authorization            = true
    enable_direct_grant             = true
    enable_service_account          = true
    enable_standard_flow            = true
  },
  {
    client_id                       = "kiali"
    name                            = "Kiali Client"
    root_url                        = "http://traffic.local.io:32080"
    valid_redirect_uris             = ["http://traffic.local.io:32080/*"]
    valid_post_logout_redirect_uris = []
    roles                           = ["admin", "readwrite", "readonly"]
    web_origins                     = ["+"]
    enable_authorization            = true
    enable_direct_grant             = true
    enable_service_account          = true
    enable_standard_flow            = true
  },
  {
    client_id            = "kafka-authz-idp-broker"
    name                 = "Broker for Kafka Authz Realm"
    enabled              = true
    enable_standard_flow = true
    # Confidential is required for IdP Brokering
    access_type = "CONFIDENTIAL"
    # This must match the alias we use in the kafka-authz side
    valid_redirect_uris   = ["http://sso.local.io:32080/realms/kafka-authz/broker/platform-idp/endpoint"]
    web_origins           = ["+"]
    realm_role_claim_name = "groups"
    mappers = [
      {
        name                = "realm-role-mapper"
        type                = "realm-roles"
        claim_name          = "groups" # Kafka-Authz will look for this claim
        add_to_id_token     = true
        add_to_access_token = true
      }
    ]
  },
]

groups = ["devops", "engineering", "data"]

realm_roles = ["admin", "readwrite", "readonly", "consoleAdmin"]

group_realm_roles = {
  "devops"      = ["admin", "consoleAdmin"],
  "engineering" = ["readwrite"],
  "data"        = ["readonly"]
}

users = [
  {
    username   = "alice"
    email      = "alice@local.io"
    first_name = "Alice"
    last_name  = "User"
    groups     = ["engineering"]
    roles = {
      "argocd"        = ["readwrite"]
      "secrets"       = ["readonly"]
      "grafana"       = ["readwrite"]
      "auth"          = ["readwrite"]
      "argo-workflow" = ["readwrite"]
      "storage"       = ["readwrite"]
      "kiali"         = ["readwrite"]
    }
  },
  {
    username   = "bob"
    email      = "bob@local.io"
    first_name = "Bob"
    last_name  = "User"
    groups     = ["devops"]
    roles = {
      "argocd"        = ["admin"]
      "secrets"       = ["admin"]
      "grafana"       = ["admin"]
      "auth"          = ["admin"]
      "argo-workflow" = ["admin"]
      "storage"       = ["admin"]
      "storage"       = ["consoleAdmin"]
      "kiali"         = ["admin"]
    }
  },
  {
    username   = "eve"
    email      = "eve@local.io"
    first_name = "Eve"
    last_name  = "User"
    groups     = ["data"]
    roles = {
      "argocd"        = ["readonly"]
      "secrets"       = ["readonly"]
      "grafana"       = ["readonly"]
      "auth"          = ["readonly"]
      "argo-workflow" = ["readonly"]
      "storage"       = ["readonly"]
      "kiali"         = ["readonly"]
    }
  },
  {
    username   = "sam"
    email      = "sam@local.io"
    first_name = "Sam"
    last_name  = "User"
    groups     = []
    roles      = {}
  },
]
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Format and plan and apply the Configuration
```bash
terraform fmt

terraform plan

terraform apply (or -auto-approve)
```

### 4. Output of Users and Client secrets 
```bash
terraform output clients

terraform output users
```

## 👥 Users and Groups

| Group    | Users      |
| -------- | -----------|
| DevOps   | bob, dave  |
| Backend  | alice, john|
| Business | eve        |

* Randomly generated password
* Password must be reset on first login if enabled

## Example Clients

| Client ID     | Use Case          | Secret Source                     |
| ------------- | ----------------- | --------------------------------- |
| argo-cd       | Argo CD SSO       | `var.argo-cd_client_secret`       |
| argo-workflow |Argo Workflows SSO | `var.argo-workflow_client_secret` |

## Notes

* The groups client scope is added as a default scope to both clients, and includes a Group Membership mapper (claim: groups).
* If you see "Account is not fully set up" when logging in, ensure you reset the password as prompted.
* If DNS fails on login (no such host), configure CoreDNS to resolve sso.local.io. Follow steps mentioned [here](https://github.com/sahil-sharma/k8s-stuff/blob/main/update-coredns-configmap.txt).
* Add keycloak self-signed certificates to Operating System CA so that Terraform can make an API call to Keycloak over HTTPS if enabled:
```bash
# openssl s_client -showcerts -connect sso.local.io:32443 </dev/null 2>/dev/null | openssl x509 -outform PEM > /tmp/sso.crt
# sudo cp /tmp/sso.crt /usr/local/share/ca-certificates/sso.crt
# sudo update-ca-certificates
```
## Debug Tips

```bash
# Test DNS resolution inside a pod
kubectl run -i --tty dns-test --image=busybox:latest --rm --restart=Never -- sh
nslookup sso.local.io

# Get configured client secret
terraform output -json | jq -r '.argo_cd_client_secret.value'
```

## Outputs

* `client IDs and secrets`: Display all client-id and client-secrets 
* `user credentials`: All users will have a randomly generated password

You can set a SHELL alias to get easy outputs:

```bash
alias tfout='terraform output -state=$HOME/keycloak-terraform/terraform.tfstate'

tfout users && tfout clients
```

## Fuzz Keycloak for valid and invalid requests for monitoring purposes

```bash
# Install dependencies
pip install requests
pip3 install aiohttp
pip3 install aiolimiter

# Add valid client-ids and client-secrets in python script: kc-fuzzer.py

python3 kc-fuzzer.py --rps 100 --duration 300 --concurrency 50
```

## Cleanup
```bash
terraform destroy -auto-approve
```