resource "keycloak_realm" "realm" {
  realm   = var.realm_name
  enabled = true
}

resource "keycloak_realm_events" "realm_events" {
  realm_id = keycloak_realm.realm.id

  events_enabled    = true
  events_expiration = 9000

  admin_events_enabled         = true
  admin_events_details_enabled = true

  # When omitted or left empty, keycloak will enable all event types
  enabled_event_types = [
    "LOGIN",
    "LOGOUT",
    "REGISTER",
    "UPDATE_PASSWORD"
  ]

  events_listeners = [
    "jboss-logging",
    "metrics-listener"
  ]
}

# --- NEW: manage events only for master realm ---
resource "keycloak_realm_events" "master_realm_events" {
  realm_id = "master"

  events_enabled    = true
  events_expiration = 9000

  admin_events_enabled         = true
  admin_events_details_enabled = true

  # optional: leave empty to capture all events
  enabled_event_types = [
    "LOGIN",
    "LOGOUT",
    "REGISTER",
    "UPDATE_PASSWORD"
  ]

  events_listeners = [
    "jboss-logging",
    "metrics-listener"
  ]
}