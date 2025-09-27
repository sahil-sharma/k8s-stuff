#!/bin/bash -e

export KEYCLOAK_HOME=/root/keycloak-26.3.3
export PATH=$PATH:$KEYCLOAK_HOME/bin
cd /root

apt update
apt install -y wget uuid-runtime unzip nano jq openjdk-21-jdk -y

wget https://github.com/keycloak/keycloak/releases/download/26.3.3/keycloak-26.3.3.zip
wget https://github.com/keycloak/keycloak-benchmark/releases/download/26.0-SNAPSHOT/keycloak-benchmark-26.0-SNAPSHOT.zip

unzip keycloak-26.3.3.zip
unzip keycloak-benchmark-26.0-SNAPSHOT.zip
rm -rf keycloak-26.3.3.zip keycloak-benchmark-26.0-SNAPSHOT.zip

$KEYCLOAK_HOME/bin/kcadm.sh config credentials --server http://sso.local.io:32080 --realm master --user admin --password admin123

cd /root/keycloak-benchmark-26.0-SNAPSHOT/bin
./initialize-benchmark-entities.sh -r test-realm -c gatling -u user-0
./kcb.sh --scenario=keycloak.scenario.authentication.AuthorizationCode --server-url=http://sso.local.io:32080 --realm-name=test-realm