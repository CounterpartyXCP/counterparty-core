import re

import pytest
from counterpartycore.lib import exceptions
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
