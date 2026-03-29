# --- Admin Policy ---
resource "vault_policy" "admin" {
  name   = "admin"
  policy = <<EOT
path "*" {
  capabilities = ["create","read","update","delete","list","sudo"]
}
EOT
}

# --- Reader Policy ---
resource "vault_policy" "reader" {
  name   = "reader"
  policy = <<EOT
path "apps/data/*" { capabilities = ["read","list"] }
path "apps/metadata/*" { capabilities = ["list"] }
path "globals/data/*" { capabilities = ["read","list"] }
path "globals/metadata/*" { capabilities = ["list"] }
EOT
}

# --- App Policy ---
resource "vault_policy" "app" {
  name   = "app"
  policy = <<EOT
path "apps/data/*" { capabilities = ["read","list"] }
path "apps/metadata/*" { capabilities = ["list"] }
path "database/data/*" { capabilities = ["read","list"] }
path "database/metadata/*" { capabilities = ["list"] }
path "globals/data/*" { capabilities = ["read","list"] }
path "globals/metadata/*" { capabilities = ["list"] }
path "sso/data/*" { capabilities = ["read","list"] }
path "sso/metadata/*" { capabilities = ["list"] }
EOT
}

# --- Data Reader Policy ---
resource "vault_policy" "data_reader" {
  name   = "data-reader"
  policy = <<EOT
path "data/data/*" { capabilities = ["read","list"] }
path "data/metadata/*" { capabilities = ["list"] }
EOT
}

# --- ESO Read Policy (Copies the App policy logic) ---
resource "vault_policy" "eso_read" {
  name   = "eso-read"
  policy = vault_policy.app.policy
}

# --- Default Role Policy ---
resource "vault_policy" "default_role" {
  name   = "default-role"
  policy = <<EOT
path "auth/token/lookup-self" { capabilities = ["read"] }
path "auth/token/renew-self" { capabilities = ["update"] }
path "auth/token/revoke-self" { capabilities = ["update"] }
path "sys/capabilities-self" { capabilities = ["update"] }
EOT
}
