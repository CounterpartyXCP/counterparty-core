from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled, run_scenario


def check_standard_scenario(
    empty_ledger_db, bitcoind_mock, defaults, address1, address2, ledger_hash
):
    # (initial, final) counts for each table
    check_counters = {
        "balances": (0, 41),
        "credits": (0, 23),
        "debits": (0, 18),
        "messages": (2, 188),
        "order_matches": (0, 2),
        "orders": (0, 7),
        "bet_matches": (0, 6),
        "bet_match_resolutions": (0, 3),
        "bet_expirations": (0, 1),
        "bets": (0, 13),
        "broadcasts": (0, 4),
        "btcpays": (0, 1),
        "burns": (0, 2),
        "dividends": (0, 2),
        "issuances": (0, 2),
        "sends": (0, 4),
        "assets": (2, 4),
    }
    # ensure tables are empty
    for table, check_count in check_counters.items():
        count = empty_ledger_db.execute(
            f"SELECT COUNT(*) AS count FROM {table}",  # noqa S608
        ).fetchone()["count"]
        initial, _final = check_count
        assert count == initial

    run_scenario(
        empty_ledger_db,
        bitcoind_mock,
        [
            [
                "burn",
                {
                    "source": address1,
                    "quantity": int(0.62 * defaults["quantity"]),
                    "overburn": False,
                },
                {"encoding": "multisig"},
            ],
            [
                "send",
                {
                    "source": address1,
                    "destination": address2,
                    "asset": "XCP",
                    "quantity": defaults["small"],
                },
                {"encoding": "multisig"},
            ],
            [
                "order",
                {
                    "source": address1,
                    "give_asset": "BTC",
                    "give_quantity": defaults["small"],
                    "get_asset": "XCP",
                    "get_quantity": defaults["small"] * 2,
                    "expiration": defaults["expiration"],
                    "fee_required": 0,
                },
                {"encoding": "multisig", "exact_fee": defaults["fee_provided"]},
            ],
            [
                "order",
                {
                    "source": address1,
                    "give_asset": "XCP",
                    "give_quantity": round(defaults["small"] * 2.1),
                    "get_asset": "BTC",
                    "get_quantity": defaults["small"],
                    "expiration": defaults["expiration"],
                    "fee_required": defaults["fee_required"],
                },
                {"encoding": "multisig"},
            ],
        ],
    )

    order_match_id = empty_ledger_db.execute(
        "SELECT id FROM order_matches ORDER BY rowid DESC"
    ).fetchone()["id"]

    run_scenario(
        empty_ledger_db,
        bitcoind_mock,
        [
            [
                "btcpay",
                {
                    "source": address1,
                    "order_match_id": order_match_id,
                },
                {"encoding": "multisig"},
            ],
            [
                "issuance",
                {
                    "source": address1,
                    "asset": "BBBB",
                    "quantity": defaults["quantity"] * 10,
                    "transfer_destination": None,
                    "divisible": True,
                    "lock": None,
                    "reset": None,
                    "description": "",
                },
                {"encoding": "multisig"},
            ],
            [
                "issuance",
                {
                    "source": address1,
                    "asset": "BBBC",
                    "quantity": round(defaults["quantity"] / 1000),
                    "transfer_destination": None,
                    "divisible": False,
                    "lock": None,
                    "reset": None,
                    "description": "foobar",
                },
                {"encoding": "multisig"},
            ],
            [
                "send",
                {
                    "source": address1,
                    "destination": address2,
                    "asset": "BBBB",
                    "quantity": round(defaults["quantity"] / 25),
                },
                {"encoding": "multisig"},
            ],
            [
                "send",
                {
                    "source": address1,
                    "destination": address2,
                    "asset": "BBBC",
                    "quantity": round(defaults["quantity"] / 190000),
                },
                {"encoding": "multisig"},
            ],
            [
                "dividend",
                {
                    "source": address1,
                    "quantity_per_unit": 600,
                    "asset": "BBBB",
                    "dividend_asset": "XCP",
                },
                {"encoding": "multisig"},
            ],
            [
                "dividend",
                {
                    "source": address1,
                    "quantity_per_unit": 800,
                    "asset": "BBBC",
                    "dividend_asset": "XCP",
                },
                {"encoding": "multisig"},
            ],
            [
                "broadcast",
                {
                    "source": address1,
                    "timestamp": 1388000000,
                    "value": 100,
                    "fee_fraction": 0.99999999,
                    "text": "Unit Test",
                },
                {"encoding": "multisig"},
            ],
            [
                "bet",
                {
                    "source": address1,
                    "feed_address": address1,
                    "bet_type": 0,
                    "deadline": 1388000100,
                    "wager_quantity": defaults["small"],
                    "counterwager_quantity": round(defaults["small"] / 2),
                    "target_value": 0.0,
                    "leverage": 15120,
                    "expiration": defaults["expiration"],
                },
                {"encoding": "multisig"},
            ],
            [
                "bet",
                {
                    "source": address1,
                    "feed_address": address1,
                    "bet_type": 1,
                    "deadline": 1388000100,
                    "wager_quantity": round(defaults["small"] / 2),
                    "counterwager_quantity": round(defaults["small"] * 0.83),
                    "target_value": 0.0,
                    "leverage": 15120,
                    "expiration": defaults["expiration"],
                },
                {"encoding": "multisig"},
            ],
            [
                "bet",
                {
                    "source": address1,
                    "feed_address": address1,
                    "bet_type": 0,
                    "deadline": 1388000100,
                    "wager_quantity": defaults["small"] * 3,
                    "counterwager_quantity": defaults["small"] * 7,
                    "target_value": 0.0,
                    "leverage": 5040,
                    "expiration": defaults["expiration"],
                },
                {"encoding": "multisig"},
            ],
            [
                "bet",
                {
                    "source": address1,
                    "feed_address": address1,
                    "bet_type": 1,
                    "deadline": 1388000100,
                    "wager_quantity": defaults["small"] * 7,
                    "counterwager_quantity": defaults["small"] * 3,
                    "target_value": 0.0,
                    "leverage": 5040,
                    "expiration": defaults["expiration"],
                },
                {"encoding": "multisig"},
            ],
            [
                "bet",
                {
                    "source": address1,
                    "feed_address": address1,
                    "bet_type": 2,
                    "deadline": 1388000200,
                    "wager_quantity": defaults["small"] * 15,
                    "counterwager_quantity": defaults["small"] * 13,
                    "target_value": 1,
                    "leverage": 5040,
                    "expiration": defaults["expiration"],
                },
                {"encoding": "multisig"},
            ],
            [
                "bet",
                {
                    "source": address1,
                    "feed_address": address1,
                    "bet_type": 3,
                    "deadline": 1388000200,
                    "wager_quantity": defaults["small"] * 13,
                    "counterwager_quantity": defaults["small"] * 15,
                    "target_value": 1,
                    "leverage": 5040,
                    "expiration": defaults["expiration"],
                },
                {"encoding": "multisig"},
            ],
            [
                "broadcast",
                {
                    "source": address1,
                    "timestamp": 1388000050,
                    "value": round(100 - (0.415 / 3) - 0.00001, 5),
                    "fee_fraction": defaults["fee_multiplier"],
                    "text": "Unit Test",
                },
                {"encoding": "multisig"},
            ],
            [
                "broadcast",
                {
                    "source": address1,
                    "timestamp": 1388000101,
                    "value": 100.343,
                    "fee_fraction": defaults["fee_multiplier"],
                    "text": "Unit Test",
                },
                {"encoding": "multisig"},
            ],
            [
                "broadcast",
                {
                    "source": address1,
                    "timestamp": 1388000201,
                    "value": 2,
                    "fee_fraction": defaults["fee_multiplier"],
                    "text": "Unit Test",
                },
                {"encoding": "multisig"},
            ],
            [
                "order",
                {
                    "source": address1,
                    "give_asset": "BBBB",
                    "give_quantity": defaults["small"],
                    "get_asset": "XCP",
                    "get_quantity": defaults["small"],
                    "expiration": defaults["expiration"],
                    "fee_required": 0,
                },
                {"encoding": "multisig"},
            ],
            [
                "burn",
                {"source": address1, "quantity": 1 * defaults["quantity"], "overburn": True},
                {"encoding": "multisig"},
            ],  # Try to burn a whole 'nother BTC.
            [
                "send",
                {"source": address1, "destination": address2, "asset": "BBBC", "quantity": 10000},
                {"encoding": "multisig"},
            ],
        ],
    )

    assert (
        empty_ledger_db.execute(
            "SELECT COUNT(*) AS count FROM btcpays WHERE order_match_id = ?", (order_match_id,)
        ).fetchone()["count"]
        == 1
    )

    # ensure final counts are correct
    for table, check_count in check_counters.items():
        count = empty_ledger_db.execute(
            f"SELECT COUNT(*) AS count FROM {table}",  # noqa S608
        ).fetchone()["count"]
        _initial, final = check_count
        assert count == final

    last_block = empty_ledger_db.execute(
        "SELECT ledger_hash FROM blocks ORDER BY rowid DESC LIMIT 1"
    ).fetchone()
    assert ledger_hash == last_block["ledger_hash"]


def test_simplesig_scenario(empty_ledger_db, bitcoind_mock, defaults):
    check_standard_scenario(
        empty_ledger_db,
        bitcoind_mock,
        defaults,
        defaults["addresses"][0],
        defaults["addresses"][1],
        "8a4b51a85ac08e64b95e9358f6eeb47c40585da22387c1f258169c5138ca51b7",
    )


def test_multisig_1_of_2_scenario(empty_ledger_db, bitcoind_mock, defaults):
    with ProtocolChangesDisabled(["enhanced_sends"]):
        check_standard_scenario(
            empty_ledger_db,
            bitcoind_mock,
            defaults,
            defaults["p2ms_addresses"][0],
            defaults["p2ms_addresses"][1],
            "24b52df5dcdf9341260237c6ad9bdd0d6f060e20470aa39528078185a8042eba",
        )


def test_multisig_2_of_2_scenario(empty_ledger_db, bitcoind_mock, defaults):
    with ProtocolChangesDisabled(["enhanced_sends"]):
        check_standard_scenario(
            empty_ledger_db,
            bitcoind_mock,
            defaults,
            defaults["p2ms_addresses"][3],
            defaults["p2ms_addresses"][4],
            "bb413c2bd3ea862c54366a7024df02d0980a6f35860f0a2f7f6663275c9688ca",
        )


def test_multisig_1_of_3_scenario(empty_ledger_db, bitcoind_mock, defaults):
    with ProtocolChangesDisabled(["enhanced_sends"]):
        check_standard_scenario(
            empty_ledger_db,
            bitcoind_mock,
            defaults,
            defaults["p2ms_addresses"][5],
            defaults["p2ms_addresses"][6],
            "3a3de61b47b2a1c05805e63dedd298d6757a4a5f55997ba82c2b2e892de05992",
        )


def test_multisig_2_of_3_scenario(empty_ledger_db, bitcoind_mock, defaults):
    with ProtocolChangesDisabled(["enhanced_sends"]):
        check_standard_scenario(
            empty_ledger_db,
            bitcoind_mock,
            defaults,
            defaults["p2ms_addresses"][7],
            defaults["p2ms_addresses"][8],
            "8e908ca910facebd0f36d71fab68766fea6b3096fab762326630aa4541cb9807",
        )


def test_multisig_3_of_3_scenario(empty_ledger_db, bitcoind_mock, defaults):
    with ProtocolChangesDisabled(["enhanced_sends"]):
        check_standard_scenario(
            empty_ledger_db,
            bitcoind_mock,
            defaults,
            defaults["p2ms_addresses"][9],
            defaults["p2ms_addresses"][10],
            "a269b831b30baaa5506145564f85d6b494d5ed47f9ad43b6c678c17f1691f035",
        )
