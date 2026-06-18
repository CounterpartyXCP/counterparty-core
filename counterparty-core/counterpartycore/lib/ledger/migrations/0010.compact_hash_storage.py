"""Compact hash storage migration.

This migration compacts the on-disk size of every hash-typed column on the
ledger schema. It applies two independent storage optimizations in a single
table-rewrite pass:

  1. Hex -> binary: every ``*_hash`` column (and derivatives like
     ``*_random_hash``/``offer_hash``) is converted from ``TEXT(64 hex)`` to
     ``BLOB(32)``. Indexes on those columns are rebuilt against the new
     binary representation. Approximate savings: 32 bytes per hash on the
     value, plus ~50% on every hash-related index.

  2. Hash -> tx_index foreign keys: a handful of tables that already store
     a ``tx_index`` no longer need to carry the duplicate ``tx_hash`` text
     column. The legacy column is dropped and, where it referenced another
     table's transaction, replaced by an integer ``*_tx_index`` foreign key
     resolved via a JOIN on ``transactions.tx_hash``. Affected tables:
     ``messages`` (drop ``tx_hash``, add ``tx_index``), ``transactions``
     (drop ``block_hash``), ``transaction_outputs`` (drop ``tx_hash``),
     ``cancels`` (``offer_hash`` -> ``offer_tx_index``), ``dispenses``,
     ``dispenser_refills`` (``dispenser_tx_hash`` -> ``dispenser_tx_index``),
     ``fairmints`` (``fairminter_tx_hash`` -> ``fairminter_tx_index``),
     ``pool_matches`` (``order_tx_hash`` -> ``order_tx_index``).

The PK ``transactions(tx_index, tx_hash, block_index)`` is reduced to
``(tx_index)`` to keep the composite-key story simple after ``block_hash``
is dropped.

Because the schema is enforced by ``BEFORE UPDATE ... RAISE(FAIL, ...)``
triggers on many tables, we use the create-new + INSERT SELECT + DROP +
RENAME pattern; the triggers themselves are dropped at the top of the
migration and recreated at the end against the new tables.

The data transformation relies on a tiny ``__hex_to_blob`` SQLite UDF that
the migration registers on the apsw/yoyo connection at the start of ``apply``.

This migration is idempotent in the sense that if it has already run, the
column types are BLOB and re-application is short-circuited via a version
sentinel stored in the ``config`` table.
"""

import logging
import sqlite3

import apsw
from counterpartycore.lib import config
from counterpartycore.lib.ledger.migration_data.compact_hash_schema import (
    ADDRESS_NAME_COLUMNS,
    ASSET_NAME_COLUMNS,
    CUSTOM_INSERT_SELECT,
    INDEXES_AFTER_REWRITE,
    NO_UPDATE_TRIGGERS,
    TABLE_REWRITES,
    TRIGGERS_AFTER_REWRITE,
    VIEWS_AFTER_REWRITE,
)
from counterpartycore.lib.utils import hashcodec
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

# DB driver errors raised by ``cursor.execute`` when the targeted table is
# missing. yoyo may pass either an apsw connection (apsw.SQLError) or a
# stdlib sqlite3 connection (sqlite3.OperationalError) depending on its
# backend. Group them so the idempotency probe doesn't depend on which
# driver yoyo selected at runtime.
_DB_PROBE_ERRORS = (apsw.SQLError, sqlite3.OperationalError, sqlite3.DatabaseError)


SENTINEL_NAME = "COMPACT_HASH_STORAGE_APPLIED"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _register_udfs(db):
    hashcodec.register_db_functions(db)


def _table_has_column(cursor, table, column):
    rows = cursor.execute(f"PRAGMA table_info({table})").fetchall()
    if not rows:
        return False
    if isinstance(rows[0], dict):
        names = {r["name"] for r in rows}
    else:
        names = {r[1] for r in rows}
    return column in names


def _populate_address_list(cursor, renamed_tables):
    """Populate the brand-new ``address_list`` id table from the DISTINCT set of
    every address value across all renamed ``*_old`` tables.

    Run AFTER phase 1 (the ``*_old`` tables exist) and BEFORE phase 2 (so the
    per-table copy can resolve addresses to ids). ``address_id`` auto-assigns in
    ``ORDER BY address`` order, which makes the assignment deterministic (it is
    an internal FK only -- consensus and API see the decoded string). Only the
    ``ADDRESS_NAME_COLUMNS`` sources are unioned, each guarded by
    ``_table_has_column`` so a column absent at migration time is skipped;
    ``mempool``/``mempool_transactions`` are excluded (transient / list)."""
    selects = []
    for table, columns in ADDRESS_NAME_COLUMNS.items():
        if table not in renamed_tables:
            continue
        old_table = f"{table}_old"
        for col in columns:
            if _table_has_column(cursor, old_table, col):
                selects.append(
                    f"SELECT {col} AS addr FROM {old_table} WHERE {col} IS NOT NULL"  # nosec B608  # noqa: S608
                )
    if not selects:
        return
    union_sql = " UNION ALL ".join(selects)
    cursor.execute(
        "INSERT INTO address_list (address) "  # nosec B608  # noqa: S608
        f"SELECT DISTINCT addr FROM ({union_sql}) ORDER BY addr"
    )


def _column_affinity(cursor, table, column):
    rows = cursor.execute(f"PRAGMA table_info({table})").fetchall()
    for r in rows:
        if isinstance(r, dict):
            if r["name"] == column:
                return (r["type"] or "").upper()
        else:
            if r[1] == column:
                return (r[2] or "").upper()
    return None


def _index_definitions(cursor, table):
    """Return a list of (name, sql) for every index on ``table`` that isn't an
    auto index for the table's primary key."""
    rows = cursor.execute(
        "SELECT name, sql FROM sqlite_master "
        "WHERE type='index' AND tbl_name = ? AND sql IS NOT NULL",
        (table,),
    ).fetchall()
    out = []
    for r in rows:
        name = r["name"] if isinstance(r, dict) else r[0]
        sql = r["sql"] if isinstance(r, dict) else r[1]
        out.append((name, sql))
    return out


def _drop_views(cursor):
    """Drop legacy views; they reference tables we are about to recreate.
    We recreate them at the end of the migration with the new column types."""
    for view in (
        "all_holders",
        "all_expirations",
        "all_transactions",
        "all_transactions_with_status",
        "transactions_with_status",
    ):
        cursor.execute(f"DROP VIEW IF EXISTS {view}")  # nosec B608


def _drop_triggers(cursor):
    for trig in NO_UPDATE_TRIGGERS:
        cursor.execute(f"DROP TRIGGER IF EXISTS {trig}")  # nosec B608


# ---------------------------------------------------------------------------
# Main migration entry points
# ---------------------------------------------------------------------------


def apply(conn):
    """Apply the compact-hash storage migration to the ledger DB.

    ``conn`` is the yoyo-provided connection (a stock sqlite3 connection wrapped
    in apsw on some versions). We coerce to the same row-factory contract as
    the rest of the codebase by extracting the underlying connection.
    """
    db = conn
    # yoyo sometimes passes the apsw Connection directly; sometimes a sqlite3
    # connection. Both expose ``cursor()``.
    cursor = db.cursor()

    if hasattr(cursor, "fetchone"):
        # sqlite3 stdlib path: rows come back as tuples by default.
        pass

    # Idempotency: bail if already applied (the rerun-safe shape avoids
    # double work on dev DBs).
    try:
        row = cursor.execute("SELECT value FROM config WHERE name = ?", (SENTINEL_NAME,)).fetchone()
    except _DB_PROBE_ERRORS:
        # ``config`` may not exist yet on a fresh DB; treat that as
        # "not applied" and let the migration create the table downstream.
        row = None
    if row:
        logger.info("Compact-hash storage migration already applied, skipping.")
        return

    # Register the apsw UDF for hex -> BLOB; yoyo on apsw exposes
    # ``createscalarfunction`` on the connection.
    try:
        db.createscalarfunction("__hex_to_blob", _hex_to_blob_udf, 1)
    except AttributeError:
        # stdlib sqlite3 path
        db.create_function("__hex_to_blob", 1, _hex_to_blob_udf)

    # Also register ``hex_lower``/``unhex`` on the migration connection: the
    # views recreated at the end of this migration reference ``hex_lower``, and
    # registering it now keeps the recreate robust even if a future SQLite/yoyo
    # backend validates a view body at CREATE time (it does not today).
    _register_udfs(db)

    # Make sure we can recreate tables freely. ``legacy_alter_table = ON``
    # prevents SQLite from auto-rewriting FK references in *other* tables
    # when we RENAME a parent table -- without it, ``ALTER TABLE blocks
    # RENAME TO blocks_old`` will silently retarget every dependent FK
    # (credits, debits, ...) to ``blocks_old`` and then crash when the
    # legacy table is dropped at the end of the migration.
    #
    # NB: ``PRAGMA foreign_keys`` is a no-op inside a transaction, and yoyo runs
    # this step transactionally -- so the actual guarantee that dropping the
    # ``*_old`` tables won't trip FK enforcement comes from yoyo's sqlite
    # backend leaving ``foreign_keys`` OFF by default, reinforced by
    # ``defer_foreign_keys``/``legacy_alter_table`` below. The OFF here is kept
    # for the non-transactional fallback and as intent; if a future backend
    # enables FKs the drop phase must be revisited.
    cursor.execute("PRAGMA foreign_keys = OFF")
    cursor.execute("PRAGMA defer_foreign_keys = ON")
    cursor.execute("PRAGMA legacy_alter_table = ON")

    _drop_views(cursor)
    _drop_triggers(cursor)

    # Phase 1: rename all existing tables to ``<table>_old`` so cross-table
    # JOINs (resolution of hex tx_hash -> tx_index for the FK-conversion
    # tables) can run against the legacy data after individual rewrites
    # complete.
    renamed_tables = []
    for entry in TABLE_REWRITES:
        table = entry[0]
        new_create_sql = entry[2]
        existing = cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
            (table,),
        ).fetchone()
        if not existing:
            cursor.execute(new_create_sql)
            continue
        cursor.execute(f"ALTER TABLE {table} RENAME TO {table}_old")  # nosec B608
        cursor.execute(new_create_sql)
        renamed_tables.append(table)

    # Phase 1b: populate the brand-new ``address_list`` id table from the
    # DISTINCT set of every address value across the ``*_old`` tables, so the
    # per-table copy below can resolve each address to its compact
    # ``address_id``. Must run after all renames and before any copy.
    _populate_address_list(cursor, renamed_tables)

    # Phase 2: copy data from each ``_old`` into the new tables. JOINs against
    # ``transactions_old`` work because all old tables are still present.
    for entry in TABLE_REWRITES:
        if len(entry) == 4:
            table, columns, _new_create_sql, hex_columns = entry
        else:
            table, columns, _new_create_sql, hex_columns, *_ = entry

        if table not in renamed_tables:
            continue

        if table in CUSTOM_INSERT_SELECT:
            select_sql = CUSTOM_INSERT_SELECT[table]
            cursor.execute(
                f"INSERT INTO {table} ({', '.join(columns)}) {select_sql}"  # nosec B608  # noqa: S608
            )
        else:
            # Asset-name columns are resolved to the compact ``asset_index`` via
            # a correlated subquery on the freshly-populated ``assets`` table
            # (``assets`` is first in TABLE_REWRITES, so it is fully rewritten
            # before any other table runs). Only columns present in this
            # table's column list are touched, so an asset column that does not
            # yet exist at migration time (e.g. ``fairminters.lp_asset``, added
            # by 0011) is naturally skipped.
            asset_cols = ASSET_NAME_COLUMNS.get(table, ())
            addr_cols = ADDRESS_NAME_COLUMNS.get(table, ())
            select_cols = []
            for col in columns:
                if col in hex_columns:
                    select_cols.append(f"__hex_to_blob({col}) AS {col}")
                elif col in asset_cols:
                    select_cols.append(
                        f"(SELECT a.asset_index FROM assets a "  # nosec B608  # noqa: S608
                        f"WHERE a.asset_name = {table}_old.{col}) AS {col}"
                    )
                elif col in addr_cols:
                    select_cols.append(
                        f"(SELECT al.address_id FROM address_list al "  # nosec B608  # noqa: S608
                        f"WHERE al.address = {table}_old.{col}) AS {col}"
                    )
                else:
                    select_cols.append(col)
            cursor.execute(
                f"INSERT INTO {table} ({', '.join(columns)}) "  # nosec B608  # noqa: S608
                f"SELECT {', '.join(select_cols)} FROM {table}_old"
            )

    # Phase 3: drop all the renamed legacy tables.
    for table in renamed_tables:
        cursor.execute(f"DROP TABLE {table}_old")  # nosec B608

    # 5. Recreate triggers and indexes.
    for trig_sql in TRIGGERS_AFTER_REWRITE:
        cursor.execute(trig_sql)
    for idx_sql in INDEXES_AFTER_REWRITE:
        cursor.execute(idx_sql)

    # 6. Recreate views referencing the new tables.
    for view_sql in VIEWS_AFTER_REWRITE:
        cursor.execute(view_sql)

    # 7. Sentinel so we don't re-run.
    cursor.execute(
        "INSERT OR REPLACE INTO config (name, value) VALUES (?, ?)",
        (SENTINEL_NAME, "1"),
    )

    cursor.execute("PRAGMA legacy_alter_table = OFF")
    cursor.execute("PRAGMA foreign_keys = ON")
    logger.info("Compact-hash storage migration applied.")


def rollback(conn):
    # Rollback is not supported for this migration: the data transformation
    # is one-directional. Operators should restore from bootstrap.
    raise NotImplementedError(
        "Compact-hash storage migration cannot be rolled back; restore from bootstrap."
    )


def _hex_to_blob_udf(value):
    """SQLite UDF: convert a hex string to BLOB, or NULL to NULL."""
    if value is None:
        return None
    if isinstance(value, bytes):
        return value
    if value == "":
        return None
    return bytes.fromhex(value)


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
