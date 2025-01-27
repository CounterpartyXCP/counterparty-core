from counterpartycore.lib.ledger import balances


def test_balances_functions(ledger_db, defaults):
    assert balances.get_balance(ledger_db, defaults["addresses"][0], "XCP") == 91699999693
    assert balances.get_balance(ledger_db, defaults["addresses"][0], "foobar") == 0
