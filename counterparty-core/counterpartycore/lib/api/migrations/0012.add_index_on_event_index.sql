-- depends: 0011.fix_close_block_index

CREATE INDEX IF NOT EXISTS address_events_event_index_idx ON address_events (event_index);