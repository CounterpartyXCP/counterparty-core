from counterpartycore.lib import config
from counterpartycore.lib.messages import sweep


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


def test_compose(ledger_db, defaults):
    assert sweep.compose(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 1, None, False
    ) == (
        defaults["addresses"][6],
        [],
        b"\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01",
    )
