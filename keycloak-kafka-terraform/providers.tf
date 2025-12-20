terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = ">= 5.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "keycloak" {
  client_id = var.admin_client_id
  username  = var.keycloak_admin_login_username
  password  = var.keycloak_admin_login_password
  url       = var.keycloak_url
  realm     = "master"
}
