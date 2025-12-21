output "users" {
  description = "Map of usernames to their generated passwords"
  value = {
    for username, pwd in random_password.user_passwords :
    username => pwd.result
  }
  sensitive = true
}

output "clients" {
  description = "Map of client IDs to their generated secrets"
  value = {
    for client_id, secret in random_password.client_secrets :
    client_id => secret.result
  }
  sensitive = true
}