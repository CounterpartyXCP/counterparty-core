"""Shared derivation rules for the State DB tables that mirror the Ledger DB.

Two independent code paths populate those tables from ``ledger_db``:

  * the **build** path -- API migrations ``0004`` (``assets_info``), ``0006``
    (consolidated tables) and ``0014`` (AMM pool tables) -- which recreates
    every table from the full ledger history, and
  * the **incremental rollback** path (:mod:`counterpartycore.lib.api.staterollback`),
    which reverts only the rows a reorganization invalidated.

Both must derive each row *identically*: the State DB stores decoded asset
names, address strings and ``tx_hash:vout`` utxo strings where the Ledger DB
stores the compact ``asset_index`` / ``address_id`` / ``(utxo_tx_hash,
utxo_vout)`` pair. Any drift between the two projections would silently
diverge a rolled-back node from a freshly built one -- the exact class of bug
that is impossible to detect from the API. The rules therefore live here,
once, and both paths import them.

This module deliberately depends only on ``config`` and ``utils.database``:
it is imported by yoyo-driven migrations, which run on a stdlib ``sqlite3``
connection outside the usual apsw plumbing.
"""

import logging

from counterpartycore.lib import config
from counterpartycore.lib.utils.database import (
    ADDRESS_INDEX_COLUMN_NAMES,
    ASSET_INDEX_COLUMN_NAMES,
)

logger = logging.getLogger(config.LOGGER_NAME)


# Consolidated tables copied from ``ledger_db`` by migration 0006, mapped to
# the column list that identifies a unique object. The Ledger DB keeps every
# version of an object as an appended row; the State DB keeps only the latest
# one (``MAX(rowid)`` per key).
LEDGER_CONSOLIDATED_KEYS = {
    "fairminters": "tx_hash",
    # ``utxo`` is the compact ``(utxo_tx_hash, utxo_vout)`` ledger pair; group
    # by both halves (the State DB stores the reconstructed ``utxo`` string).
    "balances": "address, utxo_tx_hash, utxo_vout, asset",
    "addresses": "address",
    "dispensers": "source, asset, tx_hash",
    # match tables: the composite TEXT ``id`` was dropped; the match is keyed
    # by the ``(tx0_index, tx1_index)`` pair (compact-hash storage migration).
    "bet_matches": "tx0_index, tx1_index",
    "bets": "tx_hash",
    "order_matches": "tx0_index, tx1_index",
    "orders": "tx_hash",
    "rps": "tx_hash",
    "rps_matches": "tx0_index, tx1_index",
}

# Same, for the AMM pool tables added by migration 0014. ``pool_matches`` is
# keyed on ``rowid``, i.e. it is append-only and copied verbatim.
LEDGER_POOL_KEYS = {
    "pools": "asset_a, asset_b",
    "pool_deposits": "tx_hash",
    "pool_withdrawals": "tx_hash",
    "pool_matches": "rowid",
}

# The same keys expressed in **State DB** column names, for the rollback path
# (which starts from a State DB row and looks up its Ledger DB ancestor).
# Identical to the two dicts above except for ``balances``, where the State DB
# keeps the reconstructed ``utxo`` string instead of the compact pair, and for
# ``pool_matches``, which is append-only (see ``PRUNABLE_TABLES``).
STATE_CONSOLIDATED_KEYS = {
    "fairminters": ["tx_hash"],
    "balances": ["address", "utxo", "asset"],
    "addresses": ["address"],
    "dispensers": ["source", "asset", "tx_hash"],
    "bet_matches": ["tx0_index", "tx1_index"],
    "bets": ["tx_hash"],
    "order_matches": ["tx0_index", "tx1_index"],
    "orders": ["tx_hash"],
    "rps": ["tx_hash"],
    "rps_matches": ["tx0_index", "tx1_index"],
    "pools": ["asset_a", "asset_b"],
    "pool_deposits": ["tx_hash"],
    "pool_withdrawals": ["tx_hash"],
}

# State DB columns that have no Ledger DB counterpart and must be derived by
# an explicit expression when copying a ledger row (``b`` is the ledger row).
# Columns absent from both the ledger table and this map are left out of the
# copy entirely (they are maintained separately -- see ``fairminters``'
# ``earned_quantity`` / ``paid_quantity`` / ``commission``, aggregated from
# ``fairmints``).
DERIVED_COLUMNS = {
    "balances": {
        # reconstruct the ``tx_hash:vout`` string from the compact ledger
        # ``(utxo_tx_hash, utxo_vout)`` pair (``lower(hex(...))`` yields the
        # lowercase hex the utxo string used; a NULL tx_hash -> NULL utxo).
        "utxo": "lower(hex(b.utxo_tx_hash)) || ':' || b.utxo_vout",
        # ``asset_longname`` is not a ledger column: migration 0006 adds it with
        # ALTER TABLE *after* the bulk INSERT and fills it from ``assets`` in its
        # POST_QUERIES, so on the build path this rule is never reached (the
        # column does not exist yet when the projection is computed). It exists
        # for the rollback path, where the column is already there and a restored
        # row would otherwise come back with a NULL longname. Same value, same
        # source -- ``ledger_db.assets`` -- as both the migration's POST_QUERY
        # and ``apiwatcher.update_balances`` (which reads it back out of
        # ``assets_info``, itself a projection of ``ledger_db.assets``).
        "asset_longname": (
            "(SELECT asset_longname FROM ledger_db.assets WHERE asset_index = b.asset)"
        ),
    },
}


def _rows(db, sql, bindings=None):
    """Fetch rows as dicts on both apsw and stdlib sqlite3 connections."""
    cursor = db.execute(sql, bindings) if bindings else db.execute(sql)
    return cursor.fetchall()


def _column_names(db, table_name, schema="main"):
    rows = _rows(db, f"PRAGMA {schema}.table_info({table_name})")  # noqa: S608  # nosec B608
    names = []
    for row in rows:
        names.append(row["name"] if isinstance(row, dict) else row[1])
    return names


def consolidated_projection(db, table_name):
    """Return ``(column_names, select_expressions)`` for copying one
    ``ledger_db.<table_name>`` row (aliased ``b``) into the State DB table of
    the same name.

    ``ledger_db`` must be attached to ``db``. Asset / address columns are
    decoded to their TEXT name, ``*_hash`` columns are copied verbatim (both
    schemas store BLOB(32)), and per-table derived columns come from
    ``DERIVED_COLUMNS``.
    """
    ledger_columns = set(_column_names(db, table_name, schema="ledger_db"))
    derived = DERIVED_COLUMNS.get(table_name, {})

    names = []
    expressions = []
    for column in _column_names(db, table_name):
        if column in derived:
            names.append(column)
            expressions.append(f"{derived[column]} AS {column}")
        elif column in ASSET_INDEX_COLUMN_NAMES and column in ledger_columns:
            # The State DB stores asset *names* (it must read its own rows
            # without the Ledger DB attached); decode the compact index.
            names.append(column)
            expressions.append(
                f"(SELECT asset_name FROM ledger_db.assets WHERE asset_index = b.{column}) AS {column}"  # noqa: S608  # nosec B608
            )
        elif column in ADDRESS_INDEX_COLUMN_NAMES and column in ledger_columns:
            names.append(column)
            expressions.append(
                f"(SELECT address FROM ledger_db.address_list WHERE address_id = b.{column}) AS {column}"  # noqa: S608  # nosec B608
            )
        elif column in ledger_columns:
            names.append(column)
            expressions.append(f"b.{column}")
        # else: a State DB-only column with no derivation rule; skipped.

    return names, expressions


# -----------------------------------------------------------------------------
# assets_info
# -----------------------------------------------------------------------------

ASSETS_INFO_COLUMNS = """
    asset,
    asset_id,
    asset_longname,
    issuer,
    owner,
    divisible,
    locked,
    supply,
    description,
    description_locked,
    first_issuance_block_index,
    last_issuance_block_index,
    mime_type
"""


def _block_bound(max_block_index, alias):
    """SQL fragment restricting a ledger table to blocks strictly below
    ``max_block_index`` (``""`` when unbounded)."""
    if max_block_index is None:
        return ""
    return f" AND {alias}.block_index < {int(max_block_index)}"


def populate_assets_info(db, max_block_index=None):
    """(Re)populate an existing, empty ``assets_info`` table from ``ledger_db``.

    ``assets_info`` is a pure projection of the ledger's ``issuances`` /
    ``destructions`` / ``burns`` history, so it is re-derived rather than
    incrementally undone. ``max_block_index`` bounds the derivation to blocks
    strictly below it, which is what the rollback path needs: the Ledger DB may
    already have re-parsed the *new* chain past the reorganization point, and
    those blocks must not leak into a State DB that is being rewound to just
    before it.

    ``ledger_db`` must be attached to ``db``, and the table must exist and be
    empty (migration 0004 creates it; the rollback path DELETEs it first).
    """
    bound_i = _block_bound(max_block_index, "i")
    bound_d = _block_bound(max_block_index, "d")

    # One row per asset, mirroring the latest-wins semantics of
    # ``apiwatcher.update_assets_info`` (the streamed handler that maintains
    # this table at runtime). Each per-asset value is derived explicitly from
    # the latest valid issuance (``ORDER BY rowid DESC LIMIT 1``) for fields the
    # streamed handler overwrites on every issuance, and from ``MAX(...)`` for
    # the boolean flags ``locked`` / ``description_locked`` so that multiple
    # lock events don't accumulate as integer counts in ``BOOL`` columns.
    db.execute(f"""
    INSERT INTO assets_info ({ASSETS_INFO_COLUMNS})
    SELECT
        a.asset_name AS asset,
        a.asset_id,
        a.asset_longname,
        (
            SELECT (SELECT al.address FROM ledger_db.address_list al WHERE al.address_id = i.issuer)
            FROM ledger_db.issuances i
            WHERE i.asset = a.asset_index AND i.status = 'valid'{bound_i}
            ORDER BY i.rowid ASC LIMIT 1
        ) AS issuer,
        (
            SELECT (SELECT al.address FROM ledger_db.address_list al WHERE al.address_id = i.issuer)
            FROM ledger_db.issuances i
            WHERE i.asset = a.asset_index AND i.status = 'valid'{bound_i}
            ORDER BY i.rowid DESC LIMIT 1
        ) AS owner,
        (
            SELECT i.divisible FROM ledger_db.issuances i
            WHERE i.asset = a.asset_index AND i.status = 'valid'{bound_i}
            ORDER BY i.rowid DESC LIMIT 1
        ) AS divisible,
        COALESCE((
            SELECT MAX(i.locked) FROM ledger_db.issuances i
            WHERE i.asset = a.asset_index AND i.status = 'valid'{bound_i}
        ), 0) AS locked,
        COALESCE((
            SELECT SUM(i.quantity) FROM ledger_db.issuances i
            WHERE i.asset = a.asset_index AND i.status = 'valid'{bound_i}
        ), 0) AS supply,
        (
            SELECT i.description FROM ledger_db.issuances i
            WHERE i.asset = a.asset_index AND i.status = 'valid'{bound_i}
            ORDER BY i.rowid DESC LIMIT 1
        ) AS description,
        COALESCE((
            SELECT MAX(i.description_locked) FROM ledger_db.issuances i
            WHERE i.asset = a.asset_index AND i.status = 'valid'{bound_i}
        ), 0) AS description_locked,
        (
            SELECT MIN(i.block_index) FROM ledger_db.issuances i
            WHERE i.asset = a.asset_index AND i.status = 'valid'{bound_i}
        ) AS first_issuance_block_index,
        (
            SELECT MAX(i.block_index) FROM ledger_db.issuances i
            WHERE i.asset = a.asset_index AND i.status = 'valid'{bound_i}
        ) AS last_issuance_block_index,
        (
            SELECT i.mime_type FROM ledger_db.issuances i
            WHERE i.asset = a.asset_index AND i.status = 'valid'{bound_i}
            ORDER BY i.rowid DESC LIMIT 1
        ) AS mime_type
    FROM ledger_db.assets a
    WHERE EXISTS (
        SELECT 1 FROM ledger_db.issuances i
        WHERE i.asset = a.asset_index AND i.status = 'valid'{bound_i}
    );
    """)  # noqa: S608  # nosec B608

    # XCP has no ``issuances`` rows: its supply is burns minus every fee/
    # destruction that removes XCP from circulation. This mirrors
    # ``ledger.supplies.xcp_supply()`` in SQL so it can take the same block
    # bound (the Python helper always reads the ledger at its current tip).
    db.execute(f"""
        INSERT INTO assets_info (
            asset, divisible, locked, supply, description,
            first_issuance_block_index, last_issuance_block_index
        )
        SELECT
            '{config.XCP}',
            1,
            1,
            COALESCE((
                SELECT SUM(i.earned) FROM ledger_db.burns i
                WHERE i.status = 'valid'{bound_i}
            ), 0) - (
                COALESCE((
                    SELECT SUM(i.quantity) FROM ledger_db.destructions i
                    WHERE i.status = 'valid'{bound_i}
                    AND i.asset = (SELECT asset_index FROM ledger_db.assets WHERE asset_name = '{config.XCP}')
                ), 0)
                + COALESCE((
                    SELECT SUM(i.fee_paid) FROM ledger_db.issuances i
                    WHERE i.status = 'valid'{bound_i}
                ), 0)
                + COALESCE((
                    SELECT SUM(i.fee_paid) FROM ledger_db.dividends i
                    WHERE i.status = 'valid'{bound_i}
                ), 0)
                + COALESCE((
                    SELECT SUM(i.fee_paid) FROM ledger_db.sweeps i
                    WHERE i.status = 'valid'{bound_i}
                ), 0)
            ),
            'The Counterparty protocol native currency',
            278319,
            283810
    """)  # noqa: S608  # nosec B608

    # ``supply`` above counts issuances only; subtract destructions. Done as a
    # separate set-based pass (rather than one more correlated subquery) so a
    # full rebuild stays a couple of sequential scans.
    # ``DROP ... IF EXISTS`` first: unlike the migration, the rollback path can
    # call this repeatedly on one long-lived connection, and a run that failed
    # partway could otherwise leave these behind.
    for temp_table in ("issuances_quantity", "destructions_quantity", "supplies"):
        db.execute(f"DROP TABLE IF EXISTS temp.{temp_table}")  # noqa: S608  # nosec B608

    db.execute(f"""
        CREATE TEMP TABLE issuances_quantity AS
        SELECT a.asset_name AS asset, SUM(i.quantity) AS quantity
        FROM ledger_db.issuances i
        JOIN ledger_db.assets a ON a.asset_index = i.asset
        WHERE i.status = 'valid'{bound_i} GROUP BY i.asset
    """)  # noqa: S608  # nosec B608
    db.execute(f"""
        CREATE TEMP TABLE destructions_quantity AS
        SELECT a.asset_name AS asset, SUM(d.quantity) AS quantity
        FROM ledger_db.destructions d
        JOIN ledger_db.assets a ON a.asset_index = d.asset
        WHERE d.status = 'valid'{bound_d} GROUP BY d.asset
    """)  # noqa: S608  # nosec B608
    db.execute("""
        CREATE TEMP TABLE supplies AS
        SELECT
            issuances_quantity.asset,
            issuances_quantity.quantity - COALESCE(destructions_quantity.quantity, 0) AS supply
        FROM issuances_quantity
        LEFT JOIN destructions_quantity ON issuances_quantity.asset = destructions_quantity.asset
    """)
    db.execute("""CREATE INDEX temp.supplies_asset_idx ON supplies(asset)""")
    db.execute("""
        UPDATE assets_info SET
        supply = COALESCE((SELECT supplies.supply FROM supplies WHERE assets_info.asset = supplies.asset), supply)
    """)
    db.execute("DROP TABLE issuances_quantity")
    db.execute("DROP TABLE destructions_quantity")
    db.execute("DROP TABLE supplies")
