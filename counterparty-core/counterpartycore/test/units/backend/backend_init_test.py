"""Tests for backend/__init__.py module."""

import importlib

import pytest
from counterpartycore.lib import backend, config, exceptions

# Skip these tests because they conflict with session-level mocks
# The session-level mock in bitcoind.py overrides all patching
# These functions are tested indirectly through other tests


def test_list_unspent_from_bitcoind_direct(monkeypatch):
    """Test list_unspent when Bitcoin Core returns UTXOs - direct test."""
    expected_utxos = [{"txid": "abc123", "vout": 0, "value": 100000}]

    # Patch at module level before importing
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.list_unspent",
        lambda source, allow_unconfirmed: expected_utxos,
    )

    importlib.reload(backend)

    result = backend.list_unspent("test_source", True)
    assert result == expected_utxos


def test_list_unspent_fallback_to_electrs_direct(monkeypatch):
    """Test list_unspent falls back to Electrs when Bitcoin Core returns empty."""
    expected_utxos = [{"txid": "def456", "vout": 1, "value": 200000}]

    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.list_unspent",
        lambda source, allow_unconfirmed: [],
    )
    monkeypatch.setattr(
        "counterpartycore.lib.backend.electrs.list_unspent",
        lambda source, allow_unconfirmed: expected_utxos,
    )

    importlib.reload(backend)

    # Save original and set ELECTRS_URLS
    original_electrs_url = getattr(config, "ELECTRS_URLS", None)
    config.ELECTRS_URLS = ["http://localhost:3000"]

    try:
        result = backend.list_unspent("test_source", True)
        assert result == expected_utxos
    finally:
        config.ELECTRS_URLS = original_electrs_url


def test_list_unspent_no_electrs_configured_direct(monkeypatch):
    """Test list_unspent raises error when no UTXOs and Electrs not configured."""
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.list_unspent",
        lambda source, allow_unconfirmed: [],
    )

    importlib.reload(backend)

    # Save original and set ELECTRS_URLS to None
    original_electrs_url = getattr(config, "ELECTRS_URLS", None)
    config.ELECTRS_URLS = None

    try:
        with pytest.raises(exceptions.ComposeError, match="No UTXOs found"):
            backend.list_unspent("test_source", True)
    finally:
        config.ELECTRS_URLS = original_electrs_url


def test_list_unspent_empty_electrs_urls_list_raises(monkeypatch):
    """Empty list of Electrs URLs is treated as not-configured."""
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.list_unspent",
        lambda source, allow_unconfirmed: [],
    )
    importlib.reload(backend)

    original_electrs_url = getattr(config, "ELECTRS_URLS", None)
    config.ELECTRS_URLS = []
    try:
        with pytest.raises(exceptions.ComposeError, match="No UTXOs found"):
            backend.list_unspent("test_source", True)
    finally:
        config.ELECTRS_URLS = original_electrs_url


def test_search_pubkey_uses_bitcoind_first(monkeypatch):
    """search_pubkey returns the bitcoind result without consulting Electrs
    when bitcoind already found a key."""
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.search_pubkey_in_transactions",
        lambda source, tx_hashes: "bitcoind_pubkey",
    )

    def fail_electrs(*args, **kwargs):
        raise AssertionError("Electrs must not be called when bitcoind found the pubkey")

    monkeypatch.setattr(
        "counterpartycore.lib.backend.electrs.search_pubkey",
        fail_electrs,
    )
    importlib.reload(backend)

    assert backend.search_pubkey("test_addr", tx_hashes=["abc"]) == "bitcoind_pubkey"


def test_search_pubkey_falls_back_to_electrs(monkeypatch):
    """When bitcoind returns None, Electrs is consulted."""
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.search_pubkey_in_transactions",
        lambda source, tx_hashes: None,
    )
    monkeypatch.setattr(
        "counterpartycore.lib.backend.electrs.search_pubkey",
        lambda source: "electrs_pubkey",
    )
    importlib.reload(backend)

    original_electrs_url = getattr(config, "ELECTRS_URLS", None)
    config.ELECTRS_URLS = ["http://localhost:3000"]
    try:
        assert backend.search_pubkey("test_addr", tx_hashes=["abc"]) == "electrs_pubkey"
    finally:
        config.ELECTRS_URLS = original_electrs_url


def test_search_pubkey_returns_none_when_no_electrs(monkeypatch):
    """When bitcoind returns None and Electrs is not configured, search
    returns None (not raise) -- callers handle the missing pubkey."""
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.search_pubkey_in_transactions",
        lambda source, tx_hashes: None,
    )
    importlib.reload(backend)

    original_electrs_url = getattr(config, "ELECTRS_URLS", None)
    config.ELECTRS_URLS = None
    try:
        assert backend.search_pubkey("test_addr", tx_hashes=["abc"]) is None
    finally:
        config.ELECTRS_URLS = original_electrs_url


def test_search_pubkey_returns_none_when_empty_electrs_list(monkeypatch):
    """Empty Electrs list short-circuits to None."""
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.search_pubkey_in_transactions",
        lambda source, tx_hashes: None,
    )
    importlib.reload(backend)

    original_electrs_url = getattr(config, "ELECTRS_URLS", None)
    config.ELECTRS_URLS = []
    try:
        assert backend.search_pubkey("test_addr", tx_hashes=["abc"]) is None
    finally:
        config.ELECTRS_URLS = original_electrs_url


def test_search_pubkey_skips_bitcoind_when_no_tx_hashes(monkeypatch):
    """When tx_hashes is empty/None, bitcoind branch is skipped entirely."""
    called = {"bitcoind": False}

    def bitcoind_called(*args, **kwargs):
        called["bitcoind"] = True
        return "should_not_be_returned"

    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.search_pubkey_in_transactions",
        bitcoind_called,
    )
    monkeypatch.setattr(
        "counterpartycore.lib.backend.electrs.search_pubkey",
        lambda source: "electrs_only",
    )
    importlib.reload(backend)

    original_electrs_url = getattr(config, "ELECTRS_URLS", None)
    config.ELECTRS_URLS = ["http://localhost:3000"]
    try:
        assert backend.search_pubkey("test_addr") == "electrs_only"
        assert called["bitcoind"] is False
        assert backend.search_pubkey("test_addr", tx_hashes=[]) == "electrs_only"
        assert called["bitcoind"] is False
    finally:
        config.ELECTRS_URLS = original_electrs_url
