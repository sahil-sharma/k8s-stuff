variable "keycloak_url" {
  type        = string
  description = "URL of the Keycloak server"
}

variable "keycloak_admin_login_username" {
  type        = string
  description = "Admin username"
  sensitive   = true
}

variable "keycloak_admin_login_password" {
  type        = string
  description = "Admin password"
  sensitive   = true
}

variable "realm_name" {
  type        = string
  description = "Keycloak realm name"
}

variable "clients" {
  type = list(object({
    client_id                       = string
    root_url                        = string
    valid_redirect_uris             = list(string)
    valid_post_logout_redirect_uris = list(string)
    roles                           = list(string)
    web_origins                     = list(string)
  }))
  description = "Clients and their roles"
}

variable "groups" {
  type        = list(string)
  description = "List of groups"
}

# variable "realm_roles" {
#   type        = list(string)
#   description = "List of realm roles"
# }

variable "group_realm_roles" {
  type        = map(list(string))
  description = "Map of group names to realm role names"
}

variable "users" {
  description = "List of users with metadata"
  type = list(object({
    username   = string
    first_name = string
    last_name  = string
    email      = string
    groups     = list(string)
    roles      = map(list(string)) # client_id => [role1, role2]
  }))
}
