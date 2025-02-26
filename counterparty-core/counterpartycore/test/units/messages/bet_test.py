import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.messages import bet


def test_validate(ledger_db, defaults, current_block_index):
    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        0,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == ([], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        0,
        1488000100,
        2**32,
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == ([], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][1],
        3,
        1388001000,
        defaults["small"],
        defaults["small"],
        0.0,
        5040,
        defaults["expiration"],
        current_block_index,
    ) == (["feed doesn't exist"], 5040)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        -1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["unknown bet type"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        2,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["leverage used with Equal or NotEqual"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        0,
        1488000100,
        2**32,
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == ([], 15120)

    assert bet.validate(
        ledger_db,
        defaults["p2sh_addresses"][0],
        0,
        1488000100,
        2**32,
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == ([], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        3,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        5000,
        defaults["expiration"],
        current_block_index,
    ) == (
        ["leverage used with Equal or NotEqual", "leverage level too low"],
        5000,
    )

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
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
        defaults["addresses"][0],
        1,
        1488000100,
        1.1 * defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["wager_quantity must be in satoshis"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        1,
        1488000100,
        defaults["small"],
        1.1 * defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["counterwager_quantity must be in satoshis"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        1.1 * defaults["expiration"],
        current_block_index,
    ) == (["expiration must be expressed as an integer block delta"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        1,
        1488000100,
        -1 * defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["non‐positive wager"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        1,
        1488000100,
        defaults["small"],
        -1 * defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["non‐positive counterwager"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][2],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["feed is locked"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        1,
        -1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["deadline in that feed's past", "negative deadline"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        -1 * defaults["expiration"],
        current_block_index,
    ) == (["negative expiration"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        1.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["CFDs have no target value"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        2,
        1488000100,
        defaults["small"],
        defaults["small"],
        -1.0,
        5040,
        defaults["expiration"],
        current_block_index,
    ) == (["negative target value"], 5040)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        8095,
        current_block_index,
    ) == (["expiration overflow"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        1,
        1488000100,
        2**63,
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["integer overflow"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        1,
        1488000100,
        defaults["small"],
        2**63,
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["integer overflow"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        2**63,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["integer overflow", "unknown bet type"], 15120)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        1,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        2**63,
        defaults["expiration"],
        current_block_index,
    ) == (["integer overflow"], 2**63)

    assert bet.validate(
        ledger_db,
        defaults["addresses"][0],
        1,
        2**63,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
        current_block_index,
    ) == (["integer overflow"], 15120)


def test_compose(ledger_db, defaults):
    with pytest.raises(exceptions.ComposeError, match="insufficient funds"):
        bet.compose(
            ledger_db,
            defaults["addresses"][1],
            defaults["addresses"][0],
            0,
            1488000100,
            2**32,
            defaults["small"],
            0.0,
            15120,
            defaults["expiration"],
        )

    assert bet.compose(
        ledger_db,
        defaults["addresses"][1],
        defaults["addresses"][0],
        0,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
    ) == (
        defaults["addresses"][1],
        [(defaults["addresses"][0], None)],
        b"(\x00\x00X\xb1\x14d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
    )

    assert bet.compose(
        ledger_db,
        defaults["p2sh_addresses"][0],
        defaults["addresses"][0],
        0,
        1488000100,
        defaults["small"],
        defaults["small"],
        0.0,
        15120,
        defaults["expiration"],
    ) == (
        defaults["p2sh_addresses"][0],
        [(defaults["addresses"][0], None)],
        b"(\x00\x00X\xb1\x14d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
    )


def test_parse_bet_type_0(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1], defaults["addresses"][0])
    message = b"\x00\x00X\xb1\x14d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n"
    bet.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "bets",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][1],
                    "feed_address": defaults["addresses"][0],
                    "bet_type": 0,
                    "deadline": 1488000100,
                    "wager_quantity": 50000000,
                    "wager_remaining": 50000000,
                    "counterwager_quantity": 50000000,
                    "counterwager_remaining": 50000000,
                    "target_value": 0.0,
                    "leverage": 15120,
                    "expiration": defaults["expiration"],
                    "expire_index": tx["block_index"] + defaults["expiration"],
                    "fee_fraction_int": 5000000.0,
                    "status": "open",
                },
            }
        ],
    )


def test_parse_invalid(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], defaults["addresses"][0])
    message = b"\x00\x00X\xb1\x14\x00\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x13\xb0\x00\x00\x00\n"
    bet.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "bets",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "feed_address": defaults["addresses"][0],
                    "bet_type": 0,
                    "deadline": 1488000000,
                    "wager_quantity": 100000000,
                    "wager_remaining": 100000000,
                    "counterwager_quantity": 0,
                    "counterwager_remaining": 0,
                    "target_value": 0.0,
                    "leverage": 5040,
                    "expiration": defaults["expiration"],
                    "expire_index": tx["block_index"] + defaults["expiration"],
                    "fee_fraction_int": 5000000.0,
                    "status": "invalid: non‐positive counterwager",
                },
            }
        ],
    )


def test_parse_p2sh_source(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], defaults["addresses"][0])
    message = b"\x00\x00X\xb1\x14d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n"
    bet.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "bets",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "feed_address": defaults["addresses"][0],
                    "bet_type": 0,
                    "deadline": 1488000100,
                    "wager_quantity": 50000000,
                    "wager_remaining": 50000000,
                    "counterwager_quantity": 50000000,
                    "counterwager_remaining": 50000000,
                    "target_value": 0.0,
                    "leverage": 15120,
                    "expiration": defaults["expiration"],
                    "expire_index": tx["block_index"] + defaults["expiration"],
                    "fee_fraction_int": 5000000.0,
                    "status": "open",
                },
            }
        ],
    )


def test_parse_bet_type_2(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], defaults["addresses"][0])
    message = b"\x00\x02R\xbb3\xc8\x00\x00\x00\x00\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x13\xb0\x00\x00\x03\xe8"
    bet.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "bets",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "feed_address": defaults["addresses"][0],
                    "bet_type": 2,
                    "deadline": 1388000200,
                    "wager_quantity": 10,
                    "wager_remaining": 10,
                    "counterwager_quantity": 10,
                    "counterwager_remaining": 10,
                    "target_value": 0.0,
                    "leverage": 5040,
                    "expiration": 1000,
                    "expire_index": tx["block_index"] + 1000,
                    "fee_fraction_int": 5000000.0,
                    "status": "open",
                },
            }
        ],
    )


def test_get_fee_fraction(ledger_db, defaults):
    assert bet.get_fee_fraction(ledger_db, defaults["addresses"][1]) == 0
    assert bet.get_fee_fraction(ledger_db, defaults["p2sh_addresses"][0]) == 0.05
    assert bet.get_fee_fraction(ledger_db, defaults["addresses"][0]) == 0.05
    assert bet.get_fee_fraction(ledger_db, defaults["addresses"][2]) == 0


def test_match(ledger_db):
    assert bet.match(ledger_db, {"tx_index": 99999999, "tx_hash": "fakehash"}) is None

    bets = ledger_db.execute("SELECT tx_index, tx_hash FROM bets WHERE status = 'open'").fetchall()
    for last_bet in bets:
        assert bet.match(ledger_db, last_bet) is None


def test_cancel_bet(ledger_db, test_helpers, current_block_index):
    bets = ledger_db.execute("SELECT * FROM bets WHERE status = 'open'").fetchall()
    for last_bet in bets:
        bet.cancel_bet(ledger_db, last_bet, "cancelled", last_bet["tx_index"])
        test_helpers.check_records(
            ledger_db,
            [
                {
                    "table": "credits",
                    "values": {
                        "address": last_bet["source"],
                        "asset": "XCP",
                        "quantity": last_bet["wager_remaining"],
                        "block_index": current_block_index,
                        "event": last_bet["tx_hash"],
                    },
                }
            ],
        )


def test_cancel_bet_match(ledger_db, test_helpers, current_block_index):
    bet_match = ledger_db.execute("SELECT * FROM bet_matches ORDER BY rowid LIMIT 1").fetchone()
    bet.cancel_bet_match(ledger_db, bet_match, "filled", bet_match["tx0_index"])

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "credits",
                "values": {
                    "address": bet_match["tx0_address"],
                    "asset": "XCP",
                    "quantity": bet_match["forward_quantity"],
                    "block_index": current_block_index,
                    "event": bet_match["id"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": bet_match["tx1_address"],
                    "asset": "XCP",
                    "quantity": bet_match["backward_quantity"],
                    "block_index": current_block_index,
                    "event": bet_match["id"],
                },
            },
        ],
    )
