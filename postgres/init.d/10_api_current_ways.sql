-- View: public.api_current_ways

-- DROP VIEW public.api_current_ways;

\c openstreetmap
CREATE OR REPLACE VIEW public.api_current_ways
 AS
 WITH current_way_tags_agg AS (
         SELECT current_way_tags.way_id,
            jsonb_object_agg(current_way_tags.k, current_way_tags.v) AS tags
           FROM current_way_tags
          GROUP BY current_way_tags.way_id
        ), current_way_nodes_agg AS (
         SELECT current_way_nodes.way_id,
            array_agg(current_way_nodes.node_id ORDER BY current_way_nodes.sequence_id) AS nodes
           FROM current_way_nodes
          GROUP BY current_way_nodes.way_id
        )
 SELECT 'way'::text AS type,
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
     LEFT JOIN current_way_nodes_agg ON current_way_nodes_agg.way_id = current_ways.id;

ALTER TABLE public.api_current_ways
    OWNER TO postgres;

GRANT ALL ON TABLE public.api_current_ways TO postgres;
GRANT SELECT ON TABLE public.api_current_ways TO cgimap;
