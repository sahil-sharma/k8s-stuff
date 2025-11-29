#!/bin/bash -e

PROPERTIES_FILE="/opt/client.properties"
TOPIC_NAME="my-kafka-topic"
KAFKA_BOOTSTRAP_SERVER="my-cluster-kafka-bootstrap.kafka:9093"

# Produce messages to Kafka topic
bash $KAFKA_HOME/bin/kafka-console-producer.sh \
  --topic $TOPIC_NAME \
  --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --producer.config $PROPERTIES_FILE

# Consume messages from Kafka topic
bash $KAFKA_HOME/bin/kafka-console-consumer.sh \
  --bootstrap-server $KAFKA_BOOTSTRAP_SERVER     \
  --topic $TOPIC_NAME \
  --from-beginning \
  --consumer.config $PROPERTIES_FILE