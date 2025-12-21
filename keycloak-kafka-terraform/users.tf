# Generate a unique 16-character password for each user
resource "random_password" "user_passwords" {
  for_each = var.users

  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}

resource "keycloak_user" "human_users" {
  for_each       = var.users
  realm_id       = keycloak_realm.realm.id
  username       = each.key
  enabled        = each.value.enabled
  email          = each.value.email
  first_name     = each.value.first_name
  last_name      = each.value.last_name
  email_verified = each.value.email_verified

  # Assign the random password generated above
  initial_password {
    value     = random_password.user_passwords[each.key].result
    temporary = false
  }
}

resource "keycloak_user_groups" "user_groups" {
  for_each  = var.users
  realm_id  = keycloak_realm.realm.id
  user_id   = keycloak_user.human_users[each.key].id
  group_ids = [for g in each.value.group_memberships : keycloak_group.groups[g].id]
}

resource "keycloak_user_roles" "user_roles" {
  for_each = var.users
  realm_id = keycloak_realm.realm.id
  user_id  = keycloak_user.human_users[each.key].id

  role_ids = [
    for r in each.value.roles : keycloak_role.roles[r].id
  ]
}