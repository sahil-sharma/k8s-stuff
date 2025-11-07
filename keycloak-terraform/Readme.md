# 🔐 Keycloak Terraform Configuration

This Terraform project bootstraps a complete Keycloak realm setup for use with Argo CD and Argo Workflows SSO, including:

- Custom Realm: `platform`
- Three Groups: `devops`, `engineering`, `data`
- One or more users per group with initial password (`demo123`, temporary)
- Two Clients: `argo-cd`, `argo-workflow`
- Custom OIDC Client Scope: `groups`
- Groups-to-token mapper for SSO
- Assignment of `groups`, `email`, and `profile` to each client’s default scopes

---

## 📦 Features

- Automates full Keycloak setup with `terraform-provider-keycloak`
- Uses a self-hosted Keycloak instance (e.g., `https://keycloak.local.io:32443`)
- Supports secrets via Terraform variables or `.tfvars` file
- SSO-ready for Argo CD and Argo Workflows

---

## 📁 Structure

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

## ⚙️ Prerequisites

```bash
Keycloak running and accessible via HTTPS (e.g., via NodePort or Ingress)
Admin credentials (username/password or client credentials)
Terraform >= 1.12
DNS resolution to keycloak.local.io inside the cluster (you may need to update CoreDNS)
```
---

## 🔑 Setup

### 1. Create terraform.tfvars
```bash
keycloak_url                  = "http://sso.local.io:32080"
keycloak_admin_login_username = "admin"
keycloak_admin_login_password = "admin123"

realm_name = "platform"

clients = [
  {
    client_id                       = "argocd"
    name                            = "ArgoCD Client"
    root_url                        = "http://cd.local.io:32080"
    valid_redirect_uris             = ["http://cd.local.io:32080/auth/callback"]
    valid_post_logout_redirect_uris = ["http://cd.local.io:32080"]
    roles                           = ["admin", "editor", "viewer"]
    web_origins                     = ["+"]
  },
  {
    client_id                       = "secrets"
    name                            = "Vault Client"
    root_url                        = "http://secrets.local.io:32080"
    valid_redirect_uris             = ["http://secrets.local.io:32080/ui/vault/auth/oidc/oidc/callback", "http://secrets.local.io:32080/oidc/oidc/callback"]
    valid_post_logout_redirect_uris = ["http://secrets.local.io:32080"]
    roles                           = ["admin", "editor", "viewer", "reader"]
    web_origins                     = ["+"]
  },
  {
    client_id                       = "argo-workflow"
    name                            = "Argo Workflow Client"
    root_url                        = "http://jobs.local.io:32080"
    valid_redirect_uris             = ["http://jobs.local.io:32080/oauth2/callback"]
    valid_post_logout_redirect_uris = ["http://jobs.local.io:32080/workflows"]
    roles                           = ["admin", "editor", "viewer"]
    web_origins                     = ["+"]
  },
  {
    client_id                       = "grafana"
    name                            = "grafana client"
    root_url                        = "http://dashboards.local.io:32080"
    valid_redirect_uris             = ["http://dashboards.local.io:32080/login/generic_oauth"]
    valid_post_logout_redirect_uris = ["http://dashboards.local.io:32080"]
    roles                           = ["admin", "editor", "viewer"]
    web_origins                     = ["+"]
  },
  {
    client_id                       = "auth"
    name                            = "OAuth2 Proxy Client"
    root_url                        = "http://auth.local.io:32080"
    valid_redirect_uris             = ["http://auth.local.io:32080/oauth2/callback"]
    valid_post_logout_redirect_uris = ["http://auth.local.io:32080"]
    roles                           = ["admin", "editor", "viewer"]
    web_origins                     = ["+"]
  },
  {
    client_id                       = "idp"
    name                            = "Backstage IDP"
    root_url                        = "http://idp.local.io:32080"
    valid_redirect_uris             = ["http://idp.local.io:32080/oauth2/callback"]
    valid_post_logout_redirect_uris = ["http://idp.local.io:32080"]
    roles                           = ["admin", "editor", "viewer"]
    web_origins                     = ["+"]
  },
  {
    client_id                       = "storage"
    name                            = "Storage Minio"
    root_url                        = "http://console.storage.local.io:32080"
    valid_redirect_uris             = ["*"]
    valid_post_logout_redirect_uris = ["http://console.storage.local.io:32080"]
    roles                           = ["admin", "editor", "viewer"]
    web_origins                     = ["+"]
  },
]

groups = ["devops", "engineering", "data"]

group_realm_roles = {
  "devops"      = ["admin"],
  "engineering" = ["editor"],
  "data"        = ["viewer"]
}

users = [
  {
    username   = "alice"
    email      = "alice@local.io"
    first_name = "Alice"
    last_name  = "User"
    groups     = ["engineering"]
    roles = {
      "argocd"  = ["editor"]
      "secrets" = ["reader"]
      "grafana" = ["editor"]
      "auth"    = ["editor"]
      "argo-workflow" = ["editor"]
      "storage" = ["editor"]
    }
  },
  {
    username   = "bob"
    email      = "bob@local.io"
    first_name = "Bob"
    last_name  = "User"
    groups     = ["devops"]
    roles = {
      "argocd"  = ["admin"]
      "secrets" = ["admin"]
      "grafana" = ["admin"]
      "auth"    = ["admin"]
      "argo-workflow" = ["admin"]
      "storage" = ["admin"]
    }
  },
  {
    username   = "eve"
    email      = "eve@local.io"
    first_name = "Eve"
    last_name  = "User"
    groups     = ["data"]
    roles = {
      "argocd"  = ["viewer"]
      "secrets" = ["reader"]
      "grafana" = ["viewer"]
      "auth"    = ["viewer"]
      "argo-workflow" = ["viewer"]
      "storage" = ["viewer"]
    },
    {
      username   = "sam"
      email      = "sam@local.io"
      first_name = "Sam"
      last_name  = "User"
      groups     = []
      roles      = {}
    },
  }
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
| Business | eve, marry |

* Randomly generated password
* Password must be reset on first login

## 🔐 Clients

| Client ID     | Use Case          | Secret Source                     |
| ------------- | ----------------- | --------------------------------- |
| argo-cd       | Argo CD SSO       | `var.argo-cd_client_secret`       |
| argo-workflow |Argo Workflows SSO | `var.argo-workflow_client_secret` |

## 🧠 Notes

* The groups client scope is added as a default scope to both clients, and includes a Group Membership mapper (claim: groups).
* If you see "Account is not fully set up" when logging in, ensure you reset the password as prompted.
* If DNS fails on login (no such host), configure CoreDNS to resolve keycloak.local.io. Follow steps mentioned [here](https://github.com/sahil-sharma/k8s-stuff/blob/main/update-coredns-configmap.txt).
* Add keycloak self-signed certificates to Operating System CA so that Terraform can make an API call to Keycloak over HTTPS:
```bash
# openssl s_client -showcerts -connect keycloak.local.io:32443 </dev/null 2>/dev/null | openssl x509 -outform PEM > /tmp/keycloak.crt
# sudo cp /tmp/keycloak.crt /usr/local/share/ca-certificates/keycloak.crt
# sudo update-ca-certificates
```
## 🧪 Debug Tips

```bash
# Test DNS resolution inside a pod
kubectl run -i --tty dns-test --image=busybox:latest --rm --restart=Never -- sh
nslookup keycloak.local.io

# Get Keycloak client secret
terraform output -json | jq -r '.argo_cd_client_secret.value'
```

## 📤 Outputs

* `client IDs and secrets`: Display all client-id and client-secrets 
* `user credentials`: All users will have a randomly generated password

You can set a SHELL alias to get easy outputs:

```bash
alias tfout='terraform output -state=$HOME/k8s-stuff/keycloak-terraform/terraform.tfstate'

tfout users && tfout clients
```

## Fuzz Keycloak for valid and invalid requests for monitoring purposes

```bash
# Install dependencies
pip install requests
pip3 install aiohttp
pip3 install aiolimiter

python3 kc-fuzzer.py --rps 100 --duration 300 --concurrency 50
```

## 🧼 Cleanup
```bash
terraform destroy -auto-approve
```