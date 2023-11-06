#!/bin/bash
set -e

echo "--- Creating Sonar DB..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER sonar with password '$(</run/secrets/sonar_jdbc_password)';
    CREATE DATABASE sonarqube;
    GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "sonarqube" <<-EOSQL
    GRANT ALL PRIVILEGES ON SCHEMA PUBLIC TO sonar;
    CREATE EXTENSION pg_stat_statements;
EOSQL
echo "--- Done!"
