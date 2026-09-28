from types import SimpleNamespace
from unittest.mock import MagicMock

import apsw
import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.cli import server
from counterpartycore.lib.messages.data import checkpoints
from counterpartycore.lib.parser import check

LEDGER = "11" * 32
TXLIST = "22" * 32
EXPECTED = {"ledger_hash": LEDGER, "txlist_hash": TXLIST}


@pytest.fixture
def checkpoint_db(monkeypatch):
    for flag in ("TESTNET3", "TESTNET4", "REGTEST", "SIGNET"):
        monkeypatch.setattr(config, flag, False)
    monkeypatch.setattr(config, "BLOCK_FIRST", 100)
    monkeypatch.setattr(checkpoints, "CHECKPOINTS_MAINNET", {100: EXPECTED, 200: EXPECTED})
    db = apsw.Connection(":memory:")
    db.setrowtrace(
        lambda cursor, row: dict(zip((c[0] for c in cursor.getdescription()), row, strict=True))
    )
    db.execute(
        "CREATE TABLE blocks(block_index INTEGER PRIMARY KEY, ledger_hash BLOB, txlist_hash BLOB, messages_hash BLOB)"
    )
    yield db
    db.close()


def insert(db, height, ledger=LEDGER, txlist=TXLIST):
    db.execute("INSERT INTO blocks VALUES(?,?,?,?)", (height, ledger, txlist, "informational"))


@pytest.mark.parametrize("blob", [False, True])
def test_valid_text_and_blob_checkpoints_are_read_only(checkpoint_db, blob):
    db = checkpoint_db
    encode = bytes.fromhex if blob else str
    insert(db, 100, encode(LEDGER), encode(TXLIST))
    insert(db, 200, encode(LEDGER), encode(TXLIST))
    before = list(db.execute("SELECT * FROM blocks ORDER BY block_index"))
    db.execute("PRAGMA query_only=ON")
    assert check.stored_checkpoints(db) == 2
    assert list(db.execute("SELECT * FROM blocks ORDER BY block_index")) == before


@pytest.mark.parametrize("field", ["ledger_hash", "txlist_hash"])
@pytest.mark.parametrize("bad", [None, "", "ff" * 32, b"short", 123])
def test_rejects_missing_malformed_or_mismatching_hash(checkpoint_db, field, bad):
    db = checkpoint_db
    insert(db, 100)
    sql = {
        "ledger_hash": "UPDATE blocks SET ledger_hash=? WHERE block_index=100",
        "txlist_hash": "UPDATE blocks SET txlist_hash=? WHERE block_index=100",
    }[field]
    db.execute(sql, (bad,))
    before = list(db.execute("SELECT * FROM blocks"))
    db.execute("PRAGMA query_only=ON")
    with pytest.raises(
        exceptions.ConsensusError, match=f"Stored {field} checkpoint mismatch at block 100"
    ):
        check.stored_checkpoints(db)
    assert list(db.execute("SELECT * FROM blocks")) == before


def test_checks_older_checkpoint_even_if_latest_matches(checkpoint_db):
    insert(checkpoint_db, 100, "ff" * 32)
    insert(checkpoint_db, 200)
    with pytest.raises(exceptions.ConsensusError, match="block 100"):
        check.stored_checkpoints(checkpoint_db)


def test_missing_historical_checkpoint_is_not_silently_skipped(checkpoint_db):
    insert(checkpoint_db, 200)
    with pytest.raises(exceptions.ConsensusError, match="block 100"):
        check.stored_checkpoints(checkpoint_db)


def test_empty_precheckpoint_and_fetched_future_blocks_are_allowed(checkpoint_db):
    assert check.stored_checkpoints(checkpoint_db) == 0
    insert(checkpoint_db, 99)
    assert check.stored_checkpoints(checkpoint_db) == 0
    insert(checkpoint_db, 100)
    insert(checkpoint_db, 200, None, None)
    insert(checkpoint_db, config.MEMPOOL_BLOCK_INDEX, "ff" * 32, "ff" * 32)
    assert check.stored_checkpoints(checkpoint_db) == 1


@pytest.mark.parametrize("flag", ["TESTNET3", "TESTNET4", "REGTEST", "SIGNET"])
def test_selects_only_the_configured_network(checkpoint_db, monkeypatch, flag):
    monkeypatch.setattr(config, flag, True)
    monkeypatch.setattr(
        checkpoints,
        f"CHECKPOINTS_{flag}",
        {100: {"ledger_hash": "33" * 32, "txlist_hash": "44" * 32}},
    )
    insert(checkpoint_db, 100, "33" * 32, "44" * 32)
    assert check.stored_checkpoints(checkpoint_db) == 1


@pytest.mark.parametrize("api_only", [False, True])
@pytest.mark.parametrize("force", [False, True])
def test_startup_rejects_bad_history_before_either_api_starts(
    checkpoint_db, monkeypatch, api_only, force
):
    insert(checkpoint_db, 100, "ff" * 32)
    monkeypatch.setattr(config, "FORCE", force)
    monkeypatch.setattr(config, "MEMORY_PROFILE", False)
    monkeypatch.setattr(server, "should_bootstrap_database", lambda *_: False)
    monkeypatch.setattr(server.database, "apply_outstanding_migration", MagicMock())
    monkeypatch.setattr(server.database, "initialise_db", lambda: checkpoint_db)
    monkeypatch.setattr(server.blocks, "create_events_indexes", MagicMock())
    monkeypatch.setattr(server.blocks, "check_database_version", MagicMock())
    monkeypatch.setattr(server.CurrentState, "set_current_block_index", MagicMock())
    optimize = MagicMock()
    monkeypatch.setattr(server.database, "optimize", optimize)
    v1, v2 = MagicMock(), MagicMock()
    monkeypatch.setattr(server.apiv1, "APIServer", v1)
    monkeypatch.setattr(server.api_v2, "APIServer", v2)
    app = server.CounterpartyServer(
        SimpleNamespace(catch_up="normal", bootstrap_url=None, api_only=api_only)
    )
    with pytest.raises(exceptions.ConsensusError, match="Refusing to start the API"):
        app.run_server()
    v1.assert_not_called()
    v2.assert_not_called()
    optimize.assert_not_called()
    assert isinstance(app.startup_checkpoint_error, exceptions.ConsensusError)


@pytest.mark.parametrize("mismatch", [False, True])
def test_checkpoint_failure_propagates_after_clean_shutdown(monkeypatch, mismatch):
    error = exceptions.ConsensusError("bad stored checkpoint") if mismatch else None
    app = SimpleNamespace(
        start=MagicMock(side_effect=KeyboardInterrupt),
        stop=MagicMock(),
        startup_checkpoint_error=error,
    )
    monkeypatch.setattr(server, "CounterpartyServer", lambda *a, **k: app)
    monkeypatch.setattr(server.signal, "signal", MagicMock())
    if mismatch:
        with pytest.raises(exceptions.ConsensusError, match="bad stored checkpoint"):
            server.start_all(SimpleNamespace())
    else:
        server.start_all(SimpleNamespace())
    app.stop.assert_called_once()


def test_reported_node_checkpoint_is_rejected(checkpoint_db, monkeypatch):
    # #3528's published stored ledger hash disagrees with the v11.4 checkpoint.
    monkeypatch.setattr(
        checkpoints,
        "CHECKPOINTS_MAINNET",
        {
            967388: {
                "ledger_hash": "5726f3e2a20ee2ed7c2773021a9015340a182f8b869ccace84934fbda9499e50",
                "txlist_hash": "3312af4731072c8b593e99a39fa752f99844f5979316313b48c6da2e93d4092b",
            }
        },
    )
    insert(
        checkpoint_db,
        967388,
        "6ca177000e8c257645440f2e1466391de59c6a9c05ce877267e55b4327b85e5f",
        "cd88c7f66cfb95e9b1f52d92eb799f9a94bd9eef98319aea4bd6a1ecc2b9a0e9",
    )
    insert(checkpoint_db, 968987)
    with pytest.raises(exceptions.ConsensusError, match="block 967388"):
        check.stored_checkpoints(checkpoint_db)
