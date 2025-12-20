# 1. Scopes
resource "keycloak_openid_client_authorization_scope" "scopes" {
  for_each           = toset(var.auth_scopes)
  realm_id           = keycloak_realm.realm.id
  resource_server_id = keycloak_openid_client.clients["kafka"].resource_server_id
  name               = each.key
}

# 2. Resources (e.g., Topic:a_*)
resource "keycloak_openid_client_authorization_resource" "resources" {
  for_each           = { for r in var.kafka_resources : r.name => r }
  realm_id           = keycloak_realm.realm.id
  resource_server_id = keycloak_openid_client.clients["kafka"].resource_server_id
  name               = each.value.name
  type               = each.value.type
  scopes             = each.value.scopes
  depends_on         = [keycloak_openid_client_authorization_scope.scopes]
}

# 3. Policies (Role-Based)
resource "keycloak_openid_client_role_policy" "role_policies" {
  for_each           = { for p in var.kafka_policies_role : p.name => p }
  realm_id           = keycloak_realm.realm.id
  resource_server_id = keycloak_openid_client.clients["kafka"].resource_server_id
  name               = each.value.name
  decision_strategy  = "UNANIMOUS"
  logic              = "POSITIVE"

  type = "role"

  role {
    id       = keycloak_role.roles[each.value.role_name].id
    required = true
  }
}

# 4. Policies (Group-Based)
resource "keycloak_openid_client_group_policy" "group_policies" {
  for_each           = { for p in var.kafka_policies_group : p.name => p }
  realm_id           = keycloak_realm.realm.id
  resource_server_id = keycloak_openid_client.clients["kafka"].resource_server_id
  name               = each.value.name
  decision_strategy  = "UNANIMOUS"
  logic              = "POSITIVE"

  groups {
    id              = keycloak_group.groups[trimprefix(each.value.group_path, "/")].id
    path            = each.value.group_path
    extend_children = false
  }
}

# 5. Permissions (Resource & Scope)
resource "keycloak_openid_client_authorization_permission" "permissions" {
  for_each           = { for p in var.kafka_permissions : p.name => p }
  realm_id           = keycloak_realm.realm.id
  resource_server_id = keycloak_openid_client.clients["kafka"].resource_server_id
  name               = each.value.name

  # Logic to determine policies from both Role and Group maps
  policies = [
    for p_name in each.value.policies : try(
      keycloak_openid_client_role_policy.role_policies[p_name].id,
      keycloak_openid_client_group_policy.group_policies[p_name].id
    )
  ]

  resources = [
    for r_name in each.value.resources : keycloak_openid_client_authorization_resource.resources[r_name].id
  ]

  # Only apply scopes if it is a scope-based permission
  scopes = each.value.type == "scope" ? each.value.scopes : []
}