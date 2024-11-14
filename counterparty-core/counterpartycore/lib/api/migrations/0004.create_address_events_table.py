#
# file: counterpartycore/lib/api/migrations/0004.create_address_events_table.py
#
import logging
import os

from counterpartycore.lib import config
from counterpartycore.lib.api.dbbuilder import build_address_events_table
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

__depends__ = {"0003.recreate_views"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    logger.info("Create and populate `address_events` table...")
    db.row_factory = dict_factory

    cursor = db.cursor()
    sqls = [
        """
        CREATE TABLE IF NOT EXISTS address_events (
            address TEXT,
            event_index INTEGER
        )
        """,
        "CREATE INDEX IF NOT EXISTS address_events_address_idx ON address_events (address)",
    ]
    for sql in sqls:
        cursor.execute(sql)

    build_address_events_table(db)

    logger.info("`address_events` tables created...")


def rollback(db):
    pass


steps = [step(apply, rollback)]
