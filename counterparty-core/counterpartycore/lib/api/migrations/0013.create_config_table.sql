-- depends: 0012.add_index_on_event_index

CREATE TABLE IF NOT EXISTS config (
    name TEXT PRIMARY KEY,
    value TEXT
);
CREATE INDEX IF NOT EXISTS config_config_name_idx ON config (name);