#
# file: counterpartycore/lib/api/migrations/0009.create_and_populate_transaction_types_count.py
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0008.create_config_table"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    start_time = time.time()
    logger.debug("Populating the `transaction_types_count` table...")

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
        CREATE TABLE transaction_types_count(
            transaction_type TEXT PRIMARY KEY,
            count INTEGER
        );
    """)

    db.execute("""
        INSERT INTO transaction_types_count (transaction_type, count)
        SELECT transaction_type, COUNT(*) AS counter
        FROM ledger_db.transactions
        GROUP BY transaction_type;
    """)

    db.execute(
        """CREATE INDEX transaction_types_count_count_idx ON transaction_types_count (count)"""
    )

    logger.debug(
        f"Populated the `transaction_types_count` table in {time.time() - start_time:.2f} seconds"
    )


def rollback(db):
    db.execute("DROP TABLE transaction_types_count")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
