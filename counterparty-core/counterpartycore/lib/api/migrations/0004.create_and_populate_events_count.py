#
# file: counterpartycore/lib/api/migrations/0004.create_and_populate_events_counts.py
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0003.create_and_populate_assets_info"}


def apply(db):
    start_time = time.time()
    logger.debug("Populating the `events_count` table...")

    db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    db.execute("""
        CREATE TABLE events_count(
            event TEXT PRIMARY KEY,
            count INTEGER
        );
    """)

    db.execute("""
        INSERT INTO events_count (event, count)
        SELECT event, COUNT(*) AS counter
        FROM ledger_db.messages
        GROUP BY event;
    """)

    db.execute("""CREATE INDEX events_count_count_idx ON events_count (count)""")

    logger.debug(f"Populated the `events_count` table in {time.time() - start_time:.2f} seconds")


def rollback(db):
    db.execute("DROP TABLE events_count")


steps = [step(apply, rollback)]
