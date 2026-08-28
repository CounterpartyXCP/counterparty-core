"""Incremental State DB rollback (issue #3485).

Historically ``dbbuilder.rollback_state_db()`` did not roll anything back: it
deleted the rows of three append-only tables and then *re-applied* thirteen
migrations, each of which drops its table and repopulates it from the entire
ledger history. The cost was therefore O(history) and independent of how deep
the reorganization was -- a one-block mainnet reorg rebuilt the whole State DB
(~33 minutes, and the API degraded badly for the last minutes of it because
the single giant write transaction grew the WAL to several GB).

This module reverts only what the orphaned blocks changed:

  * **append-only tables** (``parsed_events``, ``address_events``,
    ``all_expirations``, ``pool_matches``) are pruned by ``block_index``;
  * **consolidated tables** (``balances``, ``orders``, ... -- one row per
    object, holding its latest version) have their rows touched at or after the
    rollback point deleted and re-inserted from the object's latest Ledger DB
    version *strictly below* the rollback point;
  * **counters** (``events_count``, ``transaction_types_count``) are
    decremented / re-derived, and ``assets_info`` -- a pure projection of the
    ledger's issuance history -- is re-derived with the same block bound.

The cost is proportional to the number of rows the orphaned blocks touched.

Why "strictly below the rollback point" matters
-----------------------------------------------
When the API watcher detects a reorganization the Ledger DB has *already*
rolled back and may have re-parsed part of the new chain. Restoring a row to
the ledger's current tip would leave the State DB ahead of ``parsed_events``,
and the watcher's forward replay would then apply those blocks a second time.
Every ledger read here is therefore bounded by ``block_index < rollback point``.
That bound is safe because the watcher derives the rollback point from the last
*matching* event hash, which is necessarily at or below the ledger's own
rollback point.
"""

import logging
import time

from counterpartycore.lib import config
from counterpartycore.lib.api import statetables
from counterpartycore.lib.utils import database
from counterpartycore.lib.utils.database import (
    ADDRESS_INDEX_COLUMN_NAMES,
    ASSET_INDEX_COLUMN_NAMES,
)

logger = logging.getLogger(config.LOGGER_NAME)


# Deeper than this and a full rebuild is both simpler and (past a point)
# cheaper than reverting row by row. Real reorganizations are one or two
# blocks; the deep rollbacks in ``config.UPGRADE_ACTIONS`` intentionally want
# the full rebuild anyway, since the derivation rules themselves may have
# changed between releases.
MAX_INCREMENTAL_DEPTH = 1000

# Set on every State DB whose ``balances.block_index`` is known to be
# maintained (see ``apiwatcher.update_balances``). Without that column being
# up to date, the consolidated-table restore cannot find which balances an
# orphaned block touched, so a State DB missing the marker falls back to the
# full rebuild -- which sets the marker, making the fallback self-healing.
READY_FLAG = "INCREMENTAL_ROLLBACK_READY"

# Returned by ``rollback_reason`` when the State DB is already below the
# requested block. Unlike the other reasons this one does *not* select the full
# rebuild: there is nothing to undo, and re-deriving every table from the whole
# ledger history to achieve nothing would be the most expensive no-op available.
# Reached from the CLI (``counterparty-server rollback/reparse`` to a block the
# State DB has not caught up to yet), and from ``apiwatcher.check_reorg`` when
# the ledger invalidates a block the watcher had not started copying.
#
# "Below" is measured against ``apiwatcher.get_last_block_touched`` -- the block
# of the last event copied -- and not against the last block *completed*. A
# reorganization caught mid-block targets ``last_block_parsed + 1``, so measuring
# against the completed tip would answer "nothing to roll back" for the very case
# that has orphaned rows to remove.
NOTHING_TO_ROLL_BACK = "nothing to roll back"

# Append-only State DB tables: every row carries the ``block_index`` of the
# event that produced it, so reverting is a DELETE.
PRUNABLE_TABLES = [
    "parsed_events",
    "address_events",
    "all_expirations",
    # keyed on ``rowid`` by migration 0014, i.e. copied verbatim from the
    # ledger and never updated in place.
    "pool_matches",
]


def _fetch_one(db, query, bindings=None):
    cursor = db.cursor()
    cursor.execute(query, bindings)
    return cursor.fetchone()


def _table_exists(db, table_name):
    row = _fetch_one(
        db,
        "SELECT COUNT(*) AS count FROM sqlite_master WHERE type = 'table' AND name = ?",
        (table_name,),
    )
    return row is not None and row["count"] > 0


def attach_ledger_db(db):
    """Attach ``ledger_db`` if the caller has not already done so."""
    row = _fetch_one(
        db,
        "SELECT COUNT(*) AS count FROM pragma_database_list WHERE name = ?",
        ("ledger_db",),
    )
    if row is not None and row["count"] > 0:
        return False
    db.cursor().execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))
    return True


def mark_ready(state_db):
    """Record that this State DB was fully derived from the Ledger DB and is
    therefore eligible for incremental rollback."""
    database.set_config_value(state_db, READY_FLAG, "1")


def is_ready(state_db):
    return database.get_config_value(state_db, READY_FLAG) == "1"


def rollback_reason(state_db, block_index):
    """Return ``None`` when the incremental path applies, else a short reason
    explaining why the caller must take another path.

    :data:`NOTHING_TO_ROLL_BACK` is the one reason that does not mean "fall
    back to the full rebuild" -- see the caller in ``dbbuilder``.

    Any unexpected failure here (a State DB old enough to be missing the
    ``config`` or ``parsed_events`` table, say) also selects the full rebuild:
    this function only picks a path, and the full rebuild is always correct.
    """
    # A local import: apiwatcher imports dbbuilder, which imports this module.
    # pylint: disable=import-outside-toplevel
    from counterpartycore.lib.api import apiwatcher  # noqa: PLC0415

    if block_index <= config.BLOCK_FIRST:
        return "full rollback requested"
    try:
        if not is_ready(state_db):
            return "State DB predates incremental rollback support"
        # The last block *touched*, not the last one completed: while a block is
        # half copied its rows are the ones a reorganization orphans, and they
        # sit one block above the last BLOCK_PARSED. Measuring against the
        # completed tip reports NOTHING_TO_ROLL_BACK for exactly that case and
        # leaves the orphaned rows -- and their applied mutations -- in place.
        last_block_touched = apiwatcher.get_last_block_touched(state_db)
    except Exception as e:  # pylint: disable=broad-except
        # Deliberately broad: this function only picks a path. Anything that
        # stops us inspecting the State DB -- an apsw error on a schema too old
        # to have ``config`` / ``parsed_events``, a cached tip that will not
        # parse as an int -- must select the full rebuild rather than propagate.
        return f"State DB cannot be inspected ({e})"
    if last_block_touched <= 0:
        return "State DB is empty"
    if block_index > last_block_touched:
        return NOTHING_TO_ROLL_BACK
    depth = last_block_touched - block_index + 1
    if depth > MAX_INCREMENTAL_DEPTH:
        return f"rollback depth ({depth} blocks) exceeds {MAX_INCREMENTAL_DEPTH}"
    return None


# -----------------------------------------------------------------------------
# Consolidated tables
# -----------------------------------------------------------------------------


def _ledger_match_clause(column):
    """SQL matching one State DB key column (``s``) against its Ledger DB
    counterpart (``b``).

    ``IS`` rather than ``=`` throughout: the key columns are nullable
    (``balances`` rows are keyed on *either* ``address`` or ``utxo``) and
    SQLite treats ``IS`` as a null-safe ``=``, index lookups included.
    """
    if column == "utxo":
        # ``utxo`` is the ``<64 hex chars>:<vout>`` string; the Ledger DB keeps
        # the compact ``(utxo_tx_hash BLOB, utxo_vout)`` pair. A NULL utxo
        # (an address balance) yields NULL on both halves.
        return (
            "b.utxo_tx_hash IS unhex(substr(s.utxo, 1, 64)) "
            "AND b.utxo_vout IS CAST(substr(s.utxo, 66) AS INTEGER)"
        )
    if column in ASSET_INDEX_COLUMN_NAMES:
        return (
            f"b.{column} IS (SELECT asset_index FROM ledger_db.assets "  # noqa: S608  # nosec B608
            f"WHERE asset_name = s.{column})"
        )
    if column in ADDRESS_INDEX_COLUMN_NAMES:
        return (
            f"b.{column} IS (SELECT address_id FROM ledger_db.address_list "  # noqa: S608  # nosec B608
            f"WHERE address = s.{column})"
        )
    # ``tx_hash`` / ``tx0_index`` / ``tx1_index``: same representation on both
    # sides (BLOB(32) and INTEGER respectively).
    return f"b.{column} IS s.{column}"


def _restore_consolidated_table(state_db, table, key_columns, block_index):
    """Revert one consolidated table to its state at ``block_index - 1``.

    Returns the number of objects reverted.
    """
    block_index = int(block_index)
    match = " AND ".join(_ledger_match_clause(column) for column in key_columns)
    cursor = state_db.cursor()

    # For every object whose latest version was written at or after the
    # rollback point, find the rowid of its latest Ledger DB version strictly
    # below it (NULL when the object did not exist before the reorg).
    cursor.execute("DROP TABLE IF EXISTS temp.rollback_restore")
    cursor.execute(f"""
        CREATE TEMP TABLE rollback_restore AS
        SELECT
            s.rowid AS state_rowid,
            (
                SELECT MAX(b.rowid) FROM ledger_db.{table} b
                WHERE {match} AND b.block_index < {block_index}
            ) AS ledger_rowid
        FROM {table} s
        WHERE s.block_index >= {block_index}
    """)  # noqa: S608  # nosec B608

    reverted = _fetch_one(state_db, "SELECT COUNT(*) AS count FROM rollback_restore")["count"]
    if reverted == 0:
        cursor.execute("DROP TABLE temp.rollback_restore")
        return 0

    cursor.execute(f"""
        DELETE FROM {table} WHERE rowid IN (SELECT state_rowid FROM rollback_restore)
    """)  # noqa: S608  # nosec B608

    names, expressions = statetables.consolidated_projection(state_db, table)
    cursor.execute(f"""
        INSERT INTO {table} ({", ".join(names)})
        SELECT {", ".join(expressions)}
        FROM ledger_db.{table} b
        WHERE b.rowid IN (
            SELECT ledger_rowid FROM rollback_restore WHERE ledger_rowid IS NOT NULL
        )
    """)  # noqa: S608  # nosec B608

    cursor.execute("DROP TABLE temp.rollback_restore")
    logger.debug("Reverted %s object(s) in `%s`", reverted, table)
    return reverted


def _refresh_fairminter_totals(state_db, block_index):
    """Recompute ``fairminters``' ``earned_quantity`` / ``paid_quantity`` /
    ``commission``, which are aggregated from ``fairmints`` rather than copied
    from the ledger row (migration 0006's POST_QUERIES, and
    ``apiwatcher.update_fairminters`` at runtime).
    """
    block_index = int(block_index)
    cursor = state_db.cursor()
    cursor.execute("DROP TABLE IF EXISTS temp.rollback_fairmints")
    cursor.execute(f"""
        CREATE TEMP TABLE rollback_fairmints AS
        SELECT
            fairminter_tx_index,
            SUM(earn_quantity) AS earned_quantity,
            SUM(paid_quantity) AS paid_quantity,
            SUM(commission) AS commission
        FROM ledger_db.fairmints
        WHERE status = 'valid' AND block_index < {block_index}
        GROUP BY fairminter_tx_index
    """)  # noqa: S608  # nosec B608
    cursor.execute(
        "CREATE INDEX temp.rollback_fairmints_idx ON rollback_fairmints(fairminter_tx_index)"
    )
    # A fairminter with no valid fairmint left gets NULL back, which is what a
    # fresh build produces (SUM over an empty set).
    cursor.execute("""
        UPDATE fairminters SET
            earned_quantity = (
                SELECT earned_quantity FROM rollback_fairmints t
                WHERE t.fairminter_tx_index = fairminters.tx_index
            ),
            paid_quantity = (
                SELECT paid_quantity FROM rollback_fairmints t
                WHERE t.fairminter_tx_index = fairminters.tx_index
            ),
            commission = (
                SELECT commission FROM rollback_fairmints t
                WHERE t.fairminter_tx_index = fairminters.tx_index
            )
    """)
    cursor.execute("DROP TABLE temp.rollback_fairmints")


# -----------------------------------------------------------------------------
# Counters and projections
# -----------------------------------------------------------------------------


def _collect_orphan_events(state_db, block_index):
    """Tally the events the orphaned blocks produced, *before* pruning
    ``parsed_events``. Returns ``{event name: count}``; the same counts stay in
    the ``rollback_events`` temp table for ``_rollback_events_count``.
    """
    block_index = int(block_index)
    cursor = state_db.cursor()
    cursor.execute("DROP TABLE IF EXISTS temp.rollback_events")
    cursor.execute(f"""
        CREATE TEMP TABLE rollback_events AS
        SELECT event, COUNT(*) AS orphan_count
        FROM parsed_events
        WHERE block_index >= {block_index}
        GROUP BY event
    """)  # noqa: S608  # nosec B608
    rows = state_db.cursor().execute("SELECT event, orphan_count FROM rollback_events").fetchall()
    return {row["event"]: row["orphan_count"] for row in rows}


def _rollback_events_count(state_db):
    """Subtract the orphaned events from ``events_count``. Exact: the streamed
    handler increments it once per row inserted into ``parsed_events``."""
    cursor = state_db.cursor()
    cursor.execute("""
        UPDATE events_count SET count = count - COALESCE(
            (SELECT orphan_count FROM rollback_events o WHERE o.event = events_count.event), 0
        )
    """)
    # A negative count cannot happen if the invariant above holds, so it is
    # worth a warning rather than a silent DELETE: it would mean the streamed
    # handler and ``parsed_events`` have drifted apart, and every later rollback
    # would be wrong in the same way.
    negative = cursor.execute("SELECT event, count FROM events_count WHERE count < 0").fetchall()
    if negative:
        logger.warning(
            "`events_count` went negative while rolling back, which should be impossible: %s. "
            "Rebuild the State DB with `--rebuild-state-db` to resynchronize it.",
            {row["event"]: row["count"] for row in negative},
        )
    # An event type that no longer occurs at all is absent from a fresh build,
    # not present with a zero count.
    cursor.execute("DELETE FROM events_count WHERE count <= 0")
    cursor.execute("DROP TABLE temp.rollback_events")


def _rebuild_transaction_types_count(state_db, block_index):
    """``transaction_types_count`` cannot be decremented from ``parsed_events``
    (which does not record the transaction type) and the orphaned
    ``transactions`` rows are already gone from the ledger, so re-derive it --
    a single grouped scan, no table drop and no index rebuild."""
    block_index = int(block_index)
    cursor = state_db.cursor()
    cursor.execute("DELETE FROM transaction_types_count")
    cursor.execute(f"""
        INSERT INTO transaction_types_count (transaction_type, count)
        SELECT transaction_type, COUNT(*) AS counter
        FROM ledger_db.transactions
        WHERE block_index < {block_index}
        GROUP BY transaction_type
    """)  # noqa: S608  # nosec B608


def _rebuild_assets_info(state_db, block_index):
    cursor = state_db.cursor()
    cursor.execute("DELETE FROM assets_info")
    statetables.populate_assets_info(state_db, max_block_index=block_index)


# -----------------------------------------------------------------------------
# Entry point
# -----------------------------------------------------------------------------


def rollback(state_db, block_index):
    """Revert the State DB to its state at ``block_index - 1``.

    The caller is responsible for the enclosing transaction, for having checked
    :func:`rollback_reason`, and for having disabled foreign-key enforcement --
    ``PRAGMA foreign_keys`` is a no-op inside a transaction, so it cannot be set
    here (see :func:`rollback_state_db`).
    """
    # Local import: apiwatcher imports dbbuilder, which imports this module.
    # pylint: disable=import-outside-toplevel
    from counterpartycore.lib.api import apiwatcher  # noqa: PLC0415

    # Left attached on exit, like the migration path: this is the long-lived
    # State DB write connection, and DETACH is not valid inside a transaction.
    attach_ledger_db(state_db)
    cursor = state_db.cursor()

    orphan_counts = _collect_orphan_events(state_db, block_index)
    orphan_events = set(orphan_counts)

    for table in PRUNABLE_TABLES:
        if not _table_exists(state_db, table):
            continue
        cursor.execute(
            f"DELETE FROM {table} WHERE block_index >= ?",  # noqa: S608  # nosec B608
            (block_index,),
        )

    reverted = {}
    for table, key_columns in statetables.STATE_CONSOLIDATED_KEYS.items():
        if not _table_exists(state_db, table):
            # AMM pool tables do not exist before activation.
            continue
        reverted[table] = _restore_consolidated_table(state_db, table, key_columns, block_index)

    _rollback_events_count(state_db)
    if "NEW_TRANSACTION" in orphan_events:
        _rebuild_transaction_types_count(state_db, block_index)
    if reverted.get("fairminters") or "NEW_FAIRMINT" in orphan_events:
        _refresh_fairminter_totals(state_db, block_index)

    asset_events = set(apiwatcher.ASSET_EVENTS) | set(apiwatcher.XCP_DESTROY_EVENTS)
    if orphan_events & asset_events:
        _rebuild_assets_info(state_db, block_index)

    # ``parsed_events`` shrank, so the cached tip must be recomputed.
    apiwatcher.update_last_parsed_events_cache(state_db, event=None)
    # The State DB now sits exactly at ``block_index - 1``, so the
    # double-counting guard a full rebuild needs (which copies balances
    # from the ledger's *current* tip) does not apply here.
    database.set_config_value(state_db, "BALANCES_COPIED_AT_BLOCK", None)
    mark_ready(state_db)

    # Logged at INFO: this line is the only visibility an operator has into
    # what a reorganization actually cost them.
    logger.info(
        "Reverted %s event(s) and %s object(s) %s",
        sum(orphan_counts.values()),
        sum(reverted.values()),
        {table: count for table, count in reverted.items() if count},
    )


def rollback_state_db(state_db, block_index):
    """Incrementally roll the State DB back to ``block_index - 1``."""
    logger.info("Rolling back State DB to block index %s (incremental)...", block_index)
    start_time = time.time()
    cursor = state_db.cursor()
    # Migration 0006 copies the Ledger DB's CREATE TABLE statements verbatim, so
    # several consolidated tables carry FOREIGN KEY clauses pointing at parent
    # tables (``blocks``, ``transactions``) that the State DB does not have.
    # Enforcement has to be off while their rows are deleted and re-inserted --
    # and ``PRAGMA foreign_keys`` is a documented no-op inside a transaction, so
    # it must be set here, *before* ``with state_db:`` opens one.
    cursor.execute("PRAGMA foreign_keys=OFF")
    try:
        with state_db:
            rollback(state_db, block_index)
    finally:
        cursor.execute("PRAGMA foreign_keys=ON")
    logger.info("State DB rolled back in %.2f seconds", time.time() - start_time)
