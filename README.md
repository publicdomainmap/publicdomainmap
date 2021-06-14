# publicdomainmap devops
The docker-compose orchestration files including the nginx server and the database

## Includes
This is the "scaffolding" to run the opendata.land website. It includes:
* nginx: includes a conf.d file as well as links for iD and the website
* certbot: Uses let's encrypt to provide https
* postgis: Version 13. Includes scripts for initial database deployment
* editor: Forked iD editor (https://github.com/publicdomainmap/editor)
* pgadmin: Provides an interface to easily access the database through a GUI
* api: Custom API to support OSM Oauth as well as custom extentions to the OSM platform (https://github.com/publicdomainmap/api)
* render: Tools to run Osmosis, Osm2pgsql, and Gdal. (https://github.com/publicdomainmap/render)
* cgimap: Provides all Read Only access to the OSM database. (https://github.com/publicdomainmap/openstreetmap-cgimap)
* tm_backend: Backend to the Public Domain OSM Tasking Manager. (https://github.com/publicdomainmap/tasking-manager)
* tm_migration: Keeps the tasking Manager Database up to date. (https://github.com/publicdomainmap/tasking-manager)
* tm_frontend: Frontend to the Public Domain OSM Tasking Manager. (https://github.com/publicdomainmap/tasking-manager)
* pg_tileserv: Serves the rendered data out as vector tiles (TODO: Put this behind a varnish cache)
* pg_featureserv: Serves the rendered data as an OGR Feature Service

## Getting Started
This "all-in-one" approach is great for development and testing. If this is going to be deployed into production, you may want to split the services onto different servers.

1. Clone this repo and its submodules
`git clone --recurse-submodules -j8 https://github.com/publicdomainmap/devops.git`

2. Copy the settings File:
`cp ./compose/example.settings.env ./compose/settings.env`

3. Do the usual docker-compose tasks:
```
docker-compose build
docker-compose up
```

4. Navigate your browser to `http://localhost`
5. Other useful links
  * `http://localhost/id`
  * `http://localhost/tm`

6. Some services are not served through nginx by default, you can access them by on their own ports
  * pgadmin localhost:3000
  * pg_tileserv localhost:7000
  * pg_featureserv localhost:9000

### Notes:
If you use Osmosis to import data to seed the database, make sure to update the sequences:
  * changesets_id_seq
  * current_nodes_id_seq
  * current_ways_id_seq
  * current_relations_id_seq

 This can be done with the following commands:
  ```
  BEGIN;
    -- protect against concurrent inserts while you update the counter
    LOCK TABLE your_table IN EXCLUSIVE MODE;
    -- Update the sequence
    SELECT setval('changesets_id_seq', COALESCE((SELECT MAX(id) + 1 FROM changesets), 1), false);
    SELECT setval('current_nodes_id_seq', COALESCE((SELECT MAX(node_id) + 1 FROM nodes), 1), false);
    SELECT setval('current_ways_id_seq', COALESCE((SELECT MAX(way_id) + 1 FROM ways), 1), false);
    SELECT setval('current_relations_id_seq', COALESCE((SELECT MAX(relation_id) + 1 FROM relations), 1), false);
  COMMIT;
```
