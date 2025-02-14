import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.messages import burn


def test_validate(ledger_db, defaults):
    assert (
        burn.validate(
            ledger_db,
            defaults["addresses"][0],
            defaults["unspendable"],
            defaults["burn_quantity"],
            config.BURN_START,
        )
        == []
    )

    assert burn.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["unspendable"],
        1.1 * defaults["burn_quantity"],
        config.BURN_START,
    ) == ["quantity must be in satoshis"]

    assert burn.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["addresses"][1],
        defaults["burn_quantity"],
        config.BURN_START,
    ) == ["wrong destination address"]

    assert burn.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["unspendable"],
        -1 * defaults["burn_quantity"],
        config.BURN_START,
    ) == ["negative quantity"]

    assert burn.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["unspendable"],
        defaults["burn_quantity"],
        config.BURN_START - 2,
    ) == ["too early"]

    assert burn.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["unspendable"],
        defaults["burn_quantity"],
        config.BURN_END + 1,
    ) == ["too late"]

    assert burn.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["addresses"][1],
        1.1 * defaults["burn_quantity"],
        config.BURN_START - 2,
    ) == ["wrong destination address", "quantity must be in satoshis"]

    assert burn.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["addresses"][1],
        defaults["burn_quantity"],
        config.BURN_START - 2,
    ) == ["wrong destination address", "too early"]

    assert (
        burn.validate(
            ledger_db,
            defaults["p2ms_addresses"][0],
            defaults["unspendable"],
            defaults["burn_quantity"],
            config.BURN_START,
        )
        == []
    )

    assert (
        burn.validate(
            ledger_db,
            defaults["p2sh_addresses"][0],
            defaults["unspendable"],
            defaults["burn_quantity"],
            config.BURN_START,
        )
        == []
    )


def test_compose(ledger_db, defaults):
    assert burn.compose(ledger_db, defaults["addresses"][1], defaults["burn_quantity"]) == (
        defaults["addresses"][1],
        [(defaults["unspendable"], 62000000)],
        None,
    )

    with pytest.raises(exceptions.ComposeError, match="1 BTC may be burned per address"):
        burn.compose(ledger_db, defaults["addresses"][0], defaults["burn_quantity"])

    assert burn.compose(
        ledger_db, defaults["p2ms_addresses"][0], int(defaults["quantity"] / 2)
    ) == (defaults["p2ms_addresses"][0], [(defaults["unspendable"], 50000000)], None)

    assert burn.compose(
        ledger_db, defaults["p2sh_addresses"][0], int(defaults["burn_quantity"] / 2)
    ) == (defaults["p2sh_addresses"][0], [(defaults["unspendable"], 31000000)], None)


def test_parse_burn_legacy_address(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(
        ledger_db,
        defaults["addresses"][1],
        defaults["unspendable"],
        btc_amount=defaults["burn_quantity"],
    )
    message = b""
    burn.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "burns",
                "values": {
                    "block_index": tx["block_index"],
                    "burned": 62000000,
                    "earned": 92999768120,
                    "source": defaults["addresses"][1],
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
                    "calling_function": "burn",
                    "event": tx["tx_hash"],
                    "quantity": 92999768120,
                },
            },
        ],
    )


def test_parse_burn_multisig_address(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["p2ms_addresses"][0], defaults["unspendable"], btc_amount=50000000
    )
    message = b""
    burn.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "burns",
                "values": {
                    "block_index": tx["block_index"],
                    "burned": 50000000,
                    "earned": 74999812333,
                    "source": defaults["p2ms_addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["p2ms_addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "burn",
                    "event": tx["tx_hash"],
                    "quantity": 74999812333,
                },
            },
        ],
    )
