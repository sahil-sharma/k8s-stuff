#!/bin/bash -e

# # Copied from official Kafka Strimzi OAuth repo
# https://github.com/strimzi/strimzi-kafka-oauth/blob/0.17.1/examples/docker/kafka-oauth-strimzi/kafka/jwt.sh

if [ "$1" == "" ] || [ "$1" == "--help" ]; then
  echo "Usage: $0 [JSON_WEB_TOKEN]"
  exit 1
fi

IFS='.' read -r -a PARTS <<< "$1"

echo "Head: "
echo $(echo -n "${PARTS[0]}===" | base64 -d 2>/dev/null)
echo
echo "Payload: "
echo $(echo -n "${PARTS[1]}===" | base64 -d 2>/dev/null)