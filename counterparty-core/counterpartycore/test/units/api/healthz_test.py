import time

import bitcoin as bitcoinlib
import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.api import healthz
from counterpartycore.lib.ledger.currentstate import CurrentState


def set_mainnet_network(monkeypatch, block_index=400000):
    config.NETWORK_NAME = "mainnet"
    config.UNSPENDABLE = config.UNSPENDABLE_MAINNET
    bitcoinlib.SelectParams("mainnet")
    config.ADDRESSVERSION = config.ADDRESSVERSION_MAINNET
    CurrentState().set_current_block_index(block_index)
    CurrentState().last_update = 0


def restore_network():
    config.NETWORK_NAME = "regtest"
    config.UNSPENDABLE = config.UNSPENDABLE_REGTEST
    bitcoinlib.SelectParams("regtest")
    config.ADDRESSVERSION = config.ADDRESSVERSION_REGTEST


def test_healthz_light(apiv2_client, monkeypatch, current_block_index):
    set_mainnet_network(monkeypatch)
    assert apiv2_client.get("/healthz").json == {"result": {"status": "Healthy"}}
    assert apiv2_client.get("/healthz?check_type=heavy").json == {"result": {"status": "Healthy"}}
    restore_network()


def test_check_last_parsed_block_no_block(ledger_db, monkeypatch):
    """Test check_last_parsed_block when there's no block in the database."""
    monkeypatch.setattr(
        "counterpartycore.lib.ledger.blocks.get_last_block",
        lambda db: None,
    )

    with pytest.raises(exceptions.DatabaseError, match="database is behind backend"):
        healthz.check_last_parsed_block(ledger_db, 100)


def test_check_last_parsed_block_recent(ledger_db, monkeypatch):
    """Test check_last_parsed_block when block is recent (within 60 seconds)."""
    current_time = time.time()

    monkeypatch.setattr(
        "counterpartycore.lib.ledger.blocks.get_last_block",
        lambda db: {"block_time": current_time - 30},  # 30 seconds ago
    )

    # Should return without raising
    healthz.check_last_parsed_block(ledger_db, 100)


def test_check_last_parsed_block_behind(ledger_db, monkeypatch):
    """Test check_last_parsed_block when database is behind backend."""
    current_time = time.time()

    monkeypatch.setattr(
        "counterpartycore.lib.ledger.blocks.get_last_block",
        lambda db: {"block_time": current_time - 120},  # 2 minutes ago
    )

    # Set current block index to be behind backend
    original_block_index = CurrentState().current_block_index()
    CurrentState().set_current_block_index(50)  # Behind blockcount of 100

    try:
        with pytest.raises(exceptions.DatabaseError, match="database is behind backend"):
            healthz.check_last_parsed_block(ledger_db, 100)
    finally:
        CurrentState().set_current_block_index(original_block_index)


def test_healthz_function_with_exception(ledger_db, monkeypatch):
    """Test healthz function when an exception occurs."""
    monkeypatch.setattr(
        "counterpartycore.lib.api.healthz.healthz_light",
        lambda db: (_ for _ in ()).throw(Exception("Test error")),
    )

    result = healthz.healthz(ledger_db, "light")
    assert result is False


def test_check_server_health_unhealthy(ledger_db, monkeypatch):
    """Test check_server_health when unhealthy."""
    monkeypatch.setattr(
        "counterpartycore.lib.api.healthz.healthz",
        lambda db, check_type: False,
    )

    result = healthz.check_server_health(ledger_db, "light")
    assert result == {"status": "Unhealthy"}


def test_check_server_health_healthy(ledger_db, monkeypatch):
    """Test check_server_health when healthy."""
    monkeypatch.setattr(
        "counterpartycore.lib.api.healthz.healthz",
        lambda db, check_type: True,
    )

    result = healthz.check_server_health(ledger_db, "light")
    assert result == {"status": "Healthy"}


def test_rate_limited_get(apiv2_client):
    response = apiv2_client.get("/rate-limited")
    assert response.status_code == 429
    assert response.json == {"error": "rate_limit_exceeded"}
    assert response.headers["Access-Control-Allow-Origin"] == "*"
    assert response.headers["Access-Control-Allow-Headers"] == "*"
    assert response.headers["Access-Control-Allow-Methods"] == "*"


def test_rate_limited_post(apiv2_client):
    response = apiv2_client.post("/rate-limited")
    assert response.status_code == 429
    assert response.json == {"error": "rate_limit_exceeded"}
    assert response.headers["Access-Control-Allow-Origin"] == "*"
    assert response.headers["Access-Control-Allow-Headers"] == "*"
    assert response.headers["Access-Control-Allow-Methods"] == "*"


def test_rate_limited_options(apiv2_client):
    response = apiv2_client.options("/rate-limited")
    assert response.status_code == 204
    assert response.data == b""
    assert response.headers["Access-Control-Allow-Origin"] == "*"
    assert response.headers["Access-Control-Allow-Headers"] == "*"
    assert response.headers["Access-Control-Allow-Methods"] == "*"
