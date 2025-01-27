import binascii

from counterpartycore.lib.parser import messagetype
from counterpartycore.pytest.mocks.counterpartydbs import ProtocolChangesDisabled


def test_unpack():
    assert messagetype.unpack(binascii.unhexlify("01deadbeef"), 310502) == (
        1,
        binascii.unhexlify("deadbeef"),
    )
    assert messagetype.unpack(binascii.unhexlify("02deadbeef"), 310502) == (
        2,
        binascii.unhexlify("deadbeef"),
    )
    assert messagetype.unpack(binascii.unhexlify("00000001deadbeef"), 310502) == (
        1,
        binascii.unhexlify("deadbeef"),
    )
    assert messagetype.unpack(binascii.unhexlify("00000000deadbeef"), 310502) == (
        0,
        binascii.unhexlify("deadbeef"),
    )
    assert messagetype.unpack(binascii.unhexlify("00"), 310502) == (None, None)
    assert messagetype.unpack(b"f0", 310502) == (102, b"0")


def test_pack():
    with ProtocolChangesDisabled(["short_tx_type_id"]):
        assert messagetype.pack(0, 300000) == binascii.unhexlify("00000000")
        assert messagetype.pack(1, 300000) == binascii.unhexlify("00000001")
        assert messagetype.pack(0, 310502) == binascii.unhexlify("00000000")

    assert messagetype.pack(1, 310502) == binascii.unhexlify("01")
    assert messagetype.pack(2, 310502) == binascii.unhexlify("02")
