-- Create an act database from scratch

CREATE TABLE schema (
    current_version integer NOT NULL
);

CREATE TABLE users (
    user_id     serial     NOT NULL  PRIMARY KEY,
    login       text       NOT NULL,
    passwd      text       NOT NULL,
    session_id  text,

    /* personal information */
    salutation   integer,
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
    gpg_key_id   text,
    pause_id     text,
    monk_id      text,
    monk_name    text,
    im           text,
    photo_name   text,

    /* website preferences */
    language     text,
    timezone     text         NOT NULL,

    /* billing info */
    company      text,
    company_url  text,
    address      text,
    vat          text

);
CREATE UNIQUE INDEX users_session_id ON users (session_id);
CREATE UNIQUE INDEX users_login ON users (login);

CREATE TABLE bios (
    user_id   integer,
    lang      text,
    bio       text
);
CREATE UNIQUE INDEX bios_idx ON bios (user_id, lang);

/* users' rights */
CREATE TABLE rights (
    right_id    text       NOT NULL,
    conf_id     text       NOT NULL,
    user_id     integer    NOT NULL,

    FOREIGN KEY( user_id  ) REFERENCES users( user_id )
);
CREATE INDEX rights_idx ON rights (conf_id);

/* invoice numer */
CREATE TABLE invoice_num (
    conf_id     text       NOT NULL PRIMARY KEY,
    next_num    integer    NOT NULL
);

/* user's participations to conferences */
CREATE TABLE participations (
    conf_id     text                      NOT NULL,
    user_id     integer                   NOT NULL,
    tshirt_size text,                     /* S, M, L, XL, XXL */
    nb_family   integer    DEFAULT 0,
    datetime    timestamp without time zone,
    ip          text,
    attended    boolean    DEFAULT FALSE,

    FOREIGN KEY( user_id  ) REFERENCES users( user_id )
);
CREATE INDEX participations_idx ON participations (conf_id, user_id);

/*** Talks related tables ***/
/* tracks */
CREATE TABLE tracks (
    track_id    serial     NOT NULL    PRIMARY KEY,
    conf_id     text       NOT NULL,
    title       text       NOT NULL,
    description text
);
CREATE INDEX tracks_idx ON tracks ( conf_id );

/* talks */
CREATE TABLE talks (
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
    track_id     integer REFERENCES tracks(track_id) ON DELETE SET NULL,

    level        integer DEFAULT 1,
    lang         text,

    FOREIGN KEY( user_id  ) REFERENCES users( user_id )
);
CREATE INDEX talks_idx ON talks ( talk_id, conf_id );

/* events */
CREATE TABLE events (
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

/* my schedule */
CREATE TABLE user_talks (
    user_id     integer   NOT NULL,
    conf_id     text      NOT NULL,
    talk_id     integer   NOT NULL,
    FOREIGN KEY( user_id  ) REFERENCES users( user_id ),
    FOREIGN KEY( talk_id  ) REFERENCES talks( talk_id )
);
CREATE INDEX user_talks_idx ON user_talks ( user_id, talk_id );

/* orders */
CREATE TABLE orders (
    order_id   serial    NOT NULL    PRIMARY KEY,
    conf_id    text      NOT NULL,
    user_id    integer   NOT NULL,
    datetime   timestamp without time zone NOT NULL,

    /* order info */
    means      text,
    currency   text,
    status     text      NOT NULL,
    type       text,

    FOREIGN KEY( user_id  ) REFERENCES users( user_id )
);

CREATE TABLE order_items
(
    item_id    serial    NOT NULL    PRIMARY KEY,
    order_id   integer   NOT NULL,
    amount     integer   NOT NULL,
    name       text,
    registration boolean NOT NULL,

    FOREIGN KEY( order_id  ) REFERENCES orders( order_id )
);

/* invoices */
CREATE TABLE invoices
(
    /* invoice info */
    invoice_id serial    NOT NULL    PRIMARY KEY,
    order_id   integer   NOT NULL,
    datetime   timestamp without time zone NOT NULL,
    invoice_no integer   NOT NULL,

    /* order info */
    amount     integer   NOT NULL,
    means      text,
    currency   text,

    /* user info */
    first_name   text,
    last_name    text,

    /* billing info */
    company      text,
    address      text,
    vat          text,

    FOREIGN KEY( order_id  ) REFERENCES orders( order_id )
);
CREATE UNIQUE INDEX invoices_idx ON invoices ( order_id );

/* conference news */
CREATE TABLE news
(
    news_id     SERIAL NOT NULL  PRIMARY KEY,
    conf_id     text   NOT NULL,
    datetime    timestamp without time zone NOT NULL,
    user_id     integer NOT NULL,
    published   boolean DEFAULT false NOT NULL
);
CREATE TABLE news_items
(
    news_item_id    SERIAL  NOT NULL PRIMARY KEY,
    news_id         integer NOT NULL,
    lang            text    NOT NULL,
    title           text    NOT NULL,
    text            text    NOT NULL,

    UNIQUE (news_id, lang),
    FOREIGN KEY( news_id  ) REFERENCES news( news_id )
);

/* perl mongers groups */
CREATE TABLE pm_groups
(
    group_id      serial     NOT NULL  PRIMARY KEY,
    xml_group_id  integer,   /* from the perl_mongers.xml file */
    name          text,
    status        text,
    continent     text,
    country       text,
    state         text
);
CREATE INDEX pm_groups_idx ON pm_groups ( xml_group_id );

CREATE TABLE twostep
(
    token         char(32) NOT NULL PRIMARY KEY,
    email         text NOT NULL,
    datetime      timestamp without time zone,
    data          text
);

CREATE TABLE tags
(
    tag_id        serial NOT NULL PRIMARY KEY,
    conf_id       text NOT NULL,
    tag           text NOT NULL,
    type          text NOT NULL,
    tagged_id     text NOT NULL
);
