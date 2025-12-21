output "users" {
  description = "Map of usernames to their generated passwords"
  value = {
    for username, pwd in random_password.user_passwords :
    username => pwd.result
  }
  sensitive = true
}

output "clients" {
  sensitive = true
  value = {
    for k, v in random_password.client_secrets : k => v.result
  }
}