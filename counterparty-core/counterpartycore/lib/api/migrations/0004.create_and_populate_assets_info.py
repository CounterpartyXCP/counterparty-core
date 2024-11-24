#
# file: counterpartycore/lib/api/migrations/0004.create_and_populate_assets_info.py
#
import logging
import time

from counterpartycore.lib import config, database, ledger
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0003.create_and_populate_all_expirations"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def insert_assets_info(db, block_index=None):
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
    )"""
    if block_index:
        sql += " WHERE last_issuance_block_index >= ?"
        db.execute(sql, (block_index,))
    else:
        db.execute(sql)


def build_assets_info(db):
    logger.debug("Populating the `assets_info` table...")
    start_time = time.time()

    db.execute("""
        CREATE TABLE assets_info(
            asset TEXT UNIQUE,
            asset_id TEXT UNIQUE,
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

    insert_assets_info(db, block_index=None)

    ledger_db = database.get_db_connection(config.DATABASE)

    db.execute(
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
            "supply": ledger.xcp_supply(ledger_db),
            "description": "The Counterparty protocol native currency",
            "first_issuance_block_index": 278319,
            "last_issuance_block_index": 283810,
        },
    )

    db.execute("CREATE INDEX assets_info_asset_idx ON assets_info (asset)")
    db.execute("CREATE INDEX assets_info_asset_longname_idx ON assets_info (asset_longname)")
    db.execute("CREATE INDEX assets_info_issuer_idx ON assets_info (issuer)")
    db.execute("CREATE INDEX assets_info_owner_idx ON assets_info (owner)")

    logger.debug(f"Populated the `assets_info` table in {time.time() - start_time:.2f} seconds")


def rebuild_assets_info(db, block_index):
    logger.debug(f"Rebuilding `assets_info` table from block {block_index}...")
    start_time = time.time()

    insert_assets_info(db, block_index)

    logger.debug(f"Rebuilt `assets_info` table in {time.time() - start_time:.2f} seconds")


def apply(db, block_index=None):
    if hasattr(db, "row_factory"):
        db.row_factory = dict_factory

    database.attach_ledger_db(db)

    if block_index:
        rebuild_assets_info(db, block_index)
    else:
        build_assets_info(db)


def rollback(db, block_index=None):
    if block_index:
        db.execute("DELETE FROM assets_info WHERE last_issuance_block_index >= ?", (block_index,))
    else:
        db.execute("DROP TABLE assets_info")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
