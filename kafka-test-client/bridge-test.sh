#!/bin/bash

set -euo pipefail

# --- Configuration ---
SSO_URL="http://sso.local.io:32080/realms/kafka-authz/protocol/openid-connect/token"
BRIDGE_URL="http://kafka.local.io:32080"
BRIDGE_ID="kafka-bridge"
BRIDGE_SECRET="O0QUpNEYmYadf3CScsPUmoIYnII5vvKa"

# Topics
A_TOPIC="a_topic"
B_TOPIC="b_topic"
X_TOPIC="x_topic"

# Helper to get Bridge Token
get_bridge_token() {
    curl -s -X POST "$SSO_URL" \
        -d "client_id=$BRIDGE_ID" \
        -d "client_secret=$BRIDGE_SECRET" \
        -d "grant_type=client_credentials" | jq -r .access_token
}

# Helper for Bridge Producing
bridge_produce() {
    local topic=$1
    read -p "Enter message for $topic: " msg
    TOKEN=$(get_bridge_token)
    
    curl -s -X POST "$BRIDGE_URL/topics/$topic" \
        -H "Authorization: Bearer $TOKEN" \
        -H "content-type: application/vnd.kafka.json.v2+json" \
        -d "{\"records\":[{\"value\":\"$msg\"}]}" | jq .
}

bridge_consume_flow() {
    local topic=$1
    local group="bridge-group-$topic"
    local instance="inst-$topic"
    TOKEN=$(get_bridge_token)

    echo "0. Cleaning up old instances..."
    curl -s -X DELETE "$BRIDGE_URL/consumers/$group/instances/$instance" \
        -H "Authorization: Bearer $TOKEN" > /dev/null

    echo "1. Creating Consumer Instance ($instance)..."
    curl -s -X POST "$BRIDGE_URL/consumers/$group" \
        -H "Authorization: Bearer $TOKEN" \
        -H "content-type: application/vnd.kafka.v2+json" \
        -d "{\"name\":\"$instance\",\"format\":\"binary\",\"auto.offset.reset\":\"earliest\"}" > /dev/null

    echo "2. Subscribing to $topic..."
    curl -s -X POST "$BRIDGE_URL/consumers/$group/instances/$instance/subscription" \
        -H "Authorization: Bearer $TOKEN" \
        -H "content-type: application/vnd.kafka.v2+json" \
        -d "{\"topics\":[\"$topic\"]}" > /dev/null

    echo "3. Polling for messages (waiting for rebalance)..."
    # We loop because the first poll usually returns empty while rebalancing
    for i in {1..3}; do
        echo "   Poll attempt $i..."
        # timeout=5000 tells the bridge to wait up to 5 seconds for new messages
        RECORDS=$(curl -s -X GET "$BRIDGE_URL/consumers/$group/instances/$instance/records?timeout=5000" \
            -H "Authorization: Bearer $TOKEN" \
            -H "accept: application/vnd.kafka.binary.v2+json")
        
        # Check if records array is not empty
        if [[ $(echo "$RECORDS" | jq '. | length') -gt 0 ]]; then
            echo -e "\n--- [ DATA FOUND ] ---"
            # Decode the base64 values
            echo "$RECORDS" | jq -r '.[].value | @base64d'
            echo "-----------------------"
            break
        fi
        sleep 1
    done

    echo "4. Cleaning up..."
    curl -s -X DELETE "$BRIDGE_URL/consumers/$group/instances/$instance" \
        -H "Authorization: Bearer $TOKEN" > /dev/null
}

show_menu() {
    clear
    echo "================================================================"
    echo "               KAFKA BRIDGE REST API TESTER"
    echo "================================================================"
    echo " PRODUCE MESSAGES:"
    echo "  pa) Produce to $A_TOPIC      pb) Produce to $B_TOPIC      px) Produce to $X_TOPIC"
    echo "----------------------------------------------------------------"
    echo " CONSUME MESSAGES (Create -> Sub -> Read -> Delete):"
    echo "  ca) Consume from $A_TOPIC    cb) Consume from $B_TOPIC    cx) Consume from $X_TOPIC"
    echo "----------------------------------------------------------------"
    echo "  q) Quit"
    echo "================================================================"
}

while true; do
    show_menu
    read -p "Option: " opt
    case $opt in
        pa) bridge_produce "$A_TOPIC" ;;
        pb) bridge_produce "$B_TOPIC" ;;
        px) bridge_produce "$X_TOPIC" ;;
        ca) bridge_consume_flow "$A_TOPIC" ;;
        cb) bridge_consume_flow "$B_TOPIC" ;;
        cx) bridge_consume_flow "$X_TOPIC" ;;
        q) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    echo -e "\nPress Enter to continue..."
    read
done