from counterpartycore.lib import config
from counterpartycore.lib.messages import rps, rpsresolve


def test_rps_replay_events_on_test_network(ledger_db, monkeypatch):
    """Test replay_events on test network (regtest) - should return early."""
    # On test network, replay_events should return early without doing anything
    config.REGTEST = True

    # This should not raise any exception and return immediately
    rps.replay_events(ledger_db, "nonexistent_key")


def test_rps_parse(ledger_db, blockchain_mock, defaults, test_helpers, monkeypatch):
    """Test rps.parse function."""
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])

    # Mock replay_events to avoid actual event replay
    called = {"count": 0}

    def mock_replay_events(db, key):
        called["count"] += 1

    monkeypatch.setattr("counterpartycore.lib.messages.rps.replay_events", mock_replay_events)

    rps.parse(ledger_db, tx)

    # Verify replay_events was called
    assert called["count"] == 1

    # Verify transaction status was set
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "transactions_status",
                "values": {
                    "tx_index": tx["tx_index"],
                    "valid": True,
                },
            },
        ],
    )


def test_rps_expire(ledger_db, monkeypatch):
    """Test rps.expire function."""
    called = {"count": 0, "key": None}

    def mock_replay_events(db, key):
        called["count"] += 1
        called["key"] = key

    monkeypatch.setattr("counterpartycore.lib.messages.rps.replay_events", mock_replay_events)

    rps.expire(ledger_db, 100)

    # Verify replay_events was called with the block_index as string
    assert called["count"] == 1
    assert called["key"] == "100"


def test_rps_expire_mempool(ledger_db, monkeypatch):
    """Test rps.expire function with mempool block index."""
    called = {"count": 0, "key": None}

    def mock_replay_events(db, key):
        called["count"] += 1
        called["key"] = key

    monkeypatch.setattr("counterpartycore.lib.messages.rps.replay_events", mock_replay_events)

    rps.expire(ledger_db, config.MEMPOOL_BLOCK_INDEX)

    assert called["count"] == 1
    assert called["key"] == str(config.MEMPOOL_BLOCK_INDEX)


def test_rpsresolve_parse(ledger_db, blockchain_mock, defaults, test_helpers, monkeypatch):
    """Test rpsresolve.parse function - it just calls rps.parse."""
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])

    # Mock rps.parse
    called = {"count": 0}

    def mock_rps_parse(db, tx):
        called["count"] += 1

    monkeypatch.setattr("counterpartycore.lib.messages.rps.parse", mock_rps_parse)

    rpsresolve.parse(ledger_db, tx)

    # Verify rps.parse was called
    assert called["count"] == 1


def test_rps_id():
    """Test that RPS has correct ID."""
    assert rps.ID == 80


def test_rpsresolve_id():
    """Test that RPSResolve has correct ID."""
    assert rpsresolve.ID == 81
