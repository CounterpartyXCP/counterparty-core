-- depends: 0004.add_index_for_block_index_and_event
CREATE INDEX IF NOT EXISTS messages_block_index_event_idx ON messages (block_index, event);