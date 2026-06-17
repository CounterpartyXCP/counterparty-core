"""Tests for the address normalization + utxo compaction read path
(``utils.database`` resolvers, bounded LRU caches, and the rowtracer's
transparent ``address_id``->string decode and ``utxo`` reconstruction)."""

from counterpartycore.lib.utils import database


def test_address_resolve_roundtrip(ledger_db):
    row = ledger_db.execute("SELECT address_id, address FROM address_list LIMIT 1").fetchone()
    addr_id, addr = row["address_id"], row["address"]
    assert database.address_index_from_name(ledger_db, addr) == addr_id
    assert database.address_string_from_index(ledger_db, addr_id) == addr
    # an unregistered address resolves to None (stored as NULL)
    assert database.address_index_from_name(ledger_db, "1NeverSeenAddrZZZZZZZZZZZZZZZZZZZZZ") is None


def test_address_cache_lru_bounded(ledger_db, monkeypatch):
    database.reset_address_caches(ledger_db)
    monkeypatch.setattr(database, "ADDRESS_CACHE_MAXSIZE", 3)
    rows = ledger_db.execute("SELECT address_id, address FROM address_list LIMIT 10").fetchall()
    assert len(rows) >= 4, "fixture needs several addresses to exercise eviction"
    for r in rows:
        database.address_string_from_index(ledger_db, r["address_id"])
    cache = database._ADDRESS_STRING_BY_INDEX.get(ledger_db)  # noqa: SLF001
    assert cache is not None and len(cache) <= 3
    # evicted entries still re-resolve correctly from the DB
    for r in rows:
        assert database.address_string_from_index(ledger_db, r["address_id"]) == r["address"]
    database.reset_address_caches(ledger_db)


def test_reset_address_caches(ledger_db):
    row = ledger_db.execute("SELECT address FROM address_list LIMIT 1").fetchone()
    database.address_index_from_name(ledger_db, row["address"])
    assert database._ADDRESS_INDEX_BY_STRING.get(ledger_db)  # noqa: SLF001
    database.reset_address_caches(ledger_db)
    assert database._ADDRESS_INDEX_BY_STRING.get(ledger_db) is None  # noqa: SLF001


def test_rowtracer_decodes_address(ledger_db):
    # a stored INTEGER address_id comes back as the address string
    row = ledger_db.execute(
        "SELECT source FROM transactions WHERE source IS NOT NULL LIMIT 1"
    ).fetchone()
    assert isinstance(row["source"], str)
    assert database.address_index_from_name(ledger_db, row["source"]) is not None


def test_utxo_balance_reconstructed(ledger_db):
    # the scenario attaches assets to UTXOs; reading a utxo balance reconstructs
    # the ``tx_hash:vout`` string from the stored (utxo_tx_hash BLOB, utxo_vout).
    row = ledger_db.execute(
        "SELECT * FROM balances WHERE utxo_tx_hash IS NOT NULL LIMIT 1"
    ).fetchone()
    assert row is not None, "fixture should have at least one UTXO balance"
    assert row.get("utxo") is not None
    tx_hash_hex, sep, vout = row["utxo"].partition(":")
    assert sep == ":" and len(tx_hash_hex) == 64 and vout.isdigit()
    # the raw split columns are replaced by the reconstructed ``utxo``
    assert "utxo_tx_hash" not in row
    assert "utxo_vout" not in row
