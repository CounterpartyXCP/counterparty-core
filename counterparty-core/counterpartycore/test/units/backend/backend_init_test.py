"""Tests for backend/__init__.py module."""

import pytest
from counterpartycore.lib import config, exceptions

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

    # Reimport to get patched version
    import importlib

    from counterpartycore.lib import backend

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

    import importlib

    from counterpartycore.lib import backend

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

    import importlib

    from counterpartycore.lib import backend

    importlib.reload(backend)

    # Save original and set ELECTRS_URLS to None
    original_electrs_url = getattr(config, "ELECTRS_URLS", None)
    config.ELECTRS_URLS = None

    try:
        with pytest.raises(exceptions.ComposeError, match="No UTXOs found"):
            backend.list_unspent("test_source", True)
    finally:
        config.ELECTRS_URLS = original_electrs_url
