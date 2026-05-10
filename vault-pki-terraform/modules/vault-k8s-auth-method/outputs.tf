output "path" {
  description = "Path the Kubernetes auth method is mounted at."
  value       = vault_auth_backend.this.path
}

output "accessor" {
  description = "Accessor of the auth backend. Useful if you need to reference it in policies."
  value       = vault_auth_backend.this.accessor
}