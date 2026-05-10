########################################
# Root CA
########################################
resource "vault_mount" "root" {
  path                      = var.root.mount_path
  type                      = "pki"
  description               = "Root CA for ${var.name}"
  default_lease_ttl_seconds = tonumber(replace(var.root.ttl, "h", "")) * 3600
  max_lease_ttl_seconds     = tonumber(replace(var.root.max_lease_ttl, "h", "")) * 3600
}

resource "vault_pki_secret_backend_root_cert" "root" {
  backend = vault_mount.root.path

  type         = "internal"
  common_name  = var.root.common_name
  ttl          = var.root.ttl
  organization = join(",", var.root.organization)
  country      = join(",", var.root.country)
  locality     = join(",", var.root.locality)
  province     = join(",", var.root.province)
  key_type     = var.root.key_type
  key_bits     = var.root.key_bits

  exclude_cn_from_sans = true
}

########################################
# Intermediate CAs
########################################
resource "vault_mount" "intermediate" {
  for_each = var.intermediates

  path                      = each.value.mount_path
  type                      = "pki"
  description               = "Intermediate CA '${each.key}' for ${var.name}"
  default_lease_ttl_seconds = tonumber(replace(each.value.ttl, "h", "")) * 3600
  max_lease_ttl_seconds     = tonumber(replace(each.value.max_lease_ttl, "h", "")) * 3600
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  for_each = var.intermediates

  backend      = vault_mount.intermediate[each.key].path
  type         = "internal"
  common_name  = each.value.common_name
  organization = join(",", each.value.organization)
  key_type     = each.value.key_type
  key_bits     = each.value.key_bits
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  for_each = var.intermediates

  backend     = vault_mount.root.path
  csr         = vault_pki_secret_backend_intermediate_cert_request.intermediate[each.key].csr
  common_name = each.value.common_name
  ttl         = each.value.ttl
  format      = "pem_bundle"

  depends_on = [vault_pki_secret_backend_root_cert.root]
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  for_each = var.intermediates

  backend     = vault_mount.intermediate[each.key].path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate[each.key].certificate
}

########################################
# Roles on intermediates
########################################
locals {
  # Flatten { intermediate -> { role -> spec } } into [{ int_key, role_key, spec }, ...]
  role_pairs = flatten([
    for int_key, int_val in var.intermediates : [
      for role_key, role_val in int_val.roles : {
        int_key  = int_key
        role_key = role_key
        spec     = role_val
      }
    ]
  ])
}

resource "vault_pki_secret_backend_role" "role" {
  for_each = {
    for p in local.role_pairs : "${p.int_key}/${p.role_key}" => p
  }

  backend = vault_mount.intermediate[each.value.int_key].path
  name    = each.value.role_key

  allowed_domains     = each.value.spec.allowed_domains
  allow_subdomains    = each.value.spec.allow_subdomains
  allow_bare_domains  = each.value.spec.allow_bare_domains
  allow_glob_domains  = each.value.spec.allow_glob_domains
  allow_any_name      = each.value.spec.allow_any_name
  allow_localhost     = each.value.spec.allow_localhost
  allow_ip_sans       = each.value.spec.allow_ip_sans
  enforce_hostnames   = each.value.spec.enforce_hostnames

  max_ttl = each.value.spec.max_ttl
  ttl     = each.value.spec.ttl

  key_type      = each.value.spec.key_type
  key_bits      = each.value.spec.key_bits
  key_usage     = each.value.spec.key_usage
  ext_key_usage = each.value.spec.ext_key_usage

  organization = each.value.spec.organization
  ou           = each.value.spec.ou
  country      = each.value.spec.country

  require_cn          = each.value.spec.require_cn
  use_csr_common_name = each.value.spec.use_csr_common_name
  use_csr_sans        = each.value.spec.use_csr_sans

  depends_on = [vault_pki_secret_backend_intermediate_set_signed.intermediate]
}