# 1. Generate secrets for non-public clients
resource "random_password" "client_secrets" {
  for_each = { for k, v in var.clients : k => v if !v.public_client }
  length   = 32
  special  = false
}

# 2. Create Clients
resource "keycloak_openid_client" "clients" {
  for_each                     = var.clients
  realm_id                     = keycloak_realm.realm.id
  client_id                    = each.key
  enabled                      = true
  valid_redirect_uris          = each.value.valid_redirect_uris
  web_origins                  = try(each.value.web_origins, [])
  access_type                  = each.value.public_client ? "PUBLIC" : "CONFIDENTIAL"
  client_secret                = each.value.public_client ? null : random_password.client_secrets[each.key].result
  direct_access_grants_enabled = each.value.direct_access_grants_enabled
  standard_flow_enabled        = each.value.standard_flow_enabled
  service_accounts_enabled     = each.value.authorization_enabled ? true : each.value.service_accounts_enabled

  dynamic "authorization" {
    for_each = each.value.authorization_enabled ? [1] : []
    content {
      policy_enforcement_mode          = "ENFORCING"
      decision_strategy                = "AFFIRMATIVE"
      allow_remote_resource_management = true
    }
  }
}

# 3. Service Account Role Mappings (e.g., team-a-client gets "Dev Team A")
# Flatten the map to handle lists of roles per client
locals {
  sa_role_mappings = flatten([
    for client_name, config in var.clients : [
      for role_name in config.service_account_roles : {
        client_name = client_name
        role_name   = role_name
      }
    ] if config.service_accounts_enabled
  ])
}

resource "keycloak_openid_client_service_account_realm_role" "sa_roles" {
  for_each = { for mapping in local.sa_role_mappings : "${mapping.client_name}_${mapping.role_name}" => mapping }

  realm_id                = keycloak_realm.realm.id
  service_account_user_id = keycloak_openid_client.clients[each.value.client_name].service_account_user_id
  role                    = keycloak_role.roles[each.value.role_name].name
}

locals {
  # Create a unique key for every mapper: "clientname-mappername"
  all_mappers = flatten([
    for client_key, client_val in var.clients : [
      for m in client_val.mappers : {
        client_key = client_key
        client_id  = keycloak_openid_client.clients[client_key].id
        name       = m.name
        type       = m.type
        claim_name = m.claim_name
      }
    ]
  ])
}

# Resource for Group Mappers
resource "keycloak_openid_group_membership_protocol_mapper" "group_mapper" {
  for_each = { for m in local.all_mappers : "${m.client_key}-${m.name}" => m if m.type == "groups" }

  realm_id  = keycloak_realm.realm.id
  client_id = each.value.client_id
  name      = each.value.name

  claim_name          = each.value.claim_name
  full_path           = false
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}

# Resource for Realm Role Mappers
resource "keycloak_openid_user_realm_role_protocol_mapper" "role_mapper" {
  for_each = { for m in local.all_mappers : "${m.client_key}-${m.name}" => m if m.type == "realm-roles" }

  realm_id  = keycloak_realm.realm.id
  client_id = each.value.client_id
  name      = each.value.name

  claim_name          = each.value.claim_name
  multivalued         = true
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}

# Resource for Client Role Mappers
resource "keycloak_openid_user_client_role_protocol_mapper" "client_roles" {
  for_each = { for m in local.all_mappers : "${m.client_key}-${m.name}" => m if m.type == "client-roles" }

  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.clients[each.value.client_key].id
  name      = each.value.name

  claim_name          = each.value.claim_name
  multivalued         = true
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true

  # This is specific to client roles: it dictates which client's roles to map
  # Usually, you want the roles of the client itself
  client_id_for_role_mappings = each.value.client_key
}