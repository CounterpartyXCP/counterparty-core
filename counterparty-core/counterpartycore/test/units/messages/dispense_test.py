import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.messages import dispense
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_compose(ledger_db, defaults):
    assert dispense.compose(ledger_db, defaults["addresses"][0], defaults["addresses"][5], 100) == (
        defaults["addresses"][0],
        [(defaults["addresses"][5], 100)],
        b"\r\x00",
    )

    error = str(
        [
            "not enough BTC to trigger dispenser for XCP",
            "not enough BTC to trigger dispenser for TESTDISP",
        ]
    )
    with pytest.raises(exceptions.ComposeError, match=error):
        assert dispense.compose(ledger_db, defaults["addresses"][0], defaults["addresses"][5], 10)

    error = str(
        [
            "dispenser for XCP doesn't have enough asset to give",
            "dispenser for TESTDISP doesn't have enough asset to give",
        ]
    )
    with pytest.raises(exceptions.ComposeError, match=error):
        assert dispense.compose(
            ledger_db, defaults["addresses"][0], defaults["addresses"][5], 10000
        )

    error = str(["address doesn't have any open dispenser"])
    with pytest.raises(exceptions.ComposeError, match=error):
        dispense.compose(
            ledger_db,
            defaults["addresses"][0],
            defaults["addresses"][8],
            10,
        )


def test_parse(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], defaults["addresses"][5], btc_amount=100
    )
    with ProtocolChangesDisabled(["multiple_dispenses"]):
        dispense.parse(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "dispensers",
                "values": {  # Some values here correspond to the original TX that opened the dispenser
                    "block_index": current_block_index,
                    "source": defaults["addresses"][5],
                    "asset": "XCP",
                    "give_quantity": 100,
                    "escrow_quantity": 100,
                    "satoshirate": 100,
                    "status": 10,
                    "give_remaining": 0,
                },
            },
            {
                "table": "credits",
                "values": {
                    "calling_function": "dispense",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 100,
                },
            },
        ],
    )


def test_parse_lost_found(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], defaults["addresses"][5], btc_amount=300
    )
    with ProtocolChangesDisabled(["multiple_dispenses"]):
        dispense.parse(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "dispensers",
                "values": {  # Some values here correspond to the original TX that opened the dispenser
                    "block_index": current_block_index,
                    "source": defaults["addresses"][5],
                    "asset": "XCP",
                    "give_quantity": 100,
                    "escrow_quantity": 100,
                    "satoshirate": 100,
                    "status": 10,
                    "give_remaining": 0,
                },
            },
            {
                "table": "credits",
                "values": {
                    "calling_function": "dispense",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 100,
                },
            },
        ],
    )
