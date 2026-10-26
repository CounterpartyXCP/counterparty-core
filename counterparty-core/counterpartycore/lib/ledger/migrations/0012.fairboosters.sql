-- Fairboosters: boosters of trading cards sold for XCP. Created after the
-- compact-hash storage migration (0010), so the tables use its compact types
-- directly: BLOB(32) hashes, `asset_index` asset columns, `address_id` address
-- columns.

-- One row per version of a fairbooster (creation, update, sale): the current
-- state is the latest row of its `tx_hash`. `asset` is the fairbooster asset,
-- the parent of every card asset.
CREATE TABLE IF NOT EXISTS fairboosters(
    tx_index INTEGER,
    tx_hash BLOB,
    block_index INTEGER,
    source INTEGER,
    asset INTEGER,
    description TEXT,
    image_url TEXT,
    price INTEGER,
    max_boosters INTEGER,
    cards_per_booster INTEGER,
    cards_base_url TEXT,
    cards_image_extension TEXT,
    card_count INTEGER,
    boosters_sold INTEGER,
    cards_sold INTEGER,
    paid_capacity INTEGER,
    fee_paid INTEGER,
    status TEXT
);
CREATE INDEX IF NOT EXISTS fairboosters_tx_hash_idx ON fairboosters (tx_hash);
CREATE INDEX IF NOT EXISTS fairboosters_asset_idx ON fairboosters (asset);
CREATE INDEX IF NOT EXISTS fairboosters_source_idx ON fairboosters (source);
CREATE INDEX IF NOT EXISTS fairboosters_block_index_idx ON fairboosters (block_index);

-- The cards of a fairbooster, written by its creation or by an update
-- (`tx_index`/`tx_hash`). A card cannot be changed once added.
CREATE TABLE IF NOT EXISTS fairbooster_cards(
    tx_index INTEGER,
    tx_hash BLOB,
    block_index INTEGER,
    fairbooster INTEGER,
    card_id INTEGER,
    name TEXT,
    image_hash TEXT,
    weight INTEGER,
    max_supply INTEGER
);
CREATE INDEX IF NOT EXISTS fairbooster_cards_fairbooster_card_id_idx ON fairbooster_cards (fairbooster, card_id);
CREATE INDEX IF NOT EXISTS fairbooster_cards_block_index_idx ON fairbooster_cards (block_index);

-- `updatefairbooster` transactions. A NULL parameter is left unchanged.
CREATE TABLE IF NOT EXISTS fairbooster_updates(
    tx_index INTEGER,
    tx_hash BLOB,
    block_index INTEGER,
    source INTEGER,
    fairbooster INTEGER,
    description TEXT,
    image_url TEXT,
    price INTEGER,
    max_boosters INTEGER,
    cards_per_booster INTEGER,
    cards_base_url TEXT,
    cards_image_extension TEXT,
    cards_added INTEGER,
    fee_paid INTEGER,
    status TEXT
);
CREATE INDEX IF NOT EXISTS fairbooster_updates_tx_hash_idx ON fairbooster_updates (tx_hash);
CREATE INDEX IF NOT EXISTS fairbooster_updates_fairbooster_idx ON fairbooster_updates (fairbooster);
CREATE INDEX IF NOT EXISTS fairbooster_updates_source_idx ON fairbooster_updates (source);
CREATE INDEX IF NOT EXISTS fairbooster_updates_block_index_idx ON fairbooster_updates (block_index);

-- `buybooster` transactions. The cards of a valid purchase are drawn in the
-- next block (`fairbooster_draws`); `card_count` is the number of cards of the
-- booster when it was bought.
CREATE TABLE IF NOT EXISTS fairbooster_purchases(
    tx_index INTEGER,
    tx_hash BLOB,
    block_index INTEGER,
    source INTEGER,
    fairbooster INTEGER,
    paid_quantity INTEGER,
    card_count INTEGER,
    status TEXT
);
CREATE INDEX IF NOT EXISTS fairbooster_purchases_tx_hash_idx ON fairbooster_purchases (tx_hash);
CREATE INDEX IF NOT EXISTS fairbooster_purchases_fairbooster_status_idx ON fairbooster_purchases (fairbooster, status);
CREATE INDEX IF NOT EXISTS fairbooster_purchases_source_idx ON fairbooster_purchases (source);
CREATE INDEX IF NOT EXISTS fairbooster_purchases_block_index_status_idx ON fairbooster_purchases (block_index, status);

-- One row per drawn card: `asset` is the card asset created for it
-- (`<fairbooster>.<card_id>.<name>.<serial>`, supply 1, locked), `tx_index`/
-- `tx_hash` the purchase, `block_index` the block that drew it.
CREATE TABLE IF NOT EXISTS fairbooster_draws(
    tx_index INTEGER,
    tx_hash BLOB,
    block_index INTEGER,
    source INTEGER,
    fairbooster INTEGER,
    card_id INTEGER,
    serial INTEGER,
    asset INTEGER
);
CREATE INDEX IF NOT EXISTS fairbooster_draws_tx_hash_idx ON fairbooster_draws (tx_hash);
-- covers `ledger.fairboosters.get_drawn_cards`
CREATE INDEX IF NOT EXISTS fairbooster_draws_fairbooster_card_id_serial_idx ON fairbooster_draws (fairbooster, card_id, serial);
CREATE INDEX IF NOT EXISTS fairbooster_draws_source_idx ON fairbooster_draws (source);
CREATE INDEX IF NOT EXISTS fairbooster_draws_asset_idx ON fairbooster_draws (asset);
CREATE INDEX IF NOT EXISTS fairbooster_draws_block_index_idx ON fairbooster_draws (block_index);
