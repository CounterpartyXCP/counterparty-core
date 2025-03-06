import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.api import apiwatcher
from counterpartycore.lib.ledger import balances
from counterpartycore.lib.messages import send
from counterpartycore.lib.messages.versions import enhancedsend

DUMMY_UTXO = 64 * "0" + ":1"


def test_balances_functions(ledger_db, defaults):
    assert balances.get_balance(ledger_db, defaults["addresses"][0], "XCP") == 91649999693
    assert balances.get_balance(ledger_db, defaults["addresses"][0], "foobar") == 0


def test_balances_after_send(ledger_db, state_db, defaults, blockchain_mock):
    assert balances.get_balance(ledger_db, defaults["addresses"][0], "XCP") == 91649999693
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
        balances.get_balance(ledger_db, defaults["addresses"][0], "XCP") == 91649999693 - 100000000
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
        == 91649999693 - 100000000 + 500000
    )
    assert (
        balances.get_balance(ledger_db, defaults["addresses"][1], "XCP")
        == 100000000 + 100000000 - 500000
    )

    error_message = f"No balance for this address and asset: {defaults['addresses'][0]}, foobar."
    with pytest.raises(exceptions.BalanceError, match=error_message):
        balances.get_balance(
            ledger_db, defaults["addresses"][0], "foobar", raise_error_if_no_balance=True
        )


def test_get_address_assets(ledger_db, defaults):
    assert balances.get_address_assets(ledger_db, defaults["addresses"][0]) == [
        {"asset": "A95428959342453541"},
        {"asset": "CALLABLE"},
        {"asset": "DIVISIBLE"},
        {"asset": "FREEFAIRMIN"},
        {"asset": "LOCKED"},
        {"asset": "MAXI"},
        {"asset": "NODIVISIBLE"},
        {"asset": "PARENT"},
        {"asset": "RAIDFAIRMIN"},
        {"asset": "XCP"},
    ]

    assert balances.get_address_assets(ledger_db, DUMMY_UTXO) == []

    assert balances.get_balances_count(ledger_db, defaults["addresses"][0]) == [{"cnt": 10}]
    assert balances.get_balances_count(ledger_db, DUMMY_UTXO) == [{"cnt": 0}]

    check_balances = [
        {"MAX(rowid)": 94, "address": None, "asset": "XCP", "quantity": 100},
        {
            "MAX(rowid)": 19,
            "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
            "asset": "XCP",
            "quantity": 300000000,
        },
        {
            "MAX(rowid)": 101,
            "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
            "asset": "XCP",
            "quantity": 46449986773,
        },
        {
            "MAX(rowid)": 51,
            "address": "bcrt1qfaw3f6ryl9jn4f5l0x7qdccxyl82snmwkrcfh9",
            "asset": "XCP",
            "quantity": 92999971893,
        },
        {
            "MAX(rowid)": 100,
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "XCP",
            "quantity": 91649999693,
        },
        {
            "MAX(rowid)": 63,
            "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
            "asset": "XCP",
            "quantity": 3892761,
        },
        {
            "MAX(rowid)": 64,
            "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj",
            "asset": "XCP",
            "quantity": 92945878046,
        },
        {
            "MAX(rowid)": 39,
            "address": "mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK",
            "asset": "XCP",
            "quantity": 14999996,
        },
        {
            "MAX(rowid)": 89,
            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "asset": "XCP",
            "quantity": 100000000,
        },
        {
            "MAX(rowid)": 97,
            "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
            "asset": "XCP",
            "quantity": 92949974273,
        },
        {
            "MAX(rowid)": 85,
            "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
            "asset": "XCP",
            "quantity": 0,
        },
        {
            "MAX(rowid)": 50,
            "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            "asset": "XCP",
            "quantity": 92949974167,
        },
        {
            "MAX(rowid)": 102,
            "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM",
            "asset": "XCP",
            "quantity": 92999974580,
        },
    ]
    assert (
        balances.get_asset_balances(ledger_db, "XCP", exclude_zero_balances=False) == check_balances
    )

    check_balances = [b for b in check_balances if b["quantity"] > 0]
    assert balances.get_asset_balances(ledger_db, "XCP") == check_balances
