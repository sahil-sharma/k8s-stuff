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
keycloak_url                  = "https://keycloak.local.io:32443"
keycloak_admin_login_username = "admin"
keycloak_admin_login_password = "admin123"

realm_name = "platform"

clients = [
  {
    client_id                       = "argo-cd"
    name                            = "argo-cd client"
    root_url                        = "http://cd.local.io:32080"
    valid_redirect_uris             = ["http://cd.local.io:32080/auth/callback"]
    valid_post_logout_redirect_uris = ["http://cd.local.io:32080/applications"]
    roles                           = ["admin", "editor", "viewer"]
    web_origins                     = ["+"]
  },
  {
    client_id                       = "argo-workflow"
    name                            = "argo-workflow client"
    root_url                        = "http://jobs.local.io:32080"
    valid_redirect_uris             = ["http://jobs.local.io:32080/oauth2/callback"]
    valid_post_logout_redirect_uris = ["http://jobs.local.io:32080/workflows"]
    roles                           = ["admin", "editor", "viewer"]
    web_origins                     = ["+"]
  },
  {
    client_id                       = "grafana"
    name                            = "grafana client"
    root_url                        = "http://grafana.local.io:32080"
    valid_redirect_uris             = ["http://grafana.local.io:32080/login/generic_oauth"]
    valid_post_logout_redirect_uris = ["http://grafana.local.io:32080/workflows"]
    roles                           = ["admin", "editor", "viewer"]
    web_origins                     = ["http://grafana.local.io:32080"]
  }
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
    email      = "alice@example.com"
    first_name = "Alice"
    last_name  = "Dev"
    groups     = ["engineering"]
    roles = {
      "argo-cd"       = ["viewer"]
      "argo-workflow" = ["viewer"]
      "grafana"       = ["viewer"]
    }
  },
  {
    username   = "bob"
    email      = "bob@example.com"
    first_name = "Bob"
    last_name  = "Ops"
    groups     = ["devops"]
    roles = {
      "argo-cd"       = ["admin"]
      "argo-workflow" = ["admin"]
      "grafana"       = ["admin"]
    }
  },
  {
    username   = "eve"
    email      = "eve@example.com"
    first_name = "Eve"
    last_name  = "Biz"
    groups     = ["data"]
    roles = {
      "argo-cd"       = ["editor"]
      "argo-workflow" = ["viewer"]
    }
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

* `argo_cd_client_secret`: Use this in Argo CD SSO settings
* `argo_workflow_client_secret`: Use this in Argo Workflow SSO settings
* `user credentials`: All users use demo123 (temporary) password for first-login

## 🧼 Cleanup
```bash
terraform destroy -auto-approve
```