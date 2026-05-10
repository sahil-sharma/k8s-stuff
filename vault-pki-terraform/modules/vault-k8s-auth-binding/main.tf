locals {
  policy_name     = coalesce(var.policy_name, var.name)
  vault_role_name = coalesce(var.vault_role_name, var.name)
}

resource "vault_policy" "this" {
  name = local.policy_name

  policy = join("\n\n", [
    for path, caps in var.policy_paths :
    <<-HCL
    path "${path}" {
      capabilities = [${join(", ", [for c in caps : "\"${c}\""])}]
    }
    HCL
  ])
}

resource "vault_kubernetes_auth_backend_role" "this" {
  backend                          = var.kubernetes_auth_path
  role_name                        = local.vault_role_name
  bound_service_account_names      = var.bound_service_account_names
  bound_service_account_namespaces = var.bound_service_account_namespaces
  token_policies                   = [vault_policy.this.name]
  token_ttl                        = tonumber(replace(var.token_ttl, "h", "")) * 3600
  token_max_ttl                    = tonumber(replace(var.token_max_ttl, "h", "")) * 3600
}