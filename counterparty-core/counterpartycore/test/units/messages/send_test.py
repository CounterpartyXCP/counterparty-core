import re

import pytest
from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages import send
from counterpartycore.lib.messages.versions import enhancedsend, send1
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def insert_required_option(ledger_db, current_block_index, defaults):
    ledger.events.insert_record(
        ledger_db,
        "addresses",
        {
            "block_index": current_block_index,
            "address": defaults["addresses"][6],
            "options": config.ADDRESS_OPTION_REQUIRE_MEMO,
        },
        "NEW_ADDRESS_OPTIONS",
    )


def test_validate(ledger_db, defaults, current_block_index):
    assert (
        send.validate(
            ledger_db,
            defaults["addresses"][1],
            "XCP",
            defaults["quantity"],
        )
        == []
    )
    assert (
        send.validate(
            ledger_db,
            defaults["p2sh_addresses"][0],
            "XCP",
            defaults["quantity"],
        )
        == []
    )
    assert (
        send.validate(
            ledger_db,
            defaults["addresses"][1],
            "XCP",
            defaults["quantity"],
        )
        == []
    )
    assert send.validate(
        ledger_db,
        defaults["addresses"][1],
        "BTC",
        defaults["quantity"],
    ) == ["cannot send bitcoins"]
    assert send.validate(
        ledger_db,
        defaults["addresses"][1],
        "XCP",
        defaults["quantity"] / 3,
    ) == ["quantity must be in satoshis"]
    assert send.validate(
        ledger_db,
        defaults["addresses"][1],
        "XCP",
        -1 * defaults["quantity"],
    ) == ["negative quantity"]
    assert (
        send.validate(
            ledger_db,
            defaults["p2ms_addresses"][0],
            "XCP",
            defaults["quantity"],
        )
        == []
    )
    assert send.validate(ledger_db, defaults["addresses"][1], "MAXI", 2**63 - 1) == []
    assert send.validate(ledger_db, defaults["addresses"][1], "MAXI", 2**63) == ["integer overflow"]

    insert_required_option(ledger_db, current_block_index, defaults)
    assert send.validate(
        ledger_db,
        defaults["addresses"][6],
        "XCP",
        defaults["quantity"],
    ) == ["destination requires memo"]


def test_compose_valid(ledger_db, defaults, current_block_index):
    with ProtocolChangesDisabled(["short_tx_type_id", "enhanced_sends"]):
        assert send.compose(
            ledger_db, defaults["addresses"][0], defaults["addresses"][1], "XCP", defaults["small"]
        ) == (
            defaults["addresses"][0],
            [(defaults["addresses"][1], None)],
            b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
        )

        assert send.compose(
            ledger_db,
            defaults["p2sh_addresses"][0],
            defaults["addresses"][1],
            "XCP",
            defaults["small"],
        ) == (
            defaults["p2sh_addresses"][0],
            [(defaults["addresses"][1], None)],
            b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
        )

        assert send.compose(
            ledger_db,
            defaults["addresses"][0],
            defaults["p2sh_addresses"][0],
            "XCP",
            defaults["small"],
        ) == (
            defaults["addresses"][0],
            [(defaults["p2sh_addresses"][0], None)],
            b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
        )

        assert send.compose(
            ledger_db,
            defaults["addresses"][0],
            defaults["p2ms_addresses"][0],
            "XCP",
            defaults["quantity"],
        ) == (
            defaults["addresses"][0],
            [
                (
                    defaults["p2ms_addresses"][0],
                    None,
                )
            ],
            b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
        )

        assert send.compose(
            ledger_db,
            defaults["p2ms_addresses"][0],
            defaults["addresses"][0],
            "XCP",
            defaults["quantity"],
        ) == (
            defaults["p2ms_addresses"][0],
            [(defaults["addresses"][0], None)],
            b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
        )

        assert send.compose(
            ledger_db,
            defaults["p2ms_addresses"][0],
            defaults["p2ms_addresses"][1],
            "XCP",
            defaults["quantity"],
        ) == (
            defaults["p2ms_addresses"][0],
            [
                (
                    defaults["p2ms_addresses"][1],
                    None,
                )
            ],
            b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
        )

        assert send.compose(
            ledger_db, defaults["addresses"][0], defaults["addresses"][1], "MAXI", 2**63 - 1
        ) == (
            defaults["addresses"][0],
            [(defaults["addresses"][1], None)],
            b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff",
        )

        assert send.compose(
            ledger_db,
            defaults["addresses"][0],
            defaults["addresses"][1],
            "BTC",
            defaults["quantity"],
        ) == (
            defaults["addresses"][0],
            [(defaults["addresses"][1], 100000000)],
            None,
        )

        assert send.compose(
            ledger_db,
            defaults["addresses"][0],
            defaults["p2sh_addresses"][0],
            "BTC",
            defaults["quantity"],
        ) == (
            defaults["addresses"][0],
            [(defaults["p2sh_addresses"][0], 100000000)],
            None,
        )

        assert send.compose(
            ledger_db,
            defaults["addresses"][0],
            defaults["addresses"][1],
            "PARENT.already.issued",
            100000000,
        ) == (
            defaults["addresses"][0],
            [(defaults["addresses"][1], None)],
            b'\x00\x00\x00\x00\x01S\x08"\x06\xe4c%\x00\x00\x00\x00\x05\xf5\xe1\x00',
        )

    assert send.compose(
        ledger_db,
        defaults["addresses"][0],
        defaults["p2wpkh_addresses"][0],
        "XCP",
        100000,
        "segwit",
        False,
    ) == (
        defaults["addresses"][0],
        [],
        b"\x02\x84\x01\x1a\x00\x01\x86\xa0V\x03\x00O]\x14\xe8d\xf9e:\xa6\x9fy\xbc\x06\xe3\x06'\xce\xa8OnFsegwit",
    )


def test_compose_no_valid(ledger_db, defaults, current_block_index):
    with pytest.raises(exceptions.ComposeError, match="insufficient funds"):
        send.compose(
            ledger_db,
            defaults["addresses"][0],
            defaults["addresses"][1],
            "XCP",
            defaults["quantity"] * 10000000,
        )

    with pytest.raises(
        exceptions.ComposeError, match=re.escape("quantity must be an int (in satoshi)")
    ):
        send.compose(
            ledger_db,
            defaults["addresses"][0],
            defaults["addresses"][1],
            "XCP",
            defaults["quantity"] / 3,
        )

    with pytest.raises(exceptions.ComposeError, match="integer overflow"):
        send.compose(
            ledger_db, defaults["addresses"][0], defaults["addresses"][1], "MAXI", 2**63 + 1
        )

    with ProtocolChangesDisabled(["enhanced_sends"]):
        with pytest.raises(exceptions.ComposeError, match="integer overflow"):
            send.compose(
                ledger_db,
                defaults["addresses"][0],
                defaults["addresses"][1],
                "BTC",
                config.MAX_INT + 1,
                no_dispense=True,
            )

    insert_required_option(ledger_db, current_block_index, defaults)

    with pytest.raises(exceptions.ComposeError, match="destination requires memo"):
        send.compose(
            ledger_db, defaults["addresses"][0], defaults["addresses"][6], "XCP", 100000000
        )

    with ProtocolChangesDisabled(["enhanced_sends"]):
        with pytest.raises(exceptions.ComposeError, match="enhanced sends are not enabled"):
            send.compose(
                ledger_db,
                defaults["addresses"][0],
                defaults["addresses"][6],
                "XCP",
                100000000,
                memo="12345",
                use_enhanced_send=True,
            )

    with ProtocolChangesDisabled(["mpma_sends"]):
        with pytest.raises(exceptions.ComposeError, match="mpma sends are not enabled"):
            send.compose(
                ledger_db,
                defaults["addresses"][0],
                [defaults["addresses"][1], defaults["addresses"][2]],
                ["XCP", "XCP"],
                [100000000, 100000000],
                memo="12345",
                use_enhanced_send=True,
            )


def test_compose_mpma_errors(ledger_db, defaults, current_block_index):
    """Test MPMA compose error cases."""
    # Test MPMA limit exceeded
    too_many_destinations = [defaults["addresses"][1]] * (config.MPMA_LIMIT + 1)
    too_many_assets = ["XCP"] * (config.MPMA_LIMIT + 1)
    too_many_quantities = [100000] * (config.MPMA_LIMIT + 1)

    with pytest.raises(exceptions.ComposeError, match="mpma sends have a maximum of .* sends"):
        send.compose(
            ledger_db,
            defaults["addresses"][0],
            too_many_destinations,
            too_many_assets,
            too_many_quantities,
        )

    # Test memo/memo_is_hex list length mismatch
    with pytest.raises(
        exceptions.ComposeError,
        match="memo and memo_is_hex lists should have the same length",
    ):
        send.compose(
            ledger_db,
            defaults["addresses"][0],
            [defaults["addresses"][1], defaults["addresses"][2]],
            ["XCP", "XCP"],
            [100000, 100000],
            memo=["memo1", "memo2"],
            memo_is_hex=[False],  # Length mismatch
        )

    # Test memo list length != destination length
    with pytest.raises(
        exceptions.ComposeError,
        match="memo/memo_is_hex lists should have the same length as sends",
    ):
        send.compose(
            ledger_db,
            defaults["addresses"][0],
            [defaults["addresses"][1], defaults["addresses"][2]],
            ["XCP", "XCP"],
            [100000, 100000],
            memo=["memo1"],  # Only one memo for 2 destinations
            memo_is_hex=[False],
        )

    # Test dict memo missing keys
    with pytest.raises(
        exceptions.ComposeError,
        match='when specifying memo/memo_is_hex as a dict, they must contain keys "list" and "msg_wide"',
    ):
        send.compose(
            ledger_db,
            defaults["addresses"][0],
            [defaults["addresses"][1], defaults["addresses"][2]],
            ["XCP", "XCP"],
            [100000, 100000],
            memo={"list": ["memo1", "memo2"]},  # Missing msg_wide
            memo_is_hex={"list": [False, False], "msg_wide": False},
        )

    # Test dict memo list length mismatch
    with pytest.raises(
        exceptions.ComposeError,
        match="length of memo.list and memo_is_hex.list must be equal",
    ):
        send.compose(
            ledger_db,
            defaults["addresses"][0],
            [defaults["addresses"][1], defaults["addresses"][2]],
            ["XCP", "XCP"],
            [100000, 100000],
            memo={"list": ["memo1", "memo2"], "msg_wide": ""},
            memo_is_hex={"list": [False], "msg_wide": False},  # Length mismatch
        )

    # Test dict memo list length != destination length
    with pytest.raises(
        exceptions.ComposeError,
        match="length of memo.list/memo_is_hex.list must be equal to the amount of sends",
    ):
        send.compose(
            ledger_db,
            defaults["addresses"][0],
            [defaults["addresses"][1], defaults["addresses"][2]],
            ["XCP", "XCP"],
            [100000, 100000],
            memo={"list": ["memo1"], "msg_wide": ""},  # Only one for 2 destinations
            memo_is_hex={"list": [False], "msg_wide": False},
        )

    # Test destination/asset/quantity array length mismatch
    with pytest.raises(
        exceptions.ComposeError,
        match="destination, asset and quantity arrays must have the same amount of elements",
    ):
        send.compose(
            ledger_db,
            defaults["addresses"][0],
            [defaults["addresses"][1], defaults["addresses"][2]],
            ["XCP"],  # Only one asset for 2 destinations
            [100000, 100000],
        )


def test_compose_mpma_valid_with_memo_list(ledger_db, defaults, current_block_index):
    """Test valid MPMA compose with memo as list."""
    result = send.compose(
        ledger_db,
        defaults["addresses"][0],
        [defaults["addresses"][1], defaults["addresses"][2]],
        ["XCP", "XCP"],
        [100000, 100000],
        memo=["memo1", "memo2"],
        memo_is_hex=[False, False],
    )
    assert result[0] == defaults["addresses"][0]
    assert result[2] is not None


def test_compose_mpma_valid_with_memo_dict(ledger_db, defaults, current_block_index):
    """Test valid MPMA compose with memo as dict."""
    result = send.compose(
        ledger_db,
        defaults["addresses"][0],
        [defaults["addresses"][1], defaults["addresses"][2]],
        ["XCP", "XCP"],
        [100000, 100000],
        memo={"list": ["memo1", "memo2"], "msg_wide": "wide_memo"},
        memo_is_hex={"list": [False, False], "msg_wide": False},
    )
    assert result[0] == defaults["addresses"][0]
    assert result[2] is not None


def test_compose_mpma_valid_with_wide_memo(ledger_db, defaults, current_block_index):
    """Test valid MPMA compose with message-wide memo (case 3)."""
    result = send.compose(
        ledger_db,
        defaults["addresses"][0],
        [defaults["addresses"][1], defaults["addresses"][2]],
        ["XCP", "XCP"],
        [100000, 100000],
        memo="wide_memo",
        memo_is_hex=False,
    )
    assert result[0] == defaults["addresses"][0]
    assert result[2] is not None


def test_parse_send1(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _source, _destination, data = send.compose(
        ledger_db,
        defaults["addresses"][0],
        defaults["addresses"][1],
        "XCP",
        100000000,
    )
    enhancedsend.parse(ledger_db, tx, data[1:])

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "destination": defaults["addresses"][1],
                    "quantity": 100000000,
                    "source": defaults["addresses"][0],
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
                    "calling_function": "send",
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "send",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
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


def test_parse_send2(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _source, _destination, data = send.compose(
        ledger_db, defaults["addresses"][0], defaults["addresses"][1], "NODIVISIBLE", 500
    )
    enhancedsend.parse(ledger_db, tx, data[1:])

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "NODIVISIBLE",
                    "block_index": tx["block_index"],
                    "destination": defaults["addresses"][1],
                    "quantity": 500,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][1],
                    "asset": "NODIVISIBLE",
                    "block_index": current_block_index,
                    "calling_function": "send",
                    "event": tx["tx_hash"],
                    "quantity": 500,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "send",
                    "address": defaults["addresses"][0],
                    "asset": "NODIVISIBLE",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 500,
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


def test_parse_send3(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], defaults["p2ms_addresses"][0]
    )
    send1.parse(ledger_db, tx, b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x11\xe1\xa3\x00")

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "destination": defaults["p2ms_addresses"][0],
                    "quantity": 300000000,
                    "source": defaults["addresses"][0],
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
                    "calling_function": "send",
                    "event": tx["tx_hash"],
                    "quantity": 300000000,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "send",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 300000000,
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


def test_parse_send4(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["p2ms_addresses"][0], defaults["addresses"][0]
    )
    send1.parse(ledger_db, tx, b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00")

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "destination": defaults["addresses"][0],
                    "quantity": 100000000,
                    "source": defaults["p2ms_addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "send",
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "send",
                    "address": defaults["p2ms_addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
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


def test_parse_send5(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["p2ms_addresses"][0], defaults["p2ms_addresses"][1]
    )
    send1.parse(ledger_db, tx, b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00")

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "destination": defaults["p2ms_addresses"][1],
                    "quantity": 100000000,
                    "source": defaults["p2ms_addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["p2ms_addresses"][1],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "send",
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "send",
                    "address": defaults["p2ms_addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
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


def test_parse_send6(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], defaults["addresses"][1])
    send1.parse(ledger_db, tx, b"\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff")

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "MAXI",
                    "block_index": tx["block_index"],
                    "destination": defaults["addresses"][1],
                    "quantity": 9223372036854775807,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][1],
                    "asset": "MAXI",
                    "block_index": current_block_index,
                    "calling_function": "send",
                    "event": tx["tx_hash"],
                    "quantity": 9223372036854775807,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "send",
                    "address": defaults["addresses"][0],
                    "asset": "MAXI",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 9223372036854775807,
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


def test_parse_send7(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index, apiv2_client
):
    url = "/v2/transactions?valid=false"
    result = apiv2_client.get(url).json["result"]
    assert len(result) == 0

    insert_required_option(ledger_db, current_block_index, defaults)
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], defaults["addresses"][6])
    send1.parse(ledger_db, tx, b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80")

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "destination": defaults["addresses"][6],
                    "quantity": 50000000,
                    "source": defaults["addresses"][0],
                    "status": "invalid: destination requires memo",
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

    url = "/v2/transactions?valid=false"
    result = apiv2_client.get(url).json["result"]
    assert len(result) == 1


def test_parse_send8(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    insert_required_option(ledger_db, current_block_index, defaults)
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][2], defaults["addresses"][0])
    send1.parse(ledger_db, tx, b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00")

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "destination": defaults["addresses"][0],
                    "quantity": 0,
                    "source": defaults["addresses"][2],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
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
