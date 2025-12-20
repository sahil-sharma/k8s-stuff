resource "keycloak_group" "groups" {
  for_each = toset(var.groups)
  realm_id = keycloak_realm.realm.id
  name     = each.key
}