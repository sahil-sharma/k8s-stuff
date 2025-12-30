locals {
  user_map = { for user in var.users : user.username => user }
}

# 1. Generate random passwords
resource "random_password" "user_passwords" {
  for_each = local.user_map

  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# 2. Create Users
resource "keycloak_user" "users" {
  for_each = local.user_map

  realm_id       = keycloak_realm.realm.id
  username       = each.key
  email          = each.value.email
  first_name     = each.value.first_name
  last_name      = each.value.last_name
  enabled        = true
  email_verified = true

  initial_password {
    value     = random_password.user_passwords[each.key].result
    temporary = false
  }
}

# 3. Assign Users to Groups
resource "keycloak_user_groups" "user_groups" {
  for_each = local.user_map

  realm_id = keycloak_realm.realm.id
  user_id  = keycloak_user.users[each.key].id

  # References the groups created in groups.tf
  group_ids = [
    for g in each.value.groups : keycloak_group.groups[g].id
  ]
}

# 4. Helper local to flatten User -> Client Role mappings
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

# 5. Assign Client Roles to Users
resource "keycloak_user_roles" "user_client_roles" {
  for_each = {
    for r in local.user_client_roles_flat : "${r.username}:${r.client_id}:${r.role_name}" => r
  }

  realm_id = keycloak_realm.realm.id
  user_id  = keycloak_user.users[each.value.username].id

  # References the client roles created in clients.tf
  role_ids = [
    keycloak_role.client_roles["${each.value.client_id}:${each.value.role_name}"].id
  ]
}