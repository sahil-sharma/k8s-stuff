
variable "vault_addr" {
  type        = string
  description = "The external endpoint for Vault"
}

variable "k8s_host" {
  type    = string
  default = "https://kubernetes.default.svc:443"
}

variable "oidc_discovery_url" {
  type = string
}

# --- NON-SENSITIVE LIST FOR LOOPS ---
variable "oidc_client_names" {
  type        = list(string)
  description = "List of OIDC client names (used for resource keys/addresses)"
}

# --- SENSITIVE DATA FOR VALUES ---
variable "oidc_clients" {
  type = map(object({
    client_id     = string
    client_secret = string
  }))
  sensitive = true
}

variable "cookie_secret" {
  type      = string
  sensitive = true
}
