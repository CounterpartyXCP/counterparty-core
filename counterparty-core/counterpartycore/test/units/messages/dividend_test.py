from counterpartycore.lib import ledger
from counterpartycore.lib.messages import dividend


def test_validate(ledger_db, defaults, current_block_index):
    assert dividend.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["quantity"] * 1000,
        "DIVISIBLE",
        "XCP",
        current_block_index,
    ) == (None, None, ["insufficient funds (XCP)"], 0)

    assert dividend.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["quantity"] * -1000,
        "DIVISIBLE",
        "XCP",
        current_block_index,
    ) == (None, None, ["non‐positive quantity per unit"], 0)

    assert dividend.validate(
        ledger_db, defaults["addresses"][0], defaults["quantity"], "BTC", "XCP", current_block_index
    ) == (
        None,
        None,
        ["cannot pay dividends to holders of BTC", "only issuer can pay dividends"],
        0,
    )

    assert dividend.validate(
        ledger_db, defaults["addresses"][0], defaults["quantity"], "XCP", "XCP", current_block_index
    ) == (
        None,
        None,
        [
            "cannot pay dividends to holders of XCP",
            "only issuer can pay dividends",
            "insufficient funds (XCP)",
        ],
        0,
    )

    assert dividend.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["quantity"],
        "NOASSET",
        "XCP",
        current_block_index,
    ) == (None, None, ["no such asset, NOASSET."], 0)

    assert dividend.validate(
        ledger_db, defaults["addresses"][0], 0, "DIVISIBLE", "XCP", current_block_index
    ) == (None, None, ["non‐positive quantity per unit", "zero dividend"], 0)

    assert dividend.validate(
        ledger_db,
        defaults["addresses"][1],
        defaults["quantity"],
        "DIVISIBLE",
        "XCP",
        current_block_index,
    ) == (None, None, ["only issuer can pay dividends", "insufficient funds (XCP)"], 0)

    assert dividend.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["quantity"],
        "DIVISIBLE",
        "NOASSET",
        current_block_index,
    ) == (None, None, ["no such dividend asset, NOASSET."], 0)

    assert dividend.validate(
        ledger_db, defaults["addresses"][0], 8359090909, "DIVISIBLE", "XCP", current_block_index
    ) == (None, None, ["insufficient funds (XCP)"], 0)

    assert dividend.validate(
        ledger_db, defaults["addresses"][2], 2**63, "DIVIDEND", "DIVIDEND", current_block_index
    ) == (None, None, ["integer overflow", "insufficient funds (DIVIDEND)"], 0)

    # let's debit some XCP so that he can't pay the dividend fees
    ledger.events.debit(ledger_db, defaults["addresses"][2], "XCP", 3892760, current_block_index)
    assert dividend.validate(
        ledger_db, defaults["addresses"][2], 100000000, "DIVIDEND", "DIVIDEND", 333333
    ) == (None, None, ["insufficient funds (XCP)"], 0)


def test_compose(ledger_db, defaults):
    assert dividend.compose(
        ledger_db, defaults["addresses"][0], defaults["quantity"], "DIVISIBLE", "XCP"
    ) == (
        defaults["addresses"][0],
        [],
        b"2\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01",
    )

    assert dividend.compose(ledger_db, defaults["addresses"][0], 1, "NODIVISIBLE", "XCP") == (
        defaults["addresses"][0],
        [],
        b"2\x00\x00\x00\x00\x00\x00\x00\x01\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x00\x01",
    )

    assert dividend.compose(
        ledger_db, defaults["addresses"][0], 1, "DIVISIBLE", "PARENT.already.issued"
    ) == (
        defaults["addresses"][0],
        [],
        b'2\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\xa2[\xe3Kf\x01S\x08"\x06\xe4c%',
    )


def test_parse_dividend(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = (
        b"\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01"
    )
    dividend.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "dividends",
                "values": {
                    "asset": "DIVISIBLE",
                    "block_index": tx["block_index"],
                    "dividend_asset": "XCP",
                    "fee_paid": 80000,
                    "quantity_per_unit": 100000000,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][1],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "dividend",
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "dividend",
                    "event": tx["tx_hash"],
                    "quantity": 1000000000,
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "dividend",
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "dividend",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 1200000001,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "dividend fee",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 80000,
                },
            },
        ],
    )


def test_parse_dividend_no_divisible(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x00\x01"
    dividend.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "dividends",
                "values": {
                    "asset": "NODIVISIBLE",
                    "block_index": tx["block_index"],
                    "dividend_asset": "XCP",
                    "fee_paid": 40000,
                    "quantity_per_unit": 1,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][1],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "dividend",
                    "event": tx["tx_hash"],
                    "quantity": 5,
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "dividend",
                    "event": tx["tx_hash"],
                    "quantity": 10,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "dividend",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 15,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "dividend fee",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 40000,
                },
            },
        ],
    )
