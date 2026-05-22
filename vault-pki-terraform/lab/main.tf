module "k8s_auth_method" {
  source          = "../modules/vault-k8s-auth-method"
  path            = var.kubernetes_auth_path
  kubernetes_host = var.kubernetes_host
}

module "pki" {
  source = "../modules/vault-pki"

  name = var.pki_name

  root = {
    mount_path    = var.root_ca.mount_path
    common_name   = var.root_ca.common_name
    ttl           = var.root_ca.ttl
    max_lease_ttl = var.root_ca.max_lease_ttl
    organization  = var.root_ca.organization
    key_type      = var.root_ca.key_type
    key_bits      = var.root_ca.key_bits
  }

  intermediates = var.intermediates
}

module "k8s_auth" {
  source   = "../modules/vault-k8s-auth-binding"
  for_each = var.k8s_auth_bindings

  name                             = each.key
  policy_name                      = each.value.policy_name
  vault_role_name                  = each.value.vault_role_name
  kubernetes_auth_path             = module.k8s_auth_method.path
  bound_service_account_names      = each.value.bound_service_account_names
  bound_service_account_namespaces = each.value.bound_service_account_namespaces
  token_ttl                        = each.value.token_ttl
  token_max_ttl                    = each.value.token_max_ttl
  policy_paths                     = each.value.policy_paths

  depends_on = [module.k8s_auth_method]
}
