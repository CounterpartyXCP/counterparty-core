import re

import cbor2
import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.messages.versions import enhancedsend
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_compose(ledger_db, defaults):
    assert enhancedsend.compose(
        ledger_db, defaults["addresses"][0], defaults["addresses"][1], "XCP", 1000, "memo", False
    ) == (
        defaults["addresses"][0],
        [],
        b"\x02\x84\x01\x19\x03\xe8U\x01\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xecDmemo",
    )

    assert enhancedsend.compose(
        ledger_db,
        defaults["p2tr_addresses"][0],
        defaults["p2tr_addresses"][1],
        "XCP",
        1000,
        "abcdef",
        True,
        True,  # skip validation
    ) == (
        defaults["p2tr_addresses"][0],
        [],
        b'\x02\x84\x01\x19\x03\xe8X"\x03\x01qe0u\xb3n\xe3\xd25\x1bU\x81\xd9\xb9\x90W!\xcb\xfe`\xb7\x1c\xe2%\x01\xe1\xb4N\xd0:\x96\x84C\xab\xcd\xef',
    )

    with ProtocolChangesDisabled(["taproot_support"]):
        assert enhancedsend.compose(
            ledger_db,
            defaults["addresses"][0],
            defaults["addresses"][1],
            "XCP",
            1000,
            "memo",
            False,
        ) == (
            defaults["addresses"][0],
            [],
            b"\x02\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x03\xe8o\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xecmemo",
        )

        with pytest.raises(
            exceptions.AddressError,
            match=re.escape(
                f"The address {defaults['p2tr_addresses'][1]} is not a valid bitcoin address (regtest)"
            ),
        ):
            enhancedsend.compose(
                ledger_db,
                defaults["p2tr_addresses"][0],
                defaults["p2tr_addresses"][1],
                "XCP",
                1000,
                "abcdef",
                True,
                True,  # skip validation
            )


def test_compose_rejects_overflow_quantity_with_skip_validation(ledger_db, defaults):
    with pytest.raises(exceptions.ComposeError, match="integer overflow"):
        enhancedsend.compose(
            ledger_db,
            defaults["addresses"][0],
            defaults["addresses"][1],
            "XCP",
            config.MAX_INT + 1,
            None,
            False,
            True,  # skip validation
        )

    with ProtocolChangesDisabled(["taproot_support"]):
        with pytest.raises(exceptions.ComposeError, match="integer overflow"):
            enhancedsend.compose(
                ledger_db,
                defaults["addresses"][0],
                defaults["addresses"][1],
                "XCP",
                config.MAX_INT + 1,
                None,
                False,
                True,  # skip validation
            )


def test_compose_rejects_overflow_btc_quantity(ledger_db, defaults):
    with pytest.raises(exceptions.ComposeError, match="integer overflow"):
        enhancedsend.compose(
            ledger_db,
            defaults["addresses"][0],
            defaults["addresses"][1],
            "BTC",
            config.MAX_INT + 1,
            None,
            False,
            True,  # skip validation
            True,  # no dispense
        )


def test_compose_rejects_non_boolean_memo_is_hex(ledger_db, defaults):
    with pytest.raises(exceptions.ComposeError, match="`memo_is_hex` must be a boolean"):
        enhancedsend.compose(
            ledger_db,
            defaults["addresses"][0],
            defaults["addresses"][1],
            "XCP",
            1000,
            "abcdef",
            "true",
        )


def test_unpack(ledger_db, defaults):
    assert enhancedsend.unpack(
        b"\x84\x01\x19\x03\xe8U\x01\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xecDmemo"
    ) == {"asset": "XCP", "quantity": 1000, "address": defaults["addresses"][1], "memo": b"memo"}

    assert enhancedsend.new_unpack(
        b"\x84\x01\x19\x03\xe8U\x01\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xecDmemo"
    ) == {"asset": "XCP", "quantity": 1000, "address": defaults["addresses"][1], "memo": b"memo"}

    assert enhancedsend.unpack(
        b'\x84\x01\x19\x03\xe8X"\x03\x01qe0u\xb3n\xe3\xd25\x1bU\x81\xd9\xb9\x90W!\xcb\xfe`\xb7\x1c\xe2%\x01\xe1\xb4N\xd0:\x96\x84C\xab\xcd\xef'
    ) == {
        "asset": "XCP",
        "quantity": 1000,
        "address": defaults["p2tr_addresses"][1],
        "memo": b"\xab\xcd\xef",
    }

    assert enhancedsend.unpack(
        b'x02\xe8\x03"\x03\x01qe0u\xb3n\xe3\xd25\x1bU\x81\xd9\xb9\x90W!\xcb\xfe`\xb7\x1c\xe2%\x01\xe1\xb4N\xd0:\x96'
    ) == {
        "address": "NNQVs5hJBSVwDH4nY4A1LMHDviwwCbXPCV",
        "asset": "A8660478055499825921",
        "memo": b":\x96",
        "quantity": 8170990381013328850,
    }

    with pytest.raises(exceptions.UnpackError, match="invalid message length"):
        enhancedsend.unpack(
            b"\x84\x00\x19\x03\xe8U\x01\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xecDmemo"
        )

    with pytest.raises(exceptions.UnpackError, match="could not unpack"):
        result = enhancedsend.unpack(
            "x02\xe1\xb4N\xd0:\x96x02\xe1\xb4N\xd0:\x96x02\xe1\xb4N\xd0:\x96x02\xe1\xb4N\xd0:\x96a"
        )

    with ProtocolChangesDisabled(["taproot_support"]):
        with pytest.raises(exceptions.UnpackError, match="could not unpack"):
            result = enhancedsend.unpack(
                "x02\xe1\xb4N\xd0:\x96x02\xe1\xb4N\xd0:\x96x02\xe1\xb4N\xd0:\x96x02\xe1\xb4N\xd0:\x96a"
            )
            print(result)


def test_unpack_with_block_index_falls_back_when_taproot_off(ledger_db, defaults):
    """When taproot_support is gated off via block_index, unpack falls back
    to the legacy struct path; an arbitrary CBOR message that has the wrong
    length for the legacy fixed-size FORMAT raises UnpackError."""
    # A short payload that has neither the right length for the legacy
    # struct nor a valid CBOR-decodable shape
    short_message = b"\x84\x00"
    with pytest.raises(exceptions.UnpackError):
        enhancedsend.unpack(short_message, block_index=1)


def test_unpack_with_block_index_uses_cbor_when_taproot_on(ledger_db, defaults):
    """Late block index -> taproot_support active -> CBOR path used."""
    cbor_message = cbor2.dumps(
        [1, 1000, b"\x00" + bytes.fromhex("8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec"), b""]
    )
    # Use a high block_index where taproot_support is active in the test fixture
    result = enhancedsend.unpack(cbor_message, block_index=10**8)
    assert result["asset"] == "XCP"
    assert result["quantity"] == 1000


def test_validate_rejects_non_bytes_memo(ledger_db, defaults):
    """CBOR-encoded messages can supply any type for memo; validate must
    reject anything that isn't bytes-like before calling len()."""
    problems = enhancedsend.validate(
        ledger_db,
        defaults["addresses"][1],
        "XCP",
        1000,
        memo_bytes=12345,
    )
    assert "memo must be bytes" in problems


def test_validate_rejects_non_int_quantity(ledger_db, defaults):
    """quantity must be int; CBOR can supply float/str."""
    problems = enhancedsend.validate(
        ledger_db,
        defaults["addresses"][1],
        "XCP",
        "not-an-int",
        memo_bytes=None,
    )
    assert "quantity must be in satoshis" in problems


def test_validate_rejects_zero_quantity(ledger_db, defaults):
    problems = enhancedsend.validate(ledger_db, defaults["addresses"][1], "XCP", 0, memo_bytes=None)
    assert "zero quantity" in problems


def test_validate_rejects_negative_quantity(ledger_db, defaults):
    problems = enhancedsend.validate(
        ledger_db, defaults["addresses"][1], "XCP", -100, memo_bytes=None
    )
    assert "negative quantity" in problems


def test_validate_rejects_btc(ledger_db, defaults):
    problems = enhancedsend.validate(
        ledger_db, defaults["addresses"][1], config.BTC, 1000, memo_bytes=None
    )
    assert any("cannot send" in p for p in problems)


def test_validate_rejects_missing_destination(ledger_db):
    """destination is required by validate."""
    problems = enhancedsend.validate(ledger_db, "", "XCP", 1000, memo_bytes=None)
    assert "destination is required" in problems


def test_validate_rejects_overflowing_quantity(ledger_db, defaults):
    problems = enhancedsend.validate(
        ledger_db,
        defaults["addresses"][1],
        "XCP",
        config.MAX_INT + 1,
        memo_bytes=None,
    )
    assert "integer overflow" in problems


def test_validate_rejects_memo_too_long(ledger_db, defaults):
    problems = enhancedsend.validate(
        ledger_db,
        defaults["addresses"][1],
        "XCP",
        1000,
        memo_bytes=b"x" * 100,
    )
    assert "memo is too long" in problems
