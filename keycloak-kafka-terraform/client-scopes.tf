resource "keycloak_openid_client_scope" "scopes" {
  for_each = toset(var.auth_scopes)

  realm_id = keycloak_realm.realm.id
  name     = each.key
}