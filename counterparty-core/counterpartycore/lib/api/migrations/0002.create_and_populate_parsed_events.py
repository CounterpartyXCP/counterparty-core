#
# file: counterpartycore/lib/api/migrations/0002.create_and_populate_parsed_events.py
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0001.create_and_populate_address_events"}


def apply(db):
    start_time = time.time()
    logger.debug("Populating the `parsed_events` table...")

    db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    sqls = [
        """
        CREATE TABLE parsed_events(
            event_index INTEGER,
            event TEXT,
            event_hash TEXT,
            block_index INTEGER
        );
        """,
        """
        INSERT INTO parsed_events (event_index, event, event_hash, block_index)
        SELECT message_index AS event_index, event, event_hash, block_index
        FROM ledger_db.messages
        """,
        """
        CREATE UNIQUE INDEX parsed_events_event_index_idx ON parsed_events (event_index)
        """,
        """
        CREATE INDEX parsed_events_event_idx ON parsed_events (event)
        """,
        """
        CREATE INDEX parsed_events_block_index_idx ON parsed_events (block_index)
        """,
    ]
    for sql in sqls:
        db.execute(sql)

    logger.debug(f"Populated the `parsed_events` table in {time.time() - start_time:.2f} seconds")


def rollback(db):
    db.execute("DROP TABLE parsed_events")


steps = [step(apply, rollback)]
