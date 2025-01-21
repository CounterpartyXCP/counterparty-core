from counterpartycore.lib.messages import bet


def test_validate(ledger_db, addresses, p2sh_addresses, defaults):
    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        0,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == ([], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        0,
        1488000100,
        2**32,
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == ([], 15120)

    assert bet.validate(
        ledger_db,
        addresses[0],
        addresses[1],
        3,
        1388001000,
        defaults["small"],
        defaults["small"],
        0.0,
        5040,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["feed doesn’t exist"], 5040)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        -1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["unknown bet type"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        2,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["leverage used with Equal or NotEqual"], 15120)

    assert bet.validate(
        ledger_db,
        p2sh_addresses[0],
        addresses[0],
        0,
        1488000100,
        2**32,
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == ([], 15120)

    assert bet.validate(
        ledger_db,
        addresses[0],
        p2sh_addresses[0],
        0,
        1488000100,
        2**32,
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == ([], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        3,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        5000,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (
        ["leverage used with Equal or NotEqual", "leverage level too low"],
        5000,
    )

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        312350,
    ) == (["CFDs temporarily disabled"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        1488000100,
        1.1 * defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["wager_quantity must be in satoshis"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        1488000100,
        defaults["small"],
        1.1 * defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["counterwager_quantity must be in satoshis"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        1.1 * defaults["expiration"],
        defaults["default_block_index"],
    ) == (["expiration must be expressed as an integer block delta"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        1488000100,
        -1 * defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["non‐positive wager"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        1488000100,
        defaults["small"],
        -1 * defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["non‐positive counterwager"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[2],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["feed is locked"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        -1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["deadline in that feed’s past", "negative deadline"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        -1 * defaults["expiration"],
        defaults["default_block_index"],
    ) == (["negative expiration"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        1.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["CFDs have no target value"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        2,
        1488000100,
        defaults["small"],
        defaults["small"],
        -1.0,
        5040,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["negative target value"], 5040)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        8095,
        defaults["default_block_index"],
    ) == (["expiration overflow"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        1488000100,
        2**63,
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["integer overflow"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        1488000100,
        defaults["small"],
        2**63,
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["integer overflow"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        2**63,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["integer overflow", "unknown bet type"], 15120)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        2**63,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["integer overflow"], 2**63)

    assert bet.validate(
        ledger_db,
        addresses[1],
        addresses[0],
        1,
        2**63,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        defaults["default_block_index"],
    ) == (["integer overflow"], 15120)
