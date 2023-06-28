#!/bin/bash
set -e

echo "--- Creating Jenkins DB..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER jenkins with password '$(</run/secrets/db_jenkins)';
    CREATE DATABASE jenkins;
    GRANT ALL PRIVILEGES ON DATABASE jenkins TO jenkins;
    CREATE USER grafanaro with password '$(</run/secrets/db_grafanaro)';
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "jenkins" <<-EOSQL
    CREATE EXTENSION pg_stat_statements;
    GRANT pg_read_all_data TO grafanaro;
EOSQL
echo "--- Done"
