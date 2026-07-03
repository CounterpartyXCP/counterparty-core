"""Tests for counterpartycore.lib.ledger.migrations.0010.compact_hash_storage helpers."""

import importlib.util
import pathlib
import sqlite3
from unittest.mock import MagicMock, patch

import pytest
from counterpartycore.lib.ledger.migration_data.compact_hash_tables import (
    ADDRESS_NAME_COLUMNS,
    ASSET_NAME_COLUMNS,
)
from counterpartycore.lib.utils import database

# The migration filename starts with a digit, so we can't use a normal import.
# We patch yoyo.step so the module-level `steps = [step(apply, rollback)]`
# doesn't fail outside of a yoyo migration runner context.
_MIG_PATH = (
    pathlib.Path(__file__).parent.parent.parent.parent
    / "lib/ledger/migrations/0010.compact_hash_storage.py"
)
_spec = importlib.util.spec_from_file_location("m0010", str(_MIG_PATH))
m0010 = importlib.util.module_from_spec(_spec)
with patch("yoyo.step", return_value=MagicMock()):
    _spec.loader.exec_module(m0010)


# ---------------------------------------------------------------------------
# Asset normalization: the flat asset-column set duplicated in
# ``utils.database`` (used by the rowtracer hot path, which must not import
# ``lib.ledger.*``) MUST stay in sync with ``ASSET_NAME_COLUMNS``.
# ``lp_asset`` is intentionally excluded (it is not normalized: an LP token is
# referenced before it is created when a pool opens).
# ---------------------------------------------------------------------------


def test_asset_index_column_names_in_sync():
    expected = {col for cols in ASSET_NAME_COLUMNS.values() for col in cols}
    expected.discard("lp_asset")
    assert database.ASSET_INDEX_COLUMN_NAMES == expected


# The flat address-column set duplicated in ``utils.database`` (rowtracer hot
# path) MUST stay in sync with the union of ``ADDRESS_NAME_COLUMNS`` values.
def test_address_index_column_names_in_sync():
    expected = {col for cols in ADDRESS_NAME_COLUMNS.values() for col in cols}
    assert database.ADDRESS_INDEX_COLUMN_NAMES == expected


def test_split_utxo_roundtrip():
    # ``utxo`` (tx_hash:vout) <-> compact (BLOB tx_hash, int vout) pair.
    utxo = "ab" * 32 + ":5"
    tx_hash, vout = database.split_utxo(utxo)
    assert isinstance(tx_hash, bytes)
    assert len(tx_hash) == 32
    assert vout == 5
    assert database.utxo_from_split(tx_hash, vout) == utxo
    # an address balance has no utxo
    assert database.split_utxo(None) == (None, None)
    assert database.utxo_from_split(None, None) is None


# ---------------------------------------------------------------------------
# _hex_to_blob_udf
# ---------------------------------------------------------------------------


def test_hex_to_blob_udf_none():
    assert m0010._hex_to_blob_udf(None) is None


def test_hex_to_blob_udf_bytes_passthrough():
    b = bytes.fromhex("abcd")
    assert m0010._hex_to_blob_udf(b) is b


def test_hex_to_blob_udf_empty_string():
    assert m0010._hex_to_blob_udf("") is None


def test_hex_to_blob_udf_valid_hex():
    result = m0010._hex_to_blob_udf("abcd1234")
    assert result == bytes.fromhex("abcd1234")


# ---------------------------------------------------------------------------
# rollback
# ---------------------------------------------------------------------------


def test_rollback_raises():
    with pytest.raises(NotImplementedError, match="cannot be rolled back"):
        m0010.rollback(None)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_sqlite3_cursor(sql_setup):
    db = sqlite3.connect(":memory:")
    cursor = db.cursor()
    for stmt in sql_setup:
        cursor.execute(stmt)
    return cursor


# ---------------------------------------------------------------------------
# _table_has_column — tuple-row path (stdlib sqlite3)
# ---------------------------------------------------------------------------


def test_table_has_column_tuple_rows_found():
    cursor = _make_sqlite3_cursor(["CREATE TABLE test_t (id INTEGER, name TEXT, value REAL)"])
    assert m0010._table_has_column(cursor, "test_t", "name") is True


def test_table_has_column_tuple_rows_not_found():
    cursor = _make_sqlite3_cursor(["CREATE TABLE test_t (id INTEGER, name TEXT)"])
    assert m0010._table_has_column(cursor, "test_t", "nonexistent") is False


def test_table_has_column_no_rows():
    cursor = _make_sqlite3_cursor([])
    assert m0010._table_has_column(cursor, "nonexistent_table", "id") is False


# ---------------------------------------------------------------------------
# _table_has_column — dict-row path (apsw with rowtracer via ledger_db fixture)
# ---------------------------------------------------------------------------


def test_table_has_column_dict_rows_found(ledger_db):
    cursor = ledger_db.cursor()
    assert m0010._table_has_column(cursor, "blocks", "block_index") is True


def test_table_has_column_dict_rows_not_found(ledger_db):
    cursor = ledger_db.cursor()
    assert m0010._table_has_column(cursor, "blocks", "nonexistent_col") is False


# ---------------------------------------------------------------------------
# _column_affinity — tuple-row path
# ---------------------------------------------------------------------------


def test_column_affinity_tuple_rows_found():
    cursor = _make_sqlite3_cursor(["CREATE TABLE test_t (id INTEGER, name TEXT, amount REAL)"])
    result = m0010._column_affinity(cursor, "test_t", "name")
    assert result == "TEXT"


def test_column_affinity_tuple_rows_not_found():
    cursor = _make_sqlite3_cursor(["CREATE TABLE test_t (id INTEGER, name TEXT)"])
    result = m0010._column_affinity(cursor, "test_t", "nonexistent")
    assert result is None


# ---------------------------------------------------------------------------
# _column_affinity — dict-row path (via ledger_db fixture)
# ---------------------------------------------------------------------------


def test_column_affinity_dict_rows_found(ledger_db):
    cursor = ledger_db.cursor()
    result = m0010._column_affinity(cursor, "blocks", "block_index")
    assert result is not None


def test_column_affinity_dict_rows_not_found(ledger_db):
    cursor = ledger_db.cursor()
    result = m0010._column_affinity(cursor, "blocks", "nonexistent_col")
    assert result is None


# ---------------------------------------------------------------------------
# _index_definitions — tuple-row path
# ---------------------------------------------------------------------------


def test_index_definitions_tuple_rows_no_indexes():
    cursor = _make_sqlite3_cursor(["CREATE TABLE test_t (id INTEGER, name TEXT)"])
    result = m0010._index_definitions(cursor, "test_t")
    assert result == []


def test_index_definitions_tuple_rows_with_index():
    cursor = _make_sqlite3_cursor(
        [
            "CREATE TABLE test_t (id INTEGER, name TEXT)",
            "CREATE INDEX idx_name ON test_t(name)",
        ]
    )
    result = m0010._index_definitions(cursor, "test_t")
    assert len(result) == 1
    assert result[0][0] == "idx_name"
    assert "idx_name" in result[0][1]


# ---------------------------------------------------------------------------
# _index_definitions — dict-row path (via ledger_db fixture)
# ---------------------------------------------------------------------------


def test_index_definitions_dict_rows(ledger_db):
    cursor = ledger_db.cursor()
    result = m0010._index_definitions(cursor, "blocks")
    assert isinstance(result, list)
    for name, sql in result:
        assert isinstance(name, str)
        assert isinstance(sql, str)


# ---------------------------------------------------------------------------
# _backfill_invalid_asset_names
#
# Assets issued ONLY invalidly (e.g. "invalid: insufficient funds") never get an
# ``assets`` row, so the normalized ``issuances.asset`` FK is NULL for them.
# Legacy stored the raw name, so ``COUNT(DISTINCT asset)`` (get_issuances_count
# -> the sweep antispam fee) counts them; ``COUNT(DISTINCT)`` skips NULL and
# undercounts -> ledger fork (observed at block 850500). The backfill interns
# every issued name so the FK resolves. Regression guard.
# ---------------------------------------------------------------------------

_ASSETS_DDL = (
    "CREATE TABLE assets(asset_index INTEGER PRIMARY KEY, asset_id TEXT UNIQUE, "
    "asset_name TEXT UNIQUE, block_index INTEGER, asset_longname TEXT)"
)
# Distinct asset_index that Alice's issuances resolve to == the value the
# normalized ``COUNT(DISTINCT asset)`` yields after the FK rewrite.
_RESOLVED = (
    "SELECT COUNT(DISTINCT (SELECT a.asset_index FROM assets a "
    "WHERE a.asset_name = i.asset)) FROM issuances_old i WHERE i.issuer = 'Alice'"
)


def test_backfill_invalid_asset_names():
    cursor = _make_sqlite3_cursor(
        [
            _ASSETS_DDL,
            "CREATE TABLE issuances_old(asset TEXT, issuer TEXT, block_index INTEGER, status TEXT)",
            # ``assets`` seeded with validly-created assets only (as the migration
            # does from ``assets_old``).
            "INSERT INTO assets(asset_id, asset_name, block_index, asset_longname) "
            "VALUES ('697326324582', 'VALIDASSET', 700000, NULL)",
        ]
    )
    cursor.executemany(
        "INSERT INTO issuances_old VALUES (?, ?, ?, ?)",
        [
            ("VALIDASSET", "Alice", 700000, "valid"),
            # invalid-only asset, issued twice -> one distinct name
            ("INVALIDONE", "Alice", 700001, "invalid: insufficient funds"),
            ("INVALIDONE", "Alice", 700005, "invalid: insufficient funds"),
            ("INVALIDTWO", "Alice", 700002, "invalid: insufficient funds"),
            # NULL-asset invalid row -> never counted (COUNT(DISTINCT) skips NULL)
            (None, "Alice", 700003, "invalid: total quantity overflow"),
        ],
    )

    # Legacy consensus value: COUNT(DISTINCT asset) over issuances of any status.
    legacy = cursor.execute(
        "SELECT COUNT(DISTINCT asset) FROM issuances_old WHERE issuer = 'Alice'"
    ).fetchone()[0]
    assert legacy == 3  # VALIDASSET + INVALIDONE + INVALIDTWO

    # Before the backfill only the validly-created asset resolves -> undercount
    # (the block-850500 bug).
    assert cursor.execute(_RESOLVED).fetchone()[0] == 1

    m0010._backfill_invalid_asset_names(cursor)

    # After: every non-NULL issued name resolves -> matches legacy exactly.
    assert cursor.execute(_RESOLVED).fetchone()[0] == legacy == 3
    # invalid-only names interned with the asset_id the parse path derives
    # (generate_asset_id('INVALIDONE') == 46319583698470), longname NULL --
    # so get_asset_id() returns the same id as a from-scratch node instead of
    # raising TypeError on int(None).
    assert cursor.execute(
        "SELECT asset_id, asset_longname FROM assets WHERE asset_name = 'INVALIDONE'"
    ).fetchone() == ("46319583698470", None)
    # ... and the validly-created asset row is left untouched.
    assert (
        cursor.execute("SELECT asset_id FROM assets WHERE asset_name = 'VALIDASSET'").fetchone()[0]
        == "697326324582"
    )

    # Idempotent: a second run adds nothing.
    n = cursor.execute("SELECT COUNT(*) FROM assets").fetchone()[0]
    m0010._backfill_invalid_asset_names(cursor)
    assert cursor.execute("SELECT COUNT(*) FROM assets").fetchone()[0] == n


def test_backfill_invalid_asset_names_no_issuances_old():
    # Fresh DB (nothing migrated -> no ``issuances_old``): no-op, no error.
    cursor = _make_sqlite3_cursor([_ASSETS_DDL])
    m0010._backfill_invalid_asset_names(cursor)
    assert cursor.execute("SELECT COUNT(*) FROM assets").fetchone()[0] == 0
