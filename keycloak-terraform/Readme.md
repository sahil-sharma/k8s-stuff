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
keycloak_url                = "https://keycloak.local.io:32443"
argo_cd_secret              = "argo-cd-secret"
keycloak_admin_user         = "admin"
keycloak_admin_password     = "admin123"
argo_cd_client_secret       = "argo-cd-secret"
argo_workflow_client_secret = "argo-workflow-secret"
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

## 👥 Users and Groups

| Group    | Users      |
| -------- | -----------|
| DevOps   | bob, dave  |
| Backend  | alice, john|
| Business | eve, marry |

* Default password: demo123
* Password must be reset on first login

## 🔐 Clients

| Client ID     | Use Case          | Secret Source                     |
| ------------- | ----------------- | --------------------------------- |
| argo-cd       | Argo CD SSO       | `var.argo_cd_client_secret`       |
| argo-workflow |Argo Workflows SSO | `var.argo_workflow_client_secret` |

## 🧠 Notes

* The groups client scope is added as a default scope to both clients, and includes a Group Membership mapper (claim: groups).
* If you see "Account is not fully set up" when logging in, ensure you reset the password as prompted.
* If DNS fails on login (no such host), configure CoreDNS to resolve keycloak.local.io. Follow steps mentioned [here](https://github.com/sahil-sharma/k8s-stuff/blob/main/update-coredns-configmap.txt).

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