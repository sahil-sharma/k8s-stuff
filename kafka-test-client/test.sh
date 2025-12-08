#!/bin/bash -e

# Environment Variables
REALM_NAME="kafka-authz"
SSO_URL="http://sso.local.io:32080"
SSO_TOKEN_URL="${SSO_URL}/realms/${REALM_NAME}/protocol/openid-connect/token"
KAFKA_BOOTSTRAP_SERVER="cluster-1-kafka-bootstrap.kafka-operator.svc:9093"
KAFKA_TOPIC_NAME="a_topic"
KAFKA_PROPERTIES_FILE="/opt/client.properties"
KAFKA_CLIENT_ID="kafka"
KAFKA_CLIENT_SECRET="kafka-secret"
export KAFKA_OPTS="-Dorg.apache.kafka.sasl.oauthbearer.allowed.urls=${SSO_TOKEN_URL}"

# Delete existing Kafka Properties File if it exists
if [ -f "$KAFKA_PROPERTIES_FILE" ]; then
  echo ""
  echo "Deleting existing Kafka properties file: $KAFKA_PROPERTIES_FILE"
  rm -f "$KAFKA_PROPERTIES_FILE"
fi

echo ""

# Writing Kafka Properties File
echo -e "Writing to Properties file at ${KAFKA_PROPERTIES_FILE} location"
cat <<EOF > $KAFKA_PROPERTIES_FILE
bootstrap.servers=${KAFKA_BOOTSTRAP_SERVER}
security.protocol=SASL_PLAINTEXT
sasl.oauthbearer.token.endpoint.url=${SSO_TOKEN_URL}
sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginCallbackHandler

sasl.mechanism=OAUTHBEARER
sasl.jaas.config= \
  org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required \
    clientId='${KAFKA_CLIENT_ID}' \
    clientSecret='${KAFKA_CLIENT_SECRET}';
EOF

echo ""

echo "Select an option:"
echo "1) Produce message"
echo "2) Consume message"
read -rp "Enter choice (1 or 2): " choice

case $choice in
  1)
    echo "Starting producer for topic: $KAFKA_TOPIC_NAME"
    bash "$KAFKA_HOME/bin/kafka-console-producer.sh" \
      --topic "$KAFKA_TOPIC_NAME" \
      --bootstrap-server "$KAFKA_BOOTSTRAP_SERVER" \
      --producer.config "$KAFKA_PROPERTIES_FILE"
    ;;
  2)
    echo "Starting consumer for topic: $KAFKA_TOPIC_NAME"
    bash "$KAFKA_HOME/bin/kafka-console-consumer.sh" \
      --bootstrap-server "$KAFKA_BOOTSTRAP_SERVER" \
      --topic "$KAFKA_TOPIC_NAME" \
      --from-beginning \
      --consumer.config "$KAFKA_PROPERTIES_FILE"
    ;;
  *)
    echo "Invalid option. Please enter 1 or 2."
    exit 1
    ;;
esac
