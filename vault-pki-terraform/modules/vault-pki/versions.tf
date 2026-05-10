terraform {
  required_version = ">= 1.14"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.9.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.2.1"
    }
  }
}