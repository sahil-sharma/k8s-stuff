locals {
  clients = [
    { id = "argo-cd", secret = var.argo_cd_client_secret },
    { id = "argo-workflow", secret = var.argo_workflow_client_secret },
  ]
}

resource "keycloak_openid_client" "clients" {
  for_each = { for c in local.clients : c.id => c }

  realm_id                     = keycloak_realm.platform.realm
  name                         = each.key
  description                  = "OpenID Client for ${each.key}"
  client_id                    = each.key
  enabled                      = true
  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  client_secret                = each.value.secret
  access_type                  = "CONFIDENTIAL"
  root_url                     = var.argocd_url
  valid_redirect_uris = [
    "${var.argocd_url}/auth/callback"
  ]
  web_origins = ["+"]
  valid_post_logout_redirect_uris = [
    "${var.argocd_url}/applications"
  ]
  admin_url = var.argocd_url

}

resource "keycloak_openid_client_default_scopes" "attach_groups_scope" {
  for_each = keycloak_openid_client.clients

  realm_id       = keycloak_realm.platform.realm
  client_id      = each.value.id
  default_scopes = ["email", "profile", "groups"]
}
