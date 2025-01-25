from counterpartycore.lib.messages import send
from counterpartycore.lib.messages.versions import send1
from counterpartycore.lib.parser import blocks


def test_parse_tx_simple(ledger_db, defaults, blockchain_mock, test_helpers):
    _source, _destination, data = send.compose(
        ledger_db, defaults["addresses"][0], defaults["addresses"][1], "XCP", 100
    )
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=data)
    blocks.parse_tx(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "destination": defaults["addresses"][1],
                    "quantity": 100,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            }
        ],
    )


def test_parse_tx_multisig(ledger_db, defaults, blockchain_mock, test_helpers):
    _source, _destination, data = send1.compose(
        ledger_db, defaults["addresses"][0], defaults["p2ms_addresses"][0], "XCP", 100
    )
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], defaults["p2ms_addresses"][0], data=data
    )
    blocks.parse_tx(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "destination": defaults["p2ms_addresses"][0],
                    "quantity": 100,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            }
        ],
    )
