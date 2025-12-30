locals {
  # 1. Extract values: [["admin", "consoleAdmin"], ["readwrite"], ...]
  # 2. Flatten: ["admin", "consoleAdmin", "readwrite", ...]
  # 3. Distinct: ["admin", "consoleAdmin", "readwrite", "readonly"]
  unique_realm_roles = distinct(flatten(values(var.group_realm_roles)))
}

# Create the Realm Roles globally
resource "keycloak_role" "realm_roles" {
  for_each = toset(local.unique_realm_roles)

  realm_id    = keycloak_realm.realm.id
  name        = each.key
  description = "Realm Role managed by Terraform"
}