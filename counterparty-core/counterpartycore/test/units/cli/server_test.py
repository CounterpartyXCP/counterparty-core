from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from counterpartycore.lib import config
from counterpartycore.lib.cli import server
from counterpartycore.lib.cli.server import rebuild


@pytest.fixture
def rebuild_mock_dependencies():
    """Fixture to simulate external dependencies"""
    with (
        patch("counterpartycore.lib.monitors.slack.send_slack_message") as mock_slack,
        patch("counterpartycore.lib.cli.bootstrap.clean_data_dir") as mock_clean,
        patch("counterpartycore.lib.cli.server.start_all") as mock_start_all,
    ):
        yield {"slack": mock_slack, "clean_data_dir": mock_clean, "start_all": mock_start_all}


def test_rebuild_success(rebuild_mock_dependencies):
    """Test the case where rebuild executes successfully"""
    # Arrange
    args = MagicMock()

    # Act
    rebuild(args)

    # Assert
    rebuild_mock_dependencies["slack"].assert_any_call("Starting new rebuild.")
    rebuild_mock_dependencies["clean_data_dir"].assert_called_once_with(config.DATA_DIR)
    rebuild_mock_dependencies["start_all"].assert_called_once_with(args, stop_when_ready=True)
    rebuild_mock_dependencies["slack"].assert_called_with("Rebuild complete.")
    assert rebuild_mock_dependencies["slack"].call_count == 2


def test_rebuild_exception(rebuild_mock_dependencies):
    """Test the case where an exception occurs during rebuild"""
    # Arrange
    args = MagicMock()
    rebuild_mock_dependencies["clean_data_dir"].side_effect = Exception("Test error")

    # Act & Assert
    with pytest.raises(Exception, match="Test error"):
        rebuild(args)

    # Verify that appropriate Slack messages were sent
    rebuild_mock_dependencies["slack"].assert_any_call("Starting new rebuild.")
    rebuild_mock_dependencies["slack"].assert_any_call("Rebuild failed: Test error")
    assert rebuild_mock_dependencies["slack"].call_count == 2


def test_rebuild_start_all_exception(rebuild_mock_dependencies):
    """Test the case where start_all raises an exception"""
    # Arrange
    args = MagicMock()
    rebuild_mock_dependencies["start_all"].side_effect = Exception("Start failed")

    # Act & Assert
    with pytest.raises(Exception, match="Start failed"):
        rebuild(args)

    # Verify that appropriate messages were sent
    rebuild_mock_dependencies["slack"].assert_any_call("Starting new rebuild.")
    rebuild_mock_dependencies["slack"].assert_any_call("Rebuild failed: Start failed")


def test_ensure_backend_is_up(monkeypatch):
    monkeypatch.setattr(config, "FORCE", False)
    mock_getblockcount = MagicMock()
    monkeypatch.setattr(server.backend.bitcoind, "getblockcount", mock_getblockcount)

    server.ensure_backend_is_up()

    mock_getblockcount.assert_called_once()


def test_ensure_backend_is_up_force_skips(monkeypatch):
    monkeypatch.setattr(config, "FORCE", True)
    mock_getblockcount = MagicMock()
    monkeypatch.setattr(server.backend.bitcoind, "getblockcount", mock_getblockcount)

    server.ensure_backend_is_up()

    mock_getblockcount.assert_not_called()


@pytest.mark.parametrize(
    ("catch_up_mode", "database_exists", "expected"),
    [
        ("normal", False, False),
        ("bootstrap", False, True),
        ("bootstrap", True, False),
        ("bootstrap-once", False, True),
        ("bootstrap-once", True, False),
        ("bootstrap-always", False, True),
        ("bootstrap-always", True, True),
    ],
)
def test_should_bootstrap_database(catch_up_mode, database_exists, expected):
    assert server.should_bootstrap_database(catch_up_mode, database_exists) is expected


def test_generate_move_random_hash(monkeypatch):
    monkeypatch.setattr(server.os, "urandom", lambda n: b"\x01" * n)

    random_hex, hash_hex = server.generate_move_random_hash(1)

    assert random_hex == "01" * 16
    assert len(hash_hex) == 64


def test_reparse_early_exit(monkeypatch, capsys):
    ledger_db = MagicMock()
    monkeypatch.setattr(server.database, "apply_outstanding_migration", MagicMock())
    monkeypatch.setattr(server.database, "initialise_db", MagicMock(return_value=ledger_db))
    monkeypatch.setattr(server.ledger.blocks, "last_db_index", MagicMock(return_value=100))
    monkeypatch.setattr(server.blocks, "check_database_version", MagicMock())
    monkeypatch.setattr(
        server.ledger.blocks, "get_last_block", MagicMock(return_value={"block_index": 10})
    )
    monkeypatch.setattr(server.CurrentState, "set_current_block_index", lambda _self, _idx: None)

    server.reparse(11)

    out = capsys.readouterr().out
    assert "Block index is higher than current block index" in out
    ledger_db.close.assert_called_once()


def test_reparse_runs_when_needed(monkeypatch):
    ledger_db = MagicMock()
    state_db = MagicMock()
    monkeypatch.setattr(server.database, "apply_outstanding_migration", MagicMock())
    monkeypatch.setattr(server.database, "initialise_db", MagicMock(return_value=ledger_db))
    monkeypatch.setattr(server.database, "get_db_connection", MagicMock(return_value=state_db))
    monkeypatch.setattr(server.ledger.blocks, "last_db_index", MagicMock(return_value=100))
    monkeypatch.setattr(server.blocks, "check_database_version", MagicMock())
    monkeypatch.setattr(
        server.ledger.blocks, "get_last_block", MagicMock(return_value={"block_index": 20})
    )
    monkeypatch.setattr(server.blocks, "reparse", MagicMock())
    monkeypatch.setattr(server.dbbuilder, "rollback_state_db", MagicMock())
    monkeypatch.setattr(server.database, "optimize", MagicMock())
    monkeypatch.setattr(server.CurrentState, "set_current_block_index", lambda _self, _idx: None)

    server.reparse(10)

    server.blocks.reparse.assert_called_once_with(ledger_db, block_index=10)
    server.dbbuilder.rollback_state_db.assert_called_once_with(state_db, 10)
    assert server.database.optimize.call_count == 2
    ledger_db.close.assert_called_once()
    state_db.close.assert_called_once()


def test_rollback_early_exit(monkeypatch, capsys):
    ledger_db = MagicMock()
    monkeypatch.setattr(server.database, "apply_outstanding_migration", MagicMock())
    monkeypatch.setattr(server.database, "initialise_db", MagicMock(return_value=ledger_db))
    monkeypatch.setattr(server.ledger.blocks, "last_db_index", MagicMock(return_value=100))
    monkeypatch.setattr(server.blocks, "check_database_version", MagicMock())
    monkeypatch.setattr(
        server.ledger.blocks, "get_last_block", MagicMock(return_value={"block_index": 10})
    )
    monkeypatch.setattr(server.CurrentState, "set_current_block_index", lambda _self, _idx: None)

    server.rollback(11)

    out = capsys.readouterr().out
    assert "Block index is higher than current block index" in out
    ledger_db.close.assert_called_once()


def test_rollback_runs_when_needed(monkeypatch):
    ledger_db = MagicMock()
    state_db = MagicMock()
    monkeypatch.setattr(server.database, "apply_outstanding_migration", MagicMock())
    monkeypatch.setattr(server.database, "initialise_db", MagicMock(return_value=ledger_db))
    monkeypatch.setattr(server.database, "get_db_connection", MagicMock(return_value=state_db))
    monkeypatch.setattr(server.ledger.blocks, "last_db_index", MagicMock(return_value=100))
    monkeypatch.setattr(server.blocks, "check_database_version", MagicMock())
    monkeypatch.setattr(
        server.ledger.blocks, "get_last_block", MagicMock(return_value={"block_index": 20})
    )
    monkeypatch.setattr(server.blocks, "rollback", MagicMock())
    monkeypatch.setattr(server.dbbuilder, "rollback_state_db", MagicMock())
    monkeypatch.setattr(server.database, "optimize", MagicMock())
    monkeypatch.setattr(server.CurrentState, "set_current_block_index", lambda _self, _idx: None)

    cache = SimpleNamespace(clear=MagicMock())
    monkeypatch.setattr(server.follow, "NotSupportedTransactionsCache", lambda: cache)

    server.rollback(10)

    server.blocks.rollback.assert_called_once_with(ledger_db, block_index=10)
    server.dbbuilder.rollback_state_db.assert_called_once_with(state_db, 10)
    cache.clear.assert_called_once()
    assert server.database.optimize.call_count == 2
    ledger_db.close.assert_called_once()
    state_db.close.assert_called_once()


def test_check_database(monkeypatch):
    ledger_db = MagicMock()

    class DummySpinner:
        def __init__(self, _message):
            self.message = _message

        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, tb):
            return False

    monkeypatch.setattr(server.database, "initialise_db", MagicMock(return_value=ledger_db))
    monkeypatch.setattr(server.ledger.blocks, "last_db_index", MagicMock(return_value=100))
    monkeypatch.setattr(server.CurrentState, "set_current_block_index", lambda _self, _idx: None)
    monkeypatch.setattr(server.check, "asset_conservation", MagicMock())
    monkeypatch.setattr(server.database, "check_foreign_keys", MagicMock())
    monkeypatch.setattr(server.database, "intergrity_check", MagicMock())
    monkeypatch.setattr(server.log, "Spinner", DummySpinner)
    monkeypatch.setattr(server, "cprint", MagicMock())

    server.check_database()

    server.check.asset_conservation.assert_called_once_with(ledger_db)
    server.database.check_foreign_keys.assert_called_once_with(ledger_db)
    server.database.intergrity_check.assert_called_once_with(ledger_db)


def test_vacuum(monkeypatch):
    ledger_db = MagicMock()

    class DummySpinner:
        def __init__(self, _message):
            self.message = _message

        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, tb):
            return False

    monkeypatch.setattr(server.database, "initialise_db", MagicMock(return_value=ledger_db))
    monkeypatch.setattr(server.database, "vacuum", MagicMock())
    monkeypatch.setattr(server.log, "Spinner", DummySpinner)

    server.vacuum()

    server.database.vacuum.assert_called_once_with(ledger_db)


def test_show_params(monkeypatch, capsys):
    monkeypatch.setattr(config, "TEST_PARAM", "hello", raising=False)

    server.show_params()

    out = capsys.readouterr().out
    assert "TEST_PARAM: hello" in out
