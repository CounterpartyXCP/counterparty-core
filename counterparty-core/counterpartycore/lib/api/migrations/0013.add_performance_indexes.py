#
# file: counterpartycore/lib/api/migrations/0013.add_performance_indexes.py
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0012.add_event_column_to_address_events"}


def apply(db):
    start_time = time.time()
    logger.debug("Adding performance indexes...")

    # Case-insensitive index for asset_longname lookups
    # This allows queries with COLLATE NOCASE to use the index
    db.execute(
        "CREATE INDEX IF NOT EXISTS assets_info_asset_longname_nocase_idx "
        "ON assets_info (asset_longname COLLATE NOCASE)"
    )

    # Index on balances.address for address-based balance queries
    # This is one of the most common query patterns in the API
    db.execute("CREATE INDEX IF NOT EXISTS balances_address_idx ON balances (address)")

    # Index on balances.utxo_address for UTXO-based balance queries
    db.execute("CREATE INDEX IF NOT EXISTS balances_utxo_address_idx ON balances (utxo_address)")

    # Index on dispensers.source for address-based dispenser queries
    # The existing composite index (source, asset, tx_hash) doesn't help
    # when querying by source alone
    db.execute("CREATE INDEX IF NOT EXISTS dispensers_source_idx ON dispensers (source)")

    logger.debug(
        "Performance indexes created in %.2f seconds",
        time.time() - start_time,
    )


def rollback(db):
    db.execute("DROP INDEX IF EXISTS assets_info_asset_longname_nocase_idx")
    db.execute("DROP INDEX IF EXISTS balances_address_idx")
    db.execute("DROP INDEX IF EXISTS balances_utxo_address_idx")
    db.execute("DROP INDEX IF EXISTS dispensers_source_idx")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
