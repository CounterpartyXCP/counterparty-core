#
# file: counterpartycore/lib/api/migrations/0003.create_and_populate_all_expirations.py
#
import logging

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)


__depends__ = {"0002.create_and_populate_address_events"}


def apply(db):
    logger.debug("Preparing `all_expirations` table...")

    db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    sqls = [
        """
        CREATE TABLE all_expirations(
            type TEXT,
            object_id TEXT,
            block_index INTEGER);
        """,
        """
        CREATE INDEX all_expirations_type_idx ON all_expirations (type)
        """,
        """
        CREATE INDEX all_expirations_block_index_idx ON all_expirations (block_index)
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
    ]
    for sql in sqls:
        db.execute(sql)

    logger.debug("`all_expirations` table ready.")


def rollback(db):
    db.execute("DROP TABLE all_expirations")


steps = [step(apply, rollback)]
