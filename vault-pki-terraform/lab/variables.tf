variable "vault_address" {
  type = string
}

variable "vault_token" {
  type      = string
  sensitive = true
}

variable "kubernetes_host" {
  description = "Kubernetes API URL as seen from inside Vault."
  type        = string
}

variable "kubernetes_auth_path" {
  type    = string
  default = "kubernetes"
}

variable "pki_name" {
  type = string
}

variable "root_ca" {
  type = object({
    mount_path    = string
    common_name   = string
    ttl           = string
    max_lease_ttl = string
    organization  = optional(list(string), [])
    key_type      = optional(string, "rsa")
    key_bits      = optional(number, 4096)
  })
}

variable "intermediates" {
  type = map(object({
    mount_path    = string
    common_name   = string
    ttl           = string
    max_lease_ttl = string
    organization  = optional(list(string), [])
    key_type      = optional(string, "rsa")
    key_bits      = optional(number, 2048)
    roles = map(object({
      allowed_domains  = optional(list(string), [])
      allow_subdomains = optional(bool, false)
      allow_any_name   = optional(bool, false)
      max_ttl          = string
      key_type         = optional(string, "rsa")
      key_bits         = optional(number, 2048)
    }))
  }))
}

variable "k8s_auth_bindings" {
  type = map(object({
    bound_service_account_names      = list(string)
    bound_service_account_namespaces = list(string)
    token_ttl                        = optional(string, "1h")
    token_max_ttl                    = optional(string, "24h")
    policy_paths                     = map(list(string))
    policy_name                      = optional(string)
    vault_role_name                  = optional(string)
  }))
}