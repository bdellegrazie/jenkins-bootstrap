#!/bin/bash
set -e

echo "--- Creating Monitor User ..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER monitor WITH password '$(</run/secrets/db_monitor)';
    GRANT pg_monitor TO monitor;
EOSQL
echo "--- Done!"
