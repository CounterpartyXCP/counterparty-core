from counterpartycore.lib import config
from counterpartycore.lib.messages import broadcast
from counterpartycore.pytest.mocks.counterpartydbs import ProtocolChangesDisabled


def test_validate(ledger_db, defaults):
    assert (
        broadcast.validate(
            ledger_db,
            defaults["addresses"][0],
            1588000000,
            1,
            defaults["fee_multiplier"],
            "Unit Test",
            defaults["default_block_index"],
        )
        == []
    )

    assert (
        broadcast.validate(
            ledger_db,
            defaults["p2sh_addresses"][0],
            1588000000,
            1,
            defaults["fee_multiplier"],
            "Unit Test",
            defaults["default_block_index"],
        )
        == []
    )

    assert broadcast.validate(
        ledger_db,
        defaults["addresses"][2],
        1588000000,
        1,
        defaults["fee_multiplier"],
        "Unit Test",
        defaults["default_block_index"],
    ) == ["locked feed"]

    assert broadcast.validate(
        ledger_db,
        defaults["addresses"][0],
        1588000000,
        1,
        4294967296,
        "Unit Test",
        defaults["default_block_index"],
    ) == ["fee fraction greater than or equal to 1"]

    assert broadcast.validate(
        ledger_db,
        defaults["addresses"][0],
        -1388000000,
        1,
        defaults["fee_multiplier"],
        "Unit Test",
        defaults["default_block_index"],
    ) == ["negative timestamp", "feed timestamps not monotonically increasing"]

    assert broadcast.validate(
        ledger_db,
        None,
        1588000000,
        1,
        defaults["fee_multiplier"],
        "Unit Test",
        defaults["default_block_index"],
    ) == ["null source address"]

    assert broadcast.validate(
        ledger_db,
        defaults["addresses"][5],
        1588000000,
        1,
        defaults["fee_multiplier"],
        "OPTIONS %i" % (config.ADDRESS_OPTION_MAX_VALUE + 1),
        defaults["default_block_index"],
    ) == ["options out of range"]

    assert broadcast.validate(
        ledger_db,
        defaults["addresses"][5],
        1588000000,
        1,
        defaults["fee_multiplier"],
        "OPTIONS -1",
        defaults["default_block_index"],
    ) == ["options integer overflow"]

    assert broadcast.validate(
        ledger_db,
        defaults["addresses"][5],
        1588000000,
        1,
        defaults["fee_multiplier"],
        "OPTIONS XCP",
        defaults["default_block_index"],
    ) == ["options not an integer"]


def test_compose(ledger_db, defaults):
    with ProtocolChangesDisabled(["broadcast_pack_text", "short_tx_type_id"]):
        assert broadcast.compose(
            ledger_db,
            defaults["addresses"][0],
            1588000000,
            1,
            defaults["fee_multiplier"],
            "Unit Test",
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00LK@\tUnit Test",
        )

        assert broadcast.compose(
            ledger_db,
            defaults["p2sh_addresses"][0],
            1588000000,
            1,
            defaults["fee_multiplier"],
            "Unit Test",
        ) == (
            defaults["p2sh_addresses"][0],
            [],
            b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00LK@\tUnit Test",
        )

        assert broadcast.compose(
            ledger_db,
            defaults["addresses"][0],
            1588000000,
            1,
            0,
            "Exactly 51 characters test test test test test tes.",
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x003Exactly 51 characters test test test test test tes.",
        )

        assert broadcast.compose(
            ledger_db,
            defaults["addresses"][0],
            1588000000,
            1,
            0,
            "Exactly 52 characters test test test test test test.",
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x004Exactly 52 characters test test test test test test.",
        )

        assert broadcast.compose(
            ledger_db,
            defaults["addresses"][0],
            1588000000,
            1,
            0,
            "Exactly 53 characters test test test test test testt.",
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00Exactly 53 characters test test test test test testt.",
        )

        assert broadcast.compose(
            ledger_db, defaults["addresses"][0], 1588000000, 1, 0, "This is an e with an: è."
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x18This is an e with an: \xc3\xa8",
        )

        assert broadcast.compose(
            ledger_db, defaults["addresses"][0], 1388000100, 50000000, 0, "LOCK"
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1eR\xbb3dA\x87\xd7\x84\x00\x00\x00\x00\x00\x00\x00\x00\x04LOCK",
        )

        assert broadcast.compose(
            ledger_db,
            defaults["addresses"][0],
            1588000000,
            1,
            defaults["fee_multiplier"],
            "Unit Test",
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00LK@\tUnit Test",
        )

    with ProtocolChangesDisabled(["short_tx_type_id"]):
        assert broadcast.compose(
            ledger_db,
            defaults["addresses"][0],
            1588000000,
            1,
            0,
            "Exactly 51 characters test test test test test tes.",
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x003Exactly 51 characters test test test test test tes.",
        )

        assert broadcast.compose(
            ledger_db,
            defaults["addresses"][0],
            1588000000,
            1,
            0,
            "Exactly 52 characters test test test test test test.",
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x004Exactly 52 characters test test test test test test.",
        )

        assert broadcast.compose(
            ledger_db,
            defaults["addresses"][0],
            1588000000,
            1,
            0,
            "Exactly 53 characters test test test test test testt.",
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x005Exactly 53 characters test test test test test testt.",
        )

        assert broadcast.compose(
            ledger_db, defaults["addresses"][0], 1588000000, 1, 0, "This is an e with an: è."
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x19This is an e with an: \xc3\xa8.",
        )

        assert broadcast.compose(
            ledger_db, defaults["addresses"][0], 1388000100, 50000000, 0, "LOCK"
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1eR\xbb3dA\x87\xd7\x84\x00\x00\x00\x00\x00\x00\x00\x00\x04LOCK",
        )

        assert broadcast.compose(
            ledger_db,
            defaults["addresses"][0],
            1588000000,
            1,
            defaults["fee_multiplier"],
            "Over 80 characters test test test test test test test test test test test test test test test test test test",
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00LK@lOver 80 characters test test test test test test test test test test test test test test test test test test",
        )

        assert broadcast.compose(
            ledger_db, defaults["addresses"][0], 1388000100, 50000000, 0, "OPTIONS 1"
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1eR\xbb3dA\x87\xd7\x84\x00\x00\x00\x00\x00\x00\x00\x00\tOPTIONS 1",
        )

        assert broadcast.compose(
            ledger_db, defaults["addresses"][0], 1388000100, 50000000, 0, "OPTIONS 0"
        ) == (
            defaults["addresses"][0],
            [],
            b"\x00\x00\x00\x1eR\xbb3dA\x87\xd7\x84\x00\x00\x00\x00\x00\x00\x00\x00\tOPTIONS 0",
        )


def test_parse_old_packing_short_text(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1])
    message = b"R\xbb3dA\x87\xd7\x84\x00\x00\x00\x00\x00\x00\x00\x00\x06BARFOO"

    with ProtocolChangesDisabled(["broadcast_pack_text", "short_tx_type_id"]):
        broadcast.parse(ledger_db, tx, message)
        test_helpers.check_records(
            ledger_db,
            [
                {
                    "table": "broadcasts",
                    "values": {
                        "block_index": tx["block_index"],
                        "fee_fraction_int": 0,
                        "locked": 0,
                        "source": defaults["addresses"][1],
                        "status": "valid",
                        "text": "BARFOO",
                        "timestamp": 1388000100,
                        "tx_hash": tx["tx_hash"],
                        "tx_index": tx["tx_index"],
                        "value": 50000000.0,
                    },
                },
            ],
        )


def test_parse_old_packing_51_chars(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1])
    message = b"^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x003Exactly 51 characters test test test test test tes."

    with ProtocolChangesDisabled(["broadcast_pack_text", "short_tx_type_id"]):
        broadcast.parse(ledger_db, tx, message)
        test_helpers.check_records(
            ledger_db,
            [
                {
                    "table": "broadcasts",
                    "values": {
                        "block_index": tx["block_index"],
                        "fee_fraction_int": 0,
                        "locked": 0,
                        "source": defaults["addresses"][1],
                        "status": "valid",
                        "text": "Exactly 51 characters test test test test test tes.",
                        "timestamp": 1588000000,
                        "tx_hash": tx["tx_hash"],
                        "tx_index": tx["tx_index"],
                        "value": 1.0,
                    },
                },
            ],
        )


def test_parse_old_packing_52_chars(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1])
    message = b"^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x004Exactly 52 characters test test test test test test."

    with ProtocolChangesDisabled(["broadcast_pack_text", "short_tx_type_id"]):
        broadcast.parse(ledger_db, tx, message)
        test_helpers.check_records(
            ledger_db,
            [
                {
                    "table": "broadcasts",
                    "values": {
                        "block_index": tx["block_index"],
                        "fee_fraction_int": 0,
                        "locked": 0,
                        "source": defaults["addresses"][1],
                        "status": "valid",
                        "text": "4Exactly 52 characters test test test test test test.",
                        "timestamp": 1588000000,
                        "tx_hash": tx["tx_hash"],
                        "tx_index": tx["tx_index"],
                        "value": 1.0,
                    },
                },
            ],
        )


def test_parse_old_packing_53_chars(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1])
    message = b"^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00Exactly 53 characters test test test test test testt."

    with ProtocolChangesDisabled(["broadcast_pack_text", "short_tx_type_id"]):
        broadcast.parse(ledger_db, tx, message)
        test_helpers.check_records(
            ledger_db,
            [
                {
                    "table": "broadcasts",
                    "values": {
                        "block_index": tx["block_index"],
                        "fee_fraction_int": 0,
                        "locked": 0,
                        "source": defaults["addresses"][1],
                        "status": "valid",
                        "text": "Exactly 53 characters test test test test test testt.",
                        "timestamp": 1588000000,
                        "tx_hash": tx["tx_hash"],
                        "tx_index": tx["tx_index"],
                        "value": 1.0,
                    },
                },
            ],
        )


def test_parse_old_packing_utf8_chars(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1])
    message = b"^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x18This is an e with an: \xc3\xa8."

    with ProtocolChangesDisabled(["broadcast_pack_text", "short_tx_type_id"]):
        broadcast.parse(ledger_db, tx, message)
        test_helpers.check_records(
            ledger_db,
            [
                {
                    "table": "broadcasts",
                    "values": {
                        "block_index": tx["block_index"],
                        "fee_fraction_int": 0,
                        "locked": 0,
                        "source": defaults["addresses"][1],
                        "status": "valid",
                        "text": "This is an e with an: è",
                        "timestamp": 1588000000,
                        "tx_hash": tx["tx_hash"],
                        "tx_index": tx["tx_index"],
                        "value": 1.0,
                    },
                },
            ],
        )


def test_parse_old_packing_for_bet(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"R\xbb4,\xc0\x00\x00\x00\x00\x00\x00\x00\x00LK@\tUnit Test"

    with ProtocolChangesDisabled(["broadcast_pack_text", "short_tx_type_id"]):
        broadcast.parse(ledger_db, tx, message)

        test_helpers.check_records(
            ledger_db,
            [
                {
                    "table": "broadcasts",
                    "values": {
                        "block_index": tx["block_index"],
                        "fee_fraction_int": 5000000,
                        "locked": 0,
                        "source": defaults["addresses"][0],
                        "status": "valid",
                        "text": "Unit Test",
                        "timestamp": 1388000300,
                        "tx_hash": tx["tx_hash"],
                        "tx_index": tx["tx_index"],
                        "value": -2.0,
                    },
                },
            ],
        )
