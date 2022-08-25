#!/bin/bash

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# Re-declare docker_process_sql since this file doesn't seem to have access to it.
# https://github.com/docker-library/postgres/blob/master/docker-entrypoint.sh
#
# Execute sql script, passed via stdin (or -f flag of pqsl)
# usage: docker_process_sql [psql-cli-args]
#    ie: docker_process_sql --dbname=mydb <<<'INSERT ...'
#    ie: docker_process_sql -f my-file.sql
#    ie: docker_process_sql <my-file.sql
docker_process_sql() {
	local query_runner=( psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --no-password --no-psqlrc )
	if [ -n "$POSTGRES_DB" ]; then
		query_runner+=( --dbname "$POSTGRES_DB" )
	fi

	PGHOST= PGHOSTADDR= "${query_runner[@]}" "$@"
}

# Create 'openstreetmap' user and database
# Password and superuser privilege are needed to successfully run test suite
docker_process_sql -c "
    CREATE DATABASE \"$OSM_POSTGRES_DB\";
"

docker_process_sql --dbname="$OSM_POSTGRES_DB" -c "
    -- OSM Prod
    CREATE USER $OSM_POSTGRES_USER SUPERUSER PASSWORD '$OSM_POSTGRES_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE $OSM_POSTGRES_DB TO $OSM_POSTGRES_USER;
"

# Create btree_gist extensions
docker_process_sql --dbname="$OSM_POSTGRES_DB" -c "CREATE EXTENSION btree_gist"

# Create a user for CGIMAP
docker_process_sql --dbname="$CGIMAP_DBNAME" -c "
    -- OSM Prod
    CREATE USER $CGIMAP_USERNAME PASSWORD '$CGIMAP_PASSWORD';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO $CGIMAP_USERNAME;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO $CGIMAP_USERNAME;;
    GRANT TEMPORARY ON DATABASE $CGIMAP_DBNAME TO $CGIMAP_USERNAME;
"

# Build the api schema
wget -O - -o /dev/null "https://raw.github.com/openstreetmap/openstreetmap-website/master/db/structure.sql" | docker_process_sql --dbname="$OSM_POSTGRES_DB"

# Create 'pgsnapshot' user and database
docker_process_sql -c "
    CREATE DATABASE \"$PGS_POSTGRES_DB\";
"

docker_process_sql --dbname="$PGS_POSTGRES_DB" -c "
    -- Enable PostGIS (as of 3.0 contains just geometry/geography)
    CREATE EXTENSION postgis;
    CREATE EXTENSION hstore;
"

docker_process_sql --dbname="$PGS_POSTGRES_DB" -c "
    -- pg_snapshot Prod
    CREATE USER $PGS_POSTGRES_USER SUPERUSER PASSWORD '$PGS_POSTGRES_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE $PGS_POSTGRES_DB TO $PGS_POSTGRES_USER;
"

# Create a user for PG_TILESERV and PG_FEATURESERV
docker_process_sql --dbname="$PGS_POSTGRES_DB" -c "
    CREATE USER $SERV_USERNAME PASSWORD '$SERV_PASSWORD';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO $SERV_USERNAME;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO $SERV_USERNAME;
"

## Tasking Manager
# Create 'tm' user and database
docker_process_sql -c "
    CREATE DATABASE \"$TM_POSTGRES_DB\";
"

docker_process_sql --dbname="$TM_POSTGRES_DB" -c "
    -- Enable PostGIS (as of 3.0 contains just geometry/geography)
    CREATE EXTENSION postgis;
"

docker_process_sql --dbname="$TM_POSTGRES_DB" -c "
    -- pg_snapshot Prod
    CREATE USER $TM_POSTGRES_USER SUPERUSER PASSWORD '$TM_POSTGRES_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE $TM_POSTGRES_DB TO $TM_POSTGRES_USER;
"
