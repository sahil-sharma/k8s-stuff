variable "keycloak_url" {
  type = string
}

# Replace the old admin_client_secret with these
variable "keycloak_admin_login_username" {
  type    = string
  default = "admin"
}

variable "keycloak_admin_login_password" {
  type      = string
  sensitive = true
}

# The client_id remains admin-cli usually
variable "admin_client_id" {
  type    = string
  default = "admin-cli"
}

variable "realm_config" {
  type = object({
    realm        = string
    display_name = optional(string, null)
    enabled      = bool
    ssl_required = string
  })
}

variable "realm_roles" {
  description = "Map of realm roles to create"
  type        = map(object({ description = string }))
}

variable "groups" {
  description = "List of group names"
  type        = list(string)
}

variable "clients" {
  description = "Map of clients configuration"
  type = map(object({
    public_client                = optional(bool, false)
    service_accounts_enabled     = optional(bool, false)
    authorization_enabled        = optional(bool, false)
    direct_access_grants_enabled = optional(bool, false)
    standard_flow_enabled        = optional(bool, false)
    web_origins                  = optional(list(string), [])
    service_account_roles        = optional(list(string), [])
    valid_redirect_uris          = optional(list(string), [])
    mappers = optional(list(object({
      name       = string
      type       = string # Expected: "groups", "realm-roles", or "client-roles"
      claim_name = string
    })), [])
  }))
}

variable "users" {
  type = map(object({
    email             = string
    first_name        = string
    last_name         = string
    enabled           = bool
    group_memberships = list(string)
    email_verified    = optional(bool, true)
    roles             = list(string)
  }))
}

# --- Authorization Variables ---

variable "auth_scopes" {
  type = list(string)
}

variable "kafka_resources" {
  description = "List of resources to protect"
  type = list(object({
    name   = string
    type   = string
    scopes = list(string)
  }))
}

variable "kafka_policies_role" {
  description = "Role-based policies"
  type = list(object({
    name      = string
    role_name = string
  }))
}

variable "kafka_policies_group" {
  description = "Group-based policies"
  type = list(object({
    name       = string
    group_path = string
  }))
}

variable "kafka_permissions" {
  description = "Permissions linking resources/scopes to policies"
  type = list(object({
    name      = string
    type      = string # 'resource' or 'scope'
    resources = list(string)
    policies  = list(string)
    scopes    = list(string) # Empty if type is 'resource'
  }))
}