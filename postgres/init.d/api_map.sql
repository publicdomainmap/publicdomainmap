-- FUNCTION: public.api_map(double precision, double precision, double precision, double precision)

-- DROP FUNCTION public.api_map(double precision, double precision, double precision, double precision);

\c openstreetmap
CREATE OR REPLACE FUNCTION public.api_map(
	min_lon double precision,
	min_lat double precision,
	max_lon double precision,
	max_lat double precision)
    RETURNS SETOF api_current_nodes 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
WITH nodes AS (
SELECT distinct id FROM current_nodes where
  longitude >= $1 * 10000000 AND
  latitude >= $2 * 10000000 AND
  longitude < $3 * 10000000 AND
  latitude < $4 * 10000000),
ways AS (
	SELECT distinct way_id AS id FROM current_way_nodes JOIN nodes ON
 current_way_nodes.node_id = nodes.id),
 relation_nodes AS (
	SELECT distinct relation_id AS id FROM current_relation_members JOIN nodes ON
 current_relation_members.member_id = nodes.id AND current_relation_members.member_type = 'Node'),
 relation_ways AS (
	SELECT distinct relation_id AS id FROM current_relation_members JOIN ways ON
 current_relation_members.member_id = ways.id AND current_relation_members.member_type = 'Way'
 ),
 nodes_in_ways AS (
 select distinct node_id AS id
 FROM current_way_nodes
 JOIN ways ON current_way_nodes.way_id = ways.id order by node_id),
 all_nodes AS
 (SELECT id from nodes UNION select id from nodes_in_ways),
 /*SELECT all_nodes.id, 'n' as type FROM all_nodes UNION ALL
  SELECT ways.id, 'w'  as type FROM ways UNION ALL
  SELECT relation_nodes.id, 'r'  as type FROM relation_nodes UNION ALL
  SELECT relation_ways.id, 'r'  as type FROM relation_ways
 */
 
  current_node_tags_agg AS (
         SELECT current_node_tags.node_id,
            jsonb_object_agg(current_node_tags.k, current_node_tags.v) AS tags
           FROM current_node_tags
	 
          GROUP BY current_node_tags.node_id
        ),
 api_current_nodes_w AS (SELECT 'node'::text AS type,
    current_nodes.id,
    current_nodes.visible,
    current_nodes.latitude::double precision / 10000000::double precision AS lat,
    current_nodes.longitude::double precision / 10000000::double precision AS lon,
    to_char(current_nodes."timestamp", 'IYYY-MM-DD"T"HH24:MI:SS"Z"'::text) AS "timestamp",
    current_nodes.version,
    current_nodes.changeset_id AS changeset,
    users.display_name AS "user",
    users.id AS uid,
    NULL::bigint[] AS nodes,
    current_node_tags_agg.tags,
    NULL::jsonb AS members,
    NULL::text AS created_at,
    NULL::boolean AS open,
    NULL::integer AS comments_count,
    NULL::text AS closed_at,
    NULL::integer AS min_lat,
    NULL::integer AS min_lon,
    NULL::integer AS max_lat,
    NULL::integer AS max_lon
   FROM current_nodes
     JOIN changesets ON changesets.id = current_nodes.changeset_id
     JOIN users ON changesets.user_id = users.id
     LEFT JOIN current_node_tags_agg ON current_node_tags_agg.node_id = current_nodes.id),
current_way_tags_agg AS (
         SELECT current_way_tags.way_id,
            jsonb_object_agg(current_way_tags.k, current_way_tags.v) AS tags
           FROM current_way_tags
          GROUP BY current_way_tags.way_id
        ), current_way_nodes_agg AS (
         SELECT current_way_nodes.way_id,
            array_agg(current_way_nodes.node_id ORDER BY current_way_nodes.sequence_id) AS nodes
           FROM current_way_nodes
          GROUP BY current_way_nodes.way_id
        ),
 api_current_ways_w AS (SELECT 'way'::text AS type,
    current_ways.id,
    current_ways.visible,
    NULL::double precision AS lat,
    NULL::double precision AS lon,
    to_char(current_ways."timestamp", 'IYYY-MM-DD"T"HH24:MI:SS"Z"'::text) AS "timestamp",
    current_ways.version,
    current_ways.changeset_id AS changeset,
    users.display_name AS "user",
    users.id AS uid,
    current_way_nodes_agg.nodes,
    current_way_tags_agg.tags,
    NULL::jsonb AS members,
    NULL::text AS created_at,
    NULL::boolean AS open,
    NULL::integer AS comments_count,
    NULL::text AS closed_at,
    NULL::integer AS min_lat,
    NULL::integer AS min_lon,
    NULL::integer AS max_lat,
    NULL::integer AS max_lon
   FROM current_ways
     JOIN changesets ON changesets.id = current_ways.changeset_id
     JOIN users ON changesets.user_id = users.id
     LEFT JOIN current_way_tags_agg ON current_way_tags_agg.way_id = current_ways.id
     LEFT JOIN current_way_nodes_agg ON current_way_nodes_agg.way_id = current_ways.id),
current_relation_tags_agg AS (
         SELECT current_relation_tags.relation_id,
            jsonb_object_agg(current_relation_tags.k, current_relation_tags.v) AS tags
           FROM current_relation_tags
          GROUP BY current_relation_tags.relation_id
        ), current_relation_members_agg AS (
         SELECT current_relation_members.relation_id,
            jsonb_agg(jsonb_build_object('id', current_relation_members.member_id, 'type', current_relation_members.member_type, 'role', current_relation_members.member_role) ORDER BY current_relation_members.sequence_id) AS members
           FROM current_relation_members
          GROUP BY current_relation_members.relation_id
        ),
 api_current_relations_w AS (SELECT 'relations'::text AS type,
    current_relations.id,
    current_relations.visible,
    NULL::double precision AS lat,
    NULL::double precision AS lon,
    to_char(current_relations."timestamp", 'IYYY-MM-DD"T"HH24:MI:SS"Z"'::text) AS "timestamp",
    current_relations.version,
    current_relations.changeset_id AS changeset,
    users.display_name AS "user",
    users.id AS uid,
    NULL::bigint[] AS nodes,
    current_relation_tags_agg.tags,
    current_relation_members_agg.members,
    NULL::text AS created_at,
    NULL::boolean AS open,
    NULL::integer AS comments_count,
    NULL::text AS closed_at,
    NULL::integer AS min_lat,
    NULL::integer AS min_lon,
    NULL::integer AS max_lat,
    NULL::integer AS max_lon
   FROM current_relations
     JOIN changesets ON changesets.id = current_relations.changeset_id
     JOIN users ON changesets.user_id = users.id
     LEFT JOIN current_relation_tags_agg ON current_relation_tags_agg.relation_id = current_relations.id
     LEFT JOIN current_relation_members_agg ON current_relation_members_agg.relation_id = current_relations.id)
 
 SELECT api_current_nodes_w.* FROM api_current_nodes_w JOIN all_nodes ON api_current_nodes_w.id = all_nodes.id
 UNION ALL
 SELECT api_current_ways_w.* FROM api_current_ways_w JOIN ways ON api_current_ways_w.id = ways.id
 UNION ALL (
	 SELECT api_current_relations.* FROM api_current_relations JOIN relation_nodes ON api_current_relations.id = relation_nodes.id
	 UNION
	 SELECT api_current_relations.* FROM api_current_relations JOIN relation_ways ON api_current_relations.id = relation_ways.id
 )
$BODY$;

ALTER FUNCTION public.api_map(double precision, double precision, double precision, double precision)
    OWNER TO postgres;

