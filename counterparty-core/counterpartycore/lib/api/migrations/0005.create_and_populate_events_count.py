#
# file: counterpartycore/lib/api/migrations/0005.create_and_populate_events_counts.py
#
import logging

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)


__depends__ = {"0004.create_and_populate_assets_info"}


def apply(db):
    logger.debug("Preparing `events_count` table...")

    db.execute("""
        CREATE TABLE events_count(
            event TEXT PRIMARY KEY,
            count INTEGER
        );
    """)

    db.execute("""CREATE INDEX events_count_count_idx ON events_count (count)""")

    db.execute("""
        INSERT INTO events_count (event, count)
        SELECT event, COUNT(*) AS counter
        FROM messages
        GROUP BY event;
    """)

    logger.debug("`events_count` table ready.")


def rollback(db):
    db.execute("DROP TABLE events_count")


steps = [step(apply, rollback)]
