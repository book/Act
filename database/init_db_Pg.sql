/* users' rights */
DROP   TABLE rights;
CREATE TABLE rights
(
    name        text       NOT NULL,
    conf_id     text       NOT NULL,
    user_id     integer    NOT NULL

);
CREATE INDEX rights_conf_id ON rights (conf_id);

