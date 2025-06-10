variable "keycloak_url" {
  description = "Keycloak server URL"
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

variable "argo_cd_client_secret" {
  description = "Client secret for argo-cd"
  type        = string
  sensitive   = true
}

variable "argo_workflow_client_secret" {
  description = "Client secret for argo-workflow"
  type        = string
  sensitive   = true
}

variable "admin_client_secret" {
  description = "Client secret for argo-cd"
  type        = string
  default     = null
  sensitive   = true
}

variable "argocd_url" {
  description = "ArgoCD URL"
  type        = string
  default     = "http://cd.local.io:32080"
}

