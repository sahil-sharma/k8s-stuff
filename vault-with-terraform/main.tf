
# 1. Create the KV Engines (using locals.kv_mounts)
resource "vault_mount" "kv" {
  for_each = toset(local.kv_mounts)
  path     = each.value
  type     = "kv"
  options  = { version = "2" }
}

# 2. Kubernetes Auth Backend
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

# Fetch the CA Cert from K8s
data "kubernetes_config_map_v1" "kube_root_ca" {
  metadata {
    name      = "kube-root-ca.crt"
    namespace = "default"
  }
}

resource "vault_kubernetes_auth_backend_config" "config" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = var.k8s_host
  kubernetes_ca_cert = data.kubernetes_config_map_v1.kube_root_ca.data["ca.crt"]
  issuer             = "https://kubernetes.default.svc.cluster.local"
}

# 3. Create all K8s Roles (using locals.k8s_roles)
resource "vault_kubernetes_auth_backend_role" "k8s_roles" {
  for_each                         = local.k8s_roles
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = each.key
  bound_service_account_names      = [each.value.sa]
  bound_service_account_namespaces = [each.value.ns]
  token_policies                   = ["eso-read"]
  audience                         = "https://kubernetes.default.svc.cluster.local"
}

# 4. OIDC Auth Backend
resource "vault_jwt_auth_backend" "oidc" {
  path               = "oidc"
  type               = "oidc"
  oidc_discovery_url = var.oidc_discovery_url
  oidc_client_id     = var.oidc_clients["secrets"].client_id
  oidc_client_secret = var.oidc_clients["secrets"].client_secret
  default_role       = "reader"

  tune {
    listing_visibility = "unauth"
  }
}

resource "vault_jwt_auth_backend_role" "oidc_roles" {
  for_each = {
    "admin"       = { policy = "admin", group = "devops" }
    "reader"      = { policy = "reader", group = "engineering" }
    "data-reader" = { policy = "data-reader", group = "data" }
    "default"     = { policy = "default-role", group = "*" }
  }

  backend        = vault_jwt_auth_backend.oidc.path
  role_name      = each.key
  token_policies = [each.value.policy]

  user_claim            = "preferred_username"
  groups_claim          = "groups"
  role_type             = "oidc"
  allowed_redirect_uris = local.oidc_redirects

  # This handles the 'bound_claims' mapping for each group
  bound_claims = {
    groups = each.value.group
  }

  token_ttl = 3600
}
