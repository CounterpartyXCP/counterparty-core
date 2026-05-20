"""Tests that v11.1 replay-sensitive behavior is gated at activation."""

from counterpartycore.lib.messages import sweep
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_persist_invalid_sweep_gate_off_skips_journal(ledger_db, blockchain_mock, defaults):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    with ProtocolChangesDisabled(["persist_invalid_sweep"]):
        sweep.parse(ledger_db, tx, b"\x00" * 10)

    cursor = ledger_db.cursor()
    rows = cursor.execute("SELECT * FROM sweeps WHERE tx_hash = ?", (tx["tx_hash"],)).fetchall()
    assert len(rows) == 0


def test_persist_invalid_sweep_gate_on_inserts(ledger_db, blockchain_mock, defaults):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    sweep.parse(ledger_db, tx, b"\x00" * 10)

    cursor = ledger_db.cursor()
    rows = cursor.execute("SELECT * FROM sweeps WHERE tx_hash = ?", (tx["tx_hash"],)).fetchall()
    assert len(rows) == 1
    assert rows[0]["status"].startswith("invalid:")
