from counterpartycore.lib.parser import protocol
from counterpartycore.test.fixtures import ledgerdb
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_ledger_db(ledger_db):
    cursor = ledger_db.cursor()
    burns = cursor.execute("SELECT * FROM burns").fetchall()
    transactions = cursor.execute("SELECT * FROM transactions").fetchall()

    tx_count = len([tx for tx in ledgerdb.UNITTEST_FIXTURE if tx[0] != "mine_empty_blocks"])
    burn_count = len([tx for tx in ledgerdb.UNITTEST_FIXTURE if tx[0] == "burn"])

    assert len(transactions) == tx_count
    assert len(burns) == burn_count


def test_ledger_db_2(ledger_db):
    cursor = ledger_db.cursor()
    burns = cursor.execute("SELECT * FROM burns").fetchall()
    transactions = cursor.execute("SELECT * FROM transactions").fetchall()

    tx_count = len([tx for tx in ledgerdb.UNITTEST_FIXTURE if tx[0] != "mine_empty_blocks"])
    burn_count = len([tx for tx in ledgerdb.UNITTEST_FIXTURE if tx[0] == "burn"])

    assert len(transactions) == tx_count
    assert len(burns) == burn_count


def test_state_db(state_db):
    cursor = state_db.cursor()
    balances = cursor.execute(
        "SELECT asset, SUM(quantity) AS quantity FROM balances GROUP BY asset"
    ).fetchall()
    assert balances == [
        {"asset": "A160361285792733729", "quantity": 50},
        {"asset": "A95428959342453541", "quantity": 100000000},
        {"asset": "CALLABLE", "quantity": 1000},
        {"asset": "DIVIDEND", "quantity": 100},
        {"asset": "DIVISIBLE", "quantity": 100000000000},
        {"asset": "FREEFAIRMIN", "quantity": 10},
        {"asset": "LOCKED", "quantity": 1000},
        {"asset": "LOCKEDPREV", "quantity": 1000},
        {"asset": "MAXI", "quantity": 9223372036854775807},
        {"asset": "NODIVISIBLE", "quantity": 1000},
        {"asset": "PARENT", "quantity": 100000000},
        {"asset": "PAYTOSCRIPT", "quantity": 1000},
        {"asset": "QAIDFAIRMIN", "quantity": 20},
        {"asset": "RAIDFAIRMIN", "quantity": 20},
        {"asset": "TESTDISP", "quantity": 900},
        {"asset": "XCP", "quantity": 603414652282},
    ]


def test_state_db_2(state_db):
    cursor = state_db.cursor()
    balances = cursor.execute(
        "SELECT asset, SUM(quantity) AS quantity FROM balances GROUP BY asset"
    ).fetchall()
    assert len(balances) == 16


def test_protocol_changes_disabled():
    assert protocol.enabled("multisig_addresses")

    with ProtocolChangesDisabled(["multisig_addresses"]):
        assert not protocol.enabled("multisig_addresses")

    assert protocol.enabled("multisig_addresses")
