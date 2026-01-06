# ===============================
# Build stage – build Strimzi OAuth
# ===============================
FROM maven:3.9.12-eclipse-temurin-17-alpine AS builder

ARG KAFKA_OAUTH_VERSION=0.17.0
ENV OAUTH_SRC=/opt/strimzi-kafka-oauth-${KAFKA_OAUTH_VERSION}

RUN apk add --no-cache curl bash

# Download and build Strimzi OAuth
RUN curl -sL "https://github.com/strimzi/strimzi-kafka-oauth/archive/refs/tags/${KAFKA_OAUTH_VERSION}.tar.gz" \
    | tar xz -C /opt && \
    cd "${OAUTH_SRC}" && \
    mvn -q -DskipTests -Dmaven.javadoc.skip=true clean install

# ===============================
# Runtime stage
# ===============================
FROM alpine:3.20

# ---- Runtime dependencies ----
RUN apk add --no-cache \
    openjdk17-jre-headless \
    curl \
    jq \
    bash \
    nano \
    ca-certificates \
    && update-ca-certificates

# ---- Java / Kafka env ----
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV KAFKA_VERSION=4.0.0
ENV SCALA_VERSION=2.13
ENV KAFKA_HOME=/opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}
ENV PATH="${JAVA_HOME}/bin:${KAFKA_HOME}/bin:${PATH}"
ARG KAFKA_OAUTH_VERSION=0.17.0
ENV OAUTH_SRC=/opt/strimzi-kafka-oauth-${KAFKA_OAUTH_VERSION}
ENV CLASSPATH=${KAFKA_HOME}/libs/*:$CLASSPATH

# ---- OAuth / Keycloak env ----
ENV REALM_NAME=kafka-authz
ENV SSO_URL=http://sso.local.io:32080
ENV SSO_TOKEN_URL=${SSO_URL}/realms/${REALM_NAME}/protocol/openid-connect/token
ENV KAFKA_OPTS="-Dorg.apache.kafka.sasl.oauthbearer.allowed.urls=${SSO_TOKEN_URL}"

# ENVs needed for testing OAuth in Kafka
ENV BOOTSTRAP_SERVER_ADDR="my-cluster-kafka-bootstrap.kafka-operator.svc:9092"
ENV KAFKA_BRIDGE_URL="http://kafka.local.io:32080"
ENV TEAM_A_CLIENT_ID="team-a-client"
ENV TEAM_A_PROPERTIES_FILE="/opt/team-a-client.properties"
ENV TEAM_B_CLIENT_ID="team-b-client"
ENV TEAM_B_PROPERTIES_FILE="/opt/team-b-client.properties"
ENV PRODUCER_SCRIPT="$KAFKA_HOME/bin/kafka-console-producer.sh"
ENV CONSUMER_SCRIPT="$KAFKA_HOME/bin/kafka-console-consumer.sh"
ENV LIST_TOPICS="$KAFKA_HOME/bin/kafka-topics.sh"
ENV LIST_CONSUMER_GROUPS="$KAFKA_HOME/bin/kafka-consumer-groups.sh"
ENV A_TOPIC="a_topic"
ENV B_TOPIC="b_topic"
ENV X_TOPIC="x_topic"
ENV MY_TOPIC="my_topic"
ENV A_CONSUMER_GROUP="a_consumer_group_1"
ENV B_CONSUMER_GROUP="b_consumer_group_1"
ENV X_CONSUMER_GROUP="x_consumer_group_1"
ENV MY_CONSUMER_GROUP="my_consumer_group_1"

# Script that sets client secrets in .bashrc file
RUN printf '%s\n' \
      '#!/usr/bin/env bash' \
      'read -p "Enter Team A client secret: " TEAM_A_SECRET' \
      'echo' \
      'echo "export TEAM_A_CLIENT_SECRET=\"$TEAM_A_SECRET\"" >> \"$HOME/.bashrc\"' \
      'echo "TEAM_A_CLIENT_SECRET has been set in $HOME/.bashrc file."' \
      'echo $TEAM_A_CLIENT_SECRET' \
      'echo ' \
      > /usr/local/bin/set-team-a-client-secret.sh && \
    chmod +x /usr/local/bin/set-team-a-client-secret.sh && \
    printf '%s\n' \
      '#!/usr/bin/env bash' \
      'read -p "Enter Team B client secret: " TEAM_B_SECRET' \
      'echo' \
      'echo "export TEAM_B_CLIENT_SECRET=\"$TEAM_B_SECRET\"" >> \"$HOME/.bashrc\"' \
      'echo "TEAM_B_CLIENT_SECRET has been set in $HOME/.bashrc file."' \
      'echo $TEAM_B_CLIENT_SECRET' \
      'echo ' \
      > /usr/local/bin/set-team-b-client-secret.sh && \
    chmod +x /usr/local/bin/set-team-b-client-secret.sh && \
    printf '%s\n' \
      'alias set-team-a-client-secret="/usr/local/bin/set-team-a-client-secret.sh"' \
      'alias set-team-b-client-secret="/usr/local/bin/set-team-b-client-secret.sh"' \
      >> "$HOME/.bashrc" && \
     /bin/bash -lc "source \"$HOME/.bashrc\""

# ---- Install Kafka ----
RUN curl -sL "https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" \
    | tar xz -C /opt

# ===============================
# Copy OAuth JARs
# ===============================

# Core OAuth
COPY --from=builder ${OAUTH_SRC}/oauth-common/target/kafka-oauth-common-*.jar ${KAFKA_HOME}/libs/
COPY --from=builder ${OAUTH_SRC}/oauth-client/target/kafka-oauth-client-*.jar ${KAFKA_HOME}/libs/

# Server & authorizer
COPY --from=builder ${OAUTH_SRC}/oauth-server/target/kafka-oauth-server-*.jar ${KAFKA_HOME}/libs/
COPY --from=builder ${OAUTH_SRC}/oauth-server-plain/target/kafka-oauth-server-plain-*.jar ${KAFKA_HOME}/libs/
COPY --from=builder ${OAUTH_SRC}/oauth-keycloak-authorizer/target/kafka-oauth-keycloak-authorizer-*.jar ${KAFKA_HOME}/libs/

# Dependencies (explicit – avoids classpath issues)
COPY --from=builder ${OAUTH_SRC}/oauth-common/target/lib/*.jar ${KAFKA_HOME}/libs/
COPY --from=builder ${OAUTH_SRC}/oauth-server/target/lib/*.jar ${KAFKA_HOME}/libs/

# ---- Utilities ----
COPY test.sh /opt/test.sh
COPY oauth.sh /opt/oauth.sh
COPY jwt.sh /opt/jwt.sh
COPY send-message-via-bridge.sh /opt/send-message-via-bridge.sh
COPY team-a-client.properties /opt/team-a-client.properties
COPY team-b-client.properties /opt/team-b-client.properties
RUN chmod +x /opt/*.sh

WORKDIR /opt
CMD ["sleep", "infinity"]