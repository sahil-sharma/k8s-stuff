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
Terraform >= 1.3
DNS resolution to keycloak.local.io inside the cluster (you may need to update CoreDNS)
```
---

## 🔑 Setup

