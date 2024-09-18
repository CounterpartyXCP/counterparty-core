-- depends: 0008.add_utxo_fields
CREATE TABLE IF NOT EXISTS transaction_count(
        block_index INTEGER,
        transaction_id INTEGER,
        count INTEGER);
CREATE INDEX IF NOT EXISTS transaction_count_block_index_transaction_id_idx ON transaction_count (block_index, transaction_id);