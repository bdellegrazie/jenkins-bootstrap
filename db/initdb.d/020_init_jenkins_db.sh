#!/bin/bash
set -e

JENKINS_PASS="$(</run/secrets/db_jenkins)"
GRAFANARO_PASS="$(</run/secrets/db_grafanaro)"

echo "--- Creating Jenkins DB..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER jenkins with password '${JENKINS_PASS}';
    CREATE DATABASE jenkins;
    GRANT ALL PRIVILEGES ON DATABASE jenkins TO jenkins;

    CREATE USER grafanaro with password '${GRAFANARO_PASS}';
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "jenkins" <<-EOSQL
    GRANT ALL ON SCHEMA PUBLIC TO jenkins;
    GRANT USAGE ON SCHEMA PUBLIC TO grafanaro;

    CREATE EXTENSION pg_stat_statements;
    GRANT pg_read_all_data TO grafanaro;
EOSQL
echo "--- Done"
