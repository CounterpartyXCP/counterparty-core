CREATE TABLE transactions_status (
    tx_index INTEGER UNIQUE,
    valid BOOLEAN NOT NULL
);

CREATE VIEW transactions_with_status AS
SELECT 
    t.tx_index as rowid,
    t.tx_index,
    t.tx_hash,
    t.block_index,
    t.block_hash,
    t.block_time,
    t.source,
    t.destination,
    t.btc_amount,
    t.fee,
    t.data,
    t.supported,
    t.utxos_info,
    t.transaction_type,
    ts.valid
FROM transactions t
LEFT JOIN transactions_status ts ON t.tx_index = ts.tx_index;

CREATE VIEW all_transactions_with_status AS
SELECT 
    t.tx_index as rowid,
    t.tx_index,
    t.tx_hash,
    t.block_index,
    t.block_hash,
    t.block_time,
    t.source,
    t.destination,
    t.btc_amount,
    t.fee,
    t.data,
    t.supported,
    t.utxos_info,
    t.transaction_type,
    t.confirmed,
    ts.valid
FROM all_transactions t
LEFT JOIN transactions_status ts ON t.tx_index = ts.tx_index;