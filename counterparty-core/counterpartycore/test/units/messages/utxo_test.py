from counterpartycore.lib import config
from counterpartycore.lib.messages import utxo

DUMMY_UTXO = 64 * "0" + ":1"


def test_validate(ledger_db, defaults):
    assert (
        utxo.validate(
            ledger_db,
            defaults["addresses"][0],
            DUMMY_UTXO,
            "XCP",
            100,
        )
        == []
    )

    assert utxo.validate(
        ledger_db, defaults["addresses"][0], defaults["addresses"][1], "XCP", 100
    ) == ["If source is an address, destination must be a UTXO"]

    assert utxo.validate(ledger_db, DUMMY_UTXO, DUMMY_UTXO, "XCP", 100) == [
        "If source is a UTXO, destination must be an address",
        "insufficient funds for transfer and fee",
    ]

    assert utxo.validate(ledger_db, defaults["addresses"][0], DUMMY_UTXO, "XCP", 0) == [
        "quantity must be greater than zero"
    ]

    assert utxo.validate(
        ledger_db, defaults["addresses"][0], DUMMY_UTXO, "XCP", 99999999999999
    ) == ["insufficient funds for transfer and fee"]

    assert utxo.validate(
        ledger_db,
        defaults["addresses"][0],
        DUMMY_UTXO,
        "BTC",
        100,
    ) == ["cannot send bitcoins", "insufficient funds for transfer"]

    assert utxo.validate(
        ledger_db,
        defaults["addresses"][0],
        DUMMY_UTXO,
        "XCP",
        config.MAX_INT + 1,
    ) == ["integer overflow", "insufficient funds for transfer and fee"]

    assert utxo.validate(
        ledger_db,
        defaults["addresses"][0],
        DUMMY_UTXO,
        "XCP",
        "100",
    ) == ["quantity must be in satoshis"]


def test_unpack(defaults):
    assert utxo.unpack(
        b"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc|344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1|XCP|100"
    ) == (
        defaults["addresses"][0],
        "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1",
        "XCP",
        100,
    )


def test_parse_attach(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    destination_uxo = "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:0"
    blockchain_mock.address_and_value_by_utxo[destination_uxo] = (defaults["addresses"][0], 100000)
    message = b"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc|344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:0|XCP|100"
    utxo.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "debits",
                "values": {
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "quantity": 100,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "action": "attach to utxo",
                },
            },
            {
                "table": "credits",
                "values": {
                    "utxo": destination_uxo,
                    "address": None,
                    "asset": "XCP",
                    "quantity": 100,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "calling_function": "attach to utxo",
                },
            },
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "status": "valid",
                    "source": defaults["addresses"][0],
                    "destination": destination_uxo,
                    "asset": "XCP",
                    "quantity": 100,
                    "fee_paid": 0,
                    "send_type": "attach",
                },
            },
            {
                "table": "messages",
                "values": {
                    "block_index": current_block_index,
                    "command": "insert",
                    "category": "sends",
                    "event": "ATTACH_TO_UTXO",
                },
            },
        ],
    )


def get_utxo(ledger_db, address):
    return ledger_db.execute(
        "SELECT * FROM balances WHERE utxo_address = ? AND quantity > 0",
        (address,),
    ).fetchone()["utxo"]


def test_parse_detach(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    source_uxo = get_utxo(ledger_db, defaults["addresses"][0])
    message = (
        bytes(source_uxo, "utf-8") + b"|" + bytes(defaults["addresses"][1], "utf-8") + b"|XCP|100"
    )
    utxo.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "status": "valid",
                    "source": source_uxo,
                    "destination": defaults["addresses"][1],
                    "asset": "XCP",
                    "quantity": 100,
                    "fee_paid": 0,
                    "send_type": "detach",
                },
            },
            {
                "table": "messages",
                "values": {
                    "block_index": current_block_index,
                    "command": "insert",
                    "category": "sends",
                    "event": "DETACH_FROM_UTXO",
                },
            },
            {
                "table": "debits",
                "values": {
                    "utxo": source_uxo,
                    "asset": "XCP",
                    "quantity": 100,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "action": "detach from utxo",
                },
            },
            {
                "table": "credits",
                "values": {
                    "utxo": None,
                    "address": defaults["addresses"][1],
                    "asset": "XCP",
                    "quantity": 100,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "calling_function": "detach from utxo",
                },
            },
        ],
    )
