#
# file: counterpartycore/lib/api/migrations/0005.create_and_populate_events_counts.py
#
import logging
import time

from counterpartycore.lib import config, database
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0004.create_and_populate_assets_info"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db, block_index=None):
    start_time = time.time()
    logger.debug("Populating the `events_count` table...")

    if hasattr(db, "row_factory"):
        db.row_factory = dict_factory

    database.attach_ledger_db(db)

    db.execute("""
        CREATE TABLE events_count(
            event TEXT PRIMARY KEY,
            count INTEGER
        );
    """)

    db.execute("""
        INSERT INTO events_count (event, count)
        SELECT event, COUNT(*)
        FROM ledger_db.messages
        GROUP BY event;
    """)

    db.execute("""CREATE INDEX events_count_count_idx ON events_count (count)""")

    logger.debug(f"Populated the `events_count` table in {time.time() - start_time:.2f} seconds")


def rollback(db, block_index=None):
    db.execute("DROP TABLE events_count")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
