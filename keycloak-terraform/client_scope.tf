resource "keycloak_openid_client_scope" "groups" {
  realm_id               = keycloak_realm.realm.id
  name                   = "groups"
  description            = "Add user group information to ID token"
  include_in_token_scope = true
  gui_order              = 1
}

resource "keycloak_openid_group_membership_protocol_mapper" "groups_mapper" {
  name                = "groups"
  realm_id            = keycloak_realm.realm.id
  client_scope_id     = keycloak_openid_client_scope.groups.id
  claim_name          = "groups"
  full_path           = false
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}

resource "keycloak_openid_client_default_scopes" "default_scopes" {
  for_each = { for client in var.clients : client.client_id => client }

  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.clients[each.key].id
  default_scopes = [
    "profile",
    "email",
    "roles",
    keycloak_openid_client_scope.groups.name
  ]
}