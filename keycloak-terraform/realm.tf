resource "keycloak_realm" "realm" {
  realm   = var.realm_name
  enabled = true
}