resource "keycloak_group" "groups" {
  for_each = toset(var.groups)
  realm_id = keycloak_realm.realm.id
  name     = each.key
}

locals {
  user_map = { for user in var.users : user.username => user }
}

resource "random_password" "user_passwords" {
  for_each = local.user_map

  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>?"
}

resource "keycloak_user" "users" {
  for_each   = local.user_map
  realm_id   = keycloak_realm.realm.id
  username   = each.key
  email      = each.value.email
  first_name = each.value.first_name
  last_name  = each.value.last_name
  enabled    = true

  initial_password {
    value     = random_password.user_passwords[each.key].result
    temporary = true
  }
}

resource "keycloak_user_groups" "user_groups" {
  for_each = {
    for user in var.users : user.username => user
  }

  realm_id = keycloak_realm.realm.id
  user_id  = keycloak_user.users[each.key].id
  group_ids = [
    for g in each.value.groups : keycloak_group.groups[g].id
  ]
}

locals {
  user_client_roles_flat = flatten([
    for user in var.users : [
      for client_id, roles in lookup(user, "roles", {}) : [
        for role_name in roles : {
          username  = user.username
          client_id = client_id
          role_name = role_name
        }
      ]
    ]
  ])
}

resource "keycloak_user_roles" "user_roles" {
  for_each = {
    for r in local.user_client_roles_flat : "${r.username}:${r.client_id}:${r.role_name}" => r
  }

  realm_id = keycloak_realm.realm.id
  user_id  = keycloak_user.users[each.value.username].id

  role_ids = [
    keycloak_role.client_roles["${each.value.client_id}:${each.value.role_name}"].id
  ]
}
