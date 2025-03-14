#
# file: counterpartycore/lib/api/migrations/0005.create_and_populate_events_counts.py
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0004.create_and_populate_assets_info"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return dict(zip(fields, row))


def apply(db):
    start_time = time.time()
    logger.debug("Populating the `events_count` table...")

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

    logger.debug("Populated the `events_count` table in %.2f seconds", time.time() - start_time)


def rollback(db):
    db.execute("DROP TABLE events_count")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
