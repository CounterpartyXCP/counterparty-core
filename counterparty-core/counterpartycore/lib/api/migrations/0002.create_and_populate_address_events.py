#
# file: counterpartycore/lib/api/migrations/0002.populate_address_events.py
#
import json
import logging
import os

from counterpartycore.lib import config
from counterpartycore.lib.api.api_watcher import EVENTS_ADDRESS_FIELDS
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

__depends__ = {"0001.create_mempool_table"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    logger.debug("Populate `address_events` table...")
    db.row_factory = dict_factory

    db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    cursor = db.cursor()

    cursor.execute("""CREATE TABLE address_events (
        address TEXT,
        event_index INTEGER,
        block_index INTEGER
    )""")
    cursor.execute("CREATE INDEX address_events_address_idx ON address_events (address)")
    cursor.execute("CREATE INDEX address_events_event_index_idx ON address_events (event_index)")
    cursor.execute("CREATE INDEX address_events_block_index_idx ON address_events (block_index)")

    event_names = list(EVENTS_ADDRESS_FIELDS.keys())
    placeholders = ", ".join(["?"] * len(event_names))

    sql = f"""
        SELECT event, bindings, message_index, block_index
        FROM ledger_db.messages WHERE event IN ({placeholders})
        ORDER BY message_index
    """  # noqa S608

    cursor.execute(sql, event_names)

    inserted = 0
    for row in cursor:
        bindings = json.loads(row["bindings"])
        for field in EVENTS_ADDRESS_FIELDS[row["event"]]:
            sql = """
                INSERT INTO address_events (address, event_index, block_index)
                VALUES (?, ?, ?)
            """
            db.execute(sql, (bindings[field], row["message_index"], row["block_index"]))
            inserted += 1
            if inserted % 1000000 == 0:
                logger.debug(f"Inserted {inserted} address events")

    logger.debug("`address_events` ready.")


def rollback(db):
    db.execute("DROP TABLE address_events")


steps = [step(apply, rollback)]
