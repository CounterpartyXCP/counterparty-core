#
# file: counterpartycore/lib/api/migrations/0002.create_assets_info_table.py
#
import logging
import os

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

__depends__ = {"0002.create_assets_info_table"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    logger.info("Creating `holders` table...")
    db.row_factory = dict_factory

    cursor = db.cursor()
    sqls = [
        """
        CREATE TABLE IF NOT EXISTS holders (
                        asset TEXT,
                        address TEXT,
                        quantity INTEGER,
                        escrow TEXT,
                        holding_type TEXT
                        );
        """,
        "CREATE INDEX IF NOT EXISTS holders_asset_idx ON holders (asset);",
        "CREATE INDEX IF NOT EXISTS holders_address_idx ON holders (address);",
        "CREATE INDEX IF NOT EXISTS holders_holding_type_idx ON holders (holding_type);",
        "CREATE INDEX IF NOT EXISTS holders_escrow_idx ON holders (escrow);",
        "CREATE UNIQUE INDEX IF NOT EXISTS holders_asset_address_escrow_idx ON holders (asset, address, escrow);",
    ]
    for sql in sqls:
        cursor.execute(sql)

    logger.info("`assets_info` table created...")
    # db.close()


def rollback(db):
    sql = """
        DROP TABLE IF EXISTS holders;
    """
    db.cursor().execute(sql)
    db.close()


steps = [step(apply, rollback)]
