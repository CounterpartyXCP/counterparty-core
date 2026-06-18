"""Schema rewrites used by the compact-hash storage migration.

This module owns the bulky declarative data (indexes, triggers, views,
custom INSERT/SELECT clauses) that the ``0010.compact_hash_storage.py``
migration applies. The companion ``compact_hash_tables`` module owns the
CREATE TABLE statements; together they replace what used to be a single
oversized migration file.
"""

from counterpartycore.lib.ledger.migration_data.compact_hash_tables import (
    ADDRESS_NAME_COLUMNS,
    ASSET_NAME_COLUMNS,
    TABLE_REWRITES,
    UTXO_SPLIT_COLUMNS,
)

__all__ = [
    "ADDRESS_NAME_COLUMNS",
    "ASSET_NAME_COLUMNS",
    "CUSTOM_INSERT_SELECT",
    "INDEXES_AFTER_REWRITE",
    "NO_UPDATE_TRIGGERS",
    "TABLE_REWRITES",
    "TRIGGERS_AFTER_REWRITE",
    "UTXO_SPLIT_COLUMNS",
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
    "block_update_address_list",
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
    # assets (asset_index is the INTEGER PRIMARY KEY, auto-indexed)
    "CREATE INDEX IF NOT EXISTS assets_asset_name_idx ON assets (asset_name)",
    "CREATE INDEX IF NOT EXISTS assets_asset_id_idx ON assets (asset_id)",
    "CREATE UNIQUE INDEX IF NOT EXISTS assets_asset_longname_idx ON assets (asset_longname)",
    # address_list (address_id is the INTEGER PRIMARY KEY, auto-indexed). The
    # ``address`` UNIQUE constraint already creates an index; this mirrors the
    # explicit assets_asset_name_idx for the string->id resolver lookups.
    "CREATE INDEX IF NOT EXISTS address_list_address_idx ON address_list (address)",
    # addresses (options/REQUIRE_MEMO history). ``address`` is now the INTEGER FK,
    # but ``get_addresses`` still filters ``WHERE address = ? GROUP BY address`` on a
    # consensus path (memo-gated sends, options broadcasts), so the original
    # addresses_address_idx must be recreated or those lookups become full scans.
    "CREATE INDEX IF NOT EXISTS addresses_address_idx ON addresses (address)",
    # debits
    "CREATE INDEX IF NOT EXISTS debits_address_idx ON debits (address)",
    "CREATE INDEX IF NOT EXISTS debits_asset_idx ON debits (asset)",
    "CREATE INDEX IF NOT EXISTS debits_block_index_idx ON debits (block_index)",
    "CREATE INDEX IF NOT EXISTS debits_event_idx ON debits (event)",
    "CREATE INDEX IF NOT EXISTS debits_action_idx ON debits (action)",
    "CREATE INDEX IF NOT EXISTS debits_quantity_idx ON debits (quantity)",
    "CREATE INDEX IF NOT EXISTS debits_utxo_idx ON debits (utxo_tx_hash, utxo_vout)",
    "CREATE INDEX IF NOT EXISTS debits_utxo_address_idx ON debits (utxo_address)",
    # credits
    "CREATE INDEX IF NOT EXISTS credits_address_idx ON credits (address)",
    "CREATE INDEX IF NOT EXISTS credits_asset_idx ON credits (asset)",
    "CREATE INDEX IF NOT EXISTS credits_block_index_idx ON credits (block_index)",
    "CREATE INDEX IF NOT EXISTS credits_event_idx ON credits (event)",
    "CREATE INDEX IF NOT EXISTS credits_calling_function_idx ON credits (calling_function)",
    "CREATE INDEX IF NOT EXISTS credits_quantity_idx ON credits (quantity)",
    "CREATE INDEX IF NOT EXISTS credits_utxo_idx ON credits (utxo_tx_hash, utxo_vout)",
    "CREATE INDEX IF NOT EXISTS credits_utxo_address_idx ON credits (utxo_address)",
    # balances
    "CREATE INDEX IF NOT EXISTS balances_address_asset_idx ON balances (address, asset)",
    "CREATE INDEX IF NOT EXISTS balances_address_idx ON balances (address)",
    "CREATE INDEX IF NOT EXISTS balances_asset_idx ON balances (asset)",
    "CREATE INDEX IF NOT EXISTS balances_block_index_idx ON balances (block_index)",
    "CREATE INDEX IF NOT EXISTS balances_quantity_idx ON balances (quantity)",
    "CREATE INDEX IF NOT EXISTS balances_utxo_idx ON balances (utxo_tx_hash, utxo_vout)",
    "CREATE INDEX IF NOT EXISTS balances_utxo_address_idx ON balances (utxo_address)",
    "CREATE INDEX IF NOT EXISTS balances_utxo_asset_idx ON balances (utxo_tx_hash, utxo_vout, asset)",
    "CREATE INDEX IF NOT EXISTS balances_address_utxo_asset_idx ON balances (address, utxo_tx_hash, utxo_vout, asset)",
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
    "CREATE INDEX IF NOT EXISTS order_matches_tx0_index_tx1_index_idx ON order_matches (tx0_index, tx1_index)",
    "CREATE INDEX IF NOT EXISTS order_matches_tx0_address_forward_asset_idx ON order_matches (tx0_address, forward_asset)",
    "CREATE INDEX IF NOT EXISTS order_matches_tx1_address_backward_asset_idx ON order_matches (tx1_address, backward_asset)",
    "CREATE INDEX IF NOT EXISTS order_matches_match_expire_index_idx ON order_matches (match_expire_index)",
    "CREATE INDEX IF NOT EXISTS order_matches_status_idx ON order_matches (status)",
    "CREATE INDEX IF NOT EXISTS order_matches_tx0_hash_idx ON order_matches (tx0_hash)",
    "CREATE INDEX IF NOT EXISTS order_matches_tx1_hash_idx ON order_matches (tx1_hash)",
    # order_expirations
    "CREATE INDEX IF NOT EXISTS order_expirations_block_index_idx ON order_expirations (block_index)",
    "CREATE INDEX IF NOT EXISTS order_expirations_source_idx ON order_expirations (source)",
    # order_match_expirations (rewritten: order_match_id -> tx index pair)
    "CREATE INDEX IF NOT EXISTS order_match_expirations_block_index_idx ON order_match_expirations (block_index)",
    "CREATE INDEX IF NOT EXISTS order_match_expirations_tx0_address_idx ON order_match_expirations (tx0_address)",
    "CREATE INDEX IF NOT EXISTS order_match_expirations_tx1_address_idx ON order_match_expirations (tx1_address)",
    # btcpays
    "CREATE INDEX IF NOT EXISTS btcpays_block_index_idx ON btcpays (block_index)",
    "CREATE INDEX IF NOT EXISTS btcpays_source_idx ON btcpays (source)",
    "CREATE INDEX IF NOT EXISTS btcpays_destination_idx ON btcpays (destination)",
    "CREATE INDEX IF NOT EXISTS btcpays_order_match_tx_index_idx ON btcpays (order_match_tx0_index, order_match_tx1_index)",
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
    "CREATE INDEX IF NOT EXISTS bet_matches_tx0_index_tx1_index_idx ON bet_matches (tx0_index, tx1_index)",
    "CREATE INDEX IF NOT EXISTS bet_matches_status_idx ON bet_matches (status)",
    "CREATE INDEX IF NOT EXISTS bet_matches_deadline_idx ON bet_matches (deadline)",
    "CREATE INDEX IF NOT EXISTS bet_matches_tx0_address_idx ON bet_matches (tx0_address)",
    "CREATE INDEX IF NOT EXISTS bet_matches_tx1_address_idx ON bet_matches (tx1_address)",
    # bet_expirations
    "CREATE INDEX IF NOT EXISTS bet_expirations_block_index_idx ON bet_expirations (block_index)",
    "CREATE INDEX IF NOT EXISTS bet_expirations_source_idx ON bet_expirations (source)",
    # bet_match_expirations (rewritten: bet_match_id -> tx index pair)
    "CREATE INDEX IF NOT EXISTS bet_match_expirations_block_index_idx ON bet_match_expirations (block_index)",
    "CREATE INDEX IF NOT EXISTS bet_match_expirations_tx0_address_idx ON bet_match_expirations (tx0_address)",
    "CREATE INDEX IF NOT EXISTS bet_match_expirations_tx1_address_idx ON bet_match_expirations (tx1_address)",
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
    "CREATE INDEX IF NOT EXISTS rps_matches_tx0_index_tx1_index_idx ON rps_matches (tx0_index, tx1_index)",
    "CREATE INDEX IF NOT EXISTS rps_matches_match_expire_index_idx ON rps_matches (match_expire_index)",
    # rps_expirations
    "CREATE INDEX IF NOT EXISTS rps_expirations_block_index_idx ON rps_expirations (block_index)",
    "CREATE INDEX IF NOT EXISTS rps_expirations_source_idx ON rps_expirations (source)",
    # rps_match_expirations (rewritten: rps_match_id -> tx index pair)
    "CREATE INDEX IF NOT EXISTS rps_match_expirations_block_index_idx ON rps_match_expirations (block_index)",
    "CREATE INDEX IF NOT EXISTS rps_match_expirations_tx0_address_idx ON rps_match_expirations (tx0_address)",
    "CREATE INDEX IF NOT EXISTS rps_match_expirations_tx1_address_idx ON rps_match_expirations (tx1_address)",
    # rpsresolves
    "CREATE INDEX IF NOT EXISTS rpsresolves_block_index_idx ON rpsresolves (block_index)",
    "CREATE INDEX IF NOT EXISTS rpsresolves_source_idx ON rpsresolves (source)",
    "CREATE INDEX IF NOT EXISTS rpsresolves_rps_match_tx_index_idx ON rpsresolves (rps_match_tx0_index, rps_match_tx1_index)",
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
        (SELECT address FROM address_list WHERE address_id = t.source) AS source,
        (SELECT address FROM address_list WHERE address_id = t.destination) AS destination,
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
        (SELECT address FROM address_list WHERE address_id = t.source) AS source,
        (SELECT address FROM address_list WHERE address_id = t.destination) AS destination,
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
        SELECT 'order_match' AS type,
        (SELECT hex_lower(t0.tx_hash) FROM transactions t0 WHERE t0.tx_index = e.order_match_tx0_index)
        || '_' ||
        (SELECT hex_lower(t1.tx_hash) FROM transactions t1 WHERE t1.tx_index = e.order_match_tx1_index) AS object_id,
        block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_order_match_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM order_match_expirations e
         UNION ALL
        SELECT 'bet' AS type, hex_lower(bet_hash) AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_bet_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM bet_expirations
         UNION ALL
        SELECT 'bet_match' AS type,
        (SELECT hex_lower(t0.tx_hash) FROM transactions t0 WHERE t0.tx_index = e.bet_match_tx0_index)
        || '_' ||
        (SELECT hex_lower(t1.tx_hash) FROM transactions t1 WHERE t1.tx_index = e.bet_match_tx1_index) AS object_id,
        block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_bet_match_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM bet_match_expirations e
         UNION ALL
        SELECT 'rps' AS type, hex_lower(rps_hash) AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_rps_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM rps_expirations
         UNION ALL
        SELECT 'rps_match' AS type,
        (SELECT hex_lower(t0.tx_hash) FROM transactions t0 WHERE t0.tx_index = e.rps_match_tx0_index)
        || '_' ||
        (SELECT hex_lower(t1.tx_hash) FROM transactions t1 WHERE t1.tx_index = e.rps_match_tx1_index) AS object_id,
        block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_rps_match_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM rps_match_expirations e""",
    """CREATE VIEW IF NOT EXISTS all_holders AS
        SELECT (SELECT asset_name FROM assets WHERE asset_index = balances.asset) AS asset,
            (SELECT address FROM address_list WHERE address_id = balances.address) AS address,
            quantity, NULL AS escrow, MAX(rowid) AS rowid,
            CONCAT('balances_', CAST(rowid AS VARCHAR)) AS cursor_id, 'balances' AS holding_type, NULL AS status
        FROM balances
        GROUP BY asset, address
         UNION ALL
        SELECT * FROM (
            SELECT (SELECT asset_name FROM assets WHERE asset_index = give_asset) AS asset, (SELECT address FROM address_list WHERE address_id = source) AS address, give_remaining AS quantity, hex_lower(tx_hash) AS escrow,
                MAX(rowid) AS rowid, CONCAT('open_order_', CAST(rowid AS VARCHAR)) AS cursor_id,
                'open_order' AS holding_type, status
            FROM orders
            GROUP BY tx_hash
        ) WHERE status = 'open'
         UNION ALL
        SELECT * FROM (
            SELECT (SELECT asset_name FROM assets WHERE asset_index = forward_asset) AS asset, (SELECT address FROM address_list WHERE address_id = tx0_address) AS address, forward_quantity AS quantity,
                hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('order_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
                'pending_order_match' AS holding_type, status
            FROM order_matches
            GROUP BY tx0_index, tx1_index
        ) WHERE status = 'pending'
         UNION ALL
        SELECT * FROM (
            SELECT (SELECT asset_name FROM assets WHERE asset_index = backward_asset) AS asset, (SELECT address FROM address_list WHERE address_id = tx1_address) AS address, backward_quantity AS quantity,
                hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('order_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
                'pending_order_match' AS holding_type, status
            FROM order_matches
            GROUP BY tx0_index, tx1_index
        ) WHERE status = 'pending'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, (SELECT address FROM address_list WHERE address_id = source) AS address, wager_remaining AS quantity,
            hex_lower(tx_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('open_bet_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'open_bet' AS holding_type, status
            FROM bets
            GROUP BY tx_hash
        ) WHERE status = 'open'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, (SELECT address FROM address_list WHERE address_id = tx0_address) AS address, forward_quantity AS quantity,
            hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('bet_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'pending_bet_match' AS holding_type, status
            FROM bet_matches
            GROUP BY tx0_index, tx1_index
        ) WHERE status = 'pending'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, (SELECT address FROM address_list WHERE address_id = tx1_address) AS address, backward_quantity AS quantity,
            hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('bet_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'pending_bet_match' AS holding_type, status
            FROM bet_matches
            GROUP BY tx0_index, tx1_index
        ) WHERE status = 'pending'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, (SELECT address FROM address_list WHERE address_id = source) AS address, wager AS quantity,
            hex_lower(tx_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('open_rps_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'open_rps' AS holding_type, status
            FROM rps
            GROUP BY tx_hash
        ) WHERE status = 'open'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, (SELECT address FROM address_list WHERE address_id = tx0_address) AS address, wager AS quantity,
            hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('rps_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'pending_rps_match' AS holding_type, status
            FROM rps_matches
            GROUP BY tx0_index, tx1_index
        ) WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, (SELECT address FROM address_list WHERE address_id = tx1_address) AS address, wager AS quantity,
            hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('rps_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'pending_rps_match' AS holding_type, status
            FROM rps_matches
            GROUP BY tx0_index, tx1_index
        ) WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
         UNION ALL
        SELECT * FROM (
            SELECT (SELECT asset_name FROM assets WHERE asset_index = dispensers.asset) AS asset, (SELECT address FROM address_list WHERE address_id = source) AS address, give_remaining AS quantity,
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
    # assets: copy the legacy columns verbatim and let the new
    # ``asset_index INTEGER PRIMARY KEY`` auto-assign in stable insertion
    # order. ``ORDER BY rowid`` makes the assignment deterministic (it is
    # consensus- and API-irrelevant -- only internal FK consistency matters).
    # This entry MUST run before every other rewrite that resolves an asset
    # name to its ``asset_index`` (``assets`` is first in TABLE_REWRITES).
    "assets": (
        """
        SELECT
            asset_id,
            asset_name,
            block_index,
            asset_longname
        FROM assets_old
        ORDER BY rowid
        """
    ),
    # balances/credits/debits: resolve ``address``/``utxo_address`` to the
    # compact ``address_id`` (via ``address_list``), ``asset`` to ``asset_index``
    # (via ``assets``), and split the legacy ``utxo`` TEXT (``tx_hash:vout``)
    # into ``utxo_tx_hash`` (``__hex_to_blob`` of the 64-char hex hash) and
    # ``utxo_vout`` (``CAST(substr(utxo, 66) AS INTEGER)``). The tx_hash is
    # stored RAW (BLOB) -- not a tx_index FK -- because an attach destination may
    # be any bitcoin UTXO absent from ``transactions``. ``substr``/``__hex_to_blob``
    # of a NULL utxo yields NULL (address balances). ``assets`` and
    # ``address_list`` are fully populated before these run.
    "balances": (
        """
        SELECT
            (SELECT al.address_id FROM address_list al WHERE al.address = b.address) AS address,
            (SELECT a.asset_index FROM assets a WHERE a.asset_name = b.asset) AS asset,
            b.quantity,
            b.block_index,
            b.tx_index,
            __hex_to_blob(substr(b.utxo, 1, 64)) AS utxo_tx_hash,
            CAST(substr(b.utxo, 66) AS INTEGER) AS utxo_vout,
            (SELECT al.address_id FROM address_list al WHERE al.address = b.utxo_address) AS utxo_address
        FROM balances_old b
        """
    ),
    "credits": (
        """
        SELECT
            c.block_index,
            (SELECT al.address_id FROM address_list al WHERE al.address = c.address) AS address,
            (SELECT a.asset_index FROM assets a WHERE a.asset_name = c.asset) AS asset,
            c.quantity,
            c.calling_function,
            c.event,
            c.tx_index,
            __hex_to_blob(substr(c.utxo, 1, 64)) AS utxo_tx_hash,
            CAST(substr(c.utxo, 66) AS INTEGER) AS utxo_vout,
            (SELECT al.address_id FROM address_list al WHERE al.address = c.utxo_address) AS utxo_address
        FROM credits_old c
        """
    ),
    "debits": (
        """
        SELECT
            d.block_index,
            (SELECT al.address_id FROM address_list al WHERE al.address = d.address) AS address,
            (SELECT a.asset_index FROM assets a WHERE a.asset_name = d.asset) AS asset,
            d.quantity,
            d.action,
            d.event,
            d.tx_index,
            __hex_to_blob(substr(d.utxo, 1, 64)) AS utxo_tx_hash,
            CAST(substr(d.utxo, 66) AS INTEGER) AS utxo_vout,
            (SELECT al.address_id FROM address_list al WHERE al.address = d.utxo_address) AS utxo_address
        FROM debits_old d
        """
    ),
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
            (SELECT address_id FROM address_list WHERE address = transactions_old.source) AS source,
            (SELECT address_id FROM address_list WHERE address = transactions_old.destination) AS destination,
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
            (SELECT address_id FROM address_list WHERE address = c.source) AS source,
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
            (SELECT address_id FROM address_list WHERE address = d.source) AS source,
            (SELECT address_id FROM address_list WHERE address = d.destination) AS destination,
            (SELECT a.asset_index FROM assets a WHERE a.asset_name = d.asset) AS asset,
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
            (SELECT address_id FROM address_list WHERE address = r.source) AS source,
            (SELECT address_id FROM address_list WHERE address = r.destination) AS destination,
            (SELECT a.asset_index FROM assets a WHERE a.asset_name = r.asset) AS asset,
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
            (SELECT address_id FROM address_list WHERE address = f.source) AS source,
            t.tx_index AS fairminter_tx_index,
            (SELECT a.asset_index FROM assets a WHERE a.asset_name = f.asset) AS asset,
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
            (SELECT address_id FROM address_list WHERE address = p.source) AS source,
            (SELECT a.asset_index FROM assets a WHERE a.asset_name = p.asset_a) AS asset_a,
            (SELECT a.asset_index FROM assets a WHERE a.asset_name = p.asset_b) AS asset_b,
            (SELECT a.asset_index FROM assets a WHERE a.asset_name = p.forward_asset) AS forward_asset,
            p.forward_quantity,
            (SELECT a.asset_index FROM assets a WHERE a.asset_name = p.backward_asset) AS backward_asset,
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
            (SELECT address_id FROM address_list WHERE address = transaction_outputs_old.destination) AS destination,
            btc_amount
        FROM transaction_outputs_old
        """
    ),
    # --------------------------------------------------------------------
    # Composite match-id normalization. The legacy TEXT id is
    # ``tx0hash_tx1hash`` (64 hex + '_' + 64 hex); split it on the fixed
    # offsets and resolve each half to its tx_index via ``transactions_old``
    # (still hex at this point in the migration). LEFT JOINs so an
    # unresolvable / NULL id (e.g. an invalid btcpay) yields NULL indexes.
    # --------------------------------------------------------------------
    # btcpays: order_match_id -> (order_match_tx0_index, order_match_tx1_index)
    "btcpays": (
        """
        SELECT
            b.tx_index,
            __hex_to_blob(b.tx_hash) AS tx_hash,
            b.block_index,
            (SELECT address_id FROM address_list WHERE address = b.source) AS source,
            (SELECT address_id FROM address_list WHERE address = b.destination) AS destination,
            b.btc_amount,
            t0.tx_index AS order_match_tx0_index,
            t1.tx_index AS order_match_tx1_index,
            b.status
        FROM btcpays_old b
        LEFT JOIN transactions_old t0 ON t0.tx_hash = substr(b.order_match_id, 1, 64)
        LEFT JOIN transactions_old t1 ON t1.tx_hash = substr(b.order_match_id, 66)
        """
    ),
    # rpsresolves: rps_match_id -> (rps_match_tx0_index, rps_match_tx1_index)
    "rpsresolves": (
        """
        SELECT
            r.tx_index,
            __hex_to_blob(r.tx_hash) AS tx_hash,
            r.block_index,
            (SELECT address_id FROM address_list WHERE address = r.source) AS source,
            r.move,
            r.random,
            t0.tx_index AS rps_match_tx0_index,
            t1.tx_index AS rps_match_tx1_index,
            r.status
        FROM rpsresolves_old r
        LEFT JOIN transactions_old t0 ON t0.tx_hash = substr(r.rps_match_id, 1, 64)
        LEFT JOIN transactions_old t1 ON t1.tx_hash = substr(r.rps_match_id, 66)
        """
    ),
    # order_match_expirations: order_match_id -> (tx0_index, tx1_index)
    "order_match_expirations": (
        """
        SELECT
            t0.tx_index AS order_match_tx0_index,
            t1.tx_index AS order_match_tx1_index,
            (SELECT address_id FROM address_list WHERE address = e.tx0_address) AS tx0_address,
            (SELECT address_id FROM address_list WHERE address = e.tx1_address) AS tx1_address,
            e.block_index
        FROM order_match_expirations_old e
        LEFT JOIN transactions_old t0 ON t0.tx_hash = substr(e.order_match_id, 1, 64)
        LEFT JOIN transactions_old t1 ON t1.tx_hash = substr(e.order_match_id, 66)
        """
    ),
    # bet_match_expirations: bet_match_id -> (tx0_index, tx1_index)
    "bet_match_expirations": (
        """
        SELECT
            t0.tx_index AS bet_match_tx0_index,
            t1.tx_index AS bet_match_tx1_index,
            (SELECT address_id FROM address_list WHERE address = e.tx0_address) AS tx0_address,
            (SELECT address_id FROM address_list WHERE address = e.tx1_address) AS tx1_address,
            e.block_index
        FROM bet_match_expirations_old e
        LEFT JOIN transactions_old t0 ON t0.tx_hash = substr(e.bet_match_id, 1, 64)
        LEFT JOIN transactions_old t1 ON t1.tx_hash = substr(e.bet_match_id, 66)
        """
    ),
    # rps_match_expirations: rps_match_id -> (tx0_index, tx1_index)
    "rps_match_expirations": (
        """
        SELECT
            t0.tx_index AS rps_match_tx0_index,
            t1.tx_index AS rps_match_tx1_index,
            (SELECT address_id FROM address_list WHERE address = e.tx0_address) AS tx0_address,
            (SELECT address_id FROM address_list WHERE address = e.tx1_address) AS tx1_address,
            e.block_index
        FROM rps_match_expirations_old e
        LEFT JOIN transactions_old t0 ON t0.tx_hash = substr(e.rps_match_id, 1, 64)
        LEFT JOIN transactions_old t1 ON t1.tx_hash = substr(e.rps_match_id, 66)
        """
    ),
    # bet_match_resolutions: bet_match_id -> (tx0_index, tx1_index)
    "bet_match_resolutions": (
        """
        SELECT
            t0.tx_index AS bet_match_tx0_index,
            t1.tx_index AS bet_match_tx1_index,
            r.bet_match_type_id,
            r.block_index,
            (SELECT address_id FROM address_list WHERE address = r.winner) AS winner,
            r.settled,
            r.bull_credit,
            r.bear_credit,
            r.escrow_less_fee,
            r.fee
        FROM bet_match_resolutions_old r
        LEFT JOIN transactions_old t0 ON t0.tx_hash = substr(r.bet_match_id, 1, 64)
        LEFT JOIN transactions_old t1 ON t1.tx_hash = substr(r.bet_match_id, 66)
        """
    ),
}
