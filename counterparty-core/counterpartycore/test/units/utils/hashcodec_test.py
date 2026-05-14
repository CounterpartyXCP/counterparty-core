"""Tests for counterpartycore.lib.utils.hashcodec."""

import sqlite3

import apsw
import pytest
from counterpartycore.lib.utils import hashcodec


# ---------------------------------------------------------------------------
# hash_to_db
# ---------------------------------------------------------------------------


def test_hash_to_db_none():
    assert hashcodec.hash_to_db(None) is None


def test_hash_to_db_bytes_passthrough():
    b = b"\xab" * 32
    assert hashcodec.hash_to_db(b) is b


def test_hash_to_db_bytes_strict_ok():
    b = b"\xab" * 32
    assert hashcodec.hash_to_db(b, strict=True) is b


def test_hash_to_db_bytes_strict_wrong_length():
    with pytest.raises(ValueError, match="expected 32 bytes"):
        hashcodec.hash_to_db(b"\x00" * 31, strict=True)


def test_hash_to_db_hex_string():
    hex_str = "ab" * 32
    assert hashcodec.hash_to_db(hex_str) == bytes.fromhex(hex_str)


def test_hash_to_db_empty_string_permissive():
    assert hashcodec.hash_to_db("") is None


def test_hash_to_db_empty_string_strict():
    with pytest.raises(ValueError, match="empty string"):
        hashcodec.hash_to_db("", strict=True)


def test_hash_to_db_strict_wrong_hex_length():
    with pytest.raises(ValueError, match="expected 64-char hex"):
        hashcodec.hash_to_db("ab" * 16, strict=True)  # 32 chars, not 64


def test_hash_to_db_strict_valid_hex():
    hex_str = "ab" * 32
    assert hashcodec.hash_to_db(hex_str, strict=True) == bytes.fromhex(hex_str)


def test_hash_to_db_non_hex_permissive_fallback():
    result = hashcodec.hash_to_db("not_hex_data")
    assert result == b"not_hex_data"


def test_hash_to_db_unsupported_type():
    with pytest.raises(TypeError, match="unsupported type"):
        hashcodec.hash_to_db(12345)


# ---------------------------------------------------------------------------
# hash_from_db
# ---------------------------------------------------------------------------


def test_hash_from_db_none():
    assert hashcodec.hash_from_db(None) is None


def test_hash_from_db_str_passthrough():
    s = "abc123"
    assert hashcodec.hash_from_db(s) == s


def test_hash_from_db_bytes():
    b = bytes.fromhex("ab" * 32)
    assert hashcodec.hash_from_db(b) == "ab" * 32


def test_hash_from_db_unsupported_type():
    with pytest.raises(TypeError, match="unsupported type"):
        hashcodec.hash_from_db(42)


# ---------------------------------------------------------------------------
# normalize_record_hashes
# ---------------------------------------------------------------------------


def test_normalize_record_hashes_converts_present_columns():
    hex_str = "cd" * 32
    record = {"tx_hash": hex_str, "other": "value"}
    result = hashcodec.normalize_record_hashes(record, ["tx_hash"])
    assert result["tx_hash"] == bytes.fromhex(hex_str)
    assert result["other"] == "value"
    assert result is record  # in-place mutation


def test_normalize_record_hashes_skips_absent_columns():
    record = {"block_index": 100}
    result = hashcodec.normalize_record_hashes(record, ["tx_hash"])
    assert "tx_hash" not in result
    assert result == {"block_index": 100}


def test_normalize_record_hashes_multiple_columns():
    hex_str = "ef" * 32
    record = {"tx_hash": hex_str, "block_hash": hex_str, "quantity": 99}
    hashcodec.normalize_record_hashes(record, ["tx_hash", "block_hash"])
    assert record["tx_hash"] == bytes.fromhex(hex_str)
    assert record["block_hash"] == bytes.fromhex(hex_str)
    assert record["quantity"] == 99


# ---------------------------------------------------------------------------
# register_db_functions — apsw path
# ---------------------------------------------------------------------------


def test_register_db_functions_apsw_hex_lower_bytes():
    db = apsw.Connection(":memory:")
    hashcodec.register_db_functions(db)
    cursor = db.cursor()
    row = cursor.execute("SELECT hex_lower(x'ABCD')").fetchone()
    assert row[0] == "abcd"


def test_register_db_functions_apsw_hex_lower_null():
    db = apsw.Connection(":memory:")
    hashcodec.register_db_functions(db)
    cursor = db.cursor()
    row = cursor.execute("SELECT hex_lower(NULL)").fetchone()
    assert row[0] is None


def test_register_db_functions_apsw_unhex_text():
    db = apsw.Connection(":memory:")
    hashcodec.register_db_functions(db)
    cursor = db.cursor()
    row = cursor.execute("SELECT unhex('abcd')").fetchone()
    assert row[0] == bytes.fromhex("abcd")


def test_register_db_functions_apsw_unhex_null():
    db = apsw.Connection(":memory:")
    hashcodec.register_db_functions(db)
    cursor = db.cursor()
    row = cursor.execute("SELECT unhex(NULL)").fetchone()
    assert row[0] is None


def test_register_db_functions_apsw_unhex_blob_passthrough():
    db = apsw.Connection(":memory:")
    hashcodec.register_db_functions(db)
    cursor = db.cursor()
    # Pass a BLOB literal: SQLite delivers it to the UDF as bytes
    row = cursor.execute("SELECT unhex(x'AABB')").fetchone()
    assert row[0] == bytes.fromhex("aabb")


# ---------------------------------------------------------------------------
# register_db_functions — stdlib sqlite3 path (else branch)
# ---------------------------------------------------------------------------


def test_register_db_functions_sqlite3_hex_lower_bytes():
    db = sqlite3.connect(":memory:")
    hashcodec.register_db_functions(db)
    cursor = db.cursor()
    row = cursor.execute("SELECT hex_lower(x'ABCD')").fetchone()
    assert row[0] == "abcd"


def test_register_db_functions_sqlite3_hex_lower_null():
    db = sqlite3.connect(":memory:")
    hashcodec.register_db_functions(db)
    cursor = db.cursor()
    row = cursor.execute("SELECT hex_lower(NULL)").fetchone()
    assert row[0] is None


def test_register_db_functions_sqlite3_hex_lower_str():
    db = sqlite3.connect(":memory:")
    hashcodec.register_db_functions(db)
    cursor = db.cursor()
    row = cursor.execute("SELECT hex_lower('ABCDEF')").fetchone()
    assert row[0] == "abcdef"


def test_register_db_functions_sqlite3_unhex_text():
    db = sqlite3.connect(":memory:")
    hashcodec.register_db_functions(db)
    cursor = db.cursor()
    row = cursor.execute("SELECT unhex('abcd')").fetchone()
    assert row[0] == bytes.fromhex("abcd")


def test_register_db_functions_sqlite3_unhex_null():
    db = sqlite3.connect(":memory:")
    hashcodec.register_db_functions(db)
    cursor = db.cursor()
    row = cursor.execute("SELECT unhex(NULL)").fetchone()
    assert row[0] is None
