locals {
  kv_mounts = ["apps", "database", "globals", "vault-token", "metrics", "sso"]

  # Mapping Service Accounts to Namespaces for the 'eso-read' policy
  k8s_roles = {
    "welcome-app-role"              = { sa = "welcome-app-service-account", ns = "welcome-app" }
    "argocd-sso-secret-role"        = { sa = "argo-cd-sso-sa", ns = "argo-cd" }
    "grafana-sso-secret-role"       = { sa = "grafana-sso-sa", ns = "grafana" }
    "kiali-sso-secret-role"         = { sa = "kiali-sso-sa", ns = "kiali-operator" }
    "minio-sso-secret-role"         = { sa = "minio-sso-sa", ns = "minio" }
    "minio-root-secret-role"        = { sa = "minio-root-login-sa", ns = "minio" }
    "argo-workflow-sso-secret-role" = { sa = "argo-workflow", ns = "argo-workflows" }
    "oauth-sso-secret-role"         = { sa = "oauth-sso-sa", ns = "oauth2-proxy" }
    "kafka-ui-sso-secret-role"      = { sa = "kafka-ui-sso-sa", ns = "kafka-ui" }
    "kafka-bridge-sso-secret-role"  = { sa = "kafka-bridge-sso-sa", ns = "kafka-cluster" }
    "kafka-connect-sso-secret-role" = { sa = "kafka-connect-sso-sa", ns = "kafka-cluster" }
  }

  # Common redirect URIs for OIDC roles
  oidc_redirects = [
    "http://secrets.local.io:32080/ui/vault/auth/oidc/oidc/callback",
    "http://secrets.local.io:32080/oidc/callback",
    "http://vault.vault:8250/oidc/callback"
  ]
}
