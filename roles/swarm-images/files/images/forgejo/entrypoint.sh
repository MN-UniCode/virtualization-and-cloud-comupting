#!/bin/sh
set -e # Fail on error
[ "$DEBUG" = "true" ] && set -x  # Debug mode if DEBUG=true

sudo chown -R 1000:1000 /data/gitea # Set correct ownership for the Forgejo data directory
sudo chmod -R 755 /data/gitea # Set appropriate permissions

#
# TASK 30a. Complete the contents of the forgejo_cli function
#

# This helper allows to run stuff as the forgejo user
forgejo_cli() { 
    sudo -u git forgejo --config /data/gitea/conf/app.ini "$@"; 
    }

#
# TASK 30b. Complete the database health check
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
# TASK 30c. Run the database migration command
#

# Ensures the database schema is up to date before starting Forgejo
forgejo_cli migrate

#
# TASK 30d. Create the administrator user
#

# Check if the admin user already exists
if ! forgejo_cli admin user list | grep -q "$ADMIN_USER"; then
    echo "Creating admin user..."
    forgejo_cli admin user create \
        --username "$ADMIN_USER" \
        --email "$ADMIN_EMAIL" \
        --password "$ADMIN_PASS" \
        --admin
else
    echo "Admin user already exists, skipping creation."
fi

#
# TASK 30f. Add the certificate from before to the system certificates
#

# Wait until the certificate files are present
while [ ! -f /usr/local/share/ca-certificates/vcc.internal.crt ] && [ ! -f /usr/local/share/ca-certificates/ca.crt ]; do
    echo "Waiting for CA certificates to be mounted..."
    sleep 2
done
# Update the CA certificates inside the container
echo "CA certificates found. Updating..."
update-ca-certificates

#
# TASK 30g. Wait for dex to be alive
#

# Ensure the authentication server's port is open (bad)
until nc -z -w 2 "$(echo "$AUTH_SERVER" | awk -F/ '{print $3}')" "$AUTH_PORT"; do
    echo "Authentication server not responding on port $AUTH_PORT... retrying in 2s"
    sleep 2
done

# Ensure the authentication server responds to HTTP requests (better)
until curl -ks --max-time 5 --fail "$AUTH_SERVER" > /dev/null 2>&1; do
    echo "Authentication server not ready... retrying in 2s"
    sleep 2
done

#
# TASK 30h. Create the openid client to use https://auth.vcc.internal as authentication source with the "forgejo" OAuth client
#

# Check if Dex OAuth authentication is already configured
if ! sudo -u git forgejo admin auth list | grep -q "Dex"; then
    echo "Adding OAuth authentication..."
    sudo -u git forgejo admin auth add-oauth \
        --name "Dex" \
        --provider openidConnect \
        --auto-discover-url "https://auth.vcc.internal/.well-known/openid-configuration" \
        --key "forgejo" \
        --secret "$OAUTH2_SECRET" \
        --scopes "openid email profile groups offline_access" \
        --group-claim-name "groups"
else
    echo "OAuth authentication already configured."
fi

# Execute the original entrypoint
exec /bin/s6-svscan /etc/s6 "$@"