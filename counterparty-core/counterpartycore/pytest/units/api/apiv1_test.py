import re

import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.api import apiv1


def test_create_burn(apiv1_client, defaults):
    result = apiv1_client(
        "create_burn",
        {
            "source": defaults["addresses"][1],
            "quantity": defaults["burn_quantity"],
            "encoding": "multisig",
        },
    ).json
    assert (
        result["result"]
        == "0200000001c5c9b5c88b6c5e28fe4a4fd8b6792f2980c5cacc0cca959eff213818be01e0a80000000000ffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88acbcbce837000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000"
    )


def test_get_rows(ledger_db, state_db, monkeypatch):
    # print(json.dumps(apiv1.get_rows("balances", None, "AND", None, None, None, None, None, 1, 0, True), indent=4))

    assert apiv1.get_rows("balances", None, "AND", None, None, None, None, None, 1, 0, True) == [
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "CALLABLE",
            "quantity": 1000,
            "block_index": 105,
            "tx_index": 3,
            "utxo": None,
            "utxo_address": None,
            "asset_longname": None,
            "divisible": True,
        }
    ]

    with pytest.raises(exceptions.APIError, match=re.escape("Invalid filter operator (OR, AND)")):
        apiv1.get_rows("balances", None, "barfoo", None, None, None, None, None, 1000, 0, True)

    with pytest.raises(exceptions.APIError, match="Unknown table"):
        apiv1.get_rows(None, None, "AND", None, None, None, None, None, 1000, 0, True)

    with pytest.raises(exceptions.APIError, match=re.escape("Invalid order direction (ASC, DESC)")):
        apiv1.get_rows("balances", None, "AND", None, "barfoo", None, None, None, 1000, 0, True)

    with pytest.raises(exceptions.APIError, match="Invalid limit"):
        apiv1.get_rows("balances", None, "AND", None, None, None, None, None, 1000.0, 0, True)

    with pytest.raises(exceptions.APIError, match="Limit should be lower or equal to 1000"):
        apiv1.get_rows("balances", None, "AND", None, None, None, None, None, 1001, 0, True)

    with pytest.raises(exceptions.APIError, match="Invalid offset"):
        apiv1.get_rows("balances", None, "AND", None, None, None, None, None, 1000, 0.0, True)

    with pytest.raises(exceptions.APIError, match="Invalid order_by, must be a field name"):
        apiv1.get_rows("balances", None, "AND", "*", None, None, None, None, 1000, 0, True)

    with pytest.raises(exceptions.APIError, match="Unknown filter type"):
        apiv1.get_rows("balances", [0], "AND", None, None, None, None, None, 1000, 0, True)

    with pytest.raises(
        exceptions.APIError, match="A specified filter is missing the 'value' field"
    ):
        apiv1.get_rows(
            "balances",
            {"field": "bar", "op": "="},
            "AND",
            None,
            None,
            None,
            None,
            None,
            1000,
            0,
            True,
        )

    with pytest.raises(exceptions.APIError, match="Invalid value for the field 'bar'"):
        apiv1.get_rows(
            "balances",
            {"field": "bar", "op": "=", "value": {}},
            "AND",
            None,
            None,
            None,
            None,
            None,
            1000,
            0,
            True,
        )

    with pytest.raises(exceptions.APIError, match="Invalid value for the field 'bar'"):
        apiv1.get_rows(
            "balances",
            {"field": "bar", "op": "=", "value": [0, 2]},
            "AND",
            None,
            None,
            None,
            None,
            None,
            1000,
            0,
            True,
        )

    with pytest.raises(exceptions.APIError, match="Invalid operator for the field 'bar'"):
        apiv1.get_rows(
            "balances",
            {"field": "bar", "op": "AND", "value": 0},
            "AND",
            None,
            None,
            None,
            None,
            None,
            1000,
            0,
            True,
        )

    with pytest.raises(exceptions.APIError, match="case_sensitive must be a boolean"):
        apiv1.get_rows(
            "balances",
            {"field": "bar", "op": "=", "value": 0, "case_sensitive": 0},
            "AND",
            None,
            None,
            None,
            None,
            None,
            1000,
            0,
            True,
        )

    with pytest.raises(exceptions.APIError, match="Invalid memo_hex value"):
        apiv1.get_rows(
            "sends",
            [{"field": "memo_hex", "op": "=", "value": "badx"}],
            "AND",
            None,
            None,
            None,
            None,
            None,
            1000,
            0,
            True,
        )

    assert apiv1.get_rows(
        "sends",
        [{"field": "block_index", "op": "=", "value": "717"}],
        "AND",
        None,
        None,
        None,
        None,
        None,
        1000,
        0,
        True,
    ) == [
        {
            "tx_index": 37,
            "tx_hash": "b238c76bb1506b5db10c50e7e5ce5c7740fd1cc6d43cc687c8f267a1c1bd9e91",
            "block_index": 717,
            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "source_address": None,
            "destination_address": None,
            "asset": "XCP",
            "quantity": 100000000,
            "status": "valid",
            "memo": "hello",
            "memo_hex": "68656c6c6f",
            "msg_index": 0,
            "fee_paid": 0,
            "send_type": "send",
        }
    ]

    assert apiv1.get_rows(
        "sends",
        [{"field": "block_index", "op": "=", "value": "718"}],
        "AND",
        None,
        None,
        None,
        None,
        None,
        1000,
        0,
        True,
    ) == [
        {
            "tx_index": 38,
            "tx_hash": "424b437fa86c35d47c0b7a07a594d32fb866cf91a330f0022e5a0d0fdba5e06c",
            "block_index": 718,
            "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "source_address": None,
            "destination_address": None,
            "asset": "XCP",
            "quantity": 100000000,
            "status": "valid",
            "memo": "",
            "memo_hex": "fade0001",
            "msg_index": 0,
            "fee_paid": 0,
            "send_type": "send",
        }
    ]

    assert apiv1.get_rows(
        "sends",
        [{"field": "memo", "op": "=", "value": "hello"}],
        "AND",
        None,
        None,
        None,
        None,
        None,
        1000,
        0,
        True,
    ) == [
        {
            "tx_index": 37,
            "tx_hash": "b238c76bb1506b5db10c50e7e5ce5c7740fd1cc6d43cc687c8f267a1c1bd9e91",
            "block_index": 717,
            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "source_address": None,
            "destination_address": None,
            "asset": "XCP",
            "quantity": 100000000,
            "status": "valid",
            "memo": "hello",
            "memo_hex": "68656c6c6f",
            "msg_index": 0,
            "fee_paid": 0,
            "send_type": "send",
        }
    ]

    assert apiv1.get_rows(
        "sends",
        [{"field": "memo", "op": "LIKE", "value": "%ell%"}],
        "AND",
        None,
        None,
        None,
        None,
        None,
        1000,
        0,
        True,
    ) == [
        {
            "tx_index": 37,
            "tx_hash": "b238c76bb1506b5db10c50e7e5ce5c7740fd1cc6d43cc687c8f267a1c1bd9e91",
            "block_index": 717,
            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "source_address": None,
            "destination_address": None,
            "asset": "XCP",
            "quantity": 100000000,
            "status": "valid",
            "memo": "hello",
            "memo_hex": "68656c6c6f",
            "msg_index": 0,
            "fee_paid": 0,
            "send_type": "send",
        }
    ]

    assert apiv1.get_rows(
        "sends",
        [{"field": "memo_hex", "op": "=", "value": "68656C6C6F"}],
        "AND",
        None,
        None,
        None,
        None,
        None,
        1000,
        0,
        True,
    ) == [
        {
            "tx_index": 37,
            "tx_hash": "b238c76bb1506b5db10c50e7e5ce5c7740fd1cc6d43cc687c8f267a1c1bd9e91",
            "block_index": 717,
            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "source_address": None,
            "destination_address": None,
            "asset": "XCP",
            "quantity": 100000000,
            "status": "valid",
            "memo": "hello",
            "memo_hex": "68656c6c6f",
            "msg_index": 0,
            "fee_paid": 0,
            "send_type": "send",
        }
    ]

    assert apiv1.get_rows(
        "sends",
        [{"field": "memo_hex", "op": "=", "value": "68656c6c6f"}],
        "AND",
        None,
        None,
        None,
        None,
        None,
        1000,
        0,
        True,
    ) == [
        {
            "tx_index": 37,
            "tx_hash": "b238c76bb1506b5db10c50e7e5ce5c7740fd1cc6d43cc687c8f267a1c1bd9e91",
            "block_index": 717,
            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "source_address": None,
            "destination_address": None,
            "asset": "XCP",
            "quantity": 100000000,
            "status": "valid",
            "memo": "hello",
            "memo_hex": "68656c6c6f",
            "msg_index": 0,
            "fee_paid": 0,
            "send_type": "send",
        }
    ]

    assert apiv1.get_rows(
        "sends",
        [{"field": "memo_hex", "op": "=", "value": "fade0001"}],
        "AND",
        None,
        None,
        None,
        None,
        None,
        1000,
        0,
        True,
    ) == [
        {
            "tx_index": 38,
            "tx_hash": "424b437fa86c35d47c0b7a07a594d32fb866cf91a330f0022e5a0d0fdba5e06c",
            "block_index": 718,
            "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "source_address": None,
            "destination_address": None,
            "asset": "XCP",
            "quantity": 100000000,
            "status": "valid",
            "memo": "",
            "memo_hex": "fade0001",
            "msg_index": 0,
            "fee_paid": 0,
            "send_type": "send",
        }
    ]
