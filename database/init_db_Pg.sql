/* users */
DROP   TABLE users CASCADE;
CREATE TABLE users
(
    user_id     serial     NOT NULL  PRIMARY KEY,
    login       text       NOT NULL,
    passwd      text       NOT NULL,
    session_id  text
);
CREATE INDEX users_session_id ON users (session_id);

/* users' rights */
DROP   TABLE rights;
CREATE TABLE rights
(
    name        text       NOT NULL,
    conf_id     text       NOT NULL,
    user_id     integer    NOT NULL,

    FOREIGN KEY( user_id  ) REFERENCES users( user_id  )
);
CREATE INDEX rights_idx ON rights (conf_id);

/* multilingual entries */
DROP   TABLE translations;
CREATE TABLE translations
(
    tbl      text,
    col      text,           
    id       integer,
    lang     text,
    text     text
);
CREATE INDEX translations_idx ON translations ( tbl, col, id );
