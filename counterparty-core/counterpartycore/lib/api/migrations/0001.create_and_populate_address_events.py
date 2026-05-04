#
# file: counterpartycore/lib/api/migrations/0001.populate_address_events.py
#
import json
import logging
import time

from counterpartycore.lib import config
from counterpartycore.lib.api.apiwatcher import EVENTS_ADDRESS_FIELDS
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return dict(zip(fields, row, strict=True))


def insert_address_event(db, event):
    """Local insert function that includes the event column."""
    if event["event"] not in EVENTS_ADDRESS_FIELDS:
        return
    event_bindings = json.loads(event["bindings"])
    cursor = db.cursor()
    for field in EVENTS_ADDRESS_FIELDS[event["event"]]:
        if field not in event_bindings:
            continue
        address = event_bindings[field]
        cursor.execute(
            """
            INSERT INTO address_events (address, event_index, block_index, event)
            VALUES (?, ?, ?, ?)
            """,
            (address, event["message_index"], event["block_index"], event["event"]),
        )
    cursor.close()


def apply(db):
    start_time = time.time()
    logger.debug("Populating the `address_events` table...")

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

    cursor = db.cursor()

    cursor.execute("""
        CREATE TABLE address_events (
            address TEXT,
            event_index INTEGER,
            block_index INTEGER,
            event TEXT
        )
    """)

    event_names = list(EVENTS_ADDRESS_FIELDS.keys())
    placeholders = ", ".join(["?"] * len(event_names))

    sql = f"""
        SELECT event, bindings, message_index, block_index
        FROM ledger_db.messages WHERE event IN ({placeholders})
        ORDER BY message_index
    """  # noqa S608 # nosec B608

    cursor.execute(sql, event_names)

    inserted = 0
    for event in cursor:
        insert_address_event(db, event)
        inserted += 1
        if inserted % 1000000 == 0:
            logger.trace(f"Inserted {inserted} address events")

    cursor.execute("CREATE INDEX address_events_address_idx ON address_events (address)")
    cursor.execute("CREATE INDEX address_events_event_index_idx ON address_events (event_index)")
    cursor.execute("CREATE INDEX address_events_block_index_idx ON address_events (block_index)")
    cursor.execute("CREATE INDEX address_events_event_idx ON address_events (event)")

    cursor.close()

    logger.debug("Populated `address_events` table in %.2f seconds", time.time() - start_time)


def rollback(db):
    db.execute("DROP TABLE address_events")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
