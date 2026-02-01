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

ENV GO_VERSION=1.25.6

# # ---- Runtime dependencies ----
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     openjdk-17-jdk \
#     curl \
#     jq \
#     nano \
#     ca-certificates \
#     build-essential \
#     golang-go \
#  && rm -rf /var/lib/apt/lists/*

RUN apk add --no-cache \
    gcc \
    musl-dev \
    # librdkafka for confluent-kafka-go
    librdkafka-dev \
    librdkafka \
    # SSL support (required by librdkafka)
    openssl-dev \
    ca-certificates \
    openjdk17-jre-headless \
    curl \
    git \
    bash \
    build-base \
    nano \
    jq \
  && update-ca-certificates \
  && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tgz \
  && rm -rf /usr/local/go \
  && tar -C /usr/local -xzf /tmp/go.tgz \
  && rm /tmp/go.tgz

# ---- Java / Kafka env ----
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV KAFKA_VERSION=4.0.0
ENV SCALA_VERSION=2.13
ENV KAFKA_HOME=/opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}
ENV PATH="${JAVA_HOME}/bin:${KAFKA_HOME}/bin:${PATH}"
ENV KAFKA_PLUGIN_PATH=/opt/kafka/plugins
ARG KAFKA_OAUTH_VERSION=0.17.0
ENV OAUTH_SRC=/opt/strimzi-kafka-oauth-${KAFKA_OAUTH_VERSION}
ENV CLASSPATH=${KAFKA_HOME}/libs/*:$CLASSPATH

# Go Env
ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV PATH="${PATH}:${GOROOT}/bin:${GOPATH}/bin"
ENV CGO_ENABLED=1 GOOS=linux GOARCH=amd64
ENV PKG_CONFIG_PATH=/usr/lib/pkgconfig

# ---- OAuth / Keycloak env ----
ENV REALM_NAME=kafka-authz
ENV SSO_URL=http://sso.local.io:32080
ENV SSO_TOKEN_URL=${SSO_URL}/realms/${REALM_NAME}/protocol/openid-connect/token
ENV KAFKA_OPTS="-Dorg.apache.kafka.sasl.oauthbearer.allowed.urls=${SSO_TOKEN_URL}"

# ENVs needed for testing OAuth in Kafka
ENV BOOTSTRAP_SERVER_ADDR="my-cluster-kafka-bootstrap.kafka-cluster.svc:9094"
ENV KAFKA_BRIDGE_URL="http://kafka.local.io:32080"
ENV TEAM_A_CLIENT_ID="team-a-client"
ENV TEAM_B_CLIENT_ID="team-b-client"
ENV TEAM_A_PROPERTIES_FILE="/opt/a-team-client.properties"
ENV TEAM_B_PROPERTIES_FILE="/opt/b-team-client.properties"
ENV ALICE_PROPERTIES="/opt/alice.properties"
ENV BOB_PROPERTIES="/opt/bob.properties"
ENV ALICE_USERNAME="alice"
ENV BOB_USERNAME="bob"
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

RUN mkdir -p ${KAFKA_PLUGIN_PATH} \
    && cp ${KAFKA_HOME}/libs/*.jar ${KAFKA_PLUGIN_PATH}/

# ---- Utilities ----
COPY *.sh /opt
COPY *.properties /opt/
COPY input-text-file.txt /opt/
RUN chmod +x /opt/*.sh

WORKDIR /opt
CMD ["sleep", "infinity"]