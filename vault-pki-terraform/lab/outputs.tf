output "root_ca_pem" {
  description = "Root CA cert. Save this and create the trust-manager source Secret from it."
  value       = module.pki.root_certificate_pem
}

output "role_paths" {
  description = "Map of role keys to full sign paths. Useful when writing policy_paths in tfvars."
  value       = module.pki.role_paths
}