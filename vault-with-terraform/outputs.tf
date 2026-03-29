output "enabled_auth_methods" {
  value = [vault_auth_backend.kubernetes.path, vault_jwt_auth_backend.oidc.path]
}

output "configured_kv_paths" {
  value = [for m in vault_mount.kv : m.path]
}
