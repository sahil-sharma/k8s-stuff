terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = ">= 5.5.0"
    }
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = var.keycloak_admin_login_username
  password  = var.keycloak_admin_login_password
  url       = var.keycloak_url
  realm     = "master"
}
