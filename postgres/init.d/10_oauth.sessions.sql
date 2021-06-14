-- Table: oauth.sessions

-- DROP TABLE oauth.sessions;

\c openstreetmap
CREATE TABLE IF NOT EXISTS oauth.sessions
(
    created_time timestamp without time zone,
    request_token text COLLATE pg_catalog."default",
    request_token_secret text COLLATE pg_catalog."default",
    access_token text COLLATE pg_catalog."default",
    access_token_secret text COLLATE pg_catalog."default",
    user_id bigint,
    user_data jsonb
)

TABLESPACE pg_default;

ALTER TABLE oauth.sessions
    OWNER to postgres;
