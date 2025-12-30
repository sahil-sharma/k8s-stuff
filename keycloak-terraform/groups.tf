resource "keycloak_group" "groups" {
  for_each = toset(var.groups)

  realm_id = keycloak_realm.realm.id
  name     = each.key
}

# Assign Realm Roles to Groups
resource "keycloak_group_roles" "group_realm_roles" {
  for_each = {
    for group_name, roles in var.group_realm_roles : group_name => {
      group_id = keycloak_group.groups[group_name].id
      role_ids = [for role in roles : keycloak_role.realm_roles[role].id]
    }
    # Safety check: Only try to assign roles if the group is actually defined in var.groups
    if contains(var.groups, group_name)
  }

  realm_id = keycloak_realm.realm.id
  group_id = each.value.group_id
  role_ids = each.value.role_ids
}