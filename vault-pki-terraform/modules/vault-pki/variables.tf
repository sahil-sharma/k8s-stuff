variable "name" {
  description = "Logical name for this PKI hierarchy. Used to derive default mount paths if not overridden."
  type        = string
}

variable "root" {
  description = "Root CA configuration."
  type = object({
    mount_path        = string
    common_name       = string
    ttl               = string                    # e.g. "87600h"
    max_lease_ttl     = string                    # e.g. "87600h"
    organization      = optional(list(string), [])
    country           = optional(list(string), [])
    locality          = optional(list(string), [])
    province          = optional(list(string), [])
    key_type          = optional(string, "rsa")
    key_bits          = optional(number, 4096)
  })
}

variable "intermediates" {
  description = "Map of intermediate CAs to create under the root. Key is the intermediate's logical name."
  type = map(object({
    mount_path    = string
    common_name   = string
    ttl           = string                        # e.g. "43800h"
    max_lease_ttl = string
    organization  = optional(list(string), [])
    key_type      = optional(string, "rsa")
    key_bits      = optional(number, 2048)

    roles = map(object({
      allowed_domains    = optional(list(string), [])
      allow_subdomains   = optional(bool, false)
      allow_bare_domains = optional(bool, false)
      allow_glob_domains = optional(bool, false)
      allow_any_name     = optional(bool, false)
      allow_localhost    = optional(bool, true)
      allow_ip_sans      = optional(bool, true)
      enforce_hostnames  = optional(bool, true)
      max_ttl            = string                 # e.g. "720h"
      ttl                = optional(string, "")
      key_type           = optional(string, "rsa")
      key_bits           = optional(number, 2048)
      key_usage          = optional(list(string), ["DigitalSignature", "KeyEncipherment", "KeyAgreement"])
      ext_key_usage      = optional(list(string), [])
      organization       = optional(list(string), [])
      ou                 = optional(list(string), [])
      country            = optional(list(string), [])
      require_cn         = optional(bool, true)
      use_csr_common_name = optional(bool, true)
      use_csr_sans       = optional(bool, true)
    }))
  }))
  default = {}
}