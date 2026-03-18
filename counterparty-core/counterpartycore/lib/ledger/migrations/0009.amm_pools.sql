-- AMM Liquidity Pools

CREATE TABLE IF NOT EXISTS pools(
    tx_index INTEGER,
    tx_hash TEXT,
    block_index INTEGER,
    source TEXT,
    asset_a TEXT,
    asset_b TEXT,
    reserve_a INTEGER,
    reserve_b INTEGER,
    lp_asset TEXT
);
CREATE INDEX IF NOT EXISTS pools_asset_a_asset_b_idx ON pools (asset_a, asset_b);
CREATE INDEX IF NOT EXISTS pools_lp_asset_idx ON pools (lp_asset);
CREATE INDEX IF NOT EXISTS pools_block_index_idx ON pools (block_index);

CREATE TABLE IF NOT EXISTS pool_deposits(
    tx_index INTEGER,
    tx_hash TEXT,
    block_index INTEGER,
    source TEXT,
    asset_a TEXT,
    asset_b TEXT,
    quantity_a INTEGER,
    quantity_b INTEGER,
    quantity_minted INTEGER,
    status TEXT
);
CREATE INDEX IF NOT EXISTS pool_deposits_tx_hash_idx ON pool_deposits (tx_hash);
CREATE INDEX IF NOT EXISTS pool_deposits_source_status_idx ON pool_deposits (source, status);
CREATE INDEX IF NOT EXISTS pool_deposits_block_index_idx ON pool_deposits (block_index);
CREATE INDEX IF NOT EXISTS pool_deposits_asset_a_asset_b_status_idx ON pool_deposits (asset_a, asset_b, status);

CREATE TABLE IF NOT EXISTS pool_withdrawals(
    tx_index INTEGER,
    tx_hash TEXT,
    block_index INTEGER,
    source TEXT,
    asset_a TEXT,
    asset_b TEXT,
    quantity_destroyed INTEGER,
    quantity_a INTEGER,
    quantity_b INTEGER,
    status TEXT
);
CREATE INDEX IF NOT EXISTS pool_withdrawals_tx_hash_idx ON pool_withdrawals (tx_hash);
CREATE INDEX IF NOT EXISTS pool_withdrawals_source_status_idx ON pool_withdrawals (source, status);
CREATE INDEX IF NOT EXISTS pool_withdrawals_block_index_idx ON pool_withdrawals (block_index);
CREATE INDEX IF NOT EXISTS pool_withdrawals_asset_a_asset_b_status_idx ON pool_withdrawals (asset_a, asset_b, status);

CREATE TABLE IF NOT EXISTS pool_matches(
    tx_index INTEGER,
    tx_hash TEXT,
    block_index INTEGER,
    source TEXT,
    asset_a TEXT,
    asset_b TEXT,
    forward_asset TEXT,
    forward_quantity INTEGER,
    backward_asset TEXT,
    backward_quantity INTEGER,
    fee_quantity INTEGER,
    fee_bps INTEGER,
    order_tx_hash TEXT,
    status TEXT
);
CREATE INDEX IF NOT EXISTS pool_matches_tx_hash_idx ON pool_matches (tx_hash);
CREATE INDEX IF NOT EXISTS pool_matches_source_idx ON pool_matches (source);
CREATE INDEX IF NOT EXISTS pool_matches_block_index_idx ON pool_matches (block_index);
CREATE INDEX IF NOT EXISTS pool_matches_asset_a_asset_b_idx ON pool_matches (asset_a, asset_b);
CREATE INDEX IF NOT EXISTS pool_matches_order_tx_hash_idx ON pool_matches (order_tx_hash);
