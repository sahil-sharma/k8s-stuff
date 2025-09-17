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

  realm_id                        = keycloak_realm.realm.id
  client_id                       = each.key
  name                            = each.key
  enabled                         = true
  standard_flow_enabled           = true
  direct_access_grants_enabled    = true
  access_type                     = "CONFIDENTIAL"
  client_secret                   = random_password.client_secrets[each.key].result
  root_url                        = each.value.root_url
  valid_redirect_uris             = each.value.valid_redirect_uris
  valid_post_logout_redirect_uris = each.value.valid_post_logout_redirect_uris
  web_origins                     = each.value.web_origins
  frontchannel_logout_enabled      = true
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
