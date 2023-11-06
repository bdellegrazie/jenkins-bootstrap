#!/bin/bash
set -e

echo "--- Creating Dependency Track DB..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER dtrack with password '$(</run/secrets/db_dtrack)';
    CREATE DATABASE dtrack;
    GRANT ALL PRIVILEGES ON DATABASE dtrack TO dtrack;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "dtrack" <<-EOSQL
    GRANT ALL PRIVILEGES ON SCHEMA PUBLIC TO dtrack;

    CREATE EXTENSION pg_stat_statements;
EOSQL
echo "--- Done"
