from counterpartycore.lib import config
from counterpartycore.lib.parser import deserialize, gettxinfolegacy


def test_get_tx_info(current_block_index, blockchain_mock):
    original_prefix = config.PREFIX
    config.PREFIX = b"TESTXXXX"
    config.ADDRESSVERSION = config.ADDRESSVERSION_TESTNET3

    blockchain_mock.source_by_txid[
        "e43c357b78baf473fd21cbc1481ac450746b60cf1d2702ce3a73a8811811e3eb"
    ] = "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns"

    assert gettxinfolegacy.get_tx_info_legacy(
        deserialize.deserialize_tx(
            "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0636150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac36150000000000001976a9147da51ea175f108a1c63588683dc4c43a7146c46788ac36150000000000001976a9147da51ea175f108a1c6358868173e34e8ca75a06788ac36150000000000001976a9147da51ea175f108a1c637729895c4c468ca75a06788ac36150000000000001976a9147fa51ea175f108a1c63588682ed4c468ca7fa06788ace24ff505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
    ) == (
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        5430,
        900010000,
        b"\x00\x00\x00(\x00\x00R\xbb3d\x00TESTXXXX\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00TESTXXXX\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00TESTXXXX\x00\x00\x00;\x10\x00\x00\x00\n\x9b\xb3Q\x92(6\xc8\x86\x81i\x87\xe1\x0b\x03\xb8_8v\x8b",
        [],
    )
    config.PREFIX = original_prefix
