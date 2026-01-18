# Keycloak configuration for Kafka with Terraform

This repository contains the Terraform configuration to bootstrap a production-ready Keycloak Realm specifically designed for **Kafka Fine-Grained Authorization**. It implements a Zero-Trust security model where every Kafka resource is protected by specific OIDC policies.

> Note: Below set-up is inspired from Strimzi Kafka Keycloak realm JSON [file](https://github.com/strimzi/strimzi-kafka-operator/blob/main/examples/security/keycloak-authorization/kafka-authz-realm.json)

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

### 2. Sample `tfvars` file 

```bash
keycloak_url                  = "http://sso.local.io:32080"
keycloak_admin_login_username = "admin"
keycloak_admin_login_password = "admin123"
admin_client_id               = "admin-cli"

idp_realm_name    = "platform"
idp_client_id     = "kafka-authz-idp-broker"
idp_client_secret = ""    # Secret provided by platform realm

realm_config = {
  realm        = "kafka-authz",
  display_name = "Kafka Authorization Realm",
  enabled      = true,
  ssl_required = "external"
}

realm_roles = {
  "Dev Team A"   = { description = "Developer/Services from Dev Team A" }
  "Dev Team B"   = { description = "Developer/Services from Dev Team B" }
  "Ops Team"     = { description = "Operations team member" }
  "ui-admin"     = { description = "Kafka UI Administrator" }
  "ui-readonly"  = { description = "Kafka UI Read Only" }
  "ui-readwrite" = { description = "Kafka UI Read Write" }
  "bridge-admin" = { description = "Kafka Bridge Administrator" }
  "connect-admin" = { description = "Kafka Connect Administrator" }
}

groups = ["ClusterManager Group", "ClusterManager-my-cluster Group", "Ops Team Group"]

# We are not creating users as users will be created in Platform Realm
# External IdP would create usrs upon first login 
users = {}

# users = {
#   "alice" = {
#     email      = "alice@local.io",
#     first_name = "Alice",
#     last_name  = "User",
#     enabled    = true,
#     group_memberships = [
#       "ClusterManager Group"
#     ],
#     roles = [
#       "ui-readwrite"
#     ]
#   }
#   "bob" = {
#     email      = "bob@local.io",
#     first_name = "Bob",
#     last_name  = "User",
#     enabled    = true,
#     group_memberships = [
#       "ClusterManager-my-cluster Group"
#     ],
#     roles = [
#       "ui-readonly"
#     ]
#   }
# }

clients = {
  "team-a-client" = {
    public_client                = false,
    service_accounts_enabled     = true,
    authorization_enabled        = false,
    direct_access_grants_enabled = true,
    service_account_roles        = ["Dev Team A"]
    web_origins                  = ["+"]
    mappers = [
      {
        name                     = "audience-mapper"
        type                     = "audience"
        claim_name               = "aud"
        included_custom_audience = "kafka"
        add_to_access_token      = true
      }
    ]
  },
  "team-b-client" = {
    public_client                = false,
    service_accounts_enabled     = true,
    authorization_enabled        = false,
    direct_access_grants_enabled = true,
    service_account_roles        = ["Dev Team B"]
    web_origins                  = ["+"]
    mappers = [
      {
        name                     = "audience-mapper"
        type                     = "audience"
        claim_name               = "aud"
        included_custom_audience = "kafka"
        add_to_access_token      = true
      }
    ]
  },
  "kafka" = {
    public_client                = false,
    service_accounts_enabled     = true,
    authorization_enabled        = true,
    direct_access_grants_enabled = true,
    service_account_roles        = []
    web_origins                  = ["+"]
  },
  "kafka-cli" = {
    public_client                = false,
    service_accounts_enabled     = true,
    authorization_enabled        = true,
    direct_access_grants_enabled = true,
    service_account_roles        = []
    web_origins                  = ["+"]
  },
  "kafka-ui" = {
    public_client                = false
    service_accounts_enabled     = true
    authorization_enabled        = true
    direct_access_grants_enabled = false
    service_account_roles        = ["ui-admin"]
    valid_redirect_uris          = ["http://kafka-ui.local.io:32080/login/oauth2/code/keycloak"]
    web_origins                  = ["+"]
    standard_flow_enabled        = true
    mappers = [
      {
        name                = "realm-roles"
        type                = "realm-roles"
        claim_name          = "groups"
        add_to_id_token     = true
        add_to_access_token = true
      }
    ]
  },
  "kafka-bridge" = {
    public_client                = false
    standard_flow_enabled        = false
    service_accounts_enabled     = true
    authorization_enabled        = true
    direct_access_grants_enabled = false
    service_account_roles        = ["bridge-admin"]
    mappers = [
      {
        name                     = "audience-mapper"
        type                     = "audience"
        claim_name               = "aud"
        included_custom_audience = "kafka"
        add_to_id_token          = true
        add_to_access_token      = true
      }
    ]
  },
  "kafka-connect" = {
    public_client                = false
    standard_flow_enabled        = false
    service_accounts_enabled     = true
    authorization_enabled        = true
    direct_access_grants_enabled = false
    service_account_roles        = ["connect-admin"]
    mappers = [
      {
        name                     = "audience-mapper"
        type                     = "audience"
        claim_name               = "aud"
        included_custom_audience = "kafka"
        add_to_id_token          = true
        add_to_access_token      = true
      }
    ]
  }
}

idp_mappings = [
  {
    name          = "Platform-ReadWrite-to-Team-A",
    idp_role_name = "readwrite",
    target_role   = "Dev Team A"
  },
  {
    name          = "Platform-ReadWrite-to-Team-B",
    idp_role_name = "readonly",
    target_role   = "Dev Team B"
  },
  {
    name          = "Platform-Admin-to-UI-ReadWrite",
    idp_role_name = "admin",       # Bob has 'admin' in Platform
    target_role   = "ui-readwrite" # Give him full UI access
  },
  {
    name          = "Platform-Admin-to-Ops",
    idp_role_name = "admin",
    target_role   = "Ops Team"
  },
  {
    name          = "Platform-Admin-to-UI-Admin", # Mapping Bob to UI Admin too
    idp_role_name = "admin",
    target_role   = "ui-admin"
  },
  {
    name          = "Platform-ReadOnly-to-UI-ReadOnly",
    idp_role_name = "readonly",
    target_role   = "ui-readonly"
  },
  {
    name          = "Platform-ReadWrite-to-UI-ReadWrite",
    idp_role_name = "readwrite",
    target_role   = "ui-readwrite"
  }
]

auth_scopes = ["Create", "Read", "Write", "Delete", "Alter", "Describe", "ClusterAction", "DescribeConfigs", "AlterConfigs", "IdempotentWrite"]

kafka_resources = [
  # Generic Wildcards (ADMIN ONLY)
  { name = "Topic:*", type = "TopicWildcard", scopes = ["Create", "Delete", "Describe", "Write", "Read", "Alter", "DescribeConfigs", "AlterConfigs"] },
  { name = "Group:*", type = "GroupWildcard", scopes = ["Describe", "Read", "DescribeConfigs", "AlterConfigs"] },
  { name = "Cluster:*", type = "ClusterWildcard", scopes = ["IdempotentWrite", "Describe", "DescribeConfigs"] },

  # Team A Resources
  { name = "Topic:a_*", type = "TeamResource", scopes = ["Create", "Delete", "Describe", "Write", "Read", "Alter", "DescribeConfigs", "AlterConfigs"] },
  { name = "Group:a_*", type = "GroupResource", scopes = ["Describe", "Read"] },
  { name = "kafka-cluster:my-cluster,Topic:a_*", type = "Topic", scopes = ["Create", "Delete", "Describe", "Write", "Read", "Alter", "DescribeConfigs", "AlterConfigs"] },

  # Team B Resources
  { name = "Topic:b_*", type = "TeamResource", scopes = ["Create", "Delete", "Describe", "Write", "Read", "Alter", "DescribeConfigs", "AlterConfigs"] },
  { name = "Group:b_*", type = "GroupResource", scopes = ["Describe", "Read"] },
  { name = "kafka-cluster:my-cluster,Topic:b_*", type = "Topic", scopes = ["Create", "Delete", "Describe", "Write", "Read", "Alter", "DescribeConfigs", "AlterConfigs"] },

  # Shared Resources
  { name = "Topic:x_topic", type = "Topic", scopes = ["Describe", "Read", "Write"] },
  { name = "Group:x_*", type = "Group", scopes = ["Describe", "Read", "Delete"] },
  { name = "kafka-cluster:my-cluster,Topic:x_topic", type = "Topic", scopes = ["Describe", "Read", "Write"] }
]

kafka_policies_role = [
  { name = "Dev Team A", role_name = "Dev Team A" },
  { name = "Dev Team B", role_name = "Dev Team B" },
  { name = "Ops Team", role_name = "Ops Team" },
  { name = "Kafka UI Admin Policy", role_name = "ui-admin" },
  { name = "Kafka UI ReadOnly Policy", role_name = "ui-readonly" },
  { name = "Kafka UI ReadWrite Policy", role_name = "ui-readwrite" },
  { name = "Kafka Bridge Admin Policy", role_name = "bridge-admin" },
  { name = "Kafka Connect Admin Policy", role_name = "connect-admin" }
]

kafka_policies_group = [
  { name = "ClusterManager Group", group_path = "/ClusterManager Group" }
]

kafka_permissions = [
  # Dev Team A access
  {
    name      = "Dev Team A owns topics that start with a_",
    type      = "resource",
    resources = ["Topic:a_*", "kafka-cluster:my-cluster,Topic:a_*"],
    policies  = ["Dev Team A"],
    scopes    = []
  },
  {
    name      = "Dev Team A owns Groups that starts with a_",
    type      = "resource",
    resources = ["Group:a_*"],
    policies  = ["Dev Team A"],
    scopes    = []
  },
  # Dev Team B access
  {
    name      = "Dev Team B owns topics that start with b_",
    type      = "resource",
    resources = ["Topic:b_*", "kafka-cluster:my-cluster,Topic:b_*"],
    policies  = ["Dev Team B"],
    scopes    = []
  },
  {
    name      = "Dev Team B owns Groups that starts with b_",
    type      = "resource",
    resources = ["Group:b_*"],
    policies  = ["Dev Team B"],
    scopes    = []
  },
  # Shared access to topics
  {
    name      = "Shared access to x topics",
    type      = "scope",
    resources = ["Topic:x_topic", "kafka-cluster:my-cluster,Topic:x_topic"],
    policies  = ["Dev Team A", "Dev Team B"],
    scopes    = ["Describe", "Read", "Write"]
  },
  {
    name      = "Shared x groups",
    type      = "resource",
    resources = ["Group:x_*"],
    policies  = ["Dev Team A", "Dev Team B"],
    scopes    = []
  },
  {
    name      = "Allow Teams to use Idempotent Producers",
    type      = "resource",
    resources = ["Cluster:*"],
    policies  = ["Dev Team A", "Dev Team B"],
    scopes    = []
  },
  # UI Admin access 
  {
    name              = "Kafka UI Admin Full Access",
    type              = "resource",
    decision_strategy = "UNANIMOUS"
    resources         = ["Topic:*", "Group:*", "Cluster:*"],
    policies          = ["Kafka UI Admin Policy"],
    scopes            = []
  },
  {
    name              = "Kafka UI Read Only Access",
    type              = "resource",
    decision_strategy = "UNANIMOUS"
    resources         = ["Topic:*", "Group:*", "Cluster:*"],
    policies          = ["Kafka UI ReadOnly Policy"],
    scopes            = []
  },
  {
    name              = "Kafka UI Read Write Access",
    type              = "resource",
    decision_strategy = "UNANIMOUS"
    resources         = ["Topic:*", "Group:*", "Cluster:*"],
    policies          = ["Kafka UI ReadWrite Policy"],
    scopes            = []
  }
]
```

### Terraform Output

```bash
terraform output -json -state=terraform.tfstate | jq -r ".clients.value"
terraform output -json -state=terraform.tfstate | jq -r ".users.value"
```