#
# file: counterpartycore/lib/api/migrations/0003.create_and_populate_all_expirations.py
#
import binascii
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0002.create_and_populate_parsed_events"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return dict(zip(fields, row, strict=True))


def _hex_lower_udf(value):
    """SQLite UDF: BLOB/text -> 64-char lowercase hex string, NULL->NULL.

    The state DB attaches the (already migrated) ledger DB and reads
    ``*_hash`` columns that are now BLOB(32). Yoyo connects via the stdlib
    sqlite3 driver, so the apsw-registered ``hex_lower`` UDF on the main
    state-DB connection is not visible here; we register the same shim on
    the migration connection.
    """
    if value is None:
        return None
    if isinstance(value, str):
        return value.lower()
    return binascii.hexlify(value).decode("ascii")


def apply(db):
    start_time = time.time()
    logger.debug("Populating the `all_expirations` table...")

    if hasattr(db, "row_factory"):
        db.row_factory = dict_factory

    # Register hex_lower so the ``object_id`` projection produces lowercase
    # hex strings even though the underlying columns are BLOB(32).
    try:
        db.create_function("hex_lower", 1, _hex_lower_udf)
    except AttributeError:
        # apsw path: ``createscalarfunction`` instead of ``create_function``.
        db.createscalarfunction("hex_lower", _hex_lower_udf, 1)

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
        # ``*_hash`` columns on the ledger DB are now BLOB(32); convert to
        # lowercase hex via the ``hex_lower`` UDF so ``object_id`` stays a
        # 64-char hex string (matching the runtime path that gets the value
        # via ``json.loads(event["bindings"])``).
        """
        INSERT INTO all_expirations (object_id, block_index, type)
        SELECT hex_lower(order_hash) AS object_id, block_index, 'order' AS type
        FROM ledger_db.order_expirations
        """,
        # ``*_match_id`` was replaced by a ``(*_tx0_index, *_tx1_index)`` pair;
        # reconstruct the composite ``tx0hash_tx1hash`` object_id by joining the
        # two tx indexes back to ``transactions``.
        """
        INSERT INTO all_expirations (object_id, block_index, type)
        SELECT hex_lower(t0.tx_hash) || '_' || hex_lower(t1.tx_hash) AS object_id,
               e.block_index, 'order_match' AS type
        FROM ledger_db.order_match_expirations e
        JOIN ledger_db.transactions t0 ON t0.tx_index = e.order_match_tx0_index
        JOIN ledger_db.transactions t1 ON t1.tx_index = e.order_match_tx1_index
        """,
        """
        INSERT INTO all_expirations (object_id, block_index, type)
        SELECT hex_lower(bet_hash) AS object_id, block_index, 'bet' AS type
        FROM ledger_db.bet_expirations
        """,
        """
        INSERT INTO all_expirations (object_id, block_index, type)
        SELECT hex_lower(t0.tx_hash) || '_' || hex_lower(t1.tx_hash) AS object_id,
               e.block_index, 'bet_match' AS type
        FROM ledger_db.bet_match_expirations e
        JOIN ledger_db.transactions t0 ON t0.tx_index = e.bet_match_tx0_index
        JOIN ledger_db.transactions t1 ON t1.tx_index = e.bet_match_tx1_index
        """,
        """
        INSERT INTO all_expirations (object_id, block_index, type)
        SELECT hex_lower(rps_hash) AS object_id, block_index, 'rps' AS type
        FROM ledger_db.rps_expirations
        """,
        """
        INSERT INTO all_expirations (object_id, block_index, type)
        SELECT hex_lower(t0.tx_hash) || '_' || hex_lower(t1.tx_hash) AS object_id,
               e.block_index, 'rps_match' AS type
        FROM ledger_db.rps_match_expirations e
        JOIN ledger_db.transactions t0 ON t0.tx_index = e.rps_match_tx0_index
        JOIN ledger_db.transactions t1 ON t1.tx_index = e.rps_match_tx1_index
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

    logger.debug("Populated the `all_expirations` table in %.2f seconds", time.time() - start_time)


def rollback(db):
    db.execute("DROP TABLE all_expirations")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
