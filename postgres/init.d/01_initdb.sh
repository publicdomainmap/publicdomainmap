#!/bin/sh

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# Create 'openstreetmap' user and database
# Password and superuser privilege are needed to successfully run test suite
"${psql[@]}" -c "
    CREATE DATABASE \"$OSM_POSTGRES_DB\";
"

"${psql[@]}" --dbname="$OSM_POSTGRES_DB" -c "
    -- OSM Prod
    CREATE USER $OSM_POSTGRES_USER SUPERUSER PASSWORD '$OSM_POSTGRES_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE $OSM_POSTGRES_DB TO $OSM_POSTGRES_USER;
"

# Create btree_gist extensions
"${psql[@]}" --dbname="$OSM_POSTGRES_DB" -c "CREATE EXTENSION btree_gist"

# Create a user for CGIMAP
"${psql[@]}" --dbname="$CGIMAP_DBNAME" -c "
    -- OSM Prod
    CREATE USER $CGIMAP_USERNAME PASSWORD '$CGIMAP_PASSWORD';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO $CGIMAP_USERNAME;
    GRANT TEMPORARY ON DATABASE $CGIMAP_DBNAME TO $CGIMAP_USERNAME;
"

# Build the api schema
wget -O - -o /dev/null "https://raw.github.com/openstreetmap/openstreetmap-website/master/db/structure.sql" | "${psql[@]}" --dbname="$OSM_POSTGRES_DB"

# Create 'pgsnapshot' user and database
"${psql[@]}" -c "
    CREATE DATABASE \"$PGS_POSTGRES_DB\";
"

"${psql[@]}" --dbname="$PGS_POSTGRES_DB" -c "
    -- Enable PostGIS (as of 3.0 contains just geometry/geography)
    CREATE EXTENSION postgis;
    CREATE EXTENSION hstore;
"

"${psql[@]}" --dbname="$PGS_POSTGRES_DB" -c "
    -- pg_snapshot Prod
    CREATE USER $PGS_POSTGRES_USER SUPERUSER PASSWORD '$PGS_POSTGRES_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE $PGS_POSTGRES_DB TO $PGS_POSTGRES_USER;
"

# Create a user for PG_TILESERV and PG_FEATURESERV
"${psql[@]}" --dbname="$PGS_POSTGRES_DB" -c "
    CREATE USER $SERV_USERNAME PASSWORD '$SERV_PASSWORD';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO $SERV_USERNAME;
"

## Tasking Manager
# Create 'tm' user and database
"${psql[@]}" -c "
    CREATE DATABASE \"$TM_POSTGRES_DB\";
"

"${psql[@]}" --dbname="$TM_POSTGRES_DB" -c "
    -- Enable PostGIS (as of 3.0 contains just geometry/geography)
    CREATE EXTENSION postgis;
"

"${psql[@]}" --dbname="$TM_POSTGRES_DB" -c "
    -- pg_snapshot Prod
    CREATE USER $TM_POSTGRES_USER SUPERUSER PASSWORD '$TM_POSTGRES_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE $TM_POSTGRES_DB TO $TM_POSTGRES_USER;
"
