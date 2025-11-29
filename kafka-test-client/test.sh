#!/bin/bash -e

# Produce messages to Kafka topic
bash $KAFKA_HOME/bin/kafka-console-producer.sh \
  --topic my-kafka-topic \
  --bootstrap-server my-cluster-kafka-bootstrap.kafka:9093 \
  --producer.config /opt/client.properties

# Consume messages from Kafka topic
bash $KAFKA_HOME/bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap.kafka:9093 \
  --topic my-kafka-topic \
  --from-beginning \
  --consumer.config /opt/client.properties
