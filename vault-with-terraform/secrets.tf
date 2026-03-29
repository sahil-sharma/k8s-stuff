# Populating OIDC Secrets in KV paths
resource "vault_generic_secret" "oidc_kv_data" {
  # Use the non-sensitive list for the loop keys
  for_each = toset(var.oidc_client_names)

  path = "sso/data/${each.value}"

  data_json = jsonencode({
    data = {
      # Use the non-sensitive key to look up sensitive values
      CLIENT_ID     = var.oidc_clients[each.value].client_id
      CLIENT_SECRET = var.oidc_clients[each.value].client_secret
    }
  })

  depends_on = [vault_mount.kv]
}
