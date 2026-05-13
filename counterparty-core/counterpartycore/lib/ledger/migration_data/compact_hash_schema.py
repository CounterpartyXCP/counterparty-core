"""Schema rewrites used by the compact-hash storage migration.

This module owns the bulky declarative data (indexes, triggers, views,
custom INSERT/SELECT clauses) that the ``0010.compact_hash_storage.py``
migration applies. The companion ``compact_hash_tables`` module owns the
CREATE TABLE statements; together they replace what used to be a single
oversized migration file.
"""

from counterpartycore.lib.ledger.migration_data.compact_hash_tables import TABLE_REWRITES

__all__ = [
    "CUSTOM_INSERT_SELECT",
    "INDEXES_AFTER_REWRITE",
    "NO_UPDATE_TRIGGERS",
    "TABLE_REWRITES",
    "TRIGGERS_AFTER_REWRITE",
    "VIEWS_AFTER_REWRITE",
]


# Triggers that enforce the "no UPDATE" contract on every history table.
# Listed here so both the migration (drop at start, recreate at end) and the
# trigger DDL builder below share a single source of truth.
NO_UPDATE_TRIGGERS = [
    "block_update_balances",
    "block_update_credits",
    "block_update_debits",
    "block_update_messages",
    "block_update_order_match_expirations",
    "block_update_order_matches",
    "block_update_order_expirations",
    "block_update_orders",
    "block_update_bet_match_expirations",
    "block_update_bet_matches",
    "block_update_bet_match_resolutions",
    "block_update_bet_expirations",
    "block_update_bets",
    "block_update_broadcasts",
    "block_update_btcpays",
    "block_update_burns",
    "block_update_cancels",
    "block_update_dividends",
    "block_update_rps_match_expirations",
    "block_update_rps_expirations",
    "block_update_rpsresolves",
    "block_update_rps_matches",
    "block_update_rps",
    "block_update_destructions",
    "block_update_assets",
    "block_update_addresses",
    "block_update_sweeps",
    "block_update_dispensers",
    "block_update_dispenser_refills",
    "block_update_fairmints",
    "block_update_transaction_count",
    "block_update_fairminters",
    "block_update_dispenses",
    "block_update_sends",
    "block_update_issuances",
]


# Indexes that need to be recreated on the new (BLOB) tables. These mirror the
# index set from ``0001.initial_migration.sql`` plus the messages_tx_index_idx
# replacement for the runtime ``messages_tx_hash_idx``.
INDEXES_AFTER_REWRITE = [
    # blocks
    "CREATE INDEX IF NOT EXISTS blocks_block_index_idx ON blocks (block_index)",
    "CREATE INDEX IF NOT EXISTS blocks_block_index_block_hash_idx ON blocks (block_index, block_hash)",
    "CREATE INDEX IF NOT EXISTS blocks_ledger_hash_idx ON blocks (ledger_hash)",
    # transactions
    "CREATE INDEX IF NOT EXISTS transactions_block_index_idx ON transactions (block_index)",
    "CREATE INDEX IF NOT EXISTS transactions_tx_index_idx ON transactions (tx_index)",
    "CREATE INDEX IF NOT EXISTS transactions_tx_hash_idx ON transactions (tx_hash)",
    "CREATE INDEX IF NOT EXISTS transactions_block_index_tx_index_idx ON transactions (block_index, tx_index)",
    "CREATE INDEX IF NOT EXISTS transactions_tx_index_tx_hash_block_index_idx ON transactions (tx_index, tx_hash, block_index)",
    "CREATE INDEX IF NOT EXISTS transactions_source_idx ON transactions (source)",
    "CREATE INDEX IF NOT EXISTS transactions_transaction_type_idx ON transactions (transaction_type)",
    # mempool_transactions
    "CREATE INDEX IF NOT EXISTS mempool_transactions_block_index_idx ON mempool_transactions (block_index)",
    "CREATE INDEX IF NOT EXISTS mempool_transactions_tx_index_idx ON mempool_transactions (tx_index)",
    "CREATE INDEX IF NOT EXISTS mempool_transactions_tx_hash_idx ON mempool_transactions (tx_hash)",
    "CREATE INDEX IF NOT EXISTS mempool_transactions_block_index_tx_index_idx ON mempool_transactions (block_index, tx_index)",
    "CREATE INDEX IF NOT EXISTS mempool_transactions_tx_index_tx_hash_block_index_idx ON mempool_transactions (tx_index, tx_hash, block_index)",
    "CREATE INDEX IF NOT EXISTS mempool_transactions_source_idx ON mempool_transactions (source)",
    # messages: rebuild the same index set the runtime helper
    # ``parser.blocks.create_events_indexes`` would create. The migration
    # drops and recreates the table, which destroys the original indexes;
    # nodes running ``--api-only`` (load test, API-only deployments) never
    # invoke the parser path that lazily rebuilds them, so every read on
    # ``messages`` would fall back to a full table scan -- on a 30M-row
    # ledger that turns ``/v2/transactions/<tx_hash>/events`` into a
    # 6-20s request. Recreating the indexes here keeps both code paths
    # (parser catch-up and api-only) covered.
    "CREATE INDEX IF NOT EXISTS messages_block_index_idx ON messages (block_index)",
    "CREATE INDEX IF NOT EXISTS messages_block_index_message_index_idx ON messages (block_index, message_index)",
    "CREATE INDEX IF NOT EXISTS messages_block_index_event_idx ON messages (block_index, event)",
    "CREATE INDEX IF NOT EXISTS messages_event_idx ON messages (event)",
    "CREATE INDEX IF NOT EXISTS messages_tx_index_idx ON messages (tx_index)",
    "CREATE INDEX IF NOT EXISTS messages_event_hash_idx ON messages (event_hash)",
    # orders
    "CREATE INDEX IF NOT EXISTS orders_block_index_idx ON orders (block_index)",
    "CREATE INDEX IF NOT EXISTS orders_tx_index_tx_hash_idx ON orders (tx_index, tx_hash)",
    "CREATE INDEX IF NOT EXISTS orders_give_asset_idx ON orders (give_asset)",
    "CREATE INDEX IF NOT EXISTS orders_tx_hash_idx ON orders (tx_hash)",
    "CREATE INDEX IF NOT EXISTS orders_expire_index_idx ON orders (expire_index)",
    "CREATE INDEX IF NOT EXISTS orders_get_asset_give_asset_idx ON orders (get_asset, give_asset)",
    "CREATE INDEX IF NOT EXISTS orders_status_idx ON orders (status)",
    "CREATE INDEX IF NOT EXISTS orders_source_give_asset_idx ON orders (source, give_asset)",
    "CREATE INDEX IF NOT EXISTS orders_get_quantity_idx ON orders (get_quantity)",
    "CREATE INDEX IF NOT EXISTS orders_give_quantity_idx ON orders (give_quantity)",
    # order_matches
    "CREATE INDEX IF NOT EXISTS order_matches_block_index_idx ON order_matches (block_index)",
    "CREATE INDEX IF NOT EXISTS order_matches_forward_asset_idx ON order_matches (forward_asset)",
    "CREATE INDEX IF NOT EXISTS order_matches_backward_asset_idx ON order_matches (backward_asset)",
    "CREATE INDEX IF NOT EXISTS order_matches_id_idx ON order_matches (id)",
    "CREATE INDEX IF NOT EXISTS order_matches_tx0_address_forward_asset_idx ON order_matches (tx0_address, forward_asset)",
    "CREATE INDEX IF NOT EXISTS order_matches_tx1_address_backward_asset_idx ON order_matches (tx1_address, backward_asset)",
    "CREATE INDEX IF NOT EXISTS order_matches_match_expire_index_idx ON order_matches (match_expire_index)",
    "CREATE INDEX IF NOT EXISTS order_matches_status_idx ON order_matches (status)",
    "CREATE INDEX IF NOT EXISTS order_matches_tx0_hash_idx ON order_matches (tx0_hash)",
    "CREATE INDEX IF NOT EXISTS order_matches_tx1_hash_idx ON order_matches (tx1_hash)",
    # order_expirations
    "CREATE INDEX IF NOT EXISTS order_expirations_block_index_idx ON order_expirations (block_index)",
    "CREATE INDEX IF NOT EXISTS order_expirations_source_idx ON order_expirations (source)",
    # btcpays
    "CREATE INDEX IF NOT EXISTS btcpays_block_index_idx ON btcpays (block_index)",
    "CREATE INDEX IF NOT EXISTS btcpays_source_idx ON btcpays (source)",
    "CREATE INDEX IF NOT EXISTS btcpays_destination_idx ON btcpays (destination)",
    # issuances
    "CREATE INDEX IF NOT EXISTS issuances_block_index_idx ON issuances (block_index)",
    "CREATE INDEX IF NOT EXISTS issuances_asset_status_idx ON issuances (asset, status)",
    "CREATE INDEX IF NOT EXISTS issuances_status_idx ON issuances (status)",
    "CREATE INDEX IF NOT EXISTS issuances_source_idx ON issuances (source)",
    "CREATE INDEX IF NOT EXISTS issuances_asset_longname_idx ON issuances (asset_longname)",
    "CREATE INDEX IF NOT EXISTS issuances_status_asset_tx_index_idx ON issuances (status, asset, tx_index DESC)",
    "CREATE INDEX IF NOT EXISTS issuances_issuer_idx ON issuances (issuer)",
    "CREATE INDEX IF NOT EXISTS issuances_status_asset_longname_tx_index_idx ON issuances (status, asset_longname, tx_index DESC)",
    # broadcasts
    "CREATE INDEX IF NOT EXISTS broadcasts_block_index_idx ON broadcasts (block_index)",
    "CREATE INDEX IF NOT EXISTS broadcasts_status_source_idx ON broadcasts (status, source)",
    "CREATE INDEX IF NOT EXISTS broadcasts_status_source_tx_index_idx ON broadcasts (status, source, tx_index)",
    "CREATE INDEX IF NOT EXISTS broadcasts_timestamp_idx ON broadcasts (timestamp)",
    # bets
    "CREATE INDEX IF NOT EXISTS bets_block_index_idx ON bets (block_index)",
    "CREATE INDEX IF NOT EXISTS bets_tx_index_tx_hash_idx ON bets (tx_index, tx_hash)",
    "CREATE INDEX IF NOT EXISTS bets_status_idx ON bets (status)",
    "CREATE INDEX IF NOT EXISTS bets_tx_hash_idx ON bets (tx_hash)",
    "CREATE INDEX IF NOT EXISTS bets_feed_address_idx ON bets (feed_address)",
    "CREATE INDEX IF NOT EXISTS bets_expire_index_idx ON bets (expire_index)",
    "CREATE INDEX IF NOT EXISTS bets_feed_address_bet_type_idx ON bets (feed_address, bet_type)",
    # bet_matches
    "CREATE INDEX IF NOT EXISTS bet_matches_block_index_idx ON bet_matches (block_index)",
    "CREATE INDEX IF NOT EXISTS bet_matches_id_idx ON bet_matches (id)",
    "CREATE INDEX IF NOT EXISTS bet_matches_status_idx ON bet_matches (status)",
    "CREATE INDEX IF NOT EXISTS bet_matches_deadline_idx ON bet_matches (deadline)",
    "CREATE INDEX IF NOT EXISTS bet_matches_tx0_address_idx ON bet_matches (tx0_address)",
    "CREATE INDEX IF NOT EXISTS bet_matches_tx1_address_idx ON bet_matches (tx1_address)",
    # bet_expirations
    "CREATE INDEX IF NOT EXISTS bet_expirations_block_index_idx ON bet_expirations (block_index)",
    "CREATE INDEX IF NOT EXISTS bet_expirations_source_idx ON bet_expirations (source)",
    # dividends
    "CREATE INDEX IF NOT EXISTS dividends_block_index_idx ON dividends (block_index)",
    "CREATE INDEX IF NOT EXISTS dividends_source_idx ON dividends (source)",
    "CREATE INDEX IF NOT EXISTS dividends_asset_idx ON dividends (asset)",
    # burns
    "CREATE INDEX IF NOT EXISTS burns_status_idx ON burns (status)",
    "CREATE INDEX IF NOT EXISTS burns_source_idx ON burns (source)",
    # cancels
    "CREATE INDEX IF NOT EXISTS cancels_block_index_idx ON cancels (block_index)",
    "CREATE INDEX IF NOT EXISTS cancels_source_idx ON cancels (source)",
    "CREATE INDEX IF NOT EXISTS cancels_offer_tx_index_idx ON cancels (offer_tx_index)",
    # rps
    "CREATE INDEX IF NOT EXISTS rps_source_idx ON rps (source)",
    "CREATE INDEX IF NOT EXISTS rps_wager_possible_moves_idx ON rps (wager, possible_moves)",
    "CREATE INDEX IF NOT EXISTS rps_status_idx ON rps (status)",
    "CREATE INDEX IF NOT EXISTS rps_tx_index_idx ON rps (tx_index)",
    "CREATE INDEX IF NOT EXISTS rps_tx_hash_idx ON rps (tx_hash)",
    "CREATE INDEX IF NOT EXISTS rps_expire_index_idx ON rps (expire_index)",
    "CREATE INDEX IF NOT EXISTS rps_tx_index_tx_hash_idx ON rps (tx_index, tx_hash)",
    # rps_matches
    "CREATE INDEX IF NOT EXISTS rps_matches_tx0_address_idx ON rps_matches (tx0_address)",
    "CREATE INDEX IF NOT EXISTS rps_matches_tx1_address_idx ON rps_matches (tx1_address)",
    "CREATE INDEX IF NOT EXISTS rps_matches_status_idx ON rps_matches (status)",
    "CREATE INDEX IF NOT EXISTS rps_matches_id_idx ON rps_matches (id)",
    "CREATE INDEX IF NOT EXISTS rps_matches_match_expire_index_idx ON rps_matches (match_expire_index)",
    # rps_expirations
    "CREATE INDEX IF NOT EXISTS rps_expirations_block_index_idx ON rps_expirations (block_index)",
    "CREATE INDEX IF NOT EXISTS rps_expirations_source_idx ON rps_expirations (source)",
    # rpsresolves
    "CREATE INDEX IF NOT EXISTS rpsresolves_block_index_idx ON rpsresolves (block_index)",
    "CREATE INDEX IF NOT EXISTS rpsresolves_source_idx ON rpsresolves (source)",
    "CREATE INDEX IF NOT EXISTS rpsresolves_rps_match_id_idx ON rpsresolves (rps_match_id)",
    # sweeps
    "CREATE INDEX IF NOT EXISTS sweeps_block_index_idx ON sweeps (block_index)",
    "CREATE INDEX IF NOT EXISTS sweeps_source_idx ON sweeps (source)",
    "CREATE INDEX IF NOT EXISTS sweeps_destination_idx ON sweeps (destination)",
    "CREATE INDEX IF NOT EXISTS sweeps_memo_idx ON sweeps (memo)",
    # dispensers
    "CREATE INDEX IF NOT EXISTS dispensers_block_index_idx ON dispensers (block_index)",
    "CREATE INDEX IF NOT EXISTS dispensers_source_idx ON dispensers (source)",
    "CREATE INDEX IF NOT EXISTS dispensers_asset_idx ON dispensers (asset)",
    "CREATE INDEX IF NOT EXISTS dispensers_tx_index_idx ON dispensers (tx_index)",
    "CREATE INDEX IF NOT EXISTS dispensers_tx_hash_idx ON dispensers (tx_hash)",
    "CREATE INDEX IF NOT EXISTS dispensers_status_idx ON dispensers (status)",
    "CREATE INDEX IF NOT EXISTS dispensers_give_remaining_idx ON dispensers (give_remaining)",
    "CREATE INDEX IF NOT EXISTS dispensers_status_block_index_idx ON dispensers (status, block_index)",
    "CREATE INDEX IF NOT EXISTS dispensers_source_origin_idx ON dispensers (source, origin)",
    "CREATE INDEX IF NOT EXISTS dispensers_source_asset_origin_status_idx ON dispensers (source, asset, origin, status)",
    "CREATE INDEX IF NOT EXISTS dispensers_last_status_tx_hash_idx ON dispensers (last_status_tx_hash)",
    "CREATE INDEX IF NOT EXISTS dispensers_close_block_index_status_idx ON dispensers (close_block_index, status)",
    "CREATE INDEX IF NOT EXISTS dispensers_give_quantity_idx ON dispensers (give_quantity)",
    # dispenses
    "CREATE INDEX IF NOT EXISTS dispenses_tx_hash_idx ON dispenses (tx_hash)",
    "CREATE INDEX IF NOT EXISTS dispenses_block_index_idx ON dispenses (block_index)",
    "CREATE INDEX IF NOT EXISTS dispenses_dispenser_tx_index_idx ON dispenses (dispenser_tx_index)",
    "CREATE INDEX IF NOT EXISTS dispenses_asset_idx ON dispenses (asset)",
    "CREATE INDEX IF NOT EXISTS dispenses_source_idx ON dispenses (source)",
    "CREATE INDEX IF NOT EXISTS dispenses_destination_idx ON dispenses (destination)",
    "CREATE INDEX IF NOT EXISTS dispenses_dispense_quantity_idx ON dispenses (dispense_quantity)",
    # dispenser_refills
    "CREATE INDEX IF NOT EXISTS dispenser_refills_tx_hash_idx ON dispenser_refills (tx_hash)",
    "CREATE INDEX IF NOT EXISTS dispenser_refills_block_index_idx ON dispenser_refills (block_index)",
    # fairminters
    "CREATE INDEX IF NOT EXISTS fairminters_tx_hash_idx ON fairminters (tx_hash)",
    "CREATE INDEX IF NOT EXISTS fairminters_block_index_idx ON fairminters (block_index)",
    "CREATE INDEX IF NOT EXISTS fairminters_asset_idx ON fairminters (asset)",
    "CREATE INDEX IF NOT EXISTS fairminters_asset_longname_idx ON fairminters (asset_longname)",
    "CREATE INDEX IF NOT EXISTS fairminters_asset_parent_idx ON fairminters (asset_parent)",
    "CREATE INDEX IF NOT EXISTS fairminters_source_idx ON fairminters (source)",
    "CREATE INDEX IF NOT EXISTS fairminters_status_idx ON fairminters (status)",
    # fairmints
    "CREATE INDEX IF NOT EXISTS fairmints_tx_hash_idx ON fairmints (tx_hash)",
    "CREATE INDEX IF NOT EXISTS fairmints_block_index_idx ON fairmints (block_index)",
    "CREATE INDEX IF NOT EXISTS fairmints_fairminter_tx_index_idx ON fairmints (fairminter_tx_index)",
    "CREATE INDEX IF NOT EXISTS fairmints_asset_idx ON fairmints (asset)",
    "CREATE INDEX IF NOT EXISTS fairmints_source_idx ON fairmints (source)",
    "CREATE INDEX IF NOT EXISTS fairmints_status_idx ON fairmints (status)",
    # sends
    "CREATE INDEX IF NOT EXISTS sends_block_index_idx ON sends (block_index)",
    "CREATE INDEX IF NOT EXISTS sends_source_idx ON sends (source)",
    "CREATE INDEX IF NOT EXISTS sends_destination_idx ON sends (destination)",
    "CREATE INDEX IF NOT EXISTS sends_asset_idx ON sends (asset)",
    "CREATE INDEX IF NOT EXISTS sends_memo_idx ON sends (memo)",
    "CREATE INDEX IF NOT EXISTS sends_block_index_send_type_idx ON sends (block_index, send_type)",
    "CREATE INDEX IF NOT EXISTS sends_asset_send_type_idx ON sends (asset, send_type)",
    "CREATE INDEX IF NOT EXISTS sends_status_idx ON sends (status)",
    "CREATE INDEX IF NOT EXISTS sends_send_type_idx ON sends (send_type)",
    "CREATE INDEX IF NOT EXISTS sends_send_type ON sends (send_type)",
    "CREATE INDEX IF NOT EXISTS sends_source_address ON sends (source_address)",
    "CREATE INDEX IF NOT EXISTS sends_destination_address ON sends (destination_address)",
    # destructions
    "CREATE INDEX IF NOT EXISTS destructions_status_idx ON destructions (status)",
    "CREATE INDEX IF NOT EXISTS destructions_source_idx ON destructions (source)",
    "CREATE INDEX IF NOT EXISTS destructions_asset_idx ON destructions (asset)",
    # pools
    "CREATE INDEX IF NOT EXISTS pools_asset_a_asset_b_idx ON pools (asset_a, asset_b)",
    "CREATE INDEX IF NOT EXISTS pools_lp_asset_idx ON pools (lp_asset)",
    "CREATE INDEX IF NOT EXISTS pools_block_index_idx ON pools (block_index)",
    # pool_deposits
    "CREATE INDEX IF NOT EXISTS pool_deposits_tx_hash_idx ON pool_deposits (tx_hash)",
    "CREATE INDEX IF NOT EXISTS pool_deposits_source_status_idx ON pool_deposits (source, status)",
    "CREATE INDEX IF NOT EXISTS pool_deposits_block_index_idx ON pool_deposits (block_index)",
    "CREATE INDEX IF NOT EXISTS pool_deposits_asset_a_asset_b_status_idx ON pool_deposits (asset_a, asset_b, status)",
    # pool_withdrawals
    "CREATE INDEX IF NOT EXISTS pool_withdrawals_tx_hash_idx ON pool_withdrawals (tx_hash)",
    "CREATE INDEX IF NOT EXISTS pool_withdrawals_source_status_idx ON pool_withdrawals (source, status)",
    "CREATE INDEX IF NOT EXISTS pool_withdrawals_block_index_idx ON pool_withdrawals (block_index)",
    "CREATE INDEX IF NOT EXISTS pool_withdrawals_asset_a_asset_b_status_idx ON pool_withdrawals (asset_a, asset_b, status)",
    # pool_matches
    "CREATE INDEX IF NOT EXISTS pool_matches_tx_hash_idx ON pool_matches (tx_hash)",
    "CREATE INDEX IF NOT EXISTS pool_matches_source_idx ON pool_matches (source)",
    "CREATE INDEX IF NOT EXISTS pool_matches_block_index_idx ON pool_matches (block_index)",
    "CREATE INDEX IF NOT EXISTS pool_matches_asset_a_asset_b_idx ON pool_matches (asset_a, asset_b)",
    "CREATE INDEX IF NOT EXISTS pool_matches_order_tx_index_idx ON pool_matches (order_tx_index)",
]


# Triggers we recreate at the end (every BEFORE UPDATE trigger from
# 0001+0006). ``messages`` and others now reference the new tables; SQLite
# doesn't care that the table was recreated as long as the trigger names are
# unique.
TRIGGERS_AFTER_REWRITE = [
    f"CREATE TRIGGER IF NOT EXISTS {name} BEFORE UPDATE ON {name.replace('block_update_', '')} "
    'BEGIN SELECT RAISE(FAIL, "UPDATES NOT ALLOWED"); END'
    for name in NO_UPDATE_TRIGGERS
]


VIEWS_AFTER_REWRITE = [
    # all_transactions: same shape as 0002 but rebuilt against the new schema.
    # ``block_hash`` is no longer a column on ``transactions``; rebuild it via
    # JOIN against ``blocks``.
    """CREATE VIEW IF NOT EXISTS all_transactions AS
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
        t.tx_index,
        t.tx_hash,
        t.block_index,
        b.block_hash AS block_hash,
        t.block_time,
        t.source,
        t.destination,
        t.btc_amount,
        t.fee,
        t.data,
        t.supported,
        t.utxos_info,
        t.transaction_type,
        TRUE as confirmed
    FROM transactions t
    LEFT JOIN blocks b ON b.block_index = t.block_index""",
    """CREATE VIEW IF NOT EXISTS transactions_with_status AS
    SELECT
        t.tx_index as rowid,
        t.tx_index,
        t.tx_hash,
        t.block_index,
        b.block_hash AS block_hash,
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
    LEFT JOIN blocks b ON b.block_index = t.block_index
    LEFT JOIN transactions_status ts ON t.tx_index = ts.tx_index""",
    """CREATE VIEW IF NOT EXISTS all_transactions_with_status AS
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
    LEFT JOIN transactions_status ts ON t.tx_index = ts.tx_index""",
    # all_expirations: BLOB hashes; expose hex for clients via hex_lower UDF.
    """CREATE VIEW IF NOT EXISTS all_expirations AS
        SELECT 'order' AS type, hex_lower(order_hash) AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_order_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM order_expirations
         UNION ALL
        SELECT 'order_match' AS type, order_match_id AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_order_match_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM order_match_expirations
         UNION ALL
        SELECT 'bet' AS type, hex_lower(bet_hash) AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_bet_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM bet_expirations
         UNION ALL
        SELECT 'bet_match' AS type, bet_match_id AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_bet_match_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM bet_match_expirations
         UNION ALL
        SELECT 'rps' AS type, hex_lower(rps_hash) AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_rps_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM rps_expirations
         UNION ALL
        SELECT 'rps_match' AS type, rps_match_id AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_rps_match_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM rps_match_expirations""",
    """CREATE VIEW IF NOT EXISTS all_holders AS
        SELECT asset, address, quantity, NULL AS escrow, MAX(rowid) AS rowid,
            CONCAT('balances_', CAST(rowid AS VARCHAR)) AS cursor_id, 'balances' AS holding_type, NULL AS status
        FROM balances
        GROUP BY asset, address
         UNION ALL
        SELECT * FROM (
            SELECT give_asset AS asset, source AS address, give_remaining AS quantity, hex_lower(tx_hash) AS escrow,
                MAX(rowid) AS rowid, CONCAT('open_order_', CAST(rowid AS VARCHAR)) AS cursor_id,
                'open_order' AS holding_type, status
            FROM orders
            GROUP BY tx_hash
        ) WHERE status = 'open'
         UNION ALL
        SELECT * FROM (
            SELECT forward_asset AS asset, tx0_address AS address, forward_quantity AS quantity,
                id AS escrow, MAX(rowid) AS rowid, CONCAT('order_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
                'pending_order_match' AS holding_type, status
            FROM order_matches
            GROUP BY id
        ) WHERE status = 'pending'
         UNION ALL
        SELECT * FROM (
            SELECT backward_asset AS asset, tx1_address AS address, backward_quantity AS quantity,
                id AS escrow, MAX(rowid) AS rowid, CONCAT('order_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
                'pending_order_match' AS holding_type, status
            FROM order_matches
            GROUP BY id
        ) WHERE status = 'pending'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, source AS address, wager_remaining AS quantity,
            hex_lower(tx_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('open_bet_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'open_bet' AS holding_type, status
            FROM bets
            GROUP BY tx_hash
        ) WHERE status = 'open'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, tx0_address AS address, forward_quantity AS quantity,
            id AS escrow, MAX(rowid) AS rowid, CONCAT('bet_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'pending_bet_match' AS holding_type, status
            FROM bet_matches
            GROUP BY id
        ) WHERE status = 'pending'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, tx1_address AS address, backward_quantity AS quantity,
            id AS escrow, MAX(rowid) AS rowid, CONCAT('bet_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'pending_bet_match' AS holding_type, status
            FROM bet_matches
            GROUP BY id
        ) WHERE status = 'pending'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, source AS address, wager AS quantity,
            hex_lower(tx_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('open_rps_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'open_rps' AS holding_type, status
            FROM rps
            GROUP BY tx_hash
        ) WHERE status = 'open'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, tx0_address AS address, wager AS quantity,
            id AS escrow, MAX(rowid) AS rowid, CONCAT('rps_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'pending_rps_match' AS holding_type, status
            FROM rps_matches
            GROUP BY id
        ) WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, tx1_address AS address, wager AS quantity,
            id AS escrow, MAX(rowid) AS rowid, CONCAT('rps_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'pending_rps_match' AS holding_type, status
            FROM rps_matches
            GROUP BY id
        ) WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
         UNION ALL
        SELECT * FROM (
            SELECT asset, source AS address, give_remaining AS quantity,
            hex_lower(tx_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('open_dispenser_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'open_dispenser' AS holding_type, status
            FROM dispensers
            GROUP BY source, asset
        ) WHERE status = 0""",
]


# ---------------------------------------------------------------------------
# Custom INSERT SELECT logic for tables whose row shape changes between the
# old and new schema (column drops / ``*_tx_hash`` -> ``*_tx_index`` FKs).
# ---------------------------------------------------------------------------

CUSTOM_INSERT_SELECT = {
    # messages: drop tx_hash, add tx_index via JOIN; convert event_hash hex
    # to BLOB.
    "messages": (
        # SELECT clause (must produce rows in the same column order as the
        # new CREATE TABLE)
        """
        SELECT
            m.message_index,
            m.block_index,
            m.command,
            m.category,
            m.bindings,
            m.timestamp,
            m.event,
            t.tx_index AS tx_index,
            __hex_to_blob(m.event_hash) AS event_hash
        FROM messages_old m
        LEFT JOIN transactions_old t ON t.tx_hash = m.tx_hash
        """
    ),
    # transactions: drop block_hash
    "transactions": (
        """
        SELECT
            tx_index,
            __hex_to_blob(tx_hash) AS tx_hash,
            block_index,
            block_time,
            source,
            destination,
            btc_amount,
            fee,
            data,
            supported,
            utxos_info,
            transaction_type
        FROM transactions_old
        """
    ),
    # cancels: replace offer_hash with offer_tx_index via JOIN
    "cancels": (
        """
        SELECT
            c.tx_index,
            __hex_to_blob(c.tx_hash) AS tx_hash,
            c.block_index,
            c.source,
            t.tx_index AS offer_tx_index,
            c.status
        FROM cancels_old c
        LEFT JOIN transactions_old t ON t.tx_hash = c.offer_hash
        """
    ),
    # dispenses: replace dispenser_tx_hash with dispenser_tx_index
    "dispenses": (
        """
        SELECT
            d.tx_index,
            d.dispense_index,
            __hex_to_blob(d.tx_hash) AS tx_hash,
            d.block_index,
            d.source,
            d.destination,
            d.asset,
            d.dispense_quantity,
            t.tx_index AS dispenser_tx_index,
            d.btc_amount
        FROM dispenses_old d
        LEFT JOIN transactions_old t ON t.tx_hash = d.dispenser_tx_hash
        """
    ),
    # dispenser_refills: replace dispenser_tx_hash with dispenser_tx_index
    "dispenser_refills": (
        """
        SELECT
            r.tx_index,
            __hex_to_blob(r.tx_hash) AS tx_hash,
            r.block_index,
            r.source,
            r.destination,
            r.asset,
            r.dispense_quantity,
            t.tx_index AS dispenser_tx_index
        FROM dispenser_refills_old r
        LEFT JOIN transactions_old t ON t.tx_hash = r.dispenser_tx_hash
        """
    ),
    # fairmints: replace fairminter_tx_hash with fairminter_tx_index
    "fairmints": (
        """
        SELECT
            __hex_to_blob(f.tx_hash) AS tx_hash,
            f.tx_index,
            f.block_index,
            f.source,
            t.tx_index AS fairminter_tx_index,
            f.asset,
            f.earn_quantity,
            f.paid_quantity,
            f.commission,
            f.status
        FROM fairmints_old f
        LEFT JOIN transactions_old t ON t.tx_hash = f.fairminter_tx_hash
        """
    ),
    # pool_matches: replace order_tx_hash with order_tx_index
    "pool_matches": (
        """
        SELECT
            p.tx_index,
            __hex_to_blob(p.tx_hash) AS tx_hash,
            p.block_index,
            p.source,
            p.asset_a,
            p.asset_b,
            p.forward_asset,
            p.forward_quantity,
            p.backward_asset,
            p.backward_quantity,
            p.fee_quantity,
            p.fee_bps,
            t.tx_index AS order_tx_index,
            p.status
        FROM pool_matches_old p
        LEFT JOIN transactions_old t ON t.tx_hash = p.order_tx_hash
        """
    ),
    # transaction_outputs: drop tx_hash entirely (resolved via tx_index FK)
    "transaction_outputs": (
        """
        SELECT
            tx_index,
            block_index,
            out_index,
            destination,
            btc_amount
        FROM transaction_outputs_old
        """
    ),
}
