resource "vault_generic_secret" "oidc_kv_data" {
  for_each = toset(var.oidc_client_names)

  # KV-v2 path
  path = "sso/${each.value}"

  # This logic iterates over the map for the specific client,
  # uppercases the keys, and ignores null values.
  data_json = jsonencode({
    for key, value in var.oidc_clients[each.value] : upper(key) => value
    if value != null
  })

  depends_on = [vault_mount.kv]
}
