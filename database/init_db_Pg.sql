/*** users' related tables ***/

/* users */
DROP   TABLE users CASCADE;
CREATE TABLE users
(
    user_id     serial     NOT NULL  PRIMARY KEY,
    login       text       NOT NULL,
    passwd      text       NOT NULL,
    session_id  text,

    /* personal information */
    civility     integer,   /* handled in translations */
    first_name   text,
    last_name    text,
    nick_name    text,
    pseudonymous boolean    DEFAULT FALSE,
    country      text       NOT NULL,
    town         text,

    /* online indentity */
    web_page     text,
    pm_group     text,
    pm_group_url text,
    email        text                       NOT NULL,
    email_hide   boolean      DEFAULT TRUE  NOT NULL,
    gpg_pub_key  text,
    pause_id     text,
    monk_id      text,
    im           text,
    photo_name   text,
    bio          text,

    /* website preferences */
    language     text,
    timezone     text         DEFAULT 'Europe/Paris'   NOT NULL,

    /* billing info */
    company      text,
    company_url  text,
    address      text

);
CREATE UNIQUE INDEX users_session_id ON users (session_id);
CREATE UNIQUE INDEX users_login ON users (login);

/* users' rights */
DROP   TABLE rights;
CREATE TABLE rights
(
    right_id    text       NOT NULL,
    conf_id     text       NOT NULL,
    user_id     integer    NOT NULL,

    FOREIGN KEY( user_id  ) REFERENCES users( user_id )
);
CREATE INDEX rights_idx ON rights (conf_id);

/* user's participations to conferences */
DROP   TABLE participations;
CREATE TABLE participations
(
    conf_id     text                      NOT NULL,
    user_id     integer                   NOT NULL,
    registered  boolean    DEFAULT FALSE,
    payment     integer,                  /* notyet, cash, online, cheque, waived */
    tshirt_size text,                     /* S, M, L, XL, XXL */
    nb_family   integer    DEFAULT 0,

    FOREIGN KEY( user_id  ) REFERENCES users( user_id )
);
CREATE INDEX participations_idx ON participations (conf_id, user_id);

/*** Talks related tables ***/
/* talks */
DROP   TABLE talks CASCADE;
CREATE TABLE talks
(
    talk_id    serial    NOT NULL    PRIMARY KEY,
    conf_id    text      NOT NULL,
    user_id    integer   NOT NULL,

    /* talk info */
    title        text,
    abstract     text,
    url_abstract text,
    url_talk     text,
    duration     integer,
    lightning    boolean DEFAULT false NOT NULL,

    /* for the organisers */
    accepted     boolean DEFAULT false NOT NULL,
    confirmed    boolean DEFAULT false NOT NULL,
    comment      text,

    /* for the schedule */
    room         text,
    datetime     timestamp without time zone,
    /* category_id  integer, */
  

    FOREIGN KEY( user_id  ) REFERENCES users( user_id )
    /* FOREIGN KEY( category_id  ) REFERENCES category( category_id ) */
);
CREATE INDEX talks_idx ON talks ( talk_id, conf_id );

/* events */
DROP   TABLE events CASCADE;
CREATE TABLE events
(
    event_id   serial    NOT NULL    PRIMARY KEY,
    conf_id    text      NOT NULL,
    title      text      NOT NULL,
    abstract   text,
    url_abstract text,
    room       text, 
    duration   integer,
    datetime   timestamp without time zone
);
CREATE INDEX events_idx ON events ( event_id, conf_id );

/* orders */
DROP   TABLE orders CASCADE;
CREATE TABLE orders
(
    order_id   serial    NOT NULL    PRIMARY KEY,
    conf_id    text      NOT NULL,
    user_id    integer   NOT NULL,

    /* order info */
    amount     integer               NOT NULL,
    paid       boolean DEFAULT false NOT NULL,

    FOREIGN KEY( user_id  ) REFERENCES users( user_id )
);

/* multilingual entries */
DROP   TABLE translations;
CREATE TABLE translations
(
    tbl      text NOT NULL,
    col      text NOT NULL,           
    id       text NOT NULL,
    lang     text NOT NULL,
    text     text NOT NULL
);
CREATE UNIQUE INDEX translations_idx ON translations ( tbl, col, id, lang );

/* conference news */
DROP   TABLE news;
CREATE TABLE news
(
    conf_id  text,
    lang     text,
    date     date,
    text     text
);
CREATE INDEX news_idx ON news ( conf_id, lang );

