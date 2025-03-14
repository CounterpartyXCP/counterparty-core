import time

from counterpartycore.lib import config
from counterpartycore.lib.ledger import backendheight, currentstate
from counterpartycore.lib.utils import database


def test_currentstate(ledger_db, current_block_index, monkeypatch):
    before_last_block = ledger_db.execute(
        "SELECT * FROM blocks WHERE block_index = ?", (current_block_index - 1,)
    ).fetchone()

    currentstate.CurrentState().set_current_block_index(before_last_block["block_index"])
    assert currentstate.CurrentState().current_block_index() == before_last_block["block_index"]
    assert currentstate.CurrentState().current_block_time() == before_last_block["block_time"]

    assert currentstate.CurrentState().current_tx_hash() is None
    assert currentstate.CurrentState().parsing_mempool() is None
    currentstate.CurrentState().set_parsing_mempool(True)
    assert currentstate.CurrentState().parsing_mempool() is True
    currentstate.CurrentState().set_parsing_mempool(False)
    assert not currentstate.CurrentState().parsing_mempool()

    assert currentstate.CurrentState().ledger_state() == "Starting"
    currentstate.CurrentState().set_ledger_state(ledger_db, "Following")
    assert currentstate.CurrentState().ledger_state() == "Following"
    assert database.get_config_value(ledger_db, "LEDGER_STATE") == "Following"
    currentstate.CurrentState().set_ledger_state(ledger_db, "Catching Up")
    assert currentstate.CurrentState().ledger_state() == "Catching Up"
    assert database.get_config_value(ledger_db, "LEDGER_STATE") == "Catching Up"

    currentstate.CurrentState().set("toto", "tata")
    assert currentstate.CurrentState().get("toto") == "tata"


def test_backend_height(monkeypatch):
    current_backend_height = 1000
    current_block_count = 980

    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.getblockcount", lambda: current_block_count
    )
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.get_chain_tip", lambda: current_backend_height
    )

    backend_height_thread = backendheight.BackendHeight()
    currentstate.CurrentState().set_backend_height_value(
        backend_height_thread.shared_backend_height
    )

    assert (
        backend_height_thread.shared_backend_height.value
        == current_backend_height * 10e8 + current_block_count
    )
    # use .state directly because current_backend_height() is mocked
    assert currentstate.CurrentState().current_backend_height() == current_backend_height
    assert currentstate.CurrentState().current_block_count() == current_block_count

    try:
        backend_height_thread.start()
        backendheight.BACKEND_HEIGHT_REFRSH_INTERVAL = 0.1

        for _i in range(10):
            current_backend_height += 1
            current_block_count += 1
            time.sleep(backendheight.BACKEND_HEIGHT_REFRSH_INTERVAL * 3)
            assert (
                backend_height_thread.shared_backend_height.value
                == current_backend_height * 10e8 + current_block_count
            )
            assert currentstate.CurrentState().current_backend_height() == current_backend_height
            assert currentstate.CurrentState().current_block_count() == current_block_count
    finally:
        backend_height_thread.stop()

    backend_height_thread = backendheight.BackendHeight()

    last_check_before = backend_height_thread.last_check
    config.API_ONLY = True
    backend_height_thread.refresh()
    assert backend_height_thread.last_check == last_check_before

    backend_height_thread.start()
    time.sleep(backendheight.BACKEND_HEIGHT_REFRSH_INTERVAL * 3)
    backend_height_thread.stop()
    assert backend_height_thread.last_check == last_check_before
