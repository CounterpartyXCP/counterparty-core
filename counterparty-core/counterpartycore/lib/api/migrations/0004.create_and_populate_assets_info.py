#
# file: counterpartycore/lib/api/migrations/0004.create_and_populate_assets_info.py
#
import logging
import time

from counterpartycore.lib import config, ledger
from counterpartycore.lib.utils import database
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0003.create_and_populate_all_expirations"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    start_time = time.time()
    logger.debug("Populating the `assets_info` table...")

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
        CREATE TABLE assets_info(
            asset TEXT,
            asset_id TEXT,
            asset_longname TEXT,
            issuer TEXT,
            owner TEXT,
            divisible BOOL,
            locked BOOL DEFAULT 0,
            supply INTEGER DEFAULT 0,
            description TEXT,
            description_locked BOOL DEFAULT 0,
            first_issuance_block_index INTEGER,
            last_issuance_block_index INTEGER
    )""")

    sql = """
    INSERT INTO assets_info 
    SELECT 
        asset,
        asset_id,
        asset_longname,
        issuer,
        owner,
        divisible,
        locked,
        supply,
        description,
        description_locked,
        first_issuance_block_index,
        last_issuance_block_index
    FROM (
        SELECT
            asset,
            ledger_db.assets.asset_id,
            ledger_db.assets.asset_longname,
            (
                SELECT issuer
                FROM ledger_db.issuances AS issuances2
                WHERE ledger_db.assets.asset_name = issuances2.asset
                ORDER BY issuances2.rowid ASC
                LIMIT 1
            ) AS issuer,
            issuer AS owner,
            divisible,
            SUM(locked) AS locked,
            SUM(quantity) AS supply,
            description,
            SUM(description_locked) AS description_locked,
            MIN(ledger_db.issuances.block_index) AS first_issuance_block_index,
            MAX(ledger_db.issuances.block_index) AS last_issuance_block_index,
            MAX(ledger_db.issuances.rowid) AS rowid
        FROM ledger_db.issuances, ledger_db.assets
        WHERE ledger_db.issuances.asset = ledger_db.assets.asset_name
        AND ledger_db.issuances.status = 'valid'
        GROUP BY asset
    );
    """
    cursor = db.cursor()
    cursor.execute(sql)

    ledger_db = database.get_db_connection(config.DATABASE)
    cursor.execute(
        """
        INSERT INTO assets_info (
            asset, divisible, locked, supply, description,
            first_issuance_block_index, last_issuance_block_index
        ) VALUES (
            :asset, :divisible, :locked, :supply, :description,
            :first_issuance_block_index, :last_issuance_block_index
        )
        """,
        {
            "asset": "XCP",
            "divisible": True,
            "locked": True,
            "supply": ledger.ledger.xcp_supply(ledger_db),
            "description": "The Counterparty protocol native currency",
            "first_issuance_block_index": 278319,
            "last_issuance_block_index": 283810,
        },
    )

    start_time_supply = time.time()
    logger.debug("Updating the `supply` field...")

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
        CREATE INDEX temp.supplies_asset_idx ON supplies(asset)
    """)

    db.execute("""
        UPDATE assets_info SET
        supply = COALESCE((SELECT supplies.supply FROM supplies WHERE assets_info.asset = supplies.asset), supply)
    """)

    db.execute("DROP TABLE issuances_quantity")
    db.execute("DROP TABLE destructions_quantity")
    db.execute("DROP TABLE supplies")

    logger.debug(f"Updated the `supply` field in {time.time() - start_time_supply:.2f} seconds")

    db.execute("CREATE UNIQUE INDEX assets_info_asset_idx ON assets_info (asset)")
    db.execute("CREATE UNIQUE INDEX assets_info_asset_id_idx ON assets_info (asset_id)")
    db.execute("CREATE INDEX assets_info_asset_longname_idx ON assets_info (asset_longname)")
    db.execute("CREATE INDEX assets_info_issuer_idx ON assets_info (issuer)")
    db.execute("CREATE INDEX assets_info_owner_idx ON assets_info (owner)")

    logger.debug(f"Populated the `assets_info` table in {time.time() - start_time:.2f} seconds")


def rollback(db):
    db.execute("DROP TABLE assets_info")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
