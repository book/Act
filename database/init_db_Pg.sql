/* users' rights */
DROP   TABLE rights;
CREATE TABLE rights
(
    name        text       NOT NULL,
    conf_id     text       NOT NULL,
    user_id     integer    NOT NULL

);
CREATE INDEX rights_idx ON rights (conf_id);

/* multilingual entries */
DROP   TABLE translations;
CREATE TABLE translations
(
    table    text,
    col      text,           
    id       integer,
    lang     text,
    text     text,
);
CREATE INDEX translations_idx ON translations ( table col id );

