#
# file: counterpartycore/lib/api/migrations/0002.create_and_populate_parsed_events.py
#
import binascii
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0001.create_and_populate_address_events"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return dict(zip(fields, row, strict=True))


def _hex_lower_udf(value):
    """SQLite UDF: BLOB/text -> 64-char lowercase hex string, NULL->NULL.

    ``ledger_db.messages.event_hash`` is BLOB(32) after the compact-hash
    storage migration. ``parsed_events.event_hash`` is declared TEXT, and
    SQLite does NOT implicitly coerce BLOB -> TEXT on INSERT, so we must
    explicitly hex-encode the value to keep the on-disk shape consistent
    with rows inserted at runtime via ``update_last_parsed_events`` (which
    binds 64-char hex strings).
    """
    if value is None:
        return None
    if isinstance(value, str):
        return value.lower()
    return binascii.hexlify(value).decode("ascii")


def apply(db):
    start_time = time.time()
    logger.debug("Populating the `parsed_events` table...")

    if hasattr(db, "row_factory"):
        db.row_factory = dict_factory

    # Register hex_lower so the ``event_hash`` projection produces lowercase
    # hex strings even though the underlying ledger column is BLOB(32). The
    # apsw-registered ``hex_lower`` UDF on the main connection is not visible
    # to the yoyo stdlib sqlite3 connection, so register a local shim.
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
        CREATE TABLE parsed_events(
            event_index INTEGER,
            event TEXT,
            event_hash TEXT,
            block_index INTEGER
        );
        """,
        # ``ledger_db.messages.event_hash`` is BLOB(32); hex-encode it so
        # the TEXT column stays consistent with rows produced at runtime
        # (which bind hex strings via ``update_last_parsed_events``).
        """
        INSERT INTO parsed_events (event_index, event, event_hash, block_index)
        SELECT message_index AS event_index, event, hex_lower(event_hash) AS event_hash, block_index
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

    logger.debug("Populated the `parsed_events` table in %.2f seconds", time.time() - start_time)


def rollback(db):
    db.execute("DROP TABLE parsed_events")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
