-- Convert schema 'pg.dump' to 'pg_dbic.dump':;

BEGIN;

DROP INDEX bios_idx;

ALTER TABLE bios ADD CONSTRAINT bios_idx UNIQUE (user_id, lang);

DROP INDEX events_idx;

ALTER TABLE invoices DROP CONSTRAINT invoices_order_id_fkey;

DROP INDEX invoices_idx;

CREATE INDEX invoices_idx_order_id on invoices (order_id);

ALTER TABLE invoices ADD CONSTRAINT invoices_idx UNIQUE (order_id);

ALTER TABLE invoices ADD CONSTRAINT invoices_fk_order_id FOREIGN KEY (order_id)
  REFERENCES orders (order_id) DEFERRABLE;

ALTER TABLE news_items DROP CONSTRAINT news_items_news_id_fkey;

CREATE INDEX news_items_idx_news_id on news_items (news_id);

ALTER TABLE news_items ADD CONSTRAINT news_items_fk_news_id FOREIGN KEY (news_id)
  REFERENCES news (news_id) DEFERRABLE;

ALTER TABLE order_items DROP CONSTRAINT order_items_order_id_fkey;

CREATE INDEX order_items_idx_order_id on order_items (order_id);

ALTER TABLE order_items ADD CONSTRAINT order_items_fk_order_id FOREIGN KEY (order_id)
  REFERENCES orders (order_id) DEFERRABLE;

ALTER TABLE orders DROP CONSTRAINT orders_user_id_fkey;

CREATE INDEX orders_idx_user_id on orders (user_id);

ALTER TABLE orders ADD CONSTRAINT orders_fk_user_id FOREIGN KEY (user_id)
  REFERENCES users (user_id) DEFERRABLE;

ALTER TABLE participations DROP CONSTRAINT participations_user_id_fkey;

DROP INDEX participations_idx;

CREATE INDEX participations_idx_user_id on participations (user_id);

ALTER TABLE participations ADD CONSTRAINT participations_fk_user_id FOREIGN KEY (user_id)
  REFERENCES users (user_id) DEFERRABLE;

DROP INDEX pm_groups_idx;

ALTER TABLE rights DROP CONSTRAINT rights_user_id_fkey;

DROP INDEX rights_idx;

CREATE INDEX rights_idx_user_id on rights (user_id);

ALTER TABLE rights ADD CONSTRAINT rights_fk_user_id FOREIGN KEY (user_id)
  REFERENCES users (user_id) DEFERRABLE;

ALTER TABLE talks DROP CONSTRAINT talks_track_id_fkey;

ALTER TABLE talks DROP CONSTRAINT talks_user_id_fkey;

DROP INDEX talks_idx;

CREATE INDEX talks_idx_track_id on talks (track_id);

CREATE INDEX talks_idx_user_id on talks (user_id);

ALTER TABLE talks ADD CONSTRAINT talks_fk_track_id FOREIGN KEY (track_id)
  REFERENCES tracks (track_id) ON DELETE set null DEFERRABLE;

ALTER TABLE talks ADD CONSTRAINT talks_fk_user_id FOREIGN KEY (user_id)
  REFERENCES users (user_id) DEFERRABLE;

DROP INDEX tracks_idx;

ALTER TABLE user_talks DROP CONSTRAINT user_talks_talk_id_fkey;

ALTER TABLE user_talks DROP CONSTRAINT user_talks_user_id_fkey;

DROP INDEX user_talks_idx;

CREATE INDEX user_talks_idx_talk_id on user_talks (talk_id);

CREATE INDEX user_talks_idx_user_id on user_talks (user_id);

ALTER TABLE user_talks ADD CONSTRAINT user_talks_fk_talk_id FOREIGN KEY (talk_id)
  REFERENCES talks (talk_id) DEFERRABLE;

ALTER TABLE user_talks ADD CONSTRAINT user_talks_fk_user_id FOREIGN KEY (user_id)
  REFERENCES users (user_id) DEFERRABLE;

DROP INDEX users_login;

DROP INDEX users_session_id;

ALTER TABLE users ADD CONSTRAINT users_login UNIQUE (login);

ALTER TABLE users ADD CONSTRAINT users_session_id UNIQUE (session_id);


COMMIT;

