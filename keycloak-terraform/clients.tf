resource "random_password" "client_secrets" {
  for_each = { for c in var.keycloak_clients : c.id => c }
  length   = 32
  special  = true
}

locals {
  clients = [
    for c in var.keycloak_clients : {
      id                              = c.id
      secret                          = random_password.client_secrets[c.id].result
      root_url                        = c.root_url
      valid_redirect_uris             = c.valid_redirect_uris
      valid_post_logout_redirect_uris = c.valid_post_logout_redirect_uris
    }
  ]
}

resource "keycloak_openid_client" "clients" {
  for_each = { for c in local.clients : c.id => c }

  realm_id                        = keycloak_realm.platform.realm
  name                            = each.key
  description                     = "OpenID Client for ${each.key}"
  client_id                       = each.key
  enabled                         = true
  standard_flow_enabled           = true
  direct_access_grants_enabled    = true
  client_secret                   = each.value.secret
  access_type                     = "CONFIDENTIAL"
  root_url                        = each.value.root_url
  valid_redirect_uris             = each.value.valid_redirect_uris
  valid_post_logout_redirect_uris = each.value.valid_post_logout_redirect_uris
  admin_url                       = each.value.root_url
  web_origins                     = ["+"]
}

resource "keycloak_openid_client_default_scopes" "attach_groups_scope" {
  for_each = keycloak_openid_client.clients

  realm_id       = keycloak_realm.platform.realm
  client_id      = each.value.id
  default_scopes = ["email", "profile", "groups"]
}
