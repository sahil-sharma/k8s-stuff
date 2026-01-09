# 1. Scopes
resource "keycloak_openid_client_authorization_scope" "scopes" {
  for_each           = toset(var.auth_scopes)
  realm_id           = keycloak_realm.realm.id
  resource_server_id = keycloak_openid_client.clients["kafka"].resource_server_id
  name               = each.key
}

# 2. Resources (e.g., Topic:a_*)
resource "keycloak_openid_client_authorization_resource" "resources" {
  for_each           = { for r in var.kafka_resources : r.name => r }
  realm_id           = keycloak_realm.realm.id
  resource_server_id = keycloak_openid_client.clients["kafka"].resource_server_id
  name               = each.value.name
  type               = each.value.type
  scopes             = each.value.scopes
  depends_on         = [keycloak_openid_client_authorization_scope.scopes]
}

# 3. Policies (Role-Based)
resource "keycloak_openid_client_role_policy" "role_policies" {
  for_each           = { for p in var.kafka_policies_role : p.name => p }
  realm_id           = keycloak_realm.realm.id
  resource_server_id = keycloak_openid_client.clients["kafka"].resource_server_id
  name               = each.value.name
  # Roles are usually required individually, so UNANIMOUS here is fine
  decision_strategy = "UNANIMOUS"
  logic             = "POSITIVE"

  type = "role"

  role {
    id       = keycloak_role.roles[each.value.role_name].id
    required = true
  }
}

# 4. Policies (Group-Based)
resource "keycloak_openid_client_group_policy" "group_policies" {
  for_each           = { for p in var.kafka_policies_group : p.name => p }
  realm_id           = keycloak_realm.realm.id
  resource_server_id = keycloak_openid_client.clients["kafka"].resource_server_id
  name               = each.value.name
  decision_strategy  = "UNANIMOUS"
  logic              = "POSITIVE"

  groups {
    id              = keycloak_group.groups[trimprefix(each.value.group_path, "/")].id
    path            = each.value.group_path
    extend_children = false
  }
}

# 5. Permissions (Resource & Scope)
resource "keycloak_openid_client_authorization_permission" "permissions" {
  for_each           = { for p in var.kafka_permissions : p.name => p }
  realm_id           = keycloak_realm.realm.id
  resource_server_id = keycloak_openid_client.clients["kafka"].resource_server_id
  name               = each.value.name

  decision_strategy = length(each.value.policies) > 1 ? "AFFIRMATIVE" : "UNANIMOUS"

  # Logic to determine policies from both Role and Group maps
  policies = [
    for p_name in each.value.policies : try(
      keycloak_openid_client_role_policy.role_policies[p_name].id,
      keycloak_openid_client_group_policy.group_policies[p_name].id
    )
  ]

  resources = [
    for r_name in each.value.resources : keycloak_openid_client_authorization_resource.resources[r_name].id
  ]

  # Only apply scopes if it is a scope-based permission
  scopes = each.value.type == "scope" ? each.value.scopes : []

  depends_on = [
    keycloak_openid_client_authorization_resource.resources,
    keycloak_openid_client_role_policy.role_policies,
    keycloak_openid_client_group_policy.group_policies
  ]
}

# # Create the Identity Provider link to Platform Realm
# resource "keycloak_oidc_identity_provider" "platform_idp" {
#   realm        = keycloak_realm.realm.id
#   alias        = "${var.idp_realm_name}-idp"
#   display_name = "${upper(var.idp_realm_name)} Login"
#   enabled      = true
#   store_token  = false # Set to true if you need the original platform token
#   trust_email  = true

#   authorization_url = "${var.keycloak_url}/realms/${var.idp_realm_name}/protocol/openid-connect/auth"
#   token_url         = "${var.keycloak_url}/realms/${var.idp_realm_name}/protocol/openid-connect/token"
#   logout_url        = "${var.keycloak_url}/realms/${var.idp_realm_name}/protocol/openid-connect/logout"
#   user_info_url     = "${var.keycloak_url}/realms/${var.idp_realm_name}/protocol/openid-connect/userinfo"
#   issuer            = "${var.keycloak_url}/realms/${var.idp_realm_name}"

#   # These come from the client you just added to the platform realm
#   client_id     = var.idp_client_id
#   client_secret = var.idp_client_secret

#   default_scopes = "openid profile email roles"

#   # Skips the 'Review Profile' screen on first login
#   first_broker_login_flow_alias = "first broker login"
#   sync_mode                     = "FORCE"
# }

# # Map Platform Roles to Kafka-Authz Roles automatically
# resource "keycloak_custom_identity_provider_mapper" "role_mappers" {
#   for_each                 = { for m in var.idp_mappings : m.name => m }
#   realm                    = keycloak_realm.realm.id
#   name                     = each.value.name
#   identity_provider_alias  = keycloak_oidc_identity_provider.platform_idp.alias
#   identity_provider_mapper = "oidc-role-idp-mapper"

#   extra_config = {
#     "claim.value" = each.value.idp_role_name
#     "target.role" = each.value.target_role
#   }
# }