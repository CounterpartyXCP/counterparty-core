CREATE TABLE IF NOT EXISTS mempool(
    tx_hash TEXT,
    command TEXT,
    category TEXT,
    bindings TEXT,
    timestamp INTEGER,
    event TEXT,
    addresses TEXT);