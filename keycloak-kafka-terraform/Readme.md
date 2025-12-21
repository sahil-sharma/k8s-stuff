# Keycloak configuration for Kafka with Terraform

This repository contains the Terraform configuration to bootstrap a production-ready Keycloak Realm specifically designed for **Kafka Fine-Grained Authorization**. It implements a Zero-Trust security model where every Kafka resource is protected by specific OIDC policies.

---

## Architecture Overview

The configuration automates the following Keycloak components using a **No-Hardcode** approach (all data is driven by `.tfvars`):

- **Custom Realm:** `kafka-authz`
- **Functional Roles:** `Dev Team A`, `Dev Team B`, `Ops Team`
- **Organizational Groups:** `ClusterManager`, `Ops Team Group`
- **Automated Users:** Human accounts with assigned groups, "User" last names, and **random 16-character passwords**.
- **Automated Clients:** - **Public:** `kafka-cli` (For developer CLI access).
  - **Confidential:** `broker`, `kafka`, `team-a-client`, `team-b-client` (All with **random 32-character secrets**).
- **Authorization Services:** Logic to protect Kafka Topics, Groups, and Clusters via OIDC Resources, Scopes, and Policies.

---

## File Structure

| File | Description |
| :--- | :--- |
| `providers.tf` | Keycloak and Random provider configuration. |
| `variables.tf` | Schema definitions for all dynamic data. |
| `terraform.tfvars` | **Source of Truth.** All environment data and credentials. |
| `main.tf` | Realm creation and core bootstrap. |
| `roles.tf` | Management of Realm-level functional roles. |
| `groups.tf` | Organizational structure and hierarchy. |
| `users.tf` | Human user accounts and random password generation. |
| `clients.tf` | OIDC Clients, random secrets, and Service Account role mapping. |
| `client-scopes.tf` | Reusable OIDC scopes for Kafka operations. |
| `kafka_authz.tf` | Fine-grained Resource Servers, Policies, and Permissions. |
| `outputs.tf` | Secure extraction of generated credentials. |

---

## Security Model: Who Can Do What?

Access is governed by the intersection of **Policies** (Who you are) and **Resources** (What you are accessing).



### 1. Team Permissions (Roles)
| Team (Role) | Target Resources | Permitted Scopes |
| :--- | :--- | :--- |
| **Dev Team A** | `Topic:a_*` | Create, Read, Write, Delete, Alter |
| **Dev Team A** | `Topic:x_*` | Read, Describe |
| **Dev Team B** | `Topic:b_*` | Create, Read, Write, Delete |
| **Ops Team** | `Cluster:*` | AlterConfigs, DescribeConfigs, ClusterAction |

### 2. Client & Service Account Mapping
| Client ID | Role Assigned | Purpose |
| :--- | :--- | :--- |
| `team-a-client` | Dev Team A | Automated Producer/Consumer for Team A |
| `team-b-client` | Dev Team B | Automated Producer/Consumer for Team B |
| `broker` | N/A | Inter-broker cluster communication |

---

## Deployment & Setup

### 1. Prerequisites
- Terraform `>= 1.0.0`
- Keycloak admin credentials for the `master` realm.
- `admin-cli` client must have "Direct Access Grants" enabled.

### 2. Configure Credentials
Update your `terraform.tfvars` with your instance details:
```bash
keycloak_url                  = "http://sso.local.io:32080"
keycloak_admin_login_username = "admin"
keycloak_admin_login_password = "your-password"
```

### Sample `tfvars` file

```bash
keycloak_url                  = "http://sso.local.io:32080"
keycloak_admin_login_username = "admin"
keycloak_admin_login_password = "admin123"
admin_client_id               = "admin-cli"

realm_config = {
  realm        = "kafka-authz",
  enabled      = true,
  ssl_required = "external"
}

realm_roles = {
  "Dev Team A" = { description = "Developer on Dev Team A" }
  "Dev Team B" = { description = "Developer on Dev Team B" }
  "Ops Team"   = { description = "Operations team member" }
  "admin"      = { description = "Kafka UI Administrator" }
  "readonly"   = { description = "Kafka UI Read Only" }
  "readwrite"  = { description = "Kafka UI Read Write" }
}

groups = ["ClusterManager Group", "ClusterManager-my-cluster Group", "Ops Team Group"]

users = {
  "alice" = { email = "alice@local.io", first_name = "Alice", last_name = "User", enabled = true, group_memberships = ["ClusterManager Group"], roles = ["readonly"] }
  "bob"   = { email = "bob@local.io", first_name = "Bob", last_name = "User", enabled = true, group_memberships = ["ClusterManager-my-cluster Group"], roles = ["admin"] }
}

clients = {
  "team-a-client" = {
    public_client                = false,
    service_accounts_enabled     = true,
    authorization_enabled        = false,
    direct_access_grants_enabled = true,
    service_account_roles        = ["Dev Team A"]
    web_origins                  = ["+"]
  },
  "team-b-client" = {
    public_client                = false,
    service_accounts_enabled     = true,
    authorization_enabled        = false,
    direct_access_grants_enabled = true,
    service_account_roles        = ["Dev Team B"]
    web_origins                  = ["+"]
  },
  # "broker"        = {
  #   public_client = false,
  #   service_accounts_enabled = true,
  #   authorization_enabled = false, 
  #   direct_access_grants_enabled = true,
  #   service_account_roles = []
  # },
  "kafka" = {
    public_client                = false,
    service_accounts_enabled     = true,
    authorization_enabled        = true,
    direct_access_grants_enabled = true,
    service_account_roles        = []
    web_origins                  = ["+"]
  },
  "kafka-cli" = {
    public_client                = true,
    service_accounts_enabled     = false,
    authorization_enabled        = false,
    direct_access_grants_enabled = true,
    service_account_roles        = []
    web_origins                  = ["+"]
  },
  "kafka-ui" = {
    public_client                = false
    service_accounts_enabled     = true
    authorization_enabled        = true
    direct_access_grants_enabled = false
    service_account_roles        = []
    valid_redirect_uris          = ["http://kafka-ui.local.io:32080/login/oauth2/code/keycloak"]
    web_origins                  = ["+"]
    add_groups_mapper            = true
    standard_flow_enabled        = true
  },
}

auth_scopes = ["Create", "Read", "Write", "Delete", "Alter", "Describe", "ClusterAction", "DescribeConfigs", "AlterConfigs", "IdempotentWrite"]

kafka_resources = [
  { name = "Topic:a_*", type = "Topic", scopes = ["Create", "Delete", "Describe", "Write", "Read", "Alter", "DescribeConfigs", "AlterConfigs"] },
  { name = "Topic:x_*", type = "Topic", scopes = ["Create", "Delete", "Describe", "Write", "Read", "Alter", "DescribeConfigs", "AlterConfigs"] },
  { name = "kafka-cluster:my-cluster,Cluster:*", type = "Cluster", scopes = ["IdempotentWrite"] }
  # Add other resources from JSON here...
]

kafka_policies_role = [
  {
    name      = "Dev Team A",
    role_name = "Dev Team A"
  },
  {
    name      = "Dev Team B",
    role_name = "Dev Team B"
  }
]

kafka_policies_group = [
  {
    name       = "ClusterManager Group",
    group_path = "/ClusterManager Group"
  }
]

kafka_permissions = [
  { name = "Dev Team A owns topics that start with a_", type = "resource", resources = ["Topic:a_*"], policies = ["Dev Team A"], scopes = [] },
  { name = "Dev Team A can write to x topics", type = "scope", resources = ["Topic:x_*"], policies = ["Dev Team A"], scopes = ["Describe", "Write"] },
  { name = "Dev Team A IdempotentWrite", type = "scope", resources = ["kafka-cluster:my-cluster,Cluster:*"], policies = ["Dev Team A"], scopes = ["IdempotentWrite"] }
]
```