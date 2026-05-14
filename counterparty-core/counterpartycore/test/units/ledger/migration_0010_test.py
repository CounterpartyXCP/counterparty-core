"""Tests for counterpartycore.lib.ledger.migrations.0010.compact_hash_storage helpers."""

import importlib.util
import pathlib
import sqlite3
from unittest.mock import MagicMock, patch

import pytest

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
