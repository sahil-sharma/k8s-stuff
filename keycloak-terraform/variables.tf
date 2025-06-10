variable "keycloak_url" {
  description = "Keycloak server URL"
}

variable "keycloak_clients" {
  description = "List of Keycloak clients to create"
  type = list(object({
    id       = string
    root_url = string
    valid_redirect_uris = list(string)
    valid_post_logout_redirect_uris = list(string)
  }))
  default = [
    {
      id                              = "argo-cd"
      root_url                        = "http://cd.local.io:32080"
      valid_redirect_uris             = ["http://cd.local.io:32080/auth/callback"]
      valid_post_logout_redirect_uris = ["http://cd.local.io:32080/applications"]
    },
    {
      id                              = "argo-workflow"
      root_url                        = "http://jobs.local.io:32080"
      valid_redirect_uris             = ["http://jobs.local.io/:32080/oauth2/callback"]
      valid_post_logout_redirect_uris = ["http://jobs.local.io:32080/applications"]
    }
  ]
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

