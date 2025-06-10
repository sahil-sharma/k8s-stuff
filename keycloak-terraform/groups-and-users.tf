locals {
  groups = ["devops", "engineering", "data"]
  users = {
    devops      = ["bob", "dave"]
    engineering = ["alice", "john"]
    data        = ["eve", "mary"]
  }
}

resource "keycloak_group" "groups" {
  for_each = toset(local.groups)
  realm_id = keycloak_realm.platform.realm
  name     = each.value
}

# Flatten the user list into a map like:
# {
#   "DevOps:bob"   = { group = "DevOps", username = "bob" }
#   "DevOps:dave"  = { group = "DevOps", username = "dave" }
#   ...
# }
locals {
  flattened_users = merge([
    for group, users in local.users : {
      for user in users : "${group}:${user}" => {
        group    = group
        username = user
      }
    }
  ]...)
}

# Create user
resource "keycloak_user" "users" {
  for_each   = local.flattened_users
  realm_id   = keycloak_realm.platform.realm
  username   = each.value.username
  email      = "${each.value.username}@local.io"
  enabled    = true
  first_name = each.value.username
  last_name  = "User"

  initial_password {
    value     = "demo123"
    temporary = true
  }
}

# Assign users to their respective groups
resource "keycloak_user_groups" "user_groups" {
  for_each = keycloak_user.users
  realm_id = keycloak_realm.platform.realm
  user_id  = each.value.id
  group_ids = [
    keycloak_group.groups[local.flattened_users[each.key].group].id
  ]
}
