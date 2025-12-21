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
      policy_enforcement_mode = "ENFORCING"
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

resource "keycloak_openid_user_realm_role_protocol_mapper" "realm_role_mapper" {
  for_each = { for k, v in var.clients : k => v if v.add_groups_mapper }

  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.clients["kafka-ui"].id
  name      = "groups"

  claim_name          = "groups"
  claim_value_type    = "String"
  multivalued         = true
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}