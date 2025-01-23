import binascii

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
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [],
        b"\x16\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00",
    )

    assert issuance.compose(
        ledger_db, defaults["addresses"][0], "BASSET", 1000, None, True, False, None, ""
    ) == (
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
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
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
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
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
        b"\x00\x00\x00\x16\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert issuance.compose(
        ledger_db, defaults["p2ms_addresses"][0], "BSSET", 1000, None, True, False, None, ""
    ) == (
        "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
        [],
        b"\x16\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00",
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
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [
            (
                "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
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
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [],
        b"\x16\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00",
    )

    assert issuance.compose(
        ledger_db, defaults["addresses"][0], f"A{2**64 - 1}", 1000, None, None, False, None, None
    ) == (
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [],
        b"\x16\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00",
    )

    assert issuance.compose(
        ledger_db, defaults["addresses"][0], "PARENT.child1", 100000000, None, True, False, None, ""
    ) == (
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [],
        binascii.unhexlify("0000001701530821671b10010000000005f5e100010a57c6f36de23a1f5f4c46"),
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
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [],
        binascii.unhexlify(
            "0000001701530821671b10010000000005f5e100010a57c6f36de23a1f5f4c4668656c6c6f20776f726c64"
        ),
    )

    assert issuance.compose(
        ledger_db, defaults["addresses"][0], "PARENT.a.b.c", 1000, None, True, False, None, ""
    ) == (
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [],
        binascii.unhexlify("0000001701530821671b100100000000000003e8010a014a74856171ca3c559f"),
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
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [],
        binascii.unhexlify(
            "0000001701530821671b100100000000000003e801108e90a57dba99d3a77b0a2470b1816edb"
        ),
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
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [],
        b"\x00\x00\x00\x16\x01S\x08!g\x1b\x10e\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    # "mock_protocol_changes": {"short_tx_type_id": True},
    assert issuance.compose(
        ledger_db, defaults["addresses"][0], "PARENT.child1", 100000000, None, True, False, None, ""
    ) == (
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [],
        binascii.unhexlify("1701530821671b10010000000005f5e100010a57c6f36de23a1f5f4c46"),
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
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [],
        b"\x00\x00\x00\x16\x01S\x08!g\x1b\x10e\x00\x00\x00\x00\x0b\xeb\xc2\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00description",
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
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
        b"\x00\x00\x00\x16\x00\x00\x10}U\x15\xa8]\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00second divisible asset",
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
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        [],
        b"\x00\x00\x00\x16\x00\x00\x10}U\x15\xa8^\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00third divisible asset",
    )
