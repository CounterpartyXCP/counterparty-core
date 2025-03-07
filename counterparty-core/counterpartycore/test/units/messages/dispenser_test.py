import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.messages import dispenser
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_validate(ledger_db, defaults):
    assert dispenser.validate(
        ledger_db, defaults["addresses"][0], "XCP", 100, 100, 100, 0, None, config.BURN_START, None
    ) == (1, None)

    assert dispenser.validate(
        ledger_db, defaults["addresses"][0], "XCP", 200, 100, 100, 0, None, config.BURN_START, None
    ) == (None, ["escrow_quantity must be greater or equal than give_quantity"])

    assert dispenser.validate(
        ledger_db, defaults["addresses"][0], "BTC", 100, 100, 100, 0, None, config.BURN_START, None
    ) == (None, ["cannot dispense BTC"])

    assert dispenser.validate(
        ledger_db, defaults["addresses"][0], "XCP", 100, 100, 100, 5, None, config.BURN_START, None
    ) == (None, ["invalid status 5"])

    assert dispenser.validate(
        ledger_db,
        defaults["addresses"][0],
        "PARENT",
        100,
        1000000000,
        100,
        0,
        None,
        config.BURN_START,
        None,
    ) == (
        None,
        ["address doesn't have enough balance of PARENT (100000000 < 1000000000)"],
    )

    assert dispenser.validate(
        ledger_db, defaults["addresses"][5], "XCP", 100, 100, 120, 0, None, config.BURN_START, None
    ) == (
        None,
        ["address has a dispenser already opened for asset XCP with a different mainchainrate"],
    )

    assert dispenser.validate(
        ledger_db, defaults["addresses"][5], "XCP", 120, 120, 100, 0, None, config.BURN_START, None
    ) == (
        None,
        ["address has a dispenser already opened for asset XCP with a different give_quantity"],
    )

    assert dispenser.validate(
        ledger_db, defaults["addresses"][0], "PARENT", 0, 0, 0, 10, None, config.BURN_START, None
    ) == (None, ["address doesn't have an open dispenser for asset PARENT"])

    assert dispenser.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        config.MAX_INT + 1,
        100,
        100,
        0,
        None,
        config.BURN_START,
        None,
    ) == (
        None,
        [
            "escrow_quantity must be greater or equal than give_quantity",
            "integer overflow",
        ],
    )

    assert dispenser.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        100,
        config.MAX_INT + 1,
        100,
        0,
        None,
        config.BURN_START,
        None,
    ) == (
        None,
        [
            "address doesn't have enough balance of XCP (91599999693 < 9223372036854775808)",
            "integer overflow",
        ],
    )

    assert dispenser.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        100,
        100,
        config.MAX_INT + 1,
        0,
        None,
        config.BURN_START,
        None,
    ) == (None, ["integer overflow"])

    assert dispenser.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        100,
        100,
        100,
        0,
        defaults["addresses"][5],
        config.BURN_START,
        None,
    ) == (None, ["dispenser must be created by source"])


def test_compose(ledger_db, defaults):
    assert dispenser.compose(ledger_db, defaults["addresses"][0], config.XCP, 100, 100, 100, 0) == (
        defaults["addresses"][0],
        [],
        b"\x0c\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00\x00d\x00",
    )

    assert dispenser.compose(ledger_db, defaults["addresses"][5], config.XCP, 0, 0, 0, 10) == (
        defaults["addresses"][5],
        [],
        b"\x0c\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\n",
    )

    assert dispenser.compose(
        ledger_db, defaults["addresses"][0], "PARENT", 100, 10000, 2345, 0
    ) == (
        defaults["addresses"][0],
        [],
        b"\x0c\x00\x00\x00\x00\n\xa4\t}\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00'\x10\x00\x00\x00\x00\x00\x00\t)\x00",
    )

    with pytest.raises(
        exceptions.ComposeError,
        match="['escrow_quantity must be greater or equal than give_quantity', 'integer overflow']",
    ):
        dispenser.compose(
            ledger_db,
            defaults["addresses"][0],
            config.XCP,
            config.MAX_INT + 1,
            config.MAX_INT + 2,
            100,
            0,
            None,
            None,
            False,
        )

    with pytest.raises(exceptions.ComposeError, match="dispenser must be created by source"):
        dispenser.compose(
            ledger_db,
            defaults["addresses"][0],
            "PARENT",
            100,
            10000,
            2345,
            0,
            defaults["addresses"][5],
            None,
            False,
        )

    assert dispenser.compose(
        ledger_db,
        defaults["addresses"][0],
        "PARENT",
        100,
        1000000000,
        0,
        0,
        None,
        None,
        True,
    ) == (
        defaults["addresses"][0],
        [],
        b"\x0c\x00\x00\x00\x00\n\xa4\t}\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00;\x9a\xca\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    )


def test_compose_with_oracle(ledger_db, defaults, monkeypatch):
    monkeypatch.setattr(dispenser, "calculate_oracle_fee", lambda *args: 0)

    assert dispenser.compose(
        ledger_db,
        defaults["addresses"][0],
        "PARENT",
        100,
        1000000000,
        0,
        0,
        None,
        defaults["addresses"][1],
        True,
    ) == (
        defaults["addresses"][0],
        [],
        b"\x0c\x00\x00\x00\x00\n\xa4\t}\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00;\x9a\xca\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00o\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xec",
    )

    with pytest.raises(exceptions.ComposeError, match="Oracle address not supported by dispenser"):
        dispenser.compose(
            ledger_db,
            defaults["addresses"][0],
            "PARENT",
            100,
            1000000000,
            0,
            0,
            None,
            defaults["p2tr_addresses"][1],
            True,
        )


def test_parse_open_dispenser(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00\x00d\x00"
    dispenser.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "dispensers",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "asset": "XCP",
                    "give_quantity": 100,
                    "escrow_quantity": 100,
                    "satoshirate": 100,
                    "status": 0,
                    "give_remaining": 100,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "open dispenser",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 100,
                },
            },
        ],
    )


def test_parse_close_dispenser(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    open_dispenser = ledger_db.execute(
        """
            SELECT tx_hash, source, tx_index FROM (
                SELECT tx_index, tx_hash, MAX(rowid), status, source 
                FROM dispensers
                GROUP BY tx_hash
            ) WHERE status = 0"""
    ).fetchall()
    open_dispenser = open_dispenser[0]

    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][5])
    source, destination, data = dispenser.compose(
        ledger_db, open_dispenser["source"], "XCP", 0, 0, 0, 10
    )
    dispenser.parse(ledger_db, tx, data[1:])

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "dispensers",
                "values": {
                    "last_status_tx_hash": tx["tx_hash"],
                    "block_index": current_block_index,
                    "last_status_tx_source": defaults["addresses"][5],
                    "source": defaults["addresses"][5],
                    "asset": "XCP",
                    "status": 11,
                },
            },
        ],
    )


def test_parse_integer_overflow(ledger_db, blockchain_mock, defaults, caplog, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][5])
    message = b"\x00\x00\x00\x00\x00\x00\x00\x01\x80\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00d\x00"

    error = "invalid: address doesn't have enough balance of XCP (92949974273 < 9223372036854775809); integer overflow"
    with test_helpers.capture_log(caplog, error):
        dispenser.parse(ledger_db, tx, message)


def test_parse_not_source_address(ledger_db, blockchain_mock, defaults, caplog, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][5])
    message = b"\x00\x00\x00\x00\n\xa4\t}\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00'\x10\x00\x00\x00\x00\x00\x00\t)\x00"

    error = "invalid: address doesn't have the asset PARENT"
    with test_helpers.capture_log(caplog, error):
        dispenser.parse(ledger_db, tx, message)


def test_parse_debit_error(ledger_db, blockchain_mock, defaults, caplog, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"\x00\x00\x00\x00\n\xa4\t}\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00;\x9a\xca\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

    error = f"Invalid dispenser transaction [{tx['tx_hash'][0:7]}] (invalid: insufficient funds)"
    with test_helpers.capture_log(caplog, error):
        with ProtocolChangesDisabled(["dispenser_parsing_validation"]):
            dispenser.parse(ledger_db, tx, message)


def test_is_dispensable(ledger_db, defaults):
    assert dispenser.is_dispensable(ledger_db, defaults["addresses"][5], 200) is True
    assert dispenser.is_dispensable(ledger_db, defaults["addresses"][0], 200) is False
