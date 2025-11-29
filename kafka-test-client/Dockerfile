FROM ubuntu:24.04

# Install curl & jq for debugging tokens
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      curl \
      jq \
      maven \
      nano \
      openjdk-17-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

    # ---- Install Kafka ----
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV KAFKA_VERSION=4.0.0
ENV SCALA_VERSION=2.13
ENV KAFKA_HOME=/opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}
ENV PATH="${JAVA_HOME}/bin:${KAFKA_HOME}/bin:${PATH}"

# Whitelist keycloak Token end-point
ENV KAFKA_OPTS="-Dorg.apache.kafka.sasl.oauthbearer.allowed.urls=http://sso.local.io:32080/realms/platform/protocol/openid-connect/token"

ENV REALM_NAME=platform
ENV SSO_URL=http://sso.local.io:32080/realms/$REALM_NAME/protocol/openid-connect/token

# Download Kafka
RUN curl -sL "https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" \
    | tar xz -C /opt

# ---- Install Strimzi OAuth ----
ENV KAFKA_OAUTH_VERSION=0.17.0
ENV OAUTH_SRC=/opt/strimzi-kafka-oauth-${KAFKA_OAUTH_VERSION}
RUN curl -sL "https://github.com/strimzi/strimzi-kafka-oauth/archive/refs/tags/${KAFKA_OAUTH_VERSION}.tar.gz" \
    | tar xz -C /opt && \
    cd "${OAUTH_SRC}" && \
    mvn -q -DskipTests clean install

# ---- Copy OAuth JARs into Kafka libs ----
RUN cp ${OAUTH_SRC}/oauth-common/target/kafka-oauth-common-*.jar ${KAFKA_HOME}/libs/ && \
    cp ${OAUTH_SRC}/oauth-common/target/lib/nimbus-jose-jwt-*.jar ${KAFKA_HOME}/libs/ && \
    cp ${OAUTH_SRC}/oauth-server/target/kafka-oauth-server-*.jar ${KAFKA_HOME}/libs/ && \
    cp ${OAUTH_SRC}/oauth-server-plain/target/kafka-oauth-server-plain-*.jar ${KAFKA_HOME}/libs/ && \
    cp ${OAUTH_SRC}/oauth-keycloak-authorizer/target/kafka-oauth-keycloak-authorizer-*.jar ${KAFKA_HOME}/libs/ && \
    cp ${OAUTH_SRC}/oauth-client/target/kafka-oauth-client-*.jar ${KAFKA_HOME}/libs/ && \
    cp ${OAUTH_SRC}/oauth-server/target/lib/json-path-*.jar ${KAFKA_HOME}/libs/ && \
    cp ${OAUTH_SRC}/oauth-server/target/lib/json-smart-*.jar ${KAFKA_HOME}/libs/ && \
    cp ${OAUTH_SRC}/oauth-server/target/lib/accessors-smart-*.jar ${KAFKA_HOME}/libs/

COPY client.properties /opt/client.properties
COPY test.sh /opt/test.sh
RUN chmod +x /opt/test.sh

CMD ["sleep", "infinity"]