variable "keycloak_url" {
  description = "Keycloak server URL"
}

variable "keycloak_clients" {
  description = "List of Keycloak clients to create"
  type = list(object({
    id                              = string
    root_url                        = string
    valid_redirect_uris             = list(string)
    valid_post_logout_redirect_uris = list(string)
  }))
  default = []
}

variable "keycloak_admin_login_username" {
  description = "Keycloak admin login username"
  type        = string
  sensitive   = true
}

variable "keycloak_admin_login_password" {
  description = "Keycloak admin login password"
  type        = string
  sensitive   = true
}
