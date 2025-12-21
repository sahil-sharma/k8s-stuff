resource "random_password" "client_secrets" {
  for_each = { for client in var.clients : client.client_id => client }
  length   = 32
  special  = false
  upper    = true
  lower    = true
  numeric  = true
}

resource "keycloak_openid_client" "clients" {
  for_each = { for client in var.clients : client.client_id => client }

  realm_id  = keycloak_realm.realm.id
  client_id = each.key
  name      = each.key
  enabled   = true

  access_type = "CONFIDENTIAL"

  # Capability config
  standard_flow_enabled        = lookup(each.value, "enable_standard_flow", false)
  direct_access_grants_enabled = lookup(each.value, "enable_direct_grant", false)

  service_accounts_enabled = (
    lookup(each.value, "enable_authorization", false)
    ? true
    : lookup(each.value, "enable_service_account", false)
  )

  client_secret = random_password.client_secrets[each.key].result

  root_url = try(
    each.value.enable_standard_flow ? each.value.root_url : null,
    null
  )

  valid_redirect_uris = try(
    each.value.enable_standard_flow ? each.value.valid_redirect_uris : [],
    []
  )

  valid_post_logout_redirect_uris = try(
    each.value.enable_standard_flow ? each.value.valid_post_logout_redirect_uris : [],
    []
  )

  web_origins = try(each.value.web_origins, [])

  dynamic "authorization" {
    for_each = each.value.enable_authorization ? [1] : []
    content {
      policy_enforcement_mode          = "ENFORCING"
      decision_strategy                = "UNANIMOUS"
      allow_remote_resource_management = false
      keep_defaults                    = false
    }
  }
}

locals {
  client_roles_flat = flatten([
    for client in var.clients : [
      for role in lookup(client, "roles", []) : {
        client_id = client.client_id
        role_name = role
      }
    ]
  ])
}

resource "keycloak_role" "client_roles" {
  for_each = {
    for role in local.client_roles_flat : "${role.client_id}:${role.role_name}" => role
  }

  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.clients[each.value.client_id].id
  name      = each.value.role_name
}
