import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.messages import sweep
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_validate(ledger_db, defaults, monkeypatch):
    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 1, None, config.BURN_START
    ) == ([], 800000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 2, None, config.BURN_START
    ) == ([], 800000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 3, None, config.BURN_START
    ) == ([], 800000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 1, "test", config.BURN_START
    ) == ([], 800000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 1, b"test", config.BURN_START
    ) == ([], 800000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 0, None, config.BURN_START
    ) == (["must specify which kind of transfer in flags"], 800000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][6], 1, None, config.BURN_START
    ) == (["destination cannot be the same as source"], 800000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 8, None, config.BURN_START
    ) == (["invalid flags 8"], 800000)

    assert sweep.validate(
        ledger_db,
        defaults["addresses"][6],
        defaults["addresses"][5],
        1,
        "012345678900123456789001234567890012345",
        config.BURN_START,
    ) == (["memo too long"], 800000)

    monkeypatch.setattr(
        "counterpartycore.lib.messages.sweep.get_total_fee",
        lambda db, source, block_index: 1000000000000,
    )

    assert sweep.validate(
        ledger_db, defaults["addresses"][8], defaults["addresses"][5], 1, None, config.BURN_START
    ) == (
        ["insufficient XCP balance for sweep. Need 10000.0 XCP for antispam fee"],
        1000000000000,
    )

    assert sweep.validate(
        ledger_db, defaults["addresses"][8], defaults["addresses"][5], 1, None, config.BURN_START
    ) == (
        ["insufficient XCP balance for sweep. Need 10000.0 XCP for antispam fee"],
        1000000000000,
    )


def test_compose(ledger_db, defaults, monkeypatch):
    with ProtocolChangesDisabled("taproot_support"):
        assert sweep.compose(
            ledger_db, defaults["addresses"][6], defaults["addresses"][5], 1, None, False
        ) == (
            defaults["addresses"][6],
            [],
            b"\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01",
        )

        assert sweep.compose(
            ledger_db, defaults["addresses"][6], defaults["addresses"][5], 2, None
        ) == (
            "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            [],
            b"\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x02",
        )

        assert sweep.compose(
            ledger_db, defaults["addresses"][6], defaults["addresses"][5], 3, None
        ) == (
            "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            [],
            b"\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x03",
        )

        assert sweep.compose(
            ledger_db, defaults["addresses"][6], defaults["addresses"][5], 3, "test"
        ) == (
            "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            [],
            b"\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x03test",
        )

        assert sweep.compose(
            ledger_db, defaults["addresses"][6], defaults["addresses"][5], 7, "cafebabe"
        ) == (
            "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            [],
            b"\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x07\xca\xfe\xba\xbe",
        )

        monkeypatch.setattr(
            "counterpartycore.lib.messages.sweep.get_total_fee",
            lambda db, source, block_index: 1000000000000,
        )

        with pytest.raises(
            exceptions.ComposeError,
            match="insufficient XCP balance for sweep. Need 10000.0 XCP for antispam fee",
        ):
            (sweep.compose(ledger_db, defaults["addresses"][8], defaults["addresses"][5], 1, None),)


def test_compose_2(ledger_db, defaults):
    assert sweep.compose(
        ledger_db, defaults["addresses"][0], defaults["addresses"][1], 1, None, False
    ) == (
        defaults["addresses"][0],
        [],
        b"\x04\x15\x01\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xec\x01\x01\x00",
    )

    assert sweep.compose(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 7, "cafebabe"
    ) == (
        "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
        [],
        b"\x04\x15\x01\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01\x07\x04\xca\xfe\xba\xbe",
    )

    assert sweep.compose(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 3, "test"
    ) == (
        "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
        [],
        b"\x04\x15\x01\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01\x03\x04test",
    )


def test_new_unpack(defaults):
    assert sweep.unpack(
        b"\x15\x01\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xec\x01\x01\x00"
    ) == {"destination": defaults["addresses"][1], "flags": 1, "memo": None}

    assert sweep.unpack(
        b"\x15\x01\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01\x07\x04\xca\xfe\xba\xbe"
    ) == {"destination": defaults["addresses"][5], "flags": 7, "memo": b"\xca\xfe\xba\xbe"}

    assert sweep.unpack(
        b"\x15\x01\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01\x03\x04test"
    ) == {"destination": defaults["addresses"][5], "flags": 3, "memo": "test"}

    with pytest.raises(exceptions.UnpackError, match="could not unpack"):
        sweep.new_unpack(
            b"\x01\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01\x03"
        )


def test_unpack(defaults):
    with ProtocolChangesDisabled("taproot_support"):
        assert sweep.unpack(
            b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01"
        ) == {"destination": defaults["addresses"][5], "flags": 1, "memo": None}

        assert sweep.unpack(
            b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x02"
        ) == {"destination": defaults["addresses"][5], "flags": 2, "memo": None}

        assert sweep.unpack(
            b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x03test"
        ) == {"destination": defaults["addresses"][5], "flags": 3, "memo": "test"}

        assert sweep.unpack(
            b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x07\xca\xfe\xba\xbe"
        ) == {"destination": defaults["addresses"][5], "flags": 7, "memo": b"\xca\xfe\xba\xbe"}


def test_parse_flag_1(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    with ProtocolChangesDisabled("taproot_support"):
        tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
        message = b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01"
        sweep.parse(ledger_db, tx, message)

        test_helpers.check_records(
            ledger_db,
            [
                {
                    "table": "sweeps",
                    "values": {
                        "block_index": tx["block_index"],
                        "destination": defaults["addresses"][5],
                        "source": defaults["addresses"][0],
                        "status": "valid",
                        "flags": 1,
                        "tx_hash": tx["tx_hash"],
                        "tx_index": tx["tx_index"],
                    },
                },
                {
                    "table": "credits",
                    "values": {
                        "address": defaults["addresses"][5],
                        "asset": "XCP",
                        "block_index": current_block_index,
                        "calling_function": "sweep",
                        "event": tx["tx_hash"],
                        "quantity": 91693599693,
                    },
                },
                {
                    "table": "debits",
                    "values": {
                        "action": "sweep",
                        "address": defaults["addresses"][0],
                        "asset": "XCP",
                        "block_index": current_block_index,
                        "event": tx["tx_hash"],
                        "quantity": 91693599693,
                    },
                },
                {
                    "table": "credits",
                    "values": {
                        "address": defaults["addresses"][5],
                        "asset": "LOCKED",
                        "block_index": current_block_index,
                        "calling_function": "sweep",
                        "event": tx["tx_hash"],
                        "quantity": 1000,
                    },
                },
                {
                    "table": "debits",
                    "values": {
                        "action": "sweep",
                        "address": defaults["addresses"][0],
                        "asset": "LOCKED",
                        "block_index": current_block_index,
                        "event": tx["tx_hash"],
                        "quantity": 1000,
                    },
                },
            ],
        )


def test_parse_flag_2(ledger_db, blockchain_mock, defaults, test_helpers):
    with ProtocolChangesDisabled("taproot_support"):
        tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][6])
        message = b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x02"
        sweep.parse(ledger_db, tx, message)

        test_helpers.check_records(
            ledger_db,
            [
                {
                    "table": "sweeps",
                    "values": {
                        "block_index": tx["block_index"],
                        "destination": defaults["addresses"][5],
                        "source": defaults["addresses"][6],
                        "status": "valid",
                        "flags": 2,
                        "tx_hash": tx["tx_hash"],
                        "tx_index": tx["tx_index"],
                    },
                },
                {
                    "table": "issuances",
                    "values": {
                        "quantity": 0,
                        "asset_longname": None,
                        "issuer": defaults["addresses"][5],
                        "status": "valid",
                        "locked": 0,
                        "asset": "LOCKEDPREV",
                        "fee_paid": 0,
                        "callable": 0,
                        "call_date": 0,
                        "call_price": 0.0,
                        "tx_hash": tx["tx_hash"],
                        "description": "changed",
                        "divisible": 1,
                        "source": defaults["addresses"][6],
                        "block_index": tx["block_index"],
                        "tx_index": tx["tx_index"],
                        "transfer": True,
                    },
                },
            ],
        )
