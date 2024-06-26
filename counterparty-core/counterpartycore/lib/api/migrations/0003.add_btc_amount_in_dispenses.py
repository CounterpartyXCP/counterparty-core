#
# file: counterpartycore/lib/api/migrations/0002.create_assets_info_table.py
#
import json
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
    logger.info("Adding `btc_amount` field in `dispenses` table...")
    db.row_factory = dict_factory

    cursor = db.cursor()
    sqls = [
        """
        ALTER TABLE dispenses ADD COLUMN btc_amount INTEGER DEFAULT 0;
        """,
    ]
    for sql in sqls:
        cursor.execute(sql)

    # Populate assets_info table
    dispenses_events_sql = """
        SELECT * FROM messages WHERE event = ? ORDER BY message_index ASC
    """  # noqa: S608
    dispenses_events = cursor.execute(dispenses_events_sql, ("DISPENSE",))
    for event in dispenses_events:
        event_bindings = json.loads(event["bindings"])
        if "btc_amount" not in event_bindings:
            continue
        update_sql = """
            UPDATE dispenses SET btc_amount = ? WHERE rowid = ?
        """
        bindings = [event_bindings["btc_amount"], event["insert_rowid"]]
        cursor.execute(update_sql, bindings)

    logger.info("`btc_amount` field added...")


def rollback(db):
    pass


steps = [step(apply, rollback)]
