## Install Ingress Nginx

> We are exposing TCP ports (like PGSQL) over the Ingress so that our applications can easily reach out to their DBs over hostname

```bash
# Add Keycloak Helm Repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 

# Update Helm Repo
helm repo update

# Install Ingress Nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
-f values.yaml \
--set tcp.5432=keycloak-pg/keycloak-db-rw:5432 \    # keycloak-namespace:keycloak-db:keycloak-db-port
--set tcp.3200=tempo/tempo:3200 \                   # temp-namespace:tempo-service:tempo-port 
--set tcp.6379=redis/redis-master:6379 \            # redis-namespace:redis-service:redis-port
--set tcp.5433=backstage-pg/backstage-db-rw:5432 \  # backstage-namespace:backstage-db:backstage-db-port
--set tcp.5434=grafana-pg/grafana-db-rw:5432 \      # redis-namespace:grafana-db:grafana-db-port
--namespace ingress-nginx \
--create-namespace

# Delete Ingress Nginx
helm uninstall ingress-nginx -n ingress-nginx
```