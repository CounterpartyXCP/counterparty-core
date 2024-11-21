#
# file: counterpartycore/lib/api/migrations/0007.create_views.py
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)


__depends__ = {"0006.create_and_populate_consolidated_tables"}


def apply(db):
    start_time = time.time()
    logger.debug("Building views...")

    db.execute("""
         CREATE VIEW asset_holders AS 
            SELECT asset, address, quantity, NULL AS escrow,
                ('balances_' || CAST(rowid AS VARCAHR)) AS cursor_id, 'balances' AS holding_type, NULL AS status
            FROM balances
         UNION ALL 
            SELECT give_asset AS asset, source AS address, give_remaining AS quantity, tx_hash AS escrow,
                ('open_order_' || CAST(rowid AS VARCAHR)) AS cursor_id,
                'open_order' AS holding_type, status
            FROM orders WHERE status = 'open'
         UNION ALL 
            SELECT forward_asset AS asset, tx0_address AS address, forward_quantity AS quantity,
                id AS escrow, ('order_match_' || CAST(rowid AS VARCAHR)) AS cursor_id,
                'pending_order_match' AS holding_type, status
            FROM order_matches WHERE status = 'pending'
         UNION ALL 
            SELECT backward_asset AS asset, tx1_address AS address, backward_quantity AS quantity,
                id AS escrow, ('order_match_' || CAST(rowid AS VARCAHR)) AS cursor_id,
                'pending_order_match' AS holding_type, status
            FROM order_matches WHERE status = 'pending'
         UNION ALL 
            SELECT asset, source AS address, give_remaining AS quantity,
            tx_hash AS escrow, ('open_dispenser_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'open_dispenser' AS holding_type, status
            FROM dispensers WHERE status = 0;
      """)

    db.execute("""
         CREATE VIEW xcp_holders AS
            SELECT * FROM asset_holders
         UNION ALL 
            SELECT 'XCP' AS asset, source AS address, wager_remaining AS quantity,
            tx_hash AS escrow, ('open_bet_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'open_bet' AS holding_type, status
            FROM bets WHERE status = 'open'
         UNION ALL 
            SELECT 'XCP' AS asset, tx0_address AS address, forward_quantity AS quantity,
            id AS escrow, ('bet_match_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'pending_bet_match' AS holding_type, status
            FROM bet_matches WHERE status = 'pending'
         UNION ALL 
            SELECT 'XCP' AS asset, tx1_address AS address, backward_quantity AS quantity,
            id AS escrow, ('bet_match_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'pending_bet_match' AS holding_type, status
            FROM bet_matches WHERE status = 'pending'
         UNION ALL 
            SELECT 'XCP' AS asset, source AS address, wager AS quantity,
            tx_hash AS escrow, ('open_rps_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'open_rps' AS holding_type, status
            FROM rps WHERE status = 'open'
         UNION ALL 
            SELECT 'XCP' AS asset, tx0_address AS address, wager AS quantity,
            id AS escrow, ('rps_match_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'pending_rps_match' AS holding_type, status
            FROM rps_matches WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
         UNION ALL 
            SELECT 'XCP' AS asset, tx1_address AS address, wager AS quantity,
            id AS escrow, ('rps_match_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'pending_rps_match' AS holding_type, status
            FROM rps_matches WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
    """)

    logger.debug(f"Built views in {time.time() - start_time:.2f} seconds")


def rollback(db):
    db.execute("DROP VIEW asset_holders")
    db.execute("DROP VIEW xcp_holders")


steps = [step(apply, rollback)]
