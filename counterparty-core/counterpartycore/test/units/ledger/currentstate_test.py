import time

from counterpartycore.lib import config
from counterpartycore.lib.ledger import currentstate
from counterpartycore.test.mocks.bitcoind import original_current_backend_height


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

    assert currentstate.CurrentState().block_parser_status() == "starting"
    currentstate.CurrentState().set_block_parser_status("running")
    assert currentstate.CurrentState().block_parser_status() == "running"
    currentstate.CurrentState().set_block_parser_status("starting")
    assert currentstate.CurrentState().block_parser_status() == "starting"

    currentstate.CurrentState().set("toto", "tata")
    assert currentstate.CurrentState().get("toto") == "tata"


def test_backend_height(monkeypatch):
    current_backend_height = 1000

    def get_backend_height_mock():
        return current_backend_height

    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.getblockcount", get_backend_height_mock
    )
    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.get_blocks_behind", lambda: 0)
    currentstate.CurrentState.current_backend_height = original_current_backend_height

    assert currentstate.CurrentState().current_backend_height() is None

    backend_height_thread = currentstate.BackendHeight()
    currentstate.CurrentState().set_backend_height_value(
        backend_height_thread.shared_backend_height
    )

    assert backend_height_thread.shared_backend_height.value == current_backend_height
    # use .state directly because current_backend_height() is mocked
    assert currentstate.CurrentState().current_backend_height() == current_backend_height

    try:
        backend_height_thread.start()
        currentstate.BACKEND_HEIGHT_REFRSH_INTERVAL = 0.1

        for _i in range(10):
            current_backend_height += 1
            time.sleep(currentstate.BACKEND_HEIGHT_REFRSH_INTERVAL * 3)
            assert backend_height_thread.shared_backend_height.value == current_backend_height
            assert currentstate.CurrentState().current_backend_height() == current_backend_height
    finally:
        backend_height_thread.stop()

    backend_height_thread = currentstate.BackendHeight()

    last_check_before = backend_height_thread.last_check
    config.API_ONLY = True
    backend_height_thread.refresh()
    assert backend_height_thread.last_check == last_check_before

    backend_height_thread.start()
    time.sleep(currentstate.BACKEND_HEIGHT_REFRSH_INTERVAL * 3)
    backend_height_thread.stop()
    assert backend_height_thread.last_check == last_check_before
