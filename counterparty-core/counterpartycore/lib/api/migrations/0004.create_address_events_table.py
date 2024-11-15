#
# file: counterpartycore/lib/api/migrations/0004.create_address_events_table.py
#
import logging
import os

from counterpartycore.lib import config
from counterpartycore.lib.api.api_watcher import EVENTS_ADDRESS_FIELDS, update_address_events
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

__depends__ = {"0003.recreate_views"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    logger.debug("Create and populate `address_events` table...")
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

    event_count = cursor.execute("SELECT COUNT(*) AS count FROM messages").fetchone()["count"]
    parsed_event = 0

    event_list = tuple(EVENTS_ADDRESS_FIELDS.keys())
    placeholders = ", ".join(["?"] * len(event_list))

    event_count = cursor.execute(
        f"SELECT COUNT(*) AS count FROM messages WHERE event IN ({placeholders})",  # noqa S608
        event_list,
    ).fetchone()["count"]
    parsed_event = 0

    sql = f"SELECT * FROM messages WHERE event IN ({placeholders}) ORDER BY message_index"  # noqa S608
    cursor.execute(sql, event_list)
    for event in cursor:
        update_address_events(db, event)
        parsed_event += 1
        if parsed_event % 1000000 == 0:
            logger.debug(f"{parsed_event} of {event_count} events processed")

    logger.debug("`address_events` tables created...")


def rollback(db):
    pass


steps = [step(apply, rollback)]
