# Kafka Test Client Image

This image can be used to produce or consume Kafka messages in your kafka cluster.

Image has Kafka OAuth Module [strimzi-kafka-oauth](https://github.com/strimzi/strimzi-kafka-oauth/tree/main)

Please change below in `client.properties` file located in `/opt` directory:

- Kafka cluster address
- OAuth Token end-point
- Kafka ClientID
- Kafka ClientSecret

## How to Produce/Consume messages

Please use `test.sh` script located in `/opt` directory.

Do change below in the script:

- Kafka Bootstrap address
- Kafka topic name