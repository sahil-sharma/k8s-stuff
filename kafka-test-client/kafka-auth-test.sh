#!/bin/bash
set -euo pipefail

# Kafka URLs
SSO_URL="http://sso.local.io:32080/realms/kafka-authz/protocol/openid-connect/token"
BOOTSTRAP_SERVER_ADDR="my-cluster-kafka-bootstrap.kafka-cluster.svc:9094"

# Not using this but maybe needed as by default idempotence is true
DISABLE_IDEMPOTENCE="--producer-property enable.idempotence=false"

# Team Info
TEAM_A_SECRET=""
TEAM_B_SECRET=""

# Property Files
TEAM_A_PROPERTIES_FILE="/opt/a-team-client.properties"
TEAM_B_PROPERTIES_FILE="/opt/b-team-client.properties"

# Kafka scripts path
PRODUCER_SCRIPT="$KAFKA_HOME/bin/kafka-console-producer.sh"
CONSUMER_SCRIPT="$KAFKA_HOME/bin/kafka-console-consumer.sh"
LIST_TOPICS="$KAFKA_HOME/bin/kafka-topics.sh"
LIST_CONSUMER_GROUPS="$KAFKA_HOME/bin/kafka-consumer-groups.sh"

# Topic names
A_TOPIC="a_topic"
B_TOPIC="b_topic"
X_TOPIC="x_topic"
MY_TOPIC="my_topic"

# Consumer Groups names
A_CONSUMER_GROUP="a_consumer_group_1"
B_CONSUMER_GROUP="b_consumer_group_1"
X_CONSUMER_GROUP_TEAM_A="x_group_team_a"
X_CONSUMER_GROUP_TEAM_B="x_group_team_b"
MY_CONSUMER_GROUP="my_consumer_group_1"

show_menu() {
    clear
    echo "================================================================"
    echo "               KAFKA OIDC AUTHORIZATION TESTER"
    echo "================================================================"
    echo " TOKEN INSPECTION (UMA / JWT):"
    echo "  t1) Inspect Team-A Permissions (Aud: kafka)"
    echo "  t2) Inspect Team-B Permissions (Aud: kafka)"
    echo "----------------------------------------------------------------"
    echo " KAFKA OPERATIONS:"
    echo "  1) A write to A topic             13) A list topics"
    echo "  2) A write to B topic (Fail)      14) B list topics"
    echo "  3) B write to A topic (Fail)      15) A list groups"
    echo "  4) B write to B topic             16) B list groups"
    echo "  5) A write to X topic             17) Send 1000 messages to A Topic w/ delay"
    echo "  6) B write to X topic             18) Send 1000 messages to B Topic w/ delay"
    echo "  7) A read from A topic            q) Quit"
    echo "  8) A read from B topic (Fail)"
    echo "  9) A read from X topic"
    echo "  10) B read from A topic (Fail)"
    echo "  11) B read from B topic"
    echo "  12) B read from X topic"
    echo "================================================================"
}

get_message() {
    read -p "Enter message to send: " USER_MSG
}

inspect_service_account() {
    local cid=$1
    local sec=$2
    echo "--- Fetching UMA Ticket for $cid ---"
    TOKEN=$(curl -s -X POST "$SSO_URL" \
        -d "client_id=$cid" \
        -d "client_secret=$sec" \
        -d "grant_type=client_credentials" | jq -r .access_token)
    
    curl -s -X POST "$SSO_URL" \
        -H "Authorization: Bearer $TOKEN" \
        -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
        -d "audience=kafka" | jq -R 'split(".") | .[1] | @base64d | fromjson' | jq .
}

while true; do
    show_menu
    read -p "Option: " opt
    case $opt in
        t1) inspect_service_account "team-a-client" "$TEAM_A_SECRET" ;;
        t2) inspect_service_account "team-b-client" "$TEAM_B_SECRET" ;;
        1) get_message; echo "$USER_MSG" | $PRODUCER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $A_TOPIC --producer.config $TEAM_A_PROPERTIES_FILE ;;
        2) get_message; echo "$USER_MSG" | $PRODUCER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $B_TOPIC --producer.config $TEAM_A_PROPERTIES_FILE ;;
        3) get_message; echo "$USER_MSG" | $PRODUCER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $A_TOPIC --producer.config $TEAM_B_PROPERTIES_FILE ;;
        4) get_message; echo "$USER_MSG" | $PRODUCER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $B_TOPIC --producer.config $TEAM_B_PROPERTIES_FILE ;;
        5) get_message; echo "$USER_MSG" | $PRODUCER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $X_TOPIC --producer.config $TEAM_A_PROPERTIES_FILE ;;
        6) get_message; echo "$USER_MSG" | $PRODUCER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $X_TOPIC --producer.config $TEAM_B_PROPERTIES_FILE ;;
        7) $CONSUMER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $A_TOPIC --from-beginning --consumer.config $TEAM_A_PROPERTIES_FILE --group $A_CONSUMER_GROUP ;;
        8) $CONSUMER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $B_TOPIC --from-beginning --consumer.config $TEAM_A_PROPERTIES_FILE --group $A_CONSUMER_GROUP ;;
        9) $CONSUMER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $X_TOPIC --from-beginning --consumer.config $TEAM_A_PROPERTIES_FILE --group $X_CONSUMER_GROUP_TEAM_A ;;
        10) $CONSUMER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $A_TOPIC --from-beginning --consumer.config $TEAM_B_PROPERTIES_FILE --group $B_CONSUMER_GROUP ;;
        11) $CONSUMER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $B_TOPIC --from-beginning --consumer.config $TEAM_B_PROPERTIES_FILE --group $B_CONSUMER_GROUP ;;
        12) $CONSUMER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $X_TOPIC --from-beginning --consumer.config $TEAM_B_PROPERTIES_FILE --group $X_CONSUMER_GROUP_TEAM_B ;;
        13) $LIST_TOPICS --bootstrap-server $BOOTSTRAP_SERVER_ADDR --command-config $TEAM_A_PROPERTIES_FILE --list ;;
        14) $LIST_TOPICS --bootstrap-server $BOOTSTRAP_SERVER_ADDR --command-config $TEAM_B_PROPERTIES_FILE --list ;;
        15) $LIST_CONSUMER_GROUPS --bootstrap-server $BOOTSTRAP_SERVER_ADDR --command-config $TEAM_A_PROPERTIES_FILE --list ;;
        16) $LIST_CONSUMER_GROUPS --bootstrap-server $BOOTSTRAP_SERVER_ADDR --command-config $TEAM_B_PROPERTIES_FILE --list ;;
        17) for i in $(seq 1 1000); do echo "Message $i from Team A"; sleep 1; done | $PRODUCER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $A_TOPIC --producer.config $TEAM_A_PROPERTIES_FILE ;;
        18) for i in $(seq 1 1000); do echo "Message $i from Team B"; sleep 1; done | $PRODUCER_SCRIPT --bootstrap-server $BOOTSTRAP_SERVER_ADDR --topic $B_TOPIC --producer.config $TEAM_B_PROPERTIES_FILE ;;
        q|Q) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    echo -e "\nPress Enter to continue..."
    read
done
