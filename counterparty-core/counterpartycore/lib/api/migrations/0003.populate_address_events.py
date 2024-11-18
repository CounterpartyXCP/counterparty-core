#
# file: counterpartycore/lib/api/migrations/0003.populate_address_events.py
#
import json
import logging
import os

from counterpartycore.lib import config
from counterpartycore.lib.api.api_watcher import EVENTS_ADDRESS_FIELDS
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

__depends__ = {"0001.api_db_to_state_db"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def insert_address_events(db, address_events, inserted=0):
    cursor = db.cursor()
    sql = f"""
        INSERT INTO address_events (address, event_index)
        VALUES {", ".join(['(?, ?) '] * (len(address_events) // 2))}
    """  # noqa S608
    cursor.execute(sql, address_events)
    inserted += len(address_events) // 2
    return inserted


def apply(db):
    logger.debug("Populate `address_events` table...")
    db.row_factory = dict_factory

    cursor = db.cursor()

    fields = list(
        set([field for fields in list(EVENTS_ADDRESS_FIELDS.values()) for field in fields])
    )
    event_names = list(EVENTS_ADDRESS_FIELDS.keys())
    placeholders = ", ".join(["?"] * len(event_names))

    select = ["event", "message_index"]
    for field in fields:
        select += [f"json_extract(bindings, '$.{field}') AS {field}"]
    select = ", ".join(select)

    sql = f"SELECT event, bindings, message_index FROM messages WHERE event IN ({placeholders}) ORDER BY message_index"  # noqa S608
    cursor.execute(sql, event_names)

    inserted = 0
    for row in cursor:
        bindings = json.loads(row["bindings"])
        for field in EVENTS_ADDRESS_FIELDS[row["event"]]:
            inserted = insert_address_events(db, [bindings[field], row["message_index"]], inserted)
            if inserted % 1000000 == 0:
                logger.debug(f"Inserted {inserted} address events")

    logger.debug("`address_events` ready.")


def rollback(db):
    pass


steps = [step(apply, rollback)]
