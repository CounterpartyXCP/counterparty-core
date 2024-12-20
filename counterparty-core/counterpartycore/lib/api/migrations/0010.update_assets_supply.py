#
# file: counterpartycore/lib/api/migrations/0010.update_assets_supply.py
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0009.create_and_populate_transaction_types_count"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    start_time = time.time()
    logger.debug("Updating the `assets_info.supply` field...")

    if hasattr(db, "row_factory"):
        db.row_factory = dict_factory

    attached = (
        db.execute(
            "SELECT COUNT(*) AS count FROM pragma_database_list WHERE name = ?", ("ledger_db",)
        ).fetchone()["count"]
        > 0
    )
    if not attached:
        db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    db.execute("""
        CREATE TEMP TABLE issuances_quantity AS
        SELECT asset, SUM(quantity) AS quantity FROM issuances WHERE status = 'valid' GROUP BY asset
    """)
    db.execute("""
        CREATE TEMP TABLE destructions_quantity AS
        SELECT asset, SUM(quantity) AS quantity FROM destructions WHERE status = 'valid' GROUP BY asset
    """)

    db.execute("""
        CREATE TEMP TABLE supplies AS
        SELECT 
            issuances_quantity.asset, 
            issuances_quantity.quantity - COALESCE(destructions_quantity.quantity, 0) AS supply 
        FROM issuances_quantity
        LEFT JOIN destructions_quantity ON issuances_quantity.asset = destructions_quantity.asset
        WHERE issuances_quantity.asset = destructions_quantity.asset
    """)

    db.execute("""
        UPDATE assets_info SET
        supply = COALESCE((SELECT supplies.supply FROM supplies WHERE assets_info.asset = supplies.asset), supply)
    """)

    db.execute("DROP TABLE issuances_quantity")
    db.execute("DROP TABLE destructions_quantity")
    db.execute("DROP TABLE supplies")

    logger.debug(
        f"Updated the `assets_info.supply` field in {time.time() - start_time:.2f} seconds"
    )


def rollback(db):
    return


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
