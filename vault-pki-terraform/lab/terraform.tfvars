vault_address = "http://secrets.local.io:32080"
vault_token   = ""

kubernetes_host = "https://kubernetes.default.svc.cluster.local:443"

pki_name = "pki-lab"

root_ca = {
  mount_path    = "pki-root"
  common_name   = "pki-lab Root CA"
  ttl           = "87600h"
  max_lease_ttl = "87600h"
  organization  = ["pki-lab"]
  key_bits      = 4096
}

intermediates = {
  int = {
    mount_path    = "pki-int"
    common_name   = "pki-lab Intermediate CA"
    ttl           = "43800h"
    max_lease_ttl = "43800h"
    key_bits      = 2048
    roles = {
      lab-role = {
        allowed_domains  = ["svc.cluster.local", "local.io"]
        allow_subdomains = true
        max_ttl          = "720h"
      }
      external-secrets-role = {
        allowed_domains  = ["local.io"]
        allow_subdomains = true
        max_ttl          = "168h"
      }
    }
  }
}

k8s_auth_bindings = {
  cert-manager = {
    bound_service_account_names      = ["cert-manager"]
    bound_service_account_namespaces = ["cert-manager"]
    token_ttl                        = "1h"
    token_max_ttl                    = "24h"
    policy_paths = {
      "pki-int/sign/lab-role" = ["create", "update"]
    }
  }
  external-secrets = {
    policy_name                      = "external-secrets-policy"
    bound_service_account_names      = ["external-secrets"]
    bound_service_account_namespaces = ["external-secrets"]
    token_ttl                        = "1h"
    token_max_ttl                    = "0"
    policy_paths = {
      "pki-int/sign/external-secrets-role" = ["create", "update"]
    }
  }
}
