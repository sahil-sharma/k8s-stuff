output "policy_name" {
  value = vault_policy.this.name
}

output "vault_role_name" {
  value = vault_kubernetes_auth_backend_role.this.role_name
}