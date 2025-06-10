output "client_secrets" {
  description = "Client secrets for Keycloak clients"
  value = {
    for c in keycloak_openid_client.clients :
    c.client_id => c.client_secret
  }
  sensitive = true
}
