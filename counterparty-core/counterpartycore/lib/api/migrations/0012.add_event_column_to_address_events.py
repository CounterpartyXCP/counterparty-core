#
# file: counterpartycore/lib/api/migrations/0012.add_event_column_to_address_events.py
#
# Adds the `event` column to address_events table to eliminate the need for
# the in-memory AddressEventsCache, which takes ~8 minutes to build on startup.
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return dict(zip(fields, row, strict=True))


def apply(db):
    start_time = time.time()
    logger.debug("Adding `event` column to `address_events` table...")

    if hasattr(db, "row_factory"):
        db.row_factory = dict_factory

    # Attach ledger_db if not already attached
    attached = (
        db.execute(
            "SELECT COUNT(*) AS count FROM pragma_database_list WHERE name = ?", ("ledger_db",)
        ).fetchone()["count"]
        > 0
    )
    if not attached:
        db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    cursor = db.cursor()

    # Create new table with event column
    cursor.execute("""
        CREATE TABLE address_events_new (
            address TEXT,
            event_index INTEGER,
            block_index INTEGER,
            event TEXT
        )
    """)

    # Populate from join with messages table
    cursor.execute("""
        INSERT INTO address_events_new (address, event_index, block_index, event)
        SELECT ae.address, ae.event_index, ae.block_index, m.event
        FROM address_events ae
        JOIN ledger_db.messages m ON ae.event_index = m.message_index
    """)

    # Drop old table
    cursor.execute("DROP TABLE address_events")

    # Rename new table
    cursor.execute("ALTER TABLE address_events_new RENAME TO address_events")

    # Recreate indexes
    cursor.execute("CREATE INDEX address_events_address_idx ON address_events (address)")
    cursor.execute("CREATE INDEX address_events_event_index_idx ON address_events (event_index)")
    cursor.execute("CREATE INDEX address_events_block_index_idx ON address_events (block_index)")
    cursor.execute("CREATE INDEX address_events_event_idx ON address_events (event)")

    cursor.close()

    logger.debug(
        "Added `event` column to `address_events` table in %.2f seconds", time.time() - start_time
    )


def rollback(db):
    cursor = db.cursor()

    # Create table without event column
    cursor.execute("""
        CREATE TABLE address_events_old (
            address TEXT,
            event_index INTEGER,
            block_index INTEGER
        )
    """)

    # Copy data without event column
    cursor.execute("""
        INSERT INTO address_events_old (address, event_index, block_index)
        SELECT address, event_index, block_index
        FROM address_events
    """)

    # Drop new table
    cursor.execute("DROP TABLE address_events")

    # Rename old table
    cursor.execute("ALTER TABLE address_events_old RENAME TO address_events")

    # Recreate original indexes
    cursor.execute("CREATE INDEX address_events_address_idx ON address_events (address)")
    cursor.execute("CREATE INDEX address_events_event_index_idx ON address_events (event_index)")
    cursor.execute("CREATE INDEX address_events_block_index_idx ON address_events (block_index)")

    cursor.close()


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
