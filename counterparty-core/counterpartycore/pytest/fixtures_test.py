def test_ledger(ledger_db):
    cursor = ledger_db.cursor()
    blocks = cursor.execute("SELECT * FROM blocks").fetchall()
    burns = cursor.execute("SELECT * FROM burns").fetchall()
    assert len(blocks) == 11
    assert len(burns) == 1
