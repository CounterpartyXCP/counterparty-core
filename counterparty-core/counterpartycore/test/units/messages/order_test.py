import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib import ledger as ledger_mod
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import order
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_validate(ledger_db, defaults, current_block_index):
    assert (
        order.validate(
            ledger_db,
            "DIVISIBLE",
            defaults["quantity"],
            "XCP",
            defaults["quantity"],
            2000,
            0,
            current_block_index,
        )
        == []
    )

    assert (
        order.validate(
            ledger_db,
            "DIVISIBLE",
            defaults["quantity"],
            "XCP",
            defaults["quantity"],
            2000,
            0,
            current_block_index,
        )
        == []
    )

    assert order.validate(
        ledger_db,
        "DIVISIBLE",
        defaults["quantity"],
        "XCP",
        defaults["quantity"],
        2000,
        0.5,
        current_block_index,
    ) == ["fee_required must be in satoshis"]

    assert order.validate(
        ledger_db,
        "BTC",
        defaults["quantity"],
        "BTC",
        defaults["quantity"],
        2000,
        0,
        current_block_index,
    ) == ["cannot trade BTC for itself"]

    assert order.validate(
        ledger_db,
        "DIVISIBLE",
        defaults["quantity"] / 3,
        "XCP",
        defaults["quantity"],
        2000,
        0,
        current_block_index,
    ) == ["give_quantity must be in satoshis"]

    assert order.validate(
        ledger_db,
        "DIVISIBLE",
        defaults["quantity"],
        "XCP",
        defaults["quantity"] / 3,
        2000,
        0,
        current_block_index,
    ) == ["get_quantity must be in satoshis"]

    assert order.validate(
        ledger_db,
        "DIVISIBLE",
        defaults["quantity"],
        "XCP",
        defaults["quantity"],
        1.5,
        0,
        current_block_index,
    ) == ["expiration must be expressed as an integer block delta"]

    assert order.validate(
        ledger_db,
        "DIVISIBLE",
        -defaults["quantity"],
        "XCP",
        -defaults["quantity"],
        -2000,
        -10000,
        current_block_index,
    ) == [
        "non‐positive give quantity",
        "non‐positive get quantity",
        "negative fee_required",
        "negative expiration",
    ]

    assert order.validate(
        ledger_db,
        "DIVISIBLE",
        0,
        "XCP",
        defaults["quantity"],
        2000,
        0,
        current_block_index,
    ) == ["non‐positive give quantity", "zero give or zero get"]

    assert order.validate(
        ledger_db,
        "NOASSETA",
        defaults["quantity"],
        "NOASSETB",
        defaults["quantity"],
        2000,
        0,
        current_block_index,
    ) == ["no such asset to give (NOASSETA)", "no such asset to get (NOASSETB)"]

    assert order.validate(
        ledger_db,
        "DIVISIBLE",
        2**63 + 10,
        "XCP",
        defaults["quantity"],
        4 * 2016 + 10,
        0,
        current_block_index,
    ) == ["integer overflow"]


@pytest.mark.parametrize(
    ("param_name", "param_value", "expected_problem"),
    [
        ("give_quantity", "1000", "give_quantity must be in satoshis"),
        ("get_quantity", "1000", "get_quantity must be in satoshis"),
        ("fee_required", "0", "fee_required must be in satoshis"),
        (
            "expiration",
            "10",
            "expiration must be expressed as an integer block delta",
        ),
    ],
)
def test_validate_rejects_non_integer_parameters(
    ledger_db, defaults, current_block_index, param_name, param_value, expected_problem
):
    params = {
        "give_asset": "DIVISIBLE",
        "give_quantity": defaults["quantity"],
        "get_asset": "XCP",
        "get_quantity": defaults["quantity"],
        "expiration": 2000,
        "fee_required": 0,
    }
    params[param_name] = param_value

    assert order.validate(
        ledger_db,
        params["give_asset"],
        params["give_quantity"],
        params["get_asset"],
        params["get_quantity"],
        params["expiration"],
        params["fee_required"],
        current_block_index,
    ) == [expected_problem]


def test_validate_problem_ordering_is_consensus_stable(ledger_db, defaults, current_block_index):
    # The overflow problem must be appended before the BTC-for-BTC problem:
    # `parse` joins this list into the stored `status` string, so reordering
    # would change consensus state for historical transactions. Lock the order.
    assert order.validate(
        ledger_db,
        "BTC",
        2**63 + 10,
        "BTC",
        defaults["quantity"],
        2000,
        0,
        current_block_index,
    ) == ["integer overflow", "cannot trade BTC for itself"]


def test_compose(ledger_db, defaults, current_block_index):
    assert order.compose(
        ledger_db,
        defaults["addresses"][0],
        "BTC",
        defaults["small"],
        "XCP",
        defaults["small"] * 2,
        defaults["expiration"],
        0,
    ) == (
        defaults["addresses"][0],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert order.compose(
        ledger_db,
        defaults["p2sh_addresses"][0],
        "BTC",
        defaults["small"],
        "XCP",
        defaults["small"] * 2,
        defaults["expiration"],
        0,
    ) == (
        defaults["p2sh_addresses"][0],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert order.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        round(defaults["small"] * 2.1),
        "BTC",
        defaults["small"],
        defaults["expiration"],
        defaults["fee_required"],
    ) == (
        defaults["addresses"][0],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0",
    )

    assert order.compose(
        ledger_db,
        defaults["p2ms_addresses"][0],
        "BTC",
        defaults["small"],
        "XCP",
        defaults["small"] * 2,
        defaults["expiration"],
        0,
    ) == (
        defaults["p2ms_addresses"][0],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert order.compose(
        ledger_db,
        defaults["p2ms_addresses"][0],
        "XCP",
        round(defaults["small"] * 2.1),
        "BTC",
        defaults["small"],
        defaults["expiration"],
        defaults["fee_required"],
    ) == (
        defaults["p2ms_addresses"][0],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0",
    )

    assert order.compose(
        ledger_db,
        defaults["addresses"][0],
        "MAXI",
        2**63 - 1,
        "XCP",
        defaults["quantity"],
        defaults["expiration"],
        defaults["fee_required"],
    ) == (
        defaults["addresses"][0],
        [],
        b"\n\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0",
    )

    with pytest.raises(exceptions.ComposeError, match="integer overflow"):
        order.compose(
            ledger_db,
            defaults["addresses"][0],
            "MAXI",
            2**63 - 1,
            "XCP",
            defaults["quantity"],
            defaults["expiration"],
            2**63,
        )

    with pytest.raises(exceptions.ComposeError, match="insufficient funds"):
        order.compose(
            ledger_db,
            defaults["addresses"][0],
            "MAXI",
            2**63,
            "XCP",
            defaults["quantity"],
            defaults["expiration"],
            defaults["fee_required"],
        )

    assert order.compose(
        ledger_db,
        defaults["addresses"][0],
        "PARENT.already.issued",
        100000000,
        "XCP",
        defaults["small"],
        defaults["expiration"],
        defaults["fee_required"],
    ) == (
        defaults["addresses"][0],
        [],
        b'\n\x01S\x08"\x06\xe4c%\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0',
    )

    assert order.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        defaults["small"],
        "PARENT.already.issued",
        100000000,
        defaults["expiration"],
        defaults["fee_required"],
    ) == (
        defaults["addresses"][0],
        [],
        b'\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80\x01S\x08"\x06\xe4c%\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0',
    )

    assert order.compose(
        ledger_db,
        defaults["addresses"][0],
        "DIVISIBLE",
        defaults["quantity"],
        "XCP",
        defaults["quantity"],
        2000,
        0,
        current_block_index,
    ) == (
        defaults["addresses"][0],
        [],
        b"\n\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert order.compose(
        ledger_db,
        defaults["p2sh_addresses"][0],
        "DIVISIBLE",
        defaults["quantity"],
        "XCP",
        defaults["quantity"],
        2000,
        0,
        current_block_index,
    ) == (
        defaults["p2sh_addresses"][0],
        [],
        b"\n\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert order.compose(
        ledger_db,
        defaults["addresses"][1],
        "BTC",
        defaults["quantity"],
        "XCP",
        defaults["quantity"],
        2000,
        0,
        current_block_index,
    ) == (
        defaults["addresses"][1],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert order.compose(
        ledger_db,
        defaults["addresses"][1],
        "XCP",
        99999990,
        "BTC",
        666666,
        2000,
        0,
        current_block_index,
    ) == (
        defaults["addresses"][1],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe0\xf6\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\n,*\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert order.compose(
        ledger_db,
        defaults["addresses"][1],
        "XCP",
        99999990,
        "BTC",
        1999999,
        2000,
        0,
        current_block_index,
    ) == (
        defaults["addresses"][1],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe0\xf6\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x1e\x84\x7f\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert order.compose(
        ledger_db,
        defaults["addresses"][1],
        "BTC",
        500000,
        "XCP",
        100000000,
        2000,
        0,
        current_block_index,
    ) == (
        defaults["addresses"][1],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07\xa1 \x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert order.compose(
        ledger_db,
        defaults["addresses"][1],
        "XCP",
        100000000,
        "NODIVISIBLE",
        500,
        2000,
        0,
        current_block_index,
    ) == (
        defaults["addresses"][1],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x01\xf4\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert order.compose(
        ledger_db,
        defaults["p2ms_addresses"][0],
        "BTC",
        defaults["quantity"],
        "XCP",
        defaults["quantity"],
        2000,
        0,
        current_block_index,
    ) == (
        defaults["p2ms_addresses"][0],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert order.compose(
        ledger_db,
        defaults["p2ms_addresses"][0],
        "XCP",
        100000000,
        "BTC",
        500000,
        2000,
        0,
        current_block_index,
    ) == (
        defaults["p2ms_addresses"][0],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07\xa1 \x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert order.compose(
        ledger_db,
        defaults["p2ms_addresses"][0],
        "XCP",
        100000000,
        "NODIVISIBLE",
        500,
        2000,
        0,
        current_block_index,
    ) == (
        defaults["p2ms_addresses"][0],
        [],
        b"\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x01\xf4\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00",
    )


def test_parse_order(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1], fee=10000)
    message = b"\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00"
    order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "orders",
                "values": {
                    "block_index": current_block_index,
                    "expiration": 2000,
                    "expire_index": tx["block_index"] + 1999,
                    "fee_provided": 10000,
                    "fee_provided_remaining": 10000,
                    "fee_required": 0,
                    "fee_required_remaining": 0,
                    "get_asset": "XCP",
                    "get_quantity": 100000000,
                    "get_remaining": 0,
                    "give_asset": "DIVISIBLE",
                    "give_quantity": 100000000,
                    "give_remaining": 0,
                    "source": defaults["addresses"][1],
                    "status": "filled",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "order_matches",
                "values": {
                    "backward_asset": "DIVISIBLE",
                    "backward_quantity": 100000000,
                    "block_index": tx["block_index"],
                    "fee_paid": 0,
                    "forward_asset": "XCP",
                    "forward_quantity": 100000000,
                    "match_expire_index": tx["block_index"] + 19,
                    "status": "completed",
                    "tx0_address": defaults["addresses"][0],
                    "tx1_address": defaults["addresses"][1],
                    "tx1_block_index": tx["block_index"],
                    "tx1_expiration": 2000,
                    "tx1_hash": tx["tx_hash"],
                    "tx1_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][1],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "order match",
                    "quantity": 100000000,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "open order",
                    "address": defaults["addresses"][1],
                    "asset": "DIVISIBLE",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][0],
                    "asset": "DIVISIBLE",
                    "block_index": current_block_index,
                    "calling_function": "order match",
                    "quantity": 100000000,
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "filled",
                    "event": tx["tx_hash"],
                    "quantity": 0,
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][1],
                    "asset": "DIVISIBLE",
                    "block_index": current_block_index,
                    "calling_function": "filled",
                    "quantity": 0,
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


def test_parse_order_p2sh(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["p2sh_addresses"][0], fee=10000)
    message = b"\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00"
    order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "orders",
                "values": {
                    "block_index": current_block_index,
                    "expiration": 2000,
                    "expire_index": tx["block_index"] + 1999,
                    "fee_provided": 10000,
                    "fee_provided_remaining": 10000,
                    "fee_required": 0,
                    "fee_required_remaining": 0,
                    "get_asset": "XCP",
                    "get_quantity": 100000000,
                    "get_remaining": 0,
                    "give_asset": "DIVISIBLE",
                    "give_quantity": 100000000,
                    "give_remaining": 0,
                    "source": defaults["p2sh_addresses"][0],
                    "status": "filled",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "order_matches",
                "values": {
                    "backward_asset": "DIVISIBLE",
                    "backward_quantity": 100000000,
                    "block_index": tx["block_index"],
                    "fee_paid": 0,
                    "forward_asset": "XCP",
                    "forward_quantity": 100000000,
                    "match_expire_index": tx["block_index"] + 19,
                    "status": "completed",
                    "tx0_address": defaults["addresses"][0],
                    "tx1_address": defaults["p2sh_addresses"][0],
                    "tx1_block_index": tx["block_index"],
                    "tx1_expiration": 2000,
                    "tx1_hash": tx["tx_hash"],
                    "tx1_index": tx["tx_index"],
                },
            },
        ],
    )


def test_parse_order_btc(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1], fee=10000)
    message = b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00"
    order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "orders",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": 1223,
                    "source": defaults["addresses"][1],
                    "give_asset": "BTC",
                    "give_quantity": defaults["quantity"],
                    "give_remaining": defaults["quantity"],
                    "get_asset": "XCP",
                    "get_quantity": defaults["quantity"],
                    "get_remaining": defaults["quantity"],
                    "expiration": 2000,
                    "expire_index": 3222,
                    "fee_required": 0,
                    "fee_required_remaining": 0,
                    "fee_provided": 10000,
                    "fee_provided_remaining": 10000,
                    "status": "open",
                },
            },
            {
                "table": "order_matches",
                "values": {
                    "tx0_address": defaults["addresses"][0],
                    "tx1_index": tx["tx_index"],
                    "tx1_hash": tx["tx_hash"],
                    "tx1_address": defaults["addresses"][1],
                    "forward_asset": "XCP",
                    "forward_quantity": defaults["quantity"],
                    "backward_asset": "BTC",
                    "backward_quantity": 800000,
                    "tx0_block_index": 1229,
                    "tx1_block_index": 1223,
                    "block_index": 1223,
                    "tx0_expiration": 2000,
                    "tx1_expiration": 2000,
                    "match_expire_index": 1242,
                    "fee_paid": 7200,
                    "status": "pending",
                },
            },
        ],
    )


def test_parse_order_btc_2(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1], fee=10000)
    message = b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe0\xf6\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\n,*\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00"
    order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "orders",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][1],
                    "give_asset": "XCP",
                    "give_quantity": 99999990,
                    "give_remaining": 99999990,
                    "get_asset": "BTC",
                    "get_quantity": 666666,
                    "get_remaining": 666666,
                    "expiration": 2000,
                    "expire_index": 3222,
                    "fee_required": 0,
                    "fee_required_remaining": 0,
                    "fee_provided": 10000,
                    "fee_provided_remaining": 10000,
                    "status": "open",
                },
            },
            {
                "table": "order_matches",
                "values": {
                    "tx0_address": defaults["addresses"][1],
                    "tx1_index": tx["tx_index"],
                    "tx1_hash": tx["tx_hash"],
                    "tx1_address": defaults["addresses"][1],
                    "forward_asset": "BTC",
                    "forward_quantity": 799999,
                    "backward_asset": "XCP",
                    "backward_quantity": 99999875,
                    "block_index": tx["block_index"],
                    "tx0_expiration": 2000,
                    "tx1_expiration": 2000,
                    "match_expire_index": tx["block_index"] + 19,
                    "fee_paid": 0,
                    "status": "pending",
                },
            },
        ],
    )


def test_parse_order_btc_3(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1], fee=10000)
    message = b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe0\xf6\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x1e\x84\x7f\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00"
    order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "orders",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][1],
                    "give_asset": "XCP",
                    "give_quantity": 99999990,
                    "give_remaining": 99999990,
                    "get_asset": "BTC",
                    "get_quantity": 1999999,
                    "get_remaining": 1999999,
                    "expiration": 2000,
                    "expire_index": tx["block_index"] + 1999,
                    "fee_required": 0,
                    "fee_required_remaining": 0,
                    "fee_provided": 10000,
                    "fee_provided_remaining": 10000,
                    "status": "open",
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "open order",
                    "address": defaults["addresses"][1],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 99999990,
                },
            },
        ],
    )


def test_parse_order_btc_4(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1], fee=10000)
    message = b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07\xa1 \x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00"
    order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "orders",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][1],
                    "give_asset": "BTC",
                    "give_quantity": 500000,
                    "give_remaining": 500000,
                    "get_asset": "XCP",
                    "get_quantity": 100000000,
                    "get_remaining": 100000000,
                    "expiration": 2000,
                    "expire_index": tx["block_index"] + 1999,
                    "fee_required": 0,
                    "fee_required_remaining": 0,
                    "fee_provided": 10000,
                    "fee_provided_remaining": 10000,
                    "status": "open",
                },
            }
        ],
    )


def test_parse_order_invalid_data(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1], fee=10000)
    message = b"\x00\x00\x00\x00\x00 foo\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00"
    order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "orders",
                "values": {
                    "block_index": tx["block_index"],
                    "expiration": 0,
                    "expire_index": None,
                    "fee_provided": 10000,
                    "fee_provided_remaining": 10000,
                    "fee_required": 0,
                    "fee_required_remaining": 0,
                    "get_asset": "0",
                    "get_quantity": 0,
                    "get_remaining": 0,
                    "give_asset": "0",
                    "give_quantity": 0,
                    "give_remaining": 0,
                    "source": defaults["addresses"][1],
                    "status": "invalid: could not unpack",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "transactions_status",
                "values": {
                    "tx_index": tx["tx_index"],
                    "valid": False,
                },
            },
        ],
    )


def test_parse_order_no_divisible(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1], fee=10000)
    message = b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x01\xf4\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00"
    order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "orders",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][1],
                    "give_asset": "XCP",
                    "give_quantity": 100000000,
                    "give_remaining": 100000000,
                    "get_asset": "NODIVISIBLE",
                    "get_quantity": 500,
                    "get_remaining": 500,
                    "expiration": 2000,
                    "expire_index": tx["block_index"] + 1999,
                    "fee_required": 0,
                    "fee_required_remaining": 0,
                    "fee_provided": 10000,
                    "fee_provided_remaining": 10000,
                    "status": "open",
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "open order",
                    "address": defaults["addresses"][1],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
                },
            },
        ],
    )


def test_parse_order_multisig(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["p2ms_addresses"][0], fee=10000)
    message = b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00"
    order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "orders",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": current_block_index,
                    "source": defaults["p2ms_addresses"][0],
                    "give_asset": "BTC",
                    "give_quantity": 100000000,
                    "give_remaining": 99200000,
                    "get_asset": "XCP",
                    "get_quantity": 100000000,
                    "get_remaining": 0,
                    "expiration": 2000,
                    "expire_index": tx["block_index"] + 1999,
                    "fee_required": 0,
                    "fee_required_remaining": 0,
                    "fee_provided": 10000,
                    "fee_provided_remaining": 2800,
                    "status": "open",
                },
            },
            {
                "table": "order_matches",
                "values": {
                    "tx0_address": defaults["addresses"][0],
                    "tx1_index": tx["tx_index"],
                    "tx1_hash": tx["tx_hash"],
                    "tx1_address": defaults["p2ms_addresses"][0],
                    "forward_asset": "XCP",
                    "forward_quantity": 100000000,
                    "backward_asset": "BTC",
                    "backward_quantity": 800000,
                    "tx1_block_index": tx["block_index"],
                    "block_index": tx["block_index"],
                    "tx0_expiration": 2000,
                    "tx1_expiration": 2000,
                    "match_expire_index": tx["block_index"] + 19,
                    "fee_paid": 7200,
                    "status": "pending",
                },
            },
        ],
    )


def test_parse_order_multisig2(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["p2ms_addresses"][0], fee=10000)
    message = b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07\xa1 \x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00"
    order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "orders",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": current_block_index,
                    "source": defaults["p2ms_addresses"][0],
                    "give_asset": "XCP",
                    "give_quantity": 100000000,
                    "give_remaining": 0,
                    "get_asset": "BTC",
                    "get_quantity": 500000,
                    "get_remaining": -300000,
                    "expiration": 2000,
                    "expire_index": tx["block_index"] + 1999,
                    "fee_required": 0,
                    "fee_required_remaining": 0,
                    "fee_provided": 10000,
                    "fee_provided_remaining": 10000,
                    "status": "open",
                },
            },
            {
                "table": "order_matches",
                "values": {
                    "tx0_address": defaults["addresses"][1],
                    "tx1_index": tx["tx_index"],
                    "tx1_hash": tx["tx_hash"],
                    "tx1_address": defaults["p2ms_addresses"][0],
                    "forward_asset": "BTC",
                    "forward_quantity": 800000,
                    "backward_asset": "XCP",
                    "backward_quantity": 100000000,
                    "tx1_block_index": tx["block_index"],
                    "block_index": tx["block_index"],
                    "tx0_expiration": 2000,
                    "tx1_expiration": 2000,
                    "match_expire_index": tx["block_index"] + 19,
                    "fee_paid": 0,
                    "status": "pending",
                },
            },
        ],
    )


def test_parse_order_multisig3(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["p2ms_addresses"][0], fee=10000)
    message = b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x01\xf4\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00"
    order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "orders",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["p2ms_addresses"][0],
                    "give_asset": "XCP",
                    "give_quantity": 100000000,
                    "give_remaining": 100000000,
                    "get_asset": "NODIVISIBLE",
                    "get_quantity": 500,
                    "get_remaining": 500,
                    "expiration": 2000,
                    "expire_index": tx["block_index"] + 1999,
                    "fee_required": 0,
                    "fee_required_remaining": 0,
                    "fee_provided": 10000,
                    "fee_provided_remaining": 10000,
                    "status": "open",
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "open order",
                    "address": defaults["p2ms_addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
                },
            },
        ],
    )


def test_parse_order_maxi(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], fee=10000)
    message = b"\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0"
    order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "orders",
                "values": {
                    "block_index": tx["block_index"],
                    "expiration": 10,
                    "expire_index": tx["block_index"] + 9,
                    "fee_provided": 10000,
                    "fee_provided_remaining": 10000,
                    "fee_required": 900000,
                    "fee_required_remaining": 900000,
                    "get_asset": "XCP",
                    "get_quantity": 100000000,
                    "get_remaining": 100000000,
                    "give_asset": "MAXI",
                    "give_quantity": 9223372036854775807,
                    "give_remaining": 9223372036854775807,
                    "source": defaults["addresses"][0],
                    "status": "open",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "open order",
                    "address": defaults["addresses"][0],
                    "asset": "MAXI",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 9223372036854775807,
                },
            },
        ],
    )


def test_parse_more_than_maxi(ledger_db, blockchain_mock, defaults, caplog, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x80\x00\x00\x00\x00\x00\x00\x00"

    with test_helpers.capture_log(caplog, "invalid: integer overflow"):
        order.parse(ledger_db, tx, message)


def test_validate_indefinite_order(ledger_db, current_block_index):
    """expiration=0 is valid (indefinite order)."""
    assert (
        order.validate(ledger_db, "XCP", 1000, "DIVISIBLE", 1000, 0, 0, current_block_index) == []
    )


def test_validate_expiration_above_old_max(ledger_db, current_block_index):
    """expiration above old MAX_EXPIRATION (8064) is now allowed."""
    assert (
        order.validate(ledger_db, "XCP", 1000, "DIVISIBLE", 1000, 10000, 0, current_block_index)
        == []
    )


def test_validate_expiration_above_u16_max(ledger_db, current_block_index):
    """expiration above u16 max (65535) is rejected."""
    problems = order.validate(
        ledger_db, "XCP", 1000, "DIVISIBLE", 1000, 65536, 0, current_block_index
    )
    assert "expiration overflow" in problems


def test_validate_indefinite_before_activation(ledger_db, current_block_index):
    """expiration=0 is rejected when both indefinite_orders and no_zero_expiration are disabled."""
    with ProtocolChangesDisabled(["indefinite_orders", "no_zero_expiration"]):
        problems = order.validate(
            ledger_db, "XCP", 1000, "DIVISIBLE", 1000, 0, 0, current_block_index
        )
        assert "zero expiration" in problems


def test_validate_max_expiration_before_activation(ledger_db, current_block_index):
    """expiration above 8064 is rejected when indefinite_orders is disabled."""
    with ProtocolChangesDisabled(["indefinite_orders"]):
        problems = order.validate(
            ledger_db, "XCP", 1000, "DIVISIBLE", 1000, 9000, 0, current_block_index
        )
        assert "expiration overflow" in problems


def test_parse_indefinite_order_expire_index(ledger_db, blockchain_mock, defaults):
    """Indefinite order gets expire_index=NULL."""
    source = defaults["addresses"][0]
    _, _, data = order.compose(ledger_db, source, "XCP", 1000, "DIVISIBLE", 1000, 0, 0)
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    order.parse(ledger_db, tx, data[1:])

    record = ledger_db.execute(
        "SELECT * FROM orders WHERE tx_hash = ? ORDER BY rowid DESC LIMIT 1",
        (tx["tx_hash"],),
    ).fetchone()
    assert record["expire_index"] is None
    assert record["expiration"] == 0


def test_parse_expiration_n_means_n_blocks(ledger_db, blockchain_mock, defaults):
    """expiration=100 gives expire_index = block_index + 99 (100 blocks of life)."""
    source = defaults["addresses"][0]
    _, _, data = order.compose(ledger_db, source, "XCP", 1000, "DIVISIBLE", 1000, 100, 0)
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    order.parse(ledger_db, tx, data[1:])

    record = ledger_db.execute(
        "SELECT * FROM orders WHERE tx_hash = ? ORDER BY rowid DESC LIMIT 1",
        (tx["tx_hash"],),
    ).fetchone()
    assert record["expire_index"] == tx["block_index"] + 99


def test_match_expire_index_pre_activation(
    ledger_db, blockchain_mock, defaults, current_block_index, test_helpers
):
    """Before indefinite_orders, match_expire_index = block_index + 20."""
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1], fee=10000)
    message = b"\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00"
    with ProtocolChangesDisabled(["indefinite_orders"]):
        order.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "order_matches",
                "values": {
                    "match_expire_index": tx["block_index"] + 20,
                    "tx1_hash": tx["tx_hash"],
                },
            },
        ],
    )


def test_parse_expire_index_pre_activation(ledger_db, blockchain_mock, defaults):
    """Before indefinite_orders activation, expire_index = block_index + expiration (no -1)."""
    source = defaults["addresses"][0]
    _, _, data = order.compose(ledger_db, source, "XCP", 1000, "DIVISIBLE", 1000, 100, 0)
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    with ProtocolChangesDisabled(["indefinite_orders"]):
        order.parse(ledger_db, tx, data[1:])

    record = ledger_db.execute(
        "SELECT * FROM orders WHERE tx_hash = ? ORDER BY rowid DESC LIMIT 1",
        (tx["tx_hash"],),
    ).fetchone()
    assert record["expire_index"] == tx["block_index"] + 100


def test_indefinite_order_not_in_expiry_scan(ledger_db, blockchain_mock, defaults):
    """Indefinite order never appears in get_orders_to_expire."""
    source = defaults["addresses"][0]
    block_index = CurrentState().current_block_index()
    _, _, data = order.compose(ledger_db, source, "XCP", 1000, "DIVISIBLE", 1000, 0, 0)
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    order.parse(ledger_db, tx, data[1:])

    for future in [block_index + 1, block_index + 100, 1, 2]:
        expiring = ledger_mod.markets.get_orders_to_expire(ledger_db, future)
        tx_hashes = [o["tx_hash"] for o in expiring]
        assert tx["tx_hash"] not in tx_hashes
