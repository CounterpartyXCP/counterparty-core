-- depends: 0003.add_btc_amount_in_dispenses
CREATE INDEX IF NOT EXISTS messages_block_index_event_idx ON messages (block_index, event);