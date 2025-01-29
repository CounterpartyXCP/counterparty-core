from counterpartycore.lib.api import apiwatcher
from counterpartycore.lib.ledger import balances
from counterpartycore.lib.messages import send
from counterpartycore.lib.messages.versions import enhancedsend


def test_balances_functions(ledger_db, defaults):
    assert balances.get_balance(ledger_db, defaults["addresses"][0], "XCP") == 91699999693
    assert balances.get_balance(ledger_db, defaults["addresses"][0], "foobar") == 0


def test_balances_after_send(ledger_db, state_db, defaults, blockchain_mock):
    assert balances.get_balance(ledger_db, defaults["addresses"][0], "XCP") == 91699999693
    assert balances.get_balance(ledger_db, defaults["addresses"][1], "XCP") == 100000000

    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _source, _destination, data = send.compose(
        ledger_db,
        defaults["addresses"][0],
        defaults["addresses"][1],
        "XCP",
        100000000,
    )
    enhancedsend.parse(ledger_db, tx, data[1:])
    apiwatcher.catch_up(ledger_db, state_db)

    assert (
        balances.get_balance(ledger_db, defaults["addresses"][0], "XCP") == 91699999693 - 100000000
    )
    assert balances.get_balance(ledger_db, defaults["addresses"][1], "XCP") == 100000000 + 100000000

    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1])
    _source, _destination, data = send.compose(
        ledger_db,
        defaults["addresses"][1],
        defaults["addresses"][0],
        "XCP",
        500000,
    )
    enhancedsend.parse(ledger_db, tx, data[1:])
    apiwatcher.catch_up(ledger_db, state_db)

    assert (
        balances.get_balance(ledger_db, defaults["addresses"][0], "XCP")
        == 91699999693 - 100000000 + 500000
    )
    assert (
        balances.get_balance(ledger_db, defaults["addresses"][1], "XCP")
        == 100000000 + 100000000 - 500000
    )
