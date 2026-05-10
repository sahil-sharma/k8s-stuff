variable "path" {
  description = "Mount path for the Kubernetes auth method (without leading 'auth/')."
  type        = string
  default     = "kubernetes"
}

variable "kubernetes_host" {
  description = "Kubernetes API URL as seen from inside Vault. Typically 'https://kubernetes.default.svc.cluster.local:443' when Vault runs in-cluster."
  type        = string
}

variable "kubernetes_ca_cert" {
  description = "Optional. PEM-encoded CA cert used to verify the Kubernetes API. If empty, Vault uses its in-pod ServiceAccount's CA."
  type        = string
  default     = ""
}

variable "token_reviewer_jwt" {
  description = "Optional. JWT used by Vault to call TokenReview. If empty, Vault uses its own pod's ServiceAccount token."
  type        = string
  default     = ""
  sensitive   = true
}