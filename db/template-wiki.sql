-- Just an SQL file to create the database
CREATE DATABASE act_wiki;

\c act_wiki

CREATE TABLE schema_info (
    version integer NOT NULL
);

INSERT INTO schema_info (version) VALUES (10);

