variable "name" {
  description = "Logical name. Used as the Vault role name and policy name unless overridden."
  type        = string
}

variable "policy_name" {
  description = "Override the policy name. Defaults to var.name."
  type        = string
  default     = null
}

variable "vault_role_name" {
  description = "Override the Vault Kubernetes auth role name. Defaults to var.name."
  type        = string
  default     = null
}

variable "kubernetes_auth_path" {
  description = "Mount path of the Kubernetes auth method in Vault (without leading 'auth/')."
  type        = string
  default     = "kubernetes"
}

variable "bound_service_account_names" {
  description = "Kubernetes ServiceAccount names allowed to authenticate as this role."
  type        = list(string)
}

variable "bound_service_account_namespaces" {
  description = "Kubernetes namespaces of the bound ServiceAccounts."
  type        = list(string)
}

variable "token_ttl" {
  description = "TTL of tokens issued to this role (e.g. '1h')."
  type        = string
  default     = "1h"
}

variable "token_max_ttl" {
  description = "Max TTL of tokens issued to this role."
  type        = string
  default     = "24h"
}

variable "policy_paths" {
  description = "Map of Vault path -> list of capabilities to grant in the policy."
  type        = map(list(string))
  # example: { "pki-int/sign/lab-role" = ["create", "update"] }
}