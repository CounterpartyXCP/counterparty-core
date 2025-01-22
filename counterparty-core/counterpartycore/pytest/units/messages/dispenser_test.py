from counterpartycore.lib import config
from counterpartycore.lib.messages import dispenser


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
            "address doesn't have enough balance of XCP (91699999693 < 9223372036854775808)",
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
