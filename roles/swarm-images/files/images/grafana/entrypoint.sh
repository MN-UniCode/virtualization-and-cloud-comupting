#!/bin/sh
set -e # fail on error
[ "$DEBUG" = "true" ] && set -x  # Debug mode if DEBUG=true

#
# TASK 35a. Perform a database health check
#

# Wait until the database port is open (basic check)
until nc -z "$DB_HOST" "$DB_PORT"; do # waiting for netcat output on port 5432
    echo "Waiting for database port $DB_PORT..."
    sleep 2
done

# Execute a test query to ensure the database is actually responding
until PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2
done

# Use "pg_isready" for an additional check
until PGPASSWORD="$DB_PASSWORD" pg_isready -h "$DB_HOST" -U "$DB_USER"; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2
done

#
# TASK 35b. Add the certificate from the system certificates
#

# Apparently /usr/local/share/ca-certificates is involved
while [ ! -f /usr/local/share/ca-certificates/vcc.internal.crt ] && [ ! -f /usr/local/share/ca-certificates/ca.crt ]; do
    echo "Waiting for CA certificates to be mounted..."
    sleep 2
done
# Update the CA certificates inside the container
echo "CA certificates found. Updating..."
update-ca-certificates

#
# TASK 35c. Wait for dex to be alive
#

# Primo controllo: verifica se la porta è aperta
until nc -z -w 2 "$(echo "$AUTH_SERVER" | awk -F/ '{print $3}')" "$AUTH_PORT"; do
    echo "Authentication server not responding on port $AUTH_PORT... retrying in 2s"
    sleep 2
done

# Secondo controllo: verifica la risposta HTTP (migliore)
until curl -ks --max-time 5 --fail "$AUTH_SERVER" > /dev/null 2>&1; do
    echo "Authentication server not ready... retrying in 2s"
    sleep 2
done

echo "Authentication server is UP!"

# LOKI
mkdir -p /etc/grafana/provisioning/datasources
cat <<EOF > /etc/grafana/provisioning/datasources/ds.yaml
apiVersion: 1
datasources:
  - name: Loki
    type: loki
    access: proxy 
    orgId: 1
    url: http://loki:3100
    basicAuth: false
    isDefault: true
    version: 1
    editable: false
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prom.vcc.internal:9090
    version: 1
    editable: false
EOF

# TASK 36. Configure Grafana URL as https://mon.vcc.internal
export GF_SERVER_ROOT_URL="https://mon.vcc.internal"

# TASK 37. Configure Grafana to use the database you created
export GF_DATABASE_TYPE="postgres"
export GF_DATABASE_HOST="$DB_HOST:$DB_PORT"
export GF_DATABASE_USER="$DB_USER"
export GF_DATABASE_PASSWORD="$DB_PASSWORD"
export GF_DATABASE_NAME="$DB_NAME"

# TASK 38. Configure Grafana admin credentials
export GF_SECURITY_ADMIN_USER="admin"
export GF_SECURITY_ADMIN_PASSWORD="$ADMIN_PASSWORD"

# TASK 39. Enable Grafana metrics
export GF_METRICS_ENABLED=true

#
# TASK 35d. Set environment variables (using "export NAME=value") to use https://auth.vcc.internal as authentication source with the "grafana" OAuth client
#
export GF_AUTH_GENERIC_OAUTH_ENABLED=true
export GF_AUTH_GENERIC_OAUTH_AUTO_LOGIN=true # redirect to Dex if you are not already authenticated
export GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP=true
export GF_AUTH_GENERIC_OAUTH_NAME="Dex"
export GF_AUTH_GENERIC_OAUTH_CLIENT_ID="grafana"
export GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET="$OAUTH2_SECRET"
export GF_AUTH_GENERIC_OAUTH_SCOPES="openid email profile groups offline_access"
export GF_AUTH_GENERIC_OAUTH_AUTH_URL="https://auth.vcc.internal/auth"
export GF_AUTH_GENERIC_OAUTH_TOKEN_URL="https://auth.vcc.internal/token"
export GF_AUTH_GENERIC_OAUTH_API_URL="https://auth.vcc.internal/userinfo"
export GF_AUTH_GENERIC_OAUTH_USE_REFRESH_TOKEN=true
export GF_AUTH_GENERIC_OAUTH_USE_ID_TOKEN=true

# TASK 40. Enable Grafana provisioning
export GF_PATHS_PROVISIONING=/etc/grafana/provisioning

export GF_AUTH_ANONYMOUS_ENABLED=true
export GF_AUTH_ANONYMOUS_ORG_ROLE=Admin

# Execute the original entrypoint
exec /run.sh "$@"