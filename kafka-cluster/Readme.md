## Install and manage Kafka clusters via Strimzi Kafka Operator

> Make sure Kafka Operator CRDs and controller is already installed. Check [kafka-operator](https://github.com/sahil-sharma/k8s-stuff/tree/main/kafka-operator) folder for installation.

### Cluster with Oauth support

If you want to install kafka-cluster with Oauth support with Keycloak then install kafka cluster from cluster-with-oauth folder

> Make sure Keycloak is configure for Kafka realm. Check [keycloak-kafka-terraform](https://github.com/sahil-sharma/k8s-stuff/tree/main/keycloak-kafka-terraform) folder for installation.

```bash
cd cluster-with-oauth

# Install Kafka Cluster
kubectl kustomize cluster --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# Install Kafka Bridge
kubectl kustomize bridge --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# Install Kafka Connect
kubectl kustomize connect --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# Install Kafka kafbat UI
kubectl kustomize kafka-ui --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

### Cluster without Oauth support

```bash
cd cluster-with-oauth

# Install Kafka Cluster
kubectl kustomize cluster --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# Install Kafka Bridge
kubectl kustomize bridge --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# Install Kafka Connect
kubectl kustomize connect --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# Install Kafka kafbat UI
kubectl kustomize kafka-ui --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

### Kafka Cruise-Control UI

Configure cruise-control in your cluster values file like [this](https://github.com/sahil-sharma/k8s-stuff/blob/main/kafka-cluster/cluster-with-oauth/cluster/cluster.yaml#L158-L169).

```bash
# Install Kafka Cruise-Control for managing kafka cluster
kubectl kustomize cruise-control-ui --load-restrictor=LoadRestrictionsNone | kubectl apply -f -
```

### Patt-1: Kafka Connect set-up

When installing `kafka-connect` we need to follow few steps:

```bash
# 1. Install Kafka Connect cluster framework via Kustomize
kubectl kustomize cluster-without-oauth/connect --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

# 2. Deploy your application's Postgres database instance
kubectl apply -f k8s-stuff/app-pg.yaml

# 3. Spin up an interactive Ubuntu triage container pod to seed data
kubectl run -i --rm --restart=Never --tty ubuntu-test-pod --image=ubuntu:24.04 -n default -- bash'

# --- INSIDE THE UBUNTU POD CONTAINER ---
apt update && apt install curl postgresql-client -y

# Connect to the Postgres application node (Enter password when prompted)
psql -h app-db-rw.app-pg -d app_db -U app_admin -W

# 4. Create your application tables and insert starting records
CREATE TABLE customers (id SERIAL PRIMARY KEY, name TEXT, email TEXT);

INSERT INTO customers (name, email) VALUES
('Alice', 'alice@vienna.at'),
('Bob', 'bob@linz.at');

# 5. CRITICAL STEP: Alter the table structure to use the entire row for identity
# This guarantees Debezium CDC can capture UPDATE and DELETE transaction logs!
ALTER TABLE public.customers REPLICA IDENTITY FULL;

SELECT * FROM customers;
\q
exit
```

### Part-2: Spin Up CDC (Source Connector)

```bash
# 1. Start tracking database transaction mutations via Debezium
kubectl apply -f cluster-without-oauth/connect/source-connector.yaml

# 2. Verify the connector CRD status has successfully initialized
kubectl get kctr
```

### Execute an update query inside your database
```bash
UPDATE public.customers SET email = 'bob@austria.at' WHERE id = 2;
```

You can see the data being shown in respective `kafta-topic`. Debezium instantly caught that row update straight from the Postgres WAL log and pushed it as a structured message to our Kafka topic automatically.

### Part 3: Deploy Sink Connector & Target Table

Now we switch perspectives to the consumer side, creating an independent `orders` system.

```bash
# 1. Initialize your targeted JDBC Sink configuration
kubectl apply -f cluster-without-oauth/connect/sink-connector.yaml

kubectl get kctr

# 2. Fire up your terminal to declare the target storage schema destination
kubectl run -i --rm --restart=Never --tty ubuntu-test-pod --image=ubuntu:24.04 -n default -- bash

# --- INSIDE THE UBUNTU POD CONTAINER ---
apt update && apt install curl postgresql-client -y
psql -h app-db-rw.app-pg -d app_db -U app_admin -W

# Create the target receiving structure
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    item TEXT,
    quantity INT,
    price NUMERIC
);

\d;
\q
exit
```

### Part 4: Testing Payload Safety Net

#### Scenario A: The Valid Payload (Structured Envelope)
Drop this exact JSON payload directly into your designated sink topic using your cluster's Kafka-UI utility.

```bash
{
  "schema": {
    "type": "struct",
    "optional": false,
    "fields": [
      { "type": "int32", "optional": false, "field": "id" },
      { "type": "string", "optional": true, "field": "item" },
      { "type": "int32", "optional": true, "field": "quantity" },
      { "type": "double", "optional": true, "field": "price" }
    ]
  },
  "payload": {
    "id": 1,
    "item": "Demo Stuff-1",
    "quantity": 25,
    "price": 45.76
  }
}
```

Verify that the valid event safely crosses the pipeline and drops into the database:

### Run verification query

```bash
kubectl run -i --rm --restart=Never --tty ubuntu-test-pod --image=ubuntu:24.04 -n default -- \
psql -h app-db-rw.app-pg -d app_db -U app_admin -W -c "SELECT * FROM orders;"
```

#### Scenario B: Plain Schema-less JSON

Now, simulate a misconfigured publisher client bypassing your serialization guidelines by plain, raw JSON over the wire:

```bash
{
  "id": 2,
  "item": "Demo Stuff-2",
  "quantity": 26,
  "price": 45.77
}
```

Ordinarily, because our global cluster profile mandates `schemas.enable=true`, this schema-less message would trigger a fatal `DataException` and completely crash our connector task thread, halting all order traffic. But look at our console logs and Grafana dashboard: our task stays `Running`, the message safely bypassed the bottleneck into our Dead Letter Queue (`x_topic-dlq`), and our business continuity remains untouched!
