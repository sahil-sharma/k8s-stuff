terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = ">= 5.0.0"
    }
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = "admin"
  password  = var.keycloak_admin_login_password
  url       = var.keycloak_url
  realm     = "master"
  # If using WildFly distribution, uncomment the next line:
  # base_path     = "/auth"
}
