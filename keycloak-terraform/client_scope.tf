resource "keycloak_openid_client_scope" "groups_scope" {
  realm_id               = keycloak_realm.platform.id
  name                   = "groups"
  description            = "Add user group information to ID token"
  include_in_token_scope = true
  gui_order              = 1
}

resource "keycloak_openid_group_membership_protocol_mapper" "groups_mapper" {
  name                = "groups"
  realm_id            = keycloak_realm.platform.id
  client_scope_id     = keycloak_openid_client_scope.groups_scope.id
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
  claim_name          = "groups"
  full_path           = false
}
