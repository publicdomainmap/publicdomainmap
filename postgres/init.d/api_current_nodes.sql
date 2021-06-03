-- View: public.api_current_nodes

-- DROP VIEW public.api_current_nodes;

\c openstreetmap
CREATE OR REPLACE VIEW public.api_current_nodes
 AS
 WITH current_node_tags_agg AS (
         SELECT current_node_tags.node_id,
            jsonb_object_agg(current_node_tags.k, current_node_tags.v) AS tags
           FROM current_node_tags
          GROUP BY current_node_tags.node_id
        )
 SELECT 'node'::text AS type,
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
     LEFT JOIN current_node_tags_agg ON current_node_tags_agg.node_id = current_nodes.id;

ALTER TABLE public.api_current_nodes
    OWNER TO postgres;

GRANT ALL ON TABLE public.api_current_nodes TO postgres;
GRANT SELECT ON TABLE public.api_current_nodes TO cgimap;
