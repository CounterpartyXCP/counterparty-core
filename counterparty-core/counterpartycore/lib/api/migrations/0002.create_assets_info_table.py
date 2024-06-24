#
# file: counterpartycore/lib/api/migrations/0002.create_assets_info_table.py
#
import logging
import os

from counterpartycore.lib import config
from counterpartycore.lib.api import api_watcher
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

__depends__ = {"0001.create_api_database"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    logger.info("Creating `assets_info` table...")
    db.row_factory = dict_factory

    cursor = db.cursor()
    sqls = [
        """
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
                        last_issuance_block_index INTEGER
                        );
        """,
        "CREATE INDEX IF NOT EXISTS assets_info_asset_idx ON assets_info (asset);",
        "CREATE INDEX IF NOT EXISTS assets_info_asset_longname_idx ON assets_info (asset_longname);",
        "CREATE INDEX IF NOT EXISTS assets_info_issuer_idx ON assets_info (issuer);",
        "CREATE INDEX IF NOT EXISTS assets_info_owner_idx ON assets_info (owner);",
    ]
    for sql in sqls:
        cursor.execute(sql)

    # Populate assets_info table
    place_holder = ", ".join(["?"] * len(api_watcher.ASSET_EVENTS))
    asset_events_sql = f"""
        SELECT * FROM messages WHERE event IN ({place_holder}) ORDER BY message_index ASC
    """  # noqa: S608
    asset_events = cursor.execute(asset_events_sql, api_watcher.ASSET_EVENTS).fetchall()
    for event in asset_events:
        api_watcher.update_assets_info(db, event)

    logger.info("`assets_info` table created...")
    # db.close()


def rollback(db):
    sql = """
        DROP TABLE IF EXISTS assets_info;
    """
    db.cursor().execute(sql)
    db.close()


steps = [step(apply, rollback)]
