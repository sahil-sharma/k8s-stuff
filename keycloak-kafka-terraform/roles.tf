resource "keycloak_role" "roles" {
  for_each    = var.realm_roles
  realm_id    = keycloak_realm.realm.id
  name        = each.key
  description = each.value.description
}