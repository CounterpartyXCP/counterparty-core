from unittest.mock import patch

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

    with pytest.raises(exceptions.ComposeError, match=str(["quantity must be positive"])):
        dispense.compose(ledger_db, defaults["addresses"][0], defaults["addresses"][5], -100)

    with pytest.raises(exceptions.ComposeError, match=str(["quantity must be in satoshis"])):
        dispense.compose(ledger_db, defaults["addresses"][0], defaults["addresses"][5], "100")

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
            {
                "table": "transactions_status",
                "values": {
                    "tx_index": tx["tx_index"],
                    "valid": True,
                },
            },
        ],
    )


def test_parse_no_price_error_does_not_halt(ledger_db, blockchain_mock, defaults):
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], defaults["addresses"][5], btc_amount=100
    )
    with ProtocolChangesDisabled(["multiple_dispenses"]):
        with patch("counterpartycore.lib.messages.dispense.get_must_give") as mock_get:
            mock_get.side_effect = exceptions.NoPriceError("test: oracle has no price")
            dispense.parse(ledger_db, tx)


def test_get_must_give_negative_oracle_price_raises_no_price_error(ledger_db):
    """Regression: a negative oracle broadcast (e.g. value=-1) used to flow
    through get_must_give -> negative must_give -> negative actually_given
    -> ledger.events.credit(quantity=-N) raises CreditError -> uncaught ->
    ParseTransactionError -> halt. The fix widens the get_must_give guard
    to reject last_price <= 0 (was just == 0), surfacing as NoPriceError
    which dispense.parse already catches and continues over.
    """
    fake_dispenser = {
        "asset": "TESTDISP",
        "oracle_address": "fakeoracle",
        "satoshirate": 100,
        "give_quantity": 1,
        "give_remaining": 1000,
    }
    with patch("counterpartycore.lib.ledger.other.get_oracle_last_price") as mock_price:
        # Simulate a broadcast inserted with status='valid' but value < 0.
        mock_price.return_value = (-1.0, 0, "USD", 100)
        with pytest.raises(exceptions.NoPriceError):
            dispense.get_must_give(ledger_db, fake_dispenser, 10000, block_index=999999)
