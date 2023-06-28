#!/bin/bash
set -e

declare -r SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

DC_ADMIN_USER="dcadmin"
DC_ADMIN_PASS="$(</run/secrets/db_dcadmin)"
DC_RO_USER="dcuser"
DC_RO_PASS="$(</run/secrets/db_dcuser)"

echo "--- Creating DependencyCheck DB ..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE dependencycheck;
    CREATE USER ${DC_ADMIN_USER} WITH PASSWORD '${DC_ADMIN_PASS}';
    CREATE USER ${DC_RO_USER} WITH PASSWORD '${DC_RO_PASS}';
    GRANT ALL PRIVILEGES ON DATABASE dependencycheck TO ${DC_ADMIN_USER};
EOSQL

PGPASSWORD="${DC_ADMIN_PASS}" psql -v ON_ERROR_STOP=1 --username "$DC_ADMIN_USER" --no-password --dbname "dependencycheck" < "${SCRIPT_DIR}/dc-5.4.sql.t"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "dependencycheck" <<-EOSQL
    CREATE EXTENSION pg_stat_statements;
    GRANT pg_read_all_data to ${DC_RO_USER};
EOSQL

echo "--- Done!"
