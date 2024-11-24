#
# file: counterpartycore/lib/api/migrations/0003.create_and_populate_all_expirations.py
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0002.create_and_populate_parsed_events"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    start_time = time.time()
    logger.debug("Populating the `all_expirations` table...")

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

    sqls = [
        """
        CREATE TABLE all_expirations(
            type TEXT,
            object_id TEXT,
            block_index INTEGER
        );
        """,
        """
        INSERT INTO all_expirations (object_id, block_index, type)
        SELECT order_hash AS object_id, block_index, 'order' AS type
        FROM ledger_db.order_expirations
        """,
        """
        INSERT INTO all_expirations (object_id, block_index, type)
        SELECT order_match_id AS object_id, block_index, 'order_match' AS type
        FROM ledger_db.order_match_expirations
        """,
        """
        INSERT INTO all_expirations (object_id, block_index, type)
        SELECT bet_hash AS object_id, block_index, 'bet' AS type
        FROM ledger_db.bet_expirations
        """,
        """
        INSERT INTO all_expirations (object_id, block_index, type)
        SELECT bet_match_id AS object_id, block_index, 'bet_match' AS type
        FROM ledger_db.bet_match_expirations
        """,
        """
        INSERT INTO all_expirations (object_id, block_index, type)
        SELECT rps_hash AS object_id, block_index, 'rps' AS type
        FROM ledger_db.rps_expirations
        """,
        """
        INSERT INTO all_expirations (object_id, block_index, type)
        SELECT rps_match_id AS object_id, block_index, 'rps_match' AS type
        FROM ledger_db.rps_match_expirations
        """,
        """
        CREATE INDEX all_expirations_type_idx ON all_expirations (type)
        """,
        """
        CREATE INDEX all_expirations_block_index_idx ON all_expirations (block_index)
        """,
    ]
    for sql in sqls:
        db.execute(sql)

    logger.debug(f"Populated the `all_expirations` table in {time.time() - start_time:.2f} seconds")


def rollback(db):
    db.execute("DROP TABLE all_expirations")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
