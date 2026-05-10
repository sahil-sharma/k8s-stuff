output "root_mount_path" {
  description = "Vault mount path of the root CA."
  value       = vault_mount.root.path
}

output "root_certificate_pem" {
  description = "Root CA certificate in PEM format. Distribute this via trust-manager."
  value       = vault_pki_secret_backend_root_cert.root.certificate
}

output "intermediate_mount_paths" {
  description = "Map of intermediate logical name -> Vault mount path."
  value = {
    for k, v in vault_mount.intermediate : k => v.path
  }
}

output "intermediate_certificates_pem" {
  description = "Map of intermediate logical name -> intermediate cert PEM."
  value = {
    for k, v in vault_pki_secret_backend_root_sign_intermediate.intermediate : k => v.certificate
  }
}

output "role_paths" {
  description = "Map of '<intermediate>/<role>' -> full Vault sign path (e.g. 'pki-int/sign/lab-role'). Use these in policies and ClusterIssuers."
  value = {
    for k, r in vault_pki_secret_backend_role.role :
    k => "${r.backend}/sign/${r.name}"
  }
}