#!/usr/bin/env bash
set -euo pipefail

OUTPUT_FILE="/tmp/keycloak-client-details.txt"

PLATFORM_STATE="$K8S_STUFF/keycloak-terraform/terraform.tfstate"
KAFKA_STATE="$K8S_STUFF/keycloak-kafka-terraform/terraform.tfstate"

# Remove existing file if exists
rm -f "${OUTPUT_FILE}"

echo "Generating env file at ${OUTPUT_FILE}"

# ---------- Platform Realm ----------
cat >> "${OUTPUT_FILE}" <<EOF
##### Platform Realm Details #####

EOF

# Platform clients
terraform output -state="${PLATFORM_STATE}" -json clients | jq -r '
  to_entries[] |
  "export " + (.key | ascii_upcase | gsub("-"; "_")) + "_CLIENT_ID=\"" + .key + "\"\n" +
  "export " + (.key | ascii_upcase | gsub("-"; "_")) + "_CLIENT_SECRET=\"" + .value + "\"\n"
' >> "${OUTPUT_FILE}"

# Platform users
terraform output -state="${PLATFORM_STATE}" -json users | jq -r '
  to_entries[] |
  "export " + (.key | ascii_upcase) + "_USERNAME=\"" + .key + "\"\n" +
  "export " + (.key | ascii_upcase) + "_PASSWORD=\"" + .value + "\"\n"
' >> "${OUTPUT_FILE}"

cat >> "${OUTPUT_FILE}" <<EOF
###############################################
EOF

# ---------- Kafka Realm ----------
cat >> "${OUTPUT_FILE}" <<EOF

##### Kafka Authz Realm Details #####

EOF

# Kafka clients
terraform output -state="${KAFKA_STATE}" -json clients | jq -r '
  to_entries[] |
  "export " + (.key | ascii_upcase | gsub("-"; "_")) + "_CLIENT_ID=\"" + .key + "\"\n" +
  "export " + (.key | ascii_upcase | gsub("-"; "_")) + "_CLIENT_SECRET=\"" + .value + "\"\n"
' >> "${OUTPUT_FILE}"

# Kafka users
terraform output -state="${KAFKA_STATE}" -json users | jq -r '
  to_entries[] |
  "export " + (.key | ascii_upcase) + "_USERNAME=\"" + .key + "\"\n" +
  "export " + (.key | ascii_upcase) + "_PASSWORD=\"" + .value + "\"\n"
' >> "${OUTPUT_FILE}"

chmod 600 "${OUTPUT_FILE}"

echo "Load with: source ${OUTPUT_FILE}"
echo ""
cat ${OUTPUT_FILE}
