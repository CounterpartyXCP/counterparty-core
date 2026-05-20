from fractions import Fraction

import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.messages import burn


def test_validate(ledger_db, defaults):
    assert (
        burn.validate(
            defaults["unspendable"],
            defaults["burn_quantity"],
            config.BURN_START,
        )
        == []
    )

    assert burn.validate(
        defaults["unspendable"],
        1.1 * defaults["burn_quantity"],
        config.BURN_START,
    ) == ["quantity must be in satoshis"]

    assert burn.validate(
        defaults["addresses"][1],
        defaults["burn_quantity"],
        config.BURN_START,
    ) == ["wrong destination address"]

    assert burn.validate(
        defaults["unspendable"],
        -1 * defaults["burn_quantity"],
        config.BURN_START,
    ) == ["negative quantity"]

    assert burn.validate(
        defaults["unspendable"],
        defaults["burn_quantity"],
        config.BURN_START - 2,
    ) == ["too early"]

    assert burn.validate(
        defaults["unspendable"],
        defaults["burn_quantity"],
        config.BURN_END + 1,
    ) == ["too late"]

    assert burn.validate(
        defaults["addresses"][1],
        1.1 * defaults["burn_quantity"],
        config.BURN_START - 2,
    ) == ["wrong destination address", "quantity must be in satoshis"]

    assert burn.validate(
        defaults["addresses"][1],
        defaults["burn_quantity"],
        config.BURN_START - 2,
    ) == ["wrong destination address", "too early"]

    assert (
        burn.validate(
            defaults["unspendable"],
            defaults["burn_quantity"],
            config.BURN_START,
        )
        == []
    )

    assert (
        burn.validate(
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
    burn.parse(ledger_db, tx)

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
    burn.parse(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "burns",
                "values": {
                    "block_index": tx["block_index"],
                    "burned": 50000000,
                    "earned": 74999811000,
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
                    "quantity": 74999811000,
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


def test_calculate_earned_quantity_total_time_non_positive(monkeypatch):
    burn_amount = 25000000
    monkeypatch.setattr(config, "TESTNET3", False, raising=False)
    monkeypatch.setattr(config, "BURN_START", 300, raising=False)
    monkeypatch.setattr(config, "BURN_END", 300, raising=False)

    assert burn.calculate_earned_quantity(burn_amount, 300) == round(burn_amount * 1000)


def test_calculate_earned_quantity_mainnet_within_window(monkeypatch):
    burn_amount = 40000000
    monkeypatch.setattr(config, "TESTNET3", False, raising=False)
    monkeypatch.setattr(config, "BURN_START", 100, raising=False)
    monkeypatch.setattr(config, "BURN_END", 200, raising=False)

    block_index = 150
    total_time = config.BURN_END - config.BURN_START
    partial_time = config.BURN_END - block_index
    expected_multiplier = 1000 + 500 * Fraction(partial_time, total_time)

    assert burn.calculate_earned_quantity(burn_amount, block_index) == round(
        burn_amount * expected_multiplier
    )


def test_calculate_earned_quantity_mainnet_after_window(monkeypatch):
    burn_amount = 40000000
    monkeypatch.setattr(config, "TESTNET3", False, raising=False)
    monkeypatch.setattr(config, "BURN_START", 100, raising=False)
    monkeypatch.setattr(config, "BURN_END", 200, raising=False)

    block_index = 205

    assert burn.calculate_earned_quantity(burn_amount, block_index) == round(burn_amount * 1000)


def test_calculate_earned_quantity_testnet3_before_old_end(monkeypatch):
    burn_amount = 50000000
    monkeypatch.setattr(config, "TESTNET3", True, raising=False)
    monkeypatch.setattr(config, "BURN_START", 100, raising=False)
    monkeypatch.setattr(config, "BURN_END", 250, raising=False)
    monkeypatch.setattr(config, "OLD_BURN_END_TESTNET3", 180, raising=False)

    block_index = 150
    total_time = config.OLD_BURN_END_TESTNET3 - config.BURN_START
    partial_time = config.OLD_BURN_END_TESTNET3 - block_index
    expected_multiplier = 1000 + 500 * Fraction(partial_time, total_time)

    assert burn.calculate_earned_quantity(burn_amount, block_index) == round(
        burn_amount * expected_multiplier
    )


def test_calculate_earned_quantity_testnet3_after_old_end(monkeypatch):
    burn_amount = 50000000
    monkeypatch.setattr(config, "TESTNET3", True, raising=False)
    monkeypatch.setattr(config, "BURN_START", config.BURN_START_TESTNET3, raising=False)
    monkeypatch.setattr(config, "BURN_END", config.BURN_END_TESTNET3, raising=False)

    block_index = config.OLD_BURN_END_TESTNET3 + 10

    assert burn.calculate_earned_quantity(burn_amount, block_index) == round(burn_amount * 1000)
