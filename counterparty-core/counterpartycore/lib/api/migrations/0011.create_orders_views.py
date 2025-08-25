#
# file: counterpartycore/lib/api/migrations/0011.create_orders_views.py
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)


__depends__ = {"0010.fix_bet_match_resolution_event_name"}


def apply(db):
    start_time = time.time()
    logger.debug("Building view orders_info ...")

    db.execute("""
        CREATE VIEW orders_info AS 
        SELECT 
            orders.*, orders.rowid AS rowid,
            get_assets.divisible AS get_asset_divisible,
            give_assets.divisible AS give_asset_divisible,
            CASE 
                WHEN get_assets.divisible = 1 AND give_assets.divisible = 0 THEN
                    COALESCE((get_quantity / 100000000.0) / (give_quantity * 1.0), 0)
                WHEN get_assets.divisible = 0 AND give_assets.divisible = 1 THEN
                    COALESCE((get_quantity * 1.0) / (give_quantity / 100000000.0), 0)
                ELSE
                    COALESCE((get_quantity * 1.0) / (give_quantity * 1.0), 0)
            END AS give_price,
            CASE 
                WHEN get_assets.divisible = 1 AND give_assets.divisible = 0 THEN
                    COALESCE((give_quantity * 1.0) / (get_quantity / 100000000.0), 0)
                WHEN get_assets.divisible = 0 AND give_assets.divisible = 1 THEN
                    COALESCE((give_quantity / 100000000.0) / (get_quantity * 1.0), 0)
                ELSE
                    COALESCE((give_quantity * 1.0) / (get_quantity * 1.0), 0)
            END AS get_price
        FROM orders
        LEFT JOIN assets_info AS get_assets ON orders.get_asset = get_assets.asset
        LEFT JOIN assets_info AS give_assets ON orders.give_asset = give_assets.asset
    """)

    logger.debug("Built views in %.2f seconds", time.time() - start_time)


def rollback(db):
    db.execute("DROP VIEW orders_info")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
