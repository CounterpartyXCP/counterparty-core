CREATE TABLE IF NOT EXISTS mempool_transactions(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      block_hash TEXT,
                      block_time INTEGER,
                      source TEXT,
                      destination TEXT,
                      btc_amount INTEGER,
                      fee INTEGER,
                      data BLOB,
                      supported BOOL DEFAULT 1,
                      utxos_info TEXT, transaction_type TEXT);
CREATE INDEX IF NOT EXISTS mempool_transactions_block_index_idx ON mempool_transactions (block_index);
CREATE INDEX IF NOT EXISTS mempool_transactions_tx_index_idx ON mempool_transactions (tx_index);
CREATE INDEX IF NOT EXISTS mempool_transactions_tx_hash_idx ON mempool_transactions (tx_hash);
CREATE INDEX IF NOT EXISTS mempool_transactions_block_index_tx_index_idx ON mempool_transactions (block_index, tx_index);
CREATE INDEX IF NOT EXISTS mempool_transactions_tx_index_tx_hash_block_index_idx ON mempool_transactions (tx_index, tx_hash, block_index);
CREATE INDEX IF NOT EXISTS mempool_transactions_source_idx ON mempool_transactions (source);

CREATE VIEW IF NOT EXISTS all_transactions AS
    SELECT 
        tx_index,
        tx_hash,
        block_index,
        block_hash,
        block_time,
        source,
        destination,
        btc_amount,
        fee,
        data,
        supported,
        utxos_info,
        transaction_type,
        FALSE as confirmed
    FROM mempool_transactions
    UNION ALL
    SELECT 
        tx_index,
        tx_hash,
        block_index,
        block_hash,
        block_time,
        source,
        destination,
        btc_amount,
        fee,
        data,
        supported,
        utxos_info,
        transaction_type,
        TRUE as confirmed
    FROM transactions;