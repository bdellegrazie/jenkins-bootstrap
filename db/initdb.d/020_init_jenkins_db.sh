#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER jenkins with password '$(</run/secrets/db_jenkins)';
    CREATE DATABASE jenkins;
    GRANT ALL PRIVILEGES ON DATABASE jenkins TO jenkins;
    CREATE USER grafanaro with password '$(</run/secrets/db_grafanaro)';
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "jenkins" <<-EOSQL
    CREATE EXTENSION pg_stat_statements;
    GRANT USAGE ON SCHEMA public TO grafanaro;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafanaro;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO grafanaro;
EOSQL
