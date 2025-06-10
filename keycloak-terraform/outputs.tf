output "argo_cd_client_secret" {
  value     = keycloak_openid_client.clients["argo-cd"].client_secret
  sensitive = true
}
