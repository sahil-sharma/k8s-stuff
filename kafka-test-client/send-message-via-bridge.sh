#!/usr/bin/env bash

set -euo pipefail

# Ensure required env vars are set (add or remove as needed)
: "${SSO_TOKEN_URL:?Need SSO_TOKEN_URL set}"
: "${KAFKA_BRIDGE_URL:?Need KAFKA_BRIDGE_URL set}"
: "${A_TOPIC:?Need A_TOPIC set}"
: "${TEAM_A_CLIENT_ID:?Need TEAM_A_CLIENT_ID set}"
: "${TEAM_A_CLIENT_SECRET:?Need TEAM_A_CLIENT_SECRET set}"
: "${TEAM_B_CLIENT_ID:?Need TEAM_B_CLIENT_ID set}"
: "${TEAM_B_CLIENT_SECRET:?Need TEAM_B_CLIENT_SECRET set}"

#######################################
# Get token for a client
# Arguments:
#   1 - client_id
#   2 - client_secret
# Outputs:
#   Echoes access_token to stdout
#######################################
get_token() {
  local client_id="$1"
  local client_secret="$2"

  curl -s -X POST "$SSO_TOKEN_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials" \
    -d "client_id=${client_id}" \
    -d "client_secret=${client_secret}" \
  | jq -r '.access_token'
}

#######################################
# Send a message to Kafka Bridge
# Arguments:
#   1 - access_token
#   2 - message value
#######################################
send_message() {
  local token="$1"
  local message="$2"

  curl -s -X POST "${KAFKA_BRIDGE_URL}/topics/${A_TOPIC}" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/vnd.kafka.json.v2+json" \
    -d "{ \"records\": [ { \"value\": \"${message}\" } ] }"
  echo
}

#######################################
# Flow for Team A
#######################################
run_team_a_flow() {
  echo "Getting Team-A token..."
  local token
  token="$(get_token "$TEAM_A_CLIENT_ID" "$TEAM_A_CLIENT_SECRET")"
  echo "Sending message for Team-A..."
  send_message "$token" "Hello from Team-A via Bridge with Token"
}

#######################################
# Flow for Team B
#######################################
run_team_b_flow() {
  echo "Getting Team-B token..."
  local token
  token="$(get_token "$TEAM_B_CLIENT_ID" "$TEAM_B_CLIENT_SECRET")"
  echo "Sending message for Team-B..."
  send_message "$token" "Hello from Team-B via Bridge with Token"
}

#######################################
# Flow for both Team A and B
#######################################
run_both_flows() {
  run_team_a_flow
  run_team_b_flow
}

#######################################
# Simple menu
#######################################
show_menu() {
  echo "Select an option:"
  echo "1) Run Team-A flow"
  echo "2) Run Team-B flow"
  echo "3) Run both Team-A and Team-B flows"
  echo "4) Quit"
  echo
}

main() {
  while true; do
    show_menu
    read -r -p "Enter choice [1-4]: " choice
    case "$choice" in
      1)
        run_team_a_flow
        ;;
      2)
        run_team_b_flow
        ;;
      3)
        run_both_flows
        ;;
      4)
        echo "Exiting."
        exit 0
        ;;
      *)
        echo "Invalid choice, please enter 1-4."
        ;;
    esac
    echo
  done
}

main "$@"
