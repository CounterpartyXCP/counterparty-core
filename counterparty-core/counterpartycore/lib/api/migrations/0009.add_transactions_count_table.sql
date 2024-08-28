-- depends: 0008.add_utxo_fields
CREATE TABLE IF NOT EXISTS transaction_count(
        block_index INTEGER,
        difficulty_period INTEGER,
        transaction_id INTEGER,
        count INTEGER);
CREATE INDEX IF NOT EXISTS transaction_count_block_index_idx ON transaction_count (block_index);
CREATE INDEX IF NOT EXISTS transaction_count_difficulty_period_transaction_id_idx ON transaction_count (difficulty_period, transaction_id);