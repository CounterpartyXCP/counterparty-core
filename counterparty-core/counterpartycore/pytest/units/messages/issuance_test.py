import binascii

import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.messages import issuance
from counterpartycore.pytest.mocks.counterpartydbs import ProtocolChangesDisabled


def test_validate(ledger_db, defaults, current_block_index):
    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "ASSET",
        1000,
        True,
        None,
        None,
        False,
        None,
        None,
        "",
        None,
        None,
        current_block_index,
    ) == (0, 0.0, [], 50000000, "", True, False, False, False, None)

    assert issuance.validate(
        ledger_db,
        defaults["p2sh_addresses"][0],
        None,
        "ASSET",
        1000,
        True,
        None,
        None,
        False,
        None,
        None,
        "",
        None,
        None,
        current_block_index,
    ) == (0, 0.0, [], 50000000, "", True, False, False, False, None)

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][2],
        None,
        "DIVIDEND",
        1000,
        False,
        None,
        None,
        False,
        None,
        None,
        "",
        None,
        None,
        current_block_index,
    ) == (
        0,
        0.0,
        ["cannot change divisibility"],
        0,
        "",
        False,
        False,
        False,
        True,
        None,
    )

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "BTC",
        1000,
        True,
        None,
        None,
        False,
        None,
        None,
        "",
        None,
        None,
        current_block_index,
    ) == (
        0,
        0.0,
        ["cannot issue BTC or XCP"],
        50000000,
        "",
        True,
        False,
        False,
        False,
        None,
    )

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "XCP",
        1000,
        True,
        None,
        None,
        False,
        None,
        None,
        "",
        None,
        None,
        current_block_index,
    ) == (
        0,
        0.0,
        ["cannot issue BTC or XCP"],
        50000000,
        "",
        True,
        False,
        False,
        False,
        None,
    )

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "NOSATOSHI",
        1000.5,
        True,
        None,
        None,
        False,
        None,
        None,
        "",
        None,
        None,
        current_block_index,
    ) == (0, 0.0, ["quantity must be in satoshis"], 0, "", True, None, None)

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "CALLPRICEFLOAT",
        1000,
        True,
        None,
        None,
        False,
        None,
        100.0,
        "",
        None,
        None,
        current_block_index,
    ) == (0, 0.0, [], 0, "", True, False, False, False, None)

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "CALLPRICEINT",
        1000,
        True,
        None,
        None,
        False,
        None,
        100,
        "",
        None,
        None,
        current_block_index,
    ) == (0, 0.0, [], 50000000, "", True, False, False, False, None)

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "CALLPRICESTR",
        1000,
        True,
        None,
        None,
        False,
        None,
        "abc",
        "",
        None,
        None,
        current_block_index,
    ) == (0, "abc", ["call_price must be a float"], 0, "", True, None, None)

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "CALLDATEINT",
        1000,
        True,
        None,
        None,
        False,
        1409401723,
        None,
        "",
        None,
        None,
        current_block_index,
    ) == (0, 0.0, [], 50000000, "", True, False, False, False, None)

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "CALLDATEFLOAT",
        1000,
        True,
        None,
        None,
        False,
        0.9 * 1409401723,
        None,
        "",
        None,
        None,
        current_block_index,
    ) == (
        1268461550.7,
        0.0,
        ["call_date must be epoch integer"],
        0,
        "",
        True,
        None,
        None,
    )

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "CALLDATESTR",
        1000,
        True,
        None,
        None,
        False,
        "abc",
        None,
        "",
        None,
        None,
        current_block_index,
    ) == (
        "abc",
        0.0,
        ["call_date must be epoch integer"],
        0,
        "",
        True,
        None,
        None,
    )

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "NEGVALUES",
        -1000,
        True,
        None,
        None,
        True,
        -1409401723,
        -defaults["quantity"],
        "",
        None,
        None,
        current_block_index,
    ) == (
        -1409401723,
        -100000000.0,
        ["negative quantity", "negative call price", "negative call date"],
        50000000,
        "",
        True,
        False,
        False,
        False,
        None,
    )

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][2],
        None,
        "DIVISIBLE",
        1000,
        True,
        None,
        None,
        False,
        None,
        None,
        "Divisible asset",
        None,
        None,
        current_block_index,
    ) == (
        0,
        0.0,
        ["issued by another address"],
        0,
        "Divisible asset",
        True,
        False,
        False,
        True,
        None,
    )

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "LOCKED",
        1000,
        True,
        None,
        None,
        False,
        None,
        None,
        "Locked asset",
        None,
        None,
        current_block_index,
    ) == (
        0,
        0.0,
        ["locked asset and non‐zero quantity"],
        0,
        "Locked asset",
        True,
        False,
        False,
        True,
        None,
    )

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "BSSET",
        1000,
        True,
        None,
        None,
        False,
        None,
        None,
        "LOCK",
        None,
        None,
        current_block_index,
    ) == (
        0,
        0.0,
        ["cannot lock a non‐existent asset"],
        50000000,
        "LOCK",
        True,
        False,
        False,
        False,
        None,
    )

    # Now it's possible to issue and transfer simultaneously
    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["addresses"][1],
        "BSSET",
        1000,
        True,
        None,
        None,
        False,
        None,
        None,
        "",
        None,
        None,
        current_block_index,
    ) == (0, 0.0, [], 50000000, "", True, False, False, False, None)

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][2],
        None,
        "BSSET",
        1000,
        True,
        None,
        None,
        False,
        None,
        None,
        "",
        None,
        None,
        current_block_index,
    ) == (
        0,
        0.0,
        ["insufficient funds"],
        50000000,
        "",
        True,
        False,
        False,
        False,
        None,
    )

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "BSSET",
        2**63,
        True,
        None,
        None,
        False,
        None,
        None,
        "",
        None,
        None,
        current_block_index,
    ) == (
        0,
        0.0,
        ["total quantity overflow", "integer overflow"],
        50000000,
        "",
        True,
        False,
        False,
        False,
        None,
    )

    # Now it's possible to issue and transfer simultaneously
    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        defaults["addresses"][1],
        "DIVISIBLE",
        1000,
        True,
        None,
        None,
        False,
        None,
        None,
        "Divisible asset",
        None,
        None,
        current_block_index,
    ) == (0, 0.0, [], 0, "Divisible asset", True, False, False, True, None)

    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "MAXIMUM",
        2**63 - 1,
        True,
        None,
        None,
        False,
        None,
        None,
        "Maximum quantity",
        None,
        None,
        current_block_index,
    ) == (
        0,
        0.0,
        [],
        50000000,
        "Maximum quantity",
        True,
        False,
        False,
        False,
        None,
    )
    # total + quantity has to be lower than MAX_INT",
    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "DIVISIBLE",
        2**63 - 1,
        True,
        None,
        None,
        False,
        None,
        None,
        "Maximum quantity",
        None,
        None,
        current_block_index,
    ) == (
        0,
        0.0,
        ["total quantity overflow"],
        0,
        "Maximum quantity",
        True,
        False,
        False,
        True,
        None,
    )

    # "mock_protocol_changes": {"free_subassets": False},
    with ProtocolChangesDisabled(["free_subassets"]):
        assert issuance.validate(
            ledger_db,
            defaults["addresses"][0],
            None,
            f"A{26**12 + 1}",
            1000,
            True,
            None,
            None,
            False,
            None,
            None,
            "description",
            "NOTFOUND",
            "NOTFOUND.child1",
            current_block_index,
        ) == (
            0,
            0.0,
            ["parent asset not found"],
            25000000,
            "description",
            True,
            False,
            False,
            False,
            None,
        )

    # "mock_protocol_changes": {"free_subassets": False},
    with ProtocolChangesDisabled(["free_subassets"]):
        assert issuance.validate(
            ledger_db,
            defaults["addresses"][1],
            None,
            f"A{26**12 + 1}",
            100000000,
            True,
            None,
            None,
            False,
            None,
            None,
            "description",
            "PARENT",
            "PARENT.child1",
            current_block_index,
        ) == (
            0,
            0.0,
            ["parent asset owned by another address"],
            25000000,
            "description",
            True,
            False,
            False,
            False,
            None,
        )

    # "mock_protocol_changes": {"free_subassets": False},
    with ProtocolChangesDisabled(["free_subassets"]):
        assert issuance.validate(
            ledger_db,
            defaults["addresses"][0],
            None,
            f"A{26**12 + 1}",
            100000000,
            True,
            None,
            None,
            False,
            None,
            None,
            "description",
            "NOTFOUND",
            "NOTFOUND.child1",
            current_block_index,
        ) == (
            0,
            0.0,
            ["parent asset not found"],
            25000000,
            "description",
            True,
            False,
            False,
            False,
            None,
        )

    # "mock_protocol_changes": {"free_subassets": False},
    # A subasset name must be unique
    with ProtocolChangesDisabled(["free_subassets"]):
        assert issuance.validate(
            ledger_db,
            defaults["addresses"][0],
            None,
            f"A{26**12 + 1}",
            100000000,
            True,
            None,
            None,
            False,
            None,
            None,
            "description",
            "PARENT",
            "PARENT.already.issued",
            current_block_index,
        ) == (
            0,
            0.0,
            ["subasset already exists"],
            25000000,
            "description",
            True,
            False,
            False,
            False,
            None,
        )

    asset_name = ledger_db.execute(
        "SELECT asset FROM issuances WHERE asset_longname = ? LIMIT 1",
        ("PARENT.already.issued",),
    ).fetchone()["asset"]
    # cannot change subasset name through a reissuance description modification
    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        asset_name,
        200000000,
        True,
        None,
        None,
        False,
        None,
        None,
        "description",
        "PARENT",
        "PARENT.changed.name",
        current_block_index,
    ) == (
        0,
        0.0,
        [],
        0,
        "description",
        True,
        False,
        False,
        True,
        "PARENT.already.issued",
    )

    # "mock_protocol_changes": {"free_subassets": False},
    with ProtocolChangesDisabled(["free_subassets"]):
        assert issuance.validate(
            ledger_db,
            defaults["addresses"][0],
            None,
            "UNRELATED",
            1000,
            True,
            None,
            None,
            False,
            None,
            None,
            "description",
            "PARENT",
            "PARENT.child1",
            current_block_index,
        ) == (
            0,
            0.0,
            ["a subasset must be a numeric asset"],
            25000000,
            "description",
            True,
            False,
            False,
            False,
            None,
        )
    # subassets are free after protocol change
    assert issuance.validate(
        ledger_db,
        defaults["addresses"][0],
        None,
        "UNRELATED",
        1000,
        True,
        None,
        None,
        False,
        None,
        None,
        "description",
        "PARENT",
        "PARENT.child1",
        current_block_index,
    ) == (
        0,
        0.0,
        ["a subasset must be a numeric asset"],
        0,
        "description",
        True,
        False,
        False,
        False,
        None,
    )

    # before protocol change, reissuing a quantity of a locked asset was allowed if the description was changed
    # allow reissuance of locked asset before fix
    # "mock_protocol_changes": {"issuance_lock_fix": False},
    with ProtocolChangesDisabled(["issuance_lock_fix"]):
        assert issuance.validate(
            ledger_db,
            defaults["addresses"][6],
            None,
            "LOCKEDPREV",
            1000,
            True,
            None,
            None,
            False,
            None,
            None,
            "Locked prev",
            None,
            None,
            current_block_index,
        ) == (0, 0.0, [], 0, "Locked prev", True, False, False, True, None)

    # "comment": "disallow reissuance of locked asset after fix",
    # "mock_protocol_changes": {"issuance_lock_fix": True},
    assert issuance.validate(
        ledger_db,
        defaults["addresses"][6],
        None,
        "LOCKEDPREV",
        1000,
        True,
        None,
        None,
        False,
        None,
        None,
        "Locked prev",
        None,
        None,
        current_block_index,
    ) == (
        0,
        0.0,
        ["locked asset and non‐zero quantity"],
        0,
        "Locked prev",
        True,
        False,
        False,
        True,
        None,
    )


def test_valid_compose(ledger_db, defaults):
    assert issuance.compose(
        ledger_db, defaults["addresses"][0], "BSSET", 1000, None, True, False, None, ""
    ) == (
        defaults["addresses"][0],
        [],
        b"\x16\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00",
    )

    assert issuance.compose(
        ledger_db, defaults["addresses"][0], "BASSET", 1000, None, True, False, None, ""
    ) == (
        defaults["addresses"][0],
        [],
        b"\x16\x00\x00\x00\x00\x00\xbaOs\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00",
    )

    assert issuance.compose(
        ledger_db, defaults["p2sh_addresses"][0], "BSSET", 1000, None, True, False, None, ""
    ) == (
        defaults["p2sh_addresses"][0],
        [],
        b"\x16\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00",
    )

    assert issuance.compose(
        ledger_db,
        defaults["addresses"][0],
        "BSSET",
        1000,
        None,
        True,
        False,
        None,
        "description much much much longer than 42 letters",
    ) == (
        defaults["addresses"][0],
        [],
        b"\x16\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00description much much much longer than 42 letters",
    )

    assert issuance.compose(
        ledger_db,
        defaults["addresses"][0],
        "DIVISIBLE",
        0,
        defaults["addresses"][1],
        True,
        False,
        None,
        "",
    ) == (
        defaults["addresses"][0],
        [(defaults["addresses"][1], None)],
        b"\x16\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00",
    )

    assert issuance.compose(
        ledger_db, defaults["p2ms_addresses"][0], "BSSET", 1000, None, True, False, None, ""
    ) == (
        defaults["p2ms_addresses"][0],
        [],
        b"\x16\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00",
    )

    assert issuance.compose(
        ledger_db,
        defaults["addresses"][0],
        "DIVISIBLE",
        0,
        defaults["p2ms_addresses"][0],
        True,
        False,
        None,
        "",
    ) == (
        defaults["addresses"][0],
        [
            (
                defaults["p2ms_addresses"][0],
                None,
            )
        ],
        b"\x16\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00",
    )

    assert issuance.compose(
        ledger_db,
        defaults["addresses"][0],
        "MAXIMUM",
        2**63 - 1,
        None,
        True,
        False,
        None,
        "Maximum quantity",
    ) == (
        defaults["addresses"][0],
        [],
        b"\x16\x00\x00\x00\x00\xdd\x96\xd2t\x7f\xff\xff\xff\xff\xff\xff\xff\x01\x00\x00Maximum quantity",
    )

    assert issuance.compose(
        ledger_db, defaults["addresses"][0], f"A{2**64 - 1}", 1000, None, None, False, None, None
    ) == (
        defaults["addresses"][0],
        [],
        b"\x16\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\xc0NULL",
    )

    assert issuance.compose(
        ledger_db, defaults["addresses"][0], "PARENT.child1", 100000000, None, True, False, None, ""
    ) == (
        defaults["addresses"][0],
        [],
        b"\x17\x01S\x08!\xa2\xab/\x85\x00\x00\x00\x00\x05\xf5\xe1\x00\x01\x00\x00\nW\xc6\xf3m\xe2:\x1f_LF",
    )

    assert issuance.compose(
        ledger_db,
        defaults["addresses"][0],
        "PARENT.child1",
        100000000,
        None,
        True,
        False,
        None,
        "hello world",
    ) == (
        defaults["addresses"][0],
        [],
        b"\x17\x01S\x08!\xa2\xab/\x85\x00\x00\x00\x00\x05\xf5\xe1\x00\x01\x00\x00\nW\xc6\xf3m\xe2:\x1f_LFhello world",
    )

    assert issuance.compose(
        ledger_db, defaults["addresses"][0], "PARENT.a.b.c", 1000, None, True, False, None, ""
    ) == (
        defaults["addresses"][0],
        [],
        b"\x17\x01S\x08!\xeb[\xcc\x88\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\n\x01Jt\x85aq\xca<U\x9f",
    )
    assert issuance.compose(
        ledger_db,
        defaults["addresses"][0],
        "PARENT.a-zA-Z0-9.-_@!",
        1000,
        None,
        True,
        False,
        None,
        "",
    ) == (
        defaults["addresses"][0],
        [],
        b"\x17\x01S\x08!\x8fXk\xb0\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x10\x8e\x90\xa5}\xba\x99\xd3\xa7{\n$p\xb1\x81n\xdb",
    )

    assert issuance.compose(
        ledger_db,
        defaults["addresses"][0],
        "PARENT.already.issued",
        1000,
        None,
        True,
        False,
        None,
        "",
    ) == (
        defaults["addresses"][0],
        [],
        b'\x16\x01S\x08"\x06\xe4c%\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00',
    )

    # "mock_protocol_changes": {"short_tx_type_id": True},
    assert issuance.compose(
        ledger_db, defaults["addresses"][0], "PARENT.child1", 100000000, None, True, False, None, ""
    ) == (
        defaults["addresses"][0],
        [],
        b"\x17\x01S\x08!\xa2\xab/\x85\x00\x00\x00\x00\x05\xf5\xe1\x00\x01\x00\x00\nW\xc6\xf3m\xe2:\x1f_LF",
    )

    assert issuance.compose(
        ledger_db,
        defaults["addresses"][0],
        f"A{26**12 + 101}",
        200000000,
        None,
        True,
        None,
        None,
        "description",
    ) == (
        defaults["addresses"][0],
        [],
        b"\x16\x01S\x08!g\x1b\x10e\x00\x00\x00\x00\x0b\xeb\xc2\x00\x01\x00\x00description",
    )

    assert issuance.compose(
        ledger_db,
        defaults["addresses"][0],
        "DIVISIBLEB",
        0,
        defaults["addresses"][1],
        True,
        False,
        None,
        "second divisible asset",
    ) == (
        defaults["addresses"][0],
        [(defaults["addresses"][1], None)],
        b"\x16\x00\x00\x10}U\x15\xa8]\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00second divisible asset",
    )

    assert issuance.compose(
        ledger_db,
        defaults["addresses"][0],
        "DIVISIBLEC",
        0,
        None,
        True,
        True,
        None,
        "third divisible asset",
    ) == (
        defaults["addresses"][0],
        [],
        b"\x16\x00\x00\x10}U\x15\xa8^\x00\x00\x00\x00\x00\x00\x00\x00\x01\x01\x00third divisible asset",
    )


def test_invalid_compose(ledger_db, defaults):
    with pytest.raises(exceptions.AssetNameError, match="non‐numeric asset name starts with ‘A’"):
        issuance.compose(
            ledger_db, defaults["addresses"][0], "ASSET", 1000, None, True, False, None, ""
        )

    with pytest.raises(exceptions.AssetNameError, match=str(("invalid character:", "1"))):
        issuance.compose(
            ledger_db, defaults["addresses"][0], "BSSET1", 1000, None, True, False, None, ""
        )

    with pytest.raises(exceptions.AssetNameError, match="too short"):
        issuance.compose(
            ledger_db, defaults["addresses"][0], "SET", 1000, None, True, False, None, ""
        )

    # "mock_protocol_changes": {"allow_subassets_on_numerics": False},
    with ProtocolChangesDisabled(["allow_subassets_on_numerics"]):
        with pytest.raises(exceptions.AssetNameError, match="parent asset name starts with 'A'"):
            issuance.compose(
                ledger_db,
                defaults["addresses"][0],
                "A9542895.subasset",
                1000,
                None,
                True,
                False,
                None,
                "",
            )

    with pytest.raises(exceptions.ComposeError, match="parent asset not foun"):
        issuance.compose(
            ledger_db,
            defaults["addresses"][0],
            "A95428956661682177.subasset",
            1000,
            None,
            True,
            False,
            None,
            "",
        )

    with pytest.raises(exceptions.AssetNameError, match="numeric asset name not in range"):
        issuance.compose(
            ledger_db, defaults["addresses"][0], f"A{2**64}", 1000, None, True, False, None, ""
        )

    with pytest.raises(exceptions.AssetNameError, match="numeric asset name not in range"):
        issuance.compose(
            ledger_db, defaults["addresses"][0], f"A{26**12}", 1000, None, True, False, None, ""
        )

    with pytest.raises(
        exceptions.AssetNameError, match="parent asset name contains invalid character:"
    ):
        (
            issuance.compose(
                ledger_db,
                defaults["addresses"][0],
                "BADASSETx.child1",
                1000,
                None,
                True,
                False,
                None,
                "",
            ),
        )

    with pytest.raises(exceptions.ComposeError, match="parent asset owned by another address"):
        issuance.compose(
            ledger_db, defaults["addresses"][1], "PARENT.child1", 1000, None, True, False, None, ""
        )


def test_parse_basset(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"\x00\x00\x00\x00\x00\xbaOs\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00"
    issuance.parse(ledger_db, tx, message, issuance.ID)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "issuances",
                "values": {
                    "asset": "BASSET",
                    "block_index": tx["block_index"],
                    "description": "",
                    "divisible": 1,
                    "fee_paid": 50000000,
                    "issuer": defaults["addresses"][0],
                    "locked": 0,
                    "quantity": 1000,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "transfer": 0,
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                    "asset_longname": None,
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][0],
                    "asset": "BASSET",
                    "block_index": current_block_index,
                    "calling_function": "issuance",
                    "event": tx["tx_hash"],
                    "quantity": 1000,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "issuance fee",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 50000000,
                },
            },
        ],
    )


def test_parse_divisibleb(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = (
        b"\x00\x00\x10}U\x15\xa8]\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00second divisible asset"
    )
    issuance.parse(ledger_db, tx, message, issuance.ID)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "issuances",
                "values": {
                    "asset": "DIVISIBLEB",
                    "asset_longname": None,
                    "block_index": tx["block_index"],
                    "description": "second divisible asset",
                    "divisible": 1,
                    "fee_paid": 50000000,
                    "issuer": defaults["addresses"][0],
                    "locked": 0,
                    "quantity": 0,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "transfer": False,
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            }
        ],
    )


def test_parse_divisiblec(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = (
        b"\x00\x00\x10}U\x15\xa8^\x00\x00\x00\x00\x00\x00\x00\x00\x01\x01\x00third divisible asset"
    )
    issuance.parse(ledger_db, tx, message, issuance.ID)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "issuances",
                "values": {
                    "asset": "DIVISIBLEC",
                    "asset_longname": None,
                    "block_index": tx["block_index"],
                    "description": "third divisible asset",
                    "divisible": 1,
                    "fee_paid": 50000000,
                    "issuer": defaults["addresses"][0],
                    "locked": True,
                    "quantity": 0,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "transfer": False,
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            }
        ],
    )


def test_parse_bsset(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["p2ms_addresses"][0])
    message = b"\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00"
    issuance.parse(ledger_db, tx, message, issuance.ID)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "issuances",
                "values": {
                    "asset": "BSSET",
                    "asset_longname": None,
                    "block_index": tx["block_index"],
                    "description": "",
                    "divisible": 1,
                    "fee_paid": 50000000,
                    "issuer": defaults["p2ms_addresses"][0],
                    "locked": 0,
                    "quantity": 1000,
                    "source": defaults["p2ms_addresses"][0],
                    "status": "valid",
                    "transfer": 0,
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["p2ms_addresses"][0],
                    "asset": "BSSET",
                    "block_index": current_block_index,
                    "calling_function": "issuance",
                    "event": tx["tx_hash"],
                    "quantity": 1000,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "issuance fee",
                    "address": defaults["p2ms_addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 50000000,
                },
            },
        ],
    )


def test_parse_divisible(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], defaults["p2ms_addresses"][0]
    )
    message = b"\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00"
    issuance.parse(ledger_db, tx, message, issuance.ID)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "issuances",
                "values": {
                    "asset": "DIVISIBLE",
                    "asset_longname": None,
                    "block_index": tx["block_index"],
                    "description": "",
                    "divisible": 1,
                    "fee_paid": 0,
                    "issuer": defaults["p2ms_addresses"][0],
                    "locked": 0,
                    "quantity": 0,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "transfer": True,
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "issuance fee",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 0,
                },
            },
        ],
    )


def test_parse_maximum(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = (
        b"\x00\x00\x00\x00\xdd\x96\xd2t\x7f\xff\xff\xff\xff\xff\xff\xff\x01\x00\x00Maximum quantity"
    )
    issuance.parse(ledger_db, tx, message, issuance.ID)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "issuances",
                "values": {
                    "asset": "MAXIMUM",
                    "asset_longname": None,
                    "block_index": tx["block_index"],
                    "description": "Maximum quantity",
                    "fee_paid": 50000000,
                    "issuer": defaults["addresses"][0],
                    "locked": 0,
                    "quantity": 9223372036854775807,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "transfer": 0,
                    "divisible": 1,
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][0],
                    "asset": "MAXIMUM",
                    "block_index": current_block_index,
                    "calling_function": "issuance",
                    "event": tx["tx_hash"],
                    "quantity": 9223372036854775807,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "issuance fee",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 50000000,
                },
            },
        ],
    )


def test_parse_numeric(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = (
        b"\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\xc0NULL"
    )
    issuance.parse(ledger_db, tx, message, issuance.ID)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "issuances",
                "values": {
                    "asset": "A18446744073709551615",
                    "asset_longname": None,
                    "block_index": tx["block_index"],
                    "description": "",
                    "divisible": 1,
                    "fee_paid": 0,
                    "issuer": defaults["addresses"][0],
                    "locked": 0,
                    "quantity": 1000,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "transfer": 0,
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][0],
                    "asset": "A18446744073709551615",
                    "block_index": current_block_index,
                    "calling_function": "issuance",
                    "event": tx["tx_hash"],
                    "quantity": 1000,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "issuance fee",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 0,
                },
            },
        ],
    )


def test_parse_too_short(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = binascii.unhexlify("00000000000002bf0000000005f5e10001")
    issuance.parse(ledger_db, tx, message, issuance.ID)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "issuances",
                "values": {
                    "asset": None,
                    "asset_longname": None,
                    "block_index": tx["block_index"],
                    "description": None,
                    "fee_paid": 0,
                    "issuer": defaults["addresses"][0],
                    "locked": 0,
                    "quantity": None,
                    "source": defaults["addresses"][0],
                    "status": "invalid: bad asset name",
                    "transfer": 0,
                    "divisible": None,
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            }
        ],
    )


def test_parse_paid_subasset(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"\x01S\x08!\xa2\xab/\x85\x00\x00\x00\x00\x05\xf5\xe1\x00\x01\x00\x00\nW\xc6\xf3m\xe2:\x1f_LF"
    with ProtocolChangesDisabled(["free_subassets"]):
        issuance.parse(ledger_db, tx, message, issuance.SUBASSET_ID)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "issuances",
                "values": {
                    "asset": "A95428957660983173",
                    "asset_longname": "PARENT.child1",
                    "block_index": tx["block_index"],
                    "description": "",
                    "fee_paid": 25000000,
                    "issuer": defaults["addresses"][0],
                    "locked": 0,
                    "quantity": 100000000,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "transfer": 0,
                    "divisible": 1,
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][0],
                    "asset": "A95428957660983173",
                    "block_index": current_block_index,
                    "calling_function": "issuance",
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "issuance fee",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 25000000,
                },
            },
            {
                "table": "assets",
                "values": {
                    "asset_id": "95428957660983173",
                    "asset_name": "A95428957660983173",
                    "block_index": tx["block_index"],
                    "asset_longname": "PARENT.child1",
                },
            },
        ],
    )


def test_parse_paid_subasset_with_description(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"\x01S\x08!\xa2\xab/\x85\x00\x00\x00\x00\x05\xf5\xe1\x00\x01\x00\x00\nW\xc6\xf3m\xe2:\x1f_LFhello world"
    with ProtocolChangesDisabled(["free_subassets"]):
        issuance.parse(ledger_db, tx, message, issuance.SUBASSET_ID)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "issuances",
                "values": {
                    "asset": "A95428957660983173",
                    "asset_longname": "PARENT.child1",
                    "block_index": tx["block_index"],
                    "description": "hello world",
                    "fee_paid": 25000000,
                    "issuer": defaults["addresses"][0],
                    "locked": 0,
                    "quantity": 100000000,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "transfer": 0,
                    "divisible": 1,
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][0],
                    "asset": "A95428957660983173",
                    "block_index": current_block_index,
                    "calling_function": "issuance",
                    "event": tx["tx_hash"],
                    "quantity": 100000000,
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "issuance fee",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": 25000000,
                },
            },
            {
                "table": "assets",
                "values": {
                    "asset_id": "95428957660983173",
                    "asset_name": "A95428957660983173",
                    "block_index": tx["block_index"],
                    "asset_longname": "PARENT.child1",
                },
            },
        ],
    )
