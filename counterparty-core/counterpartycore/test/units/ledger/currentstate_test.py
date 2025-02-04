from counterpartycore.lib.ledger import currentstate


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

    assert currentstate.CurrentState().block_parser_status() == "starting"
    currentstate.CurrentState().set_block_parser_status("running")
    assert currentstate.CurrentState().block_parser_status() == "running"

    currentstate.CurrentState().set("toto", "tata")
    assert currentstate.CurrentState().get("toto") == "tata"

    monkeypatch.setattr(currentstate, "get_backend_height", lambda: 100)
    assert currentstate.CurrentState().current_backend_height() == 100
