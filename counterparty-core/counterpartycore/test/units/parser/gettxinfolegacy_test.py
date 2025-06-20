import binascii

import pytest
from arc4 import ARC4
from bitcoinutils.script import Script
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.parser import deserialize, gettxinfolegacy
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_get_tx_info(current_block_index, blockchain_mock, monkeypatch):
    original_prefix = config.PREFIX
    config.PREFIX = b"TESTXXXX"
    config.ADDRESSVERSION = config.ADDRESSVERSION_TESTNET3

    blockchain_mock.source_by_txid[
        "e43c357b78baf473fd21cbc1481ac450746b60cf1d2702ce3a73a8811811e3eb"
    ] = "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns"

    def get_vin_info_mock_2(*args, **lwargs):
        op_checksig_script = "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
        return (10000, binascii.unhexlify(op_checksig_script), False)

    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.get_vin_info_legacy", get_vin_info_mock_2
    )

    assert gettxinfolegacy.get_tx_info_legacy(
        deserialize.deserialize_tx(
            "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0636150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac36150000000000001976a9147da51ea175f108a1c63588683dc4c43a7146c46788ac36150000000000001976a9147da51ea175f108a1c6358868173e34e8ca75a06788ac36150000000000001976a9147da51ea175f108a1c637729895c4c468ca75a06788ac36150000000000001976a9147fa51ea175f108a1c63588682ed4c468ca7fa06788ace24ff505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
    ) == (
        "mvThcDEbeqog2aJ7JNj1FefUPaNdYYGqHt",
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        5430,
        -99980000,
        b"\x00\x00\x00(\x00\x00R\xbb3d\x00TESTXXXX\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00TESTXXXX\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00TESTXXXX\x00\x00\x00;\x10\x00\x00\x00\n\x9b\xb3Q\x92(6\xc8\x86\x81i\x87\xe1\x0b\x03\xb8_8v\x8b",
        [],
    )
    config.PREFIX = original_prefix


def test_get_pubkeyhash(current_block_index, monkeypatch):
    assert gettxinfolegacy.get_pubkeyhash(
        "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac", current_block_index
    ) == (b"\xa3\xec`\xfbR/\xdfb\xc9\x0e\xec\x19\x81Wx\x13\xd8\xf8\xa5\x8a", config.ADDRESSVERSION)

    assert gettxinfolegacy.get_pubkeyhash(
        "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a", current_block_index
    ) == (None, None)

    script = "a9141f4dfe5d2bdc0778119a834591f8e441ee00ce77"
    assert gettxinfolegacy.get_pubkeyhash(script, current_block_index) == (None, None)

    with ProtocolChangesDisabled(["multisig_addresses"]):
        assert gettxinfolegacy.get_pubkeyhash(
            "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac", current_block_index
        ) == (
            b"\xa3\xec`\xfbR/\xdfb\xc9\x0e\xec\x19\x81Wx\x13\xd8\xf8\xa5\x8a",
            config.ADDRESSVERSION,
        )
        assert gettxinfolegacy.get_pubkeyhash(
            "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a", current_block_index
        ) == (None, None)

    monkeypatch.setattr("counterpartycore.lib.utils.script.script_to_asm", lambda x: [])
    script = ""
    assert gettxinfolegacy.get_pubkeyhash(script, current_block_index) == (None, None)


def test_get_address(current_block_index, monkeypatch):
    # "bcrt1q50kxp76j9l0k9jgwasvcz4mcz0v03fv2vmrn2u"
    scriptpubkey = b"\x00\x14" + b"\xa3\xec`\xfbR/\xdfb\xc9\x0e\xec\x19\x81Wx\x13\xd8\xf8\xa5\x8a"
    # gettxinfolegacy does not support bech32 addresses
    assert not gettxinfolegacy.get_address(scriptpubkey, current_block_index)

    scriptpubkey = "a9141f4dfe5d2bdc0778119a834591f8e441ee00ce77"
    assert not gettxinfolegacy.get_address(scriptpubkey, current_block_index)

    scriptpubkey = "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
    assert (
        gettxinfolegacy.get_address(scriptpubkey, current_block_index)
        == "mvThcDEbeqog2aJ7JNj1FefUPaNdYYGqHt"
    )

    monkeypatch.setattr(
        "counterpartycore.lib.utils.base58.base58_check_decode", lambda x, y: "foobar"
    )
    scriptpubkey = "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
    assert not gettxinfolegacy.get_address(scriptpubkey, current_block_index)


def test_get_tx_info_legacy_1(current_block_index, monkeypatch):
    with pytest.raises(exceptions.DecodeError, match="coinbase transaction"):
        gettxinfolegacy.get_tx_info_legacy({"coinbase": True}, current_block_index)

    def get_vin_info_mock_2(*args, **lwargs):
        op_checksig_script = "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
        return (10000, binascii.unhexlify(op_checksig_script), False)

    data = binascii.hexlify(config.PREFIX + b"hello world").decode("utf-8")
    script_pub_key = Script(["OP_RETURN", data]).to_hex()

    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.get_vin_info_legacy", get_vin_info_mock_2
    )

    assert gettxinfolegacy.get_tx_info_legacy(
        {
            "coinbase": False,
            "vout": [{"script_pub_key": script_pub_key, "value": 0}],
            "vin": [
                {"hash": "0000000000000000000000000000000000000000000000000000000000000000", "n": 0}
            ],
        },
        current_block_index,
    ) == ("mvThcDEbeqog2aJ7JNj1FefUPaNdYYGqHt", None, None, 10000, b"hello world", [])

    data = binascii.hexlify(b"0" + config.PREFIX + b"hello world").decode("utf-8")
    script_pub_key = Script([1, data, data, 2, "OP_CHECKMULTISIG"]).to_hex()
    assert gettxinfolegacy.get_tx_info_legacy(
        {
            "coinbase": False,
            "vout": [{"script_pub_key": script_pub_key, "value": 0}],
            "vin": [
                {"hash": "0000000000000000000000000000000000000000000000000000000000000000", "n": 0}
            ],
        },
        current_block_index,
    ) == ("mvThcDEbeqog2aJ7JNj1FefUPaNdYYGqHt", None, None, 10000, b"hello world", [])

    data = b"0" + config.PREFIX + b"hello world"
    data = ARC4(
        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
    ).encrypt(data)
    # data = binascii.hexlify(data).decode("utf-8")

    script_pub_key = Script(
        [
            "OP_DUP",  # noqa: F405
            "OP_HASH160",  # noqa: F405
            binascii.hexlify(data).decode("utf-8"),
            "OP_EQUALVERIFY",  # noqa: F405
            "OP_CHECKSIG",  # noqa: F405
        ]
    ).to_hex()

    monkeypatch.setattr(
        gettxinfolegacy, "get_pubkeyhash", lambda x, y: (data, config.ADDRESSVERSION)
    )

    assert gettxinfolegacy.get_tx_info_legacy(
        {
            "coinbase": False,
            "vout": [{"script_pub_key": script_pub_key, "value": 0}],
            "vin": [
                {"hash": "0000000000000000000000000000000000000000000000000000000000000000", "n": 0}
            ],
        },
        current_block_index,
    ) == ("n3FH4XxX1VA6MrdxZWYaKV2WV8bmSpyCG5", None, None, 10000, b"hello world", [])

    data = b"0" + config.PREFIX + b"h" + config.PREFIX
    data = ARC4(
        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
    ).encrypt(data)
    assert gettxinfolegacy.get_tx_info_legacy(
        {
            "coinbase": False,
            "vout": [{"script_pub_key": script_pub_key, "value": 0}],
            "vin": [
                {"hash": "0000000000000000000000000000000000000000000000000000000000000000", "n": 0}
            ],
        },
        current_block_index,
    ) == ("3K67HRYGcVmv6a4EhFi8Lbkz1HoVryTL", None, None, 10000, b"h", [])

    data = b"0" + config.PREFIX + config.PREFIX
    data = ARC4(
        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
    ).encrypt(data)
    with pytest.raises(exceptions.BTCOnlyError, match="no data and not unspendable"):
        gettxinfolegacy.get_tx_info_legacy(
            {
                "coinbase": False,
                "vout": [{"script_pub_key": script_pub_key, "value": 0}],
                "vin": [
                    {
                        "hash": "0000000000000000000000000000000000000000000000000000000000000000",
                        "n": 0,
                    }
                ],
            },
            current_block_index,
        )

    monkeypatch.setattr(
        gettxinfolegacy, "get_pubkeyhash", lambda x, y: (None, config.ADDRESSVERSION)
    )

    with pytest.raises(exceptions.DecodeError, match="no prefix"):
        assert gettxinfolegacy.get_tx_info_legacy(
            {
                "coinbase": False,
                "vout": [{"script_pub_key": script_pub_key, "value": 0}],
                "vin": [
                    {
                        "hash": "0000000000000000000000000000000000000000000000000000000000000000",
                        "n": 0,
                    }
                ],
            },
            current_block_index,
        ) == ("n3FH4XxX1VA6MrdxZWYaKV2WV8bmSpyCG5", None, None, 10000, b"hello world", [])


def test_get_tx_info_legacy_2(current_block_index, monkeypatch):
    def get_vin_info_mock_2(vins, **kwargs):
        op_checksig_script = "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
        return (10000, binascii.unhexlify(op_checksig_script), False)

    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.get_vin_info_legacy", get_vin_info_mock_2
    )

    assert gettxinfolegacy.get_tx_info_legacy(
        {
            "coinbase": False,
            "vout": [
                {"script_pub_key": "76a914a11b66a67b3ff69671c8f82254099faf374b800e88ac", "value": 0}
            ],
            "vin": [
                {"hash": "0000000000000000000000000000000000000000000000000000000000000000", "n": 0}
            ],
        },
        current_block_index,
    ) == (
        "mvThcDEbeqog2aJ7JNj1FefUPaNdYYGqHt",
        "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
        0,
        10000,
        b"",
        [],
    )

    original_get_address = gettxinfolegacy.get_address
    global count  # noqa: PLW0603
    count = 0

    def get_address_mock(*args, **kwargs):
        global count  # noqa: PLW0603
        if (
            args[0]
            == b"v\xa9\x14\xa3\xec`\xfbR/\xdfb\xc9\x0e\xec\x19\x81Wx\x13\xd8\xf8\xa5\x8a\x88\xac"
        ):
            if count == 0:
                count += 1
                return None
            if count == 1:
                count += 1
                return original_get_address(
                    b"v\xa9\x14\xa3\xec`\xfbR/\xdfb\x0e\xc9\xec\x19\x81Wx\x13\xd8\xf8\xa5\x8a\x88\xac",
                    102,
                )
            return original_get_address(
                b"v\xa9\x14\xa3\xec`\xfbR/\xdfb\x0e\xc9\x19\xec\x81Wx\x13\xd8\xf8\xa5\x8a\x88\xac",
                102,
            )
        return original_get_address(*args, **kwargs)

    monkeypatch.setattr(gettxinfolegacy, "get_address", get_address_mock)

    with pytest.raises(exceptions.DecodeError, match="invalid scriptpubkey"):
        gettxinfolegacy.get_tx_info_legacy(
            {
                "coinbase": False,
                "vout": [
                    {
                        "script_pub_key": "76a914a11b66a67b3ff69671c8f82254099faf374b800e88ac",
                        "value": 0,
                    }
                ],
                "vin": [
                    {
                        "hash": "0000000000000000000000000000000000000000000000000000000000000000",
                        "n": 0,
                    }
                ],
            },
            current_block_index,
        )

    assert gettxinfolegacy.get_tx_info_legacy(
        {
            "coinbase": False,
            "vout": [
                {"script_pub_key": "76a914a11b66a67b3ff69671c8f82254099faf374b800e88ac", "value": 0}
            ],
            "vin": [
                {
                    "hash": "0000000000000000000000000000000000000000000000000000000000000000",
                    "n": 0,
                },
                {
                    "hash": "0000000000000000000000000000000000000000000000000000000000000001",
                    "n": 0,
                },
            ],
        },
        current_block_index,
    ) == (
        None,
        "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
        0,
        20000,
        b"",
        [],
    )
