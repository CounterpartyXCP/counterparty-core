-- depends: 0007.add_description_locked
CREATE TABLE IF NOT EXISTS fairminters (
    tx_hash TEXT,
    tx_index INTEGER,
    block_index INTEGER,
    source TEXT,
    asset TEXT,
    asset_parent TEXT,
    asset_longname TEXT,
    description TEXT,
    price INTEGER,
    hard_cap INTEGER,
    burn_payment BOOL,
    max_mint_per_tx INTEGER,
    premint_quantity INTEGER,
    start_block INTEGER,
    end_block INTEGER,
    minted_asset_commission_int INTEGER,
    soft_cap INTEGER,
    soft_cap_deadline_block INTEGER,
    lock_description BOOL,
    lock_quantity BOOL,
    divisible BOOL,
    pre_minted BOOL DEFAULT 0,
    status TEXT,
    earned_quantity INTEGER,
    commission INTEGER,
    paid_quantity INTEGER
);
CREATE INDEX IF NOT EXISTS fairminters_tx_hash_idx ON fairminters (tx_hash);
CREATE INDEX IF NOT EXISTS fairminters_block_index_idx ON fairminters (block_index);
CREATE INDEX IF NOT EXISTS fairminters_asset_idx ON fairminters (asset);
CREATE INDEX IF NOT EXISTS fairminters_asset_parent_idx ON fairminters (asset_parent);
CREATE INDEX IF NOT EXISTS fairminters_asset_longname_idx ON fairminters (asset_longname);
CREATE INDEX IF NOT EXISTS fairminters_status_idx ON fairminters (status);

CREATE TABLE IF NOT EXISTS fairmints (
    tx_hash TEXT PRIMARY KEY,
    tx_index INTEGER,
    block_index INTEGER,
    source TEXT,
    fairminter_tx_hash TEXT,
    asset TEXT,
    earn_quantity INTEGER,
    paid_quantity INTEGER,
    commission INTEGER,
    status TEXT
);
CREATE INDEX IF NOT EXISTS fairmints_tx_hash_idx ON fairmints (tx_hash);
CREATE INDEX IF NOT EXISTS fairmints_block_index_idx ON fairmints (block_index);
CREATE INDEX IF NOT EXISTS fairmints_source_idx ON fairmints (source);
CREATE INDEX IF NOT EXISTS fairmints_fairminter_tx_hash_idx ON fairmints (fairminter_tx_hash);
CREATE INDEX IF NOT EXISTS fairmints_asset_idx ON fairmints (asset);
CREATE INDEX IF NOT EXISTS fairmints_status_idx ON fairmints (status);

ALTER TABLE issuances ADD COLUMN fair_minting BOOL DEFAULT 0;