SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

CREATE TABLE content (
    node_id integer NOT NULL,
    version integer DEFAULT 0 NOT NULL,
    text text DEFAULT ''::text NOT NULL,
    modified timestamp without time zone,
    comment text DEFAULT ''::text NOT NULL,
    moderated boolean DEFAULT true NOT NULL,
    verified timestamp without time zone,
    verified_info text DEFAULT ''::text NOT NULL
);

CREATE TABLE internal_links (
    link_from character varying(200) DEFAULT ''::character varying NOT NULL,
    link_to character varying(200) DEFAULT ''::character varying NOT NULL
);

CREATE TABLE metadata (
    node_id integer NOT NULL,
    version integer DEFAULT 0 NOT NULL,
    metadata_type character varying(200) DEFAULT ''::character varying NOT NULL,
    metadata_value text DEFAULT ''::text NOT NULL
);

CREATE TABLE node (
    id serial NOT NULL PRIMARY KEY,
    name character varying(200) DEFAULT ''::character varying NOT NULL,
    version integer DEFAULT 0 NOT NULL,
    text text DEFAULT ''::text NOT NULL,
    modified timestamp without time zone,
    moderate boolean DEFAULT false NOT NULL
);


CREATE TABLE schema_info (
    version integer DEFAULT 0 NOT NULL
);

ALTER TABLE ONLY content
    ADD CONSTRAINT pk_node_id PRIMARY KEY (node_id, version);

CREATE UNIQUE INDEX internal_links_pkey ON internal_links USING btree (link_from, link_to);

CREATE INDEX metadata_index ON metadata USING btree (node_id, version, metadata_type, metadata_value);

CREATE UNIQUE INDEX node_name ON node USING btree (name);

ALTER TABLE ONLY metadata
    ADD CONSTRAINT fk_node_id FOREIGN KEY (node_id) REFERENCES node(id);

ALTER TABLE ONLY content
    ADD CONSTRAINT fk_node_id FOREIGN KEY (node_id) REFERENCES node(id);
