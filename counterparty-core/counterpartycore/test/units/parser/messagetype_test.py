import binascii

from counterpartycore.lib import config
from counterpartycore.lib.parser import messagetype
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


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


def test_get_transaction_type(monkeypatch, current_block_index):
    assert messagetype.get_transaction_type(b"CNTRPRTY00", "", [], current_block_index) == "unknown"
    assert (
        messagetype.get_transaction_type(b"[A95428957753448833|1", "", [], current_block_index)
        == "fairmint"
    )
    assert messagetype.get_transaction_type(None, "", ["txid:0"], current_block_index) == "utxomove"
    assert messagetype.get_transaction_type(None, "", [""], current_block_index) == "unknown"
    assert (
        messagetype.get_transaction_type(b"eXCPMEME|25000000000|", "", [], current_block_index)
        == "attach"
    )
    assert (
        messagetype.get_transaction_type(
            b"fbc1qcxlwq8x9fnhyhgywlnja35l7znt58tud9duqay", "", [], current_block_index
        )
        == "detach"
    )
    assert (
        messagetype.get_transaction_type(
            b"\x02\x00>\xc7\xd9>|n\x19\x00\x00\x00\x00\x00\x00\x00P\x00%?\x9e\x96I\xb3\xf9u\x15$\xb2\x90\xf93Pra\x0c\xcc\x01",
            "",
            [],
            current_block_index,
        )
        == "enhanced_send"
    )
    assert (
        messagetype.get_transaction_type(
            None, config.UNSPENDABLE_TESTNET3, [""], config.BURN_END - 1
        )
        == "burn"
    )
    assert (
        messagetype.get_transaction_type(
            None, config.UNSPENDABLE_TESTNET3, [""], config.BURN_END + 1
        )
        == "unknown"
    )

    def mock_get_change_block_index(change_name):
        if change_name == "dispensers":
            return current_block_index - 1
        if change_name == "disable_vanilla_btc_dispense":
            return current_block_index + 1
        return 0

    monkeypatch.setattr(
        "counterpartycore.lib.parser.protocol.get_change_block_index", mock_get_change_block_index
    )
    with ProtocolChangesDisabled(["utx_support"]):
        assert messagetype.get_transaction_type(None, "", [""], current_block_index) == "dispense"
