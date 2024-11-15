PRAGMA foreign_keys=OFF;

DROP TRIGGER IF EXISTS block_update_blocks;
DROP TRIGGER IF EXISTS block_update_transactions;
DROP TRIGGER IF EXISTS block_update_transaction_outputs;
DROP TRIGGER IF EXISTS block_update_debits;
DROP TRIGGER IF EXISTS block_update_credits;
DROP TRIGGER IF EXISTS block_update_sends;
DROP TRIGGER IF EXISTS block_update_assets;
DROP TRIGGER IF EXISTS block_update_destructions;
DROP TRIGGER IF EXISTS block_update_btcpays;
DROP TRIGGER IF EXISTS block_update_broadcasts;
DROP TRIGGER IF EXISTS block_update_dividends;
DROP TRIGGER IF EXISTS block_update_burns;
DROP TRIGGER IF EXISTS block_update_cancels;
DROP TRIGGER IF EXISTS block_update_rpsresolves;
DROP TRIGGER IF EXISTS block_update_sweeps;
DROP TRIGGER IF EXISTS block_update_dispenses;
DROP TRIGGER IF EXISTS block_update_dispenser_refills;
DROP TRIGGER IF EXISTS block_update_fairmints;
DROP TRIGGER IF EXISTS block_update_transaction_count;
DROP TRIGGER IF EXISTS block_update_issuances;
DROP TRIGGER IF EXISTS block_update_messages;
DROP TRIGGER IF EXISTS block_update_bet_match_resolutions;
DROP TRIGGER IF EXISTS block_update_order_expirations;
DROP TRIGGER IF EXISTS block_update_order_match_expirations;
DROP TRIGGER IF EXISTS block_update_bet_expirations;
DROP TRIGGER IF EXISTS block_update_bet_match_expirations;
DROP TRIGGER IF EXISTS block_update_rps_expirations;
DROP TRIGGER IF EXISTS block_update_rps_match_expirations;
DROP TRIGGER IF EXISTS block_update_fairminters;
DROP TRIGGER IF EXISTS block_update_balances;
DROP TRIGGER IF EXISTS block_update_addresses;
DROP TRIGGER IF EXISTS block_update_dispensers;
DROP TRIGGER IF EXISTS block_update_bet_matches;
DROP TRIGGER IF EXISTS block_update_bets;
DROP TRIGGER IF EXISTS block_update_order_matches;
DROP TRIGGER IF EXISTS block_update_orders;
DROP TRIGGER IF EXISTS block_update_rps;
DROP TRIGGER IF EXISTS block_update_rps_matches;

DROP VIEW IF EXISTS all_expirations;

ALTER TABLE fairminters ADD COLUMN earned_quantity INTEGER;
ALTER TABLE fairminters ADD COLUMN paid_quantity INTEGER;
ALTER TABLE fairminters ADD COLUMN commission INTEGER;
ALTER TABLE issuances ADD COLUMN asset_events TEXT;
ALTER TABLE dispenses ADD COLUMN btc_amount TEXT;
ALTER TABLE mempool ADD COLUMN addresses TEXT;

ALTER TABLE issuances RENAME COLUMN locked TO locked_old;
ALTER TABLE issuances ADD COLUMN locked BOOL DEFAULT FALSE;
UPDATE issuances SET locked = locked_old;
ALTER TABLE issuances DROP COLUMN locked_old;
UPDATE issuances SET locked = 0 WHERE locked IS NULL;

ALTER TABLE issuances RENAME COLUMN reset TO reset_old;
ALTER TABLE issuances ADD COLUMN reset BOOL DEFAULT FALSE;
UPDATE issuances SET reset = reset_old;
ALTER TABLE issuances DROP COLUMN reset_old;
UPDATE issuances SET locked = 0 WHERE locked IS NULL;


ALTER TABLE dispensers RENAME TO old_dispensers;
CREATE TABLE IF NOT EXISTS dispensers(
    tx_index INTEGER,
    tx_hash TEXT,
    block_index INTEGER,
    source TEXT,
    asset TEXT,
    give_quantity INTEGER,
    escrow_quantity INTEGER,
    satoshirate INTEGER,
    status INTEGER,
    give_remaining INTEGER,
    oracle_address TEXT,
    last_status_tx_hash TEXT,
    origin TEXT,
    dispense_count INTEGER DEFAULT 0,
    last_status_tx_source TEXT,
    close_block_index INTEGER);
INSERT INTO dispensers SELECT * FROM old_dispensers;
DROP TABLE old_dispensers;


CREATE INDEX IF NOT EXISTS blocks_ledger_hash_idx ON blocks (ledger_hash);


CREATE TABLE IF NOT EXISTS assets_info(
    asset TEXT UNIQUE,
    asset_id TEXT UNIQUE,
    asset_longname TEXT,
    issuer TEXT,
    owner TEXT,
    divisible BOOL,
    locked BOOL DEFAULT 0,
    supply INTEGER DEFAULT 0,
    description TEXT,
    first_issuance_block_index INTEGER,
    last_issuance_block_index INTEGER,
    confirmed BOOLEAN DEFAULT TRUE
);
CREATE INDEX IF NOT EXISTS assets_info_asset_idx ON assets_info (asset);
CREATE INDEX IF NOT EXISTS assets_info_asset_longname_idx ON assets_info (asset_longname);
CREATE INDEX IF NOT EXISTS assets_info_issuer_idx ON assets_info (issuer);
CREATE INDEX IF NOT EXISTS assets_info_owner_idx ON assets_info (owner);


CREATE TABLE IF NOT EXISTS all_expirations(
    type TEXT,
    object_id TEXT,
    block_index INTEGER);
CREATE INDEX IF NOT EXISTS all_expirations_type_idx ON all_expirations (type);
CREATE INDEX IF NOT EXISTS all_expirations_block_index_idx ON all_expirations (block_index);

INSERT INTO all_expirations (object_id, block_index, type)
SELECT order_hash AS object_id, block_index, 'order' AS type
FROM order_expirations;
INSERT INTO all_expirations (object_id, block_index, type)
SELECT order_match_id AS object_id, block_index, 'order_match' AS type
FROM order_match_expirations;
INSERT INTO all_expirations (object_id, block_index, type)
SELECT bet_hash AS object_id, block_index, 'bet' AS type
FROM bet_expirations;
INSERT INTO all_expirations (object_id, block_index, type)
SELECT bet_match_id AS object_id, block_index, 'bet_match' AS type
FROM bet_match_expirations;
INSERT INTO all_expirations (object_id, block_index, type)
SELECT rps_hash AS object_id, block_index, 'rps' AS type
FROM rps_expirations;
INSERT INTO all_expirations (object_id, block_index, type)
SELECT rps_match_id AS object_id, block_index, 'rps_match' AS type
FROM rps_match_expirations;

CREATE TABLE IF NOT EXISTS address_events (
    address TEXT,
    event_index INTEGER
);
CREATE INDEX IF NOT EXISTS address_events_address_idx ON address_events (address);
CREATE INDEX IF NOT EXISTS address_events_event_index_idx ON address_events (event_index);


CREATE TABLE IF NOT EXISTS events_count(
        event TEXT PRIMARY KEY,
        count INTEGER);
CREATE INDEX IF NOT EXISTS events_count_count_idx ON events_count (count);


INSERT INTO events_count (event, count)
    SELECT event, COUNT(*) AS counter
    FROM messages
    GROUP BY event;


UPDATE fairminters SET 
    earned_quantity = (
        SELECT SUM(earn_quantity) 
        FROM fairmints 
        WHERE fairmints.fairminter_tx_hash = fairminters.tx_hash
    ),
    paid_quantity = (
        SELECT SUM(paid_quantity) 
        FROM fairmints 
        WHERE fairmints.fairminter_tx_hash = fairminters.tx_hash
    ),
    commission = (
        SELECT SUM(commission) 
        FROM fairmints 
        WHERE fairmints.fairminter_tx_hash = fairminters.tx_hash
    );


UPDATE issuances SET 
    asset_events = (
        SELECT
            substr(
                bindings, 
                instr(bindings, '"asset_events":') + 16, 
                instr(substr(bindings, instr(bindings, '"asset_events":') + 16), '"') - 1
            )
        FROM messages
        WHERE messages.tx_hash = issuances.tx_hash
    );

UPDATE dispenses SET 
    btc_amount = (
        SELECT
        CAST (
            substr(
                bindings,
                instr(bindings, '"btc_amount":') + 13,
                instr(substr(bindings, instr(bindings, '"btc_amount":') + 13), ',') - 1
            )
            AS INTEGER
        )
        FROM messages
        WHERE messages.tx_hash = dispenses.tx_hash
    );

PRAGMA foreign_keys=ON;