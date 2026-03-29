
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.8.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0.1"
    }
  }
}

# The Vault provider uses VAULT_ADDR and VAULT_TOKEN from your shell env
provider "vault" {
  address = var.vault_addr
}

# Used only to read the CA cert for Vault's K8s auth config
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-test-cluster"
}
