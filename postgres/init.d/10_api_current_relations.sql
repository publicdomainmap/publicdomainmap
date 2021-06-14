-- View: public.api_current_relations

-- DROP VIEW public.api_current_relations;

\c openstreetmap
CREATE OR REPLACE VIEW public.api_current_relations
 AS
 WITH current_relation_tags_agg AS (
         SELECT current_relation_tags.relation_id,
            jsonb_object_agg(current_relation_tags.k, current_relation_tags.v) AS tags
           FROM current_relation_tags
          GROUP BY current_relation_tags.relation_id
        ), current_relation_members_agg AS (
         SELECT current_relation_members.relation_id,
            jsonb_agg(jsonb_build_object('id', current_relation_members.member_id, 'type', current_relation_members.member_type, 'role', current_relation_members.member_role) ORDER BY current_relation_members.sequence_id) AS members
           FROM current_relation_members
          GROUP BY current_relation_members.relation_id
        )
 SELECT 'relations'::text AS type,
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
     LEFT JOIN current_relation_members_agg ON current_relation_members_agg.relation_id = current_relations.id;

ALTER TABLE public.api_current_relations
    OWNER TO postgres;

GRANT ALL ON TABLE public.api_current_relations TO postgres;
GRANT SELECT ON TABLE public.api_current_relations TO cgimap;
