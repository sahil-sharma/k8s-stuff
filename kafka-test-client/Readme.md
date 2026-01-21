# Kafka Test Client Image

This image can be used to produce or consume Kafka messages in your kafka cluster.

Image has Kafka OAuth Module [strimzi-kafka-oauth](https://github.com/strimzi/strimzi-kafka-oauth/tree/main)

If you're trying to build image from Dockerfile then please change below environment names in Dockerfile:

```bash
- REALM_NAME
- SSO_TOKEN_URL
```

Please change below in `client.properties` file located in `/opt` directory:

```bash
- Kafka cluster address
- OAuth Token end-point
- Kafka ClientID
- Kafka ClientSecret
```

## How to Produce/Consume messages

Please use `test.sh` script located in `/opt` directory. Do change below in the script:

```bash
- Kafka Bootstrap address
- Kafka topic name
```

## How to run a Kafka Client Test Pod inside your cluster

```bash
# Alpine image
kubectl -n default run -i --rm \
    --restart=Never \
    --tty kafka-client-test-pod \
    --image=sahilwork/test-client:v1 -- bash

# Exec into Test Client Pod
k -n default exec -it kafka-client-test-pod -- bash

# Set Team-A and Team-B Client Secrets as in their properties files:
Team-A: /opt/a-team-client.properties
Team-B: /opt/b-team-client.properties

# Run script kafka-auth-test.sh to test Authz in Kafka
# Do not forget to set needed Env inside script
bash /opt/kafka-auth-test.sh

# Run script bridge-test.sh to test kafka-bridge to produce/consume messages over HTTP in Kafka
# Do not forget to set needed Env inside script
bash /opt/bridge-test.sh
```
