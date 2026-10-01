\getenv wikidb WIKIDB
\c :wikidb
INSERT INTO schema_info (version) VALUES (10);
