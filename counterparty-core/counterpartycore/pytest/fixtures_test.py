from .fixtures import ledgerdb


def test_ledger(ledger_db):
    cursor = ledger_db.cursor()
    burns = cursor.execute("SELECT * FROM burns").fetchall()
    transactions = cursor.execute("SELECT * FROM transactions").fetchall()

    tx_count = len([tx for tx in ledgerdb.UNITTEST_FIXTURE if tx[0] != "mine_empty_blocks"])
    burn_count = len([tx for tx in ledgerdb.UNITTEST_FIXTURE if tx[0] == "burn"])

    assert len(transactions) == tx_count
    assert len(burns) == burn_count
