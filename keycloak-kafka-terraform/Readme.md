# Keycloak Infrastructure as Code (Kafka Authorization)

This repository contains the Terraform configuration to bootstrap a production-ready Keycloak Realm specifically designed for **Kafka Fine-Grained Authorization**. It implements a Zero-Trust security model where every Kafka resource is protected by specific OIDC policies.

---

## 🏗 Architecture Overview

The configuration automates the following Keycloak components using a **No-Hardcode** approach (all data is driven by `.tfvars`):

- **Custom Realm:** `kafka-authz`
- **Functional Roles:** `Dev Team A`, `Dev Team B`, `Ops Team`
- **Organizational Groups:** `ClusterManager`, `Ops Team Group`
- **Automated Users:** Human accounts with assigned groups, "User" last names, and **random 16-character passwords**.
- **Automated Clients:** - **Public:** `kafka-cli` (For developer CLI access).
  - **Confidential:** `broker`, `kafka`, `team-a-client`, `team-b-client` (All with **random 32-character secrets**).
- **Authorization Services:** Logic to protect Kafka Topics, Groups, and Clusters via OIDC Resources, Scopes, and Policies.



---

## 📂 File Structure

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

## 🔐 Security Model: Who Can Do What?

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

## 🚀 Deployment & Setup

### 1. Prerequisites
- Terraform `>= 1.0.0`
- Keycloak admin credentials for the `master` realm.
- `admin-cli` client must have "Direct Access Grants" enabled.

### 2. Configure Credentials
Update your `terraform.tfvars` with your instance details:
```hcl
keycloak_url                  = "[http://sso.local.io:32080](http://sso.local.io:32080)"
keycloak_admin_login_username = "admin"
keycloak_admin_login_password = "your-password"