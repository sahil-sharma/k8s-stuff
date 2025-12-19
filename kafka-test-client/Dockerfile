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

# ---- OAuth / Keycloak env ----
ENV REALM_NAME=platform
ENV SSO_URL=http://sso.local.io:32080
ENV SSO_TOKEN_URL=${SSO_URL}/realms/${REALM_NAME}/protocol/openid-connect/token
ENV KAFKA_OPTS="-Dorg.apache.kafka.sasl.oauthbearer.allowed.urls=${SSO_TOKEN_URL}"

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
RUN chmod +x /opt/test.sh

WORKDIR /opt
CMD ["sleep", "infinity"]
