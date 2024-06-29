-- depends: 0004.add_index_for_block_index_and_event
ALTER TABLE messages ADD COLUMN event_hash TEXT;
CREATE INDEX IF NOT EXISTS messages_event_hash_idx ON messages (event_hash, event);