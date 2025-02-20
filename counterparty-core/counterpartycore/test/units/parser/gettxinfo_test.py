import binascii
import struct

import pytest
from arc4 import ARC4
from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger import markets
from counterpartycore.lib.messages import dispenser
from counterpartycore.lib.parser import deserialize, gettxinfo
from counterpartycore.lib.utils import opcodes
from counterpartycore.test.mocks.bitcoind import (
    original_is_valid_der,
)
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_get_tx_info(ledger_db, current_block_index, blockchain_mock):
    original_prefix = config.PREFIX
    config.PREFIX = b"TESTXXXX"
    blockchain_mock.source_by_txid[
        "e43c357b78baf473fd21cbc1481ac450746b60cf1d2702ce3a73a8811811e3eb"
    ] = "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns"
    blockchain_mock.source_by_txid[
        "dc4f91c42eb79898b266ee237eed0d501b8b1a843f69aed847ad740e1933f85e"
    ] = "1_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_2"

    assert gettxinfo.get_tx_info(
        ledger_db,
        deserialize.deserialize_tx(
            "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0636150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac36150000000000001976a9147da51ea175f108a1c63588683dc4c43a7146c46788ac36150000000000001976a9147da51ea175f108a1c6358868173e34e8ca75a06788ac36150000000000001976a9147da51ea175f108a1c637729895c4c468ca75a06788ac36150000000000001976a9147fa51ea175f108a1c63588682ed4c468ca7fa06788ace24ff505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
        True,
    ) == (
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        5430,
        900010000,
        b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
        [],
        [
            "",
            "4f4a408d8bd90ca994e1f6b0969a8fe1a6bcf33211a4b5bad876d26b6f3a666b:0",
            "6",
            "",
        ],
    )

    assert gettxinfo.get_tx_info(
        ledger_db,
        deserialize.deserialize_tx(
            "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
        True,
    ) == (
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        5430,
        900010000,
        b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
        [],
        [
            "",
            "564501b070077eb6e978a547ae28a3e8ec4505da3de856f03a0d127750a44f11:0",
            "3",
            "",
        ],
    )

    assert gettxinfo.get_tx_info(
        ledger_db,
        deserialize.deserialize_tx(
            "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff03361500000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
        True,
    ) == (
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
        5430,
        900010000,
        b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
        [],
        [
            "",
            "1f9b910792994070699d898d59217df052bc3568d7b8e4e5d5bba485aa62c73a:0",
            "3",
            "",
        ],
    )

    assert gettxinfo.get_tx_info(
        ledger_db,
        deserialize.deserialize_tx(
            "0100000002ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff5ef833190e74ad47d8ae693f841a8b1b500ded7e23ee66b29898b72ec4914fdc0100000000ffffffff03361500000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed2fe7c11000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
        True,
    ) == (
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
        5430,
        1706582400,
        b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
        [],
        [
            "",
            "3481e0520d4f928617e86c0695f3d49faabb10b5432d44eb02e01141a4e6fc4d:0",
            "3",
            "",
        ],
    )

    assert gettxinfo.get_tx_info(
        ledger_db,
        deserialize.deserialize_tx(
            "0100000002ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff5ef833190e74ad47d8ae693f841a8b1b500ded7e23ee66b29898b72ec4914fdc0100000000ffffffff03361500000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed2fe7c11000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
        True,
    ) == (
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
        5430,
        1706582400,
        b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
        [],
        [
            "",
            "3481e0520d4f928617e86c0695f3d49faabb10b5432d44eb02e01141a4e6fc4d:0",
            "3",
            "",
        ],
    )
    config.PREFIX = original_prefix


def test_get_tx_info_new(ledger_db, current_block_index, blockchain_mock):
    original_prefix = config.PREFIX
    config.PREFIX = b"TESTXXXX"
    blockchain_mock.source_by_txid[
        "e43c357b78baf473fd21cbc1481ac450746b60cf1d2702ce3a73a8811811e3eb"
    ] = "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns"
    blockchain_mock.source_by_txid[
        "dc4f91c42eb79898b266ee237eed0d501b8b1a843f69aed847ad740e1933f85e"
    ] = "1_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_2"

    assert gettxinfo.get_tx_info_new(
        ledger_db,
        deserialize.deserialize_tx(
            "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0636150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac36150000000000001976a9147da51ea175f108a1c63588683dc4c43a7146c46788ac36150000000000001976a9147da51ea175f108a1c6358868173e34e8ca75a06788ac36150000000000001976a9147da51ea175f108a1c637729895c4c468ca75a06788ac36150000000000001976a9147fa51ea175f108a1c63588682ed4c468ca7fa06788ace24ff505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
        False,
        True,
    ) == (
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        5430,
        900010000,
        b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
        [],
    )

    assert gettxinfo.get_tx_info_new(
        ledger_db,
        deserialize.deserialize_tx(
            "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
        False,
        True,
    ) == (
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        5430,
        900010000,
        b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
        [],
    )

    assert gettxinfo.get_tx_info_new(
        ledger_db,
        deserialize.deserialize_tx(
            "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff03361500000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
        False,
        True,
    ) == (
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
        5430,
        900010000,
        b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
        [],
    )

    assert gettxinfo.get_tx_info_new(
        ledger_db,
        deserialize.deserialize_tx(
            "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0636150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac36150000000000001976a9147da51ea175f108a1c63588683dc4c43a7146c46788ac36150000000000001976a9147da51ea175f108a1c6358868173e34e8ca75a06788ac36150000000000001976a9147da51ea175f108a1c637729895c4c468ca75a06788ac36150000000000001976a9147fa51ea175f108a1c63588682ed4c468ca7fa06788ace24ff505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
        None,
        True,
    ) == (
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        5430,
        900010000,
        b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
        [],
    )

    assert gettxinfo.get_tx_info_new(
        ledger_db,
        deserialize.deserialize_tx(
            "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
        None,
        True,
    ) == (
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        5430,
        900010000,
        b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
        [],
    )

    with pytest.raises(exceptions.BTCOnlyError, match="no data and not unspendable"):
        gettxinfo.get_tx_info_new(
            ledger_db,
            deserialize.deserialize_tx(
                "0100000001aee668de98ef5f37d4962b620b0ec3deed8bbd4c2fb8ddedaf36c2e8ca5e51a7060000001976a914f3a6b6e4a093e5a5b9da76977a5270fd4d62553e88acffffffff04781e000000000000695121027c6a5e4412be80b5ccd5aa0ea685a21e7a577a5e390d138288841d06514b47992103b00007171817fb044e8a5464e3e274210dd64cf68cca9ea9c3e06df384aae6b22103d928d7d5bbe6f435da935ed382a0061c4a22bdc9b60a2ce6deb7d0f134d22eef53ae781e000000000000695121037c6a5e4412be80b5cc13bde2d9b04fd2cd1fc7ff664c0d3b6d8133163857b08f2103bb6fba40bee91bb02b54835b32f14b9e04016bfa34411ec64f09e3a9586efd5d2103d928d7d5bbe6f435da935ed382a0061c4a22bdc9b60a2ce6deb7d0f134d22eef53ae781e00000000000069512102696a5e4412be80b5ccd6aa0ac9a95e43ca49a21d40f762fadc1aab1c25909fb02102176c68252c6b855d7967aee372f14b772c963b2aa0411ec64f09e3a951eefd3e2103d928d7d5bbe6f435da935ed382a0061c4a22bdc9b60a2ce6deb7d0f134d22eef53aea8d37700000000001976a914f3a6b6e4a093e5a5b9da76977a5270fd4d62553e88ac00000000",
                parse_vouts=True,
                block_index=current_block_index,
            ),
            current_block_index,
            None,
            True,
        )

    config.PREFIX = original_prefix


def test_select_utxo_destination():
    assert (
        gettxinfo.select_utxo_destination(
            [
                {
                    "script_pub_key": b"j] \x02\x03\x04\xfb\x8b\xdd\xe7\xe4\x9d\x9d\xaf\xcc\x8a\x93\xcd\xe0\xa2\x01\x05A\x06\x80\xc2\xd7/\n\xe8\x07\x08\x88\xa4\x01\x16\x01"
                }
            ],
        )
        == 0
    )

    assert (
        gettxinfo.select_utxo_destination(
            [
                # op_return
                {
                    "script_pub_key": b"j)\x83\xe4b\x1dIm\xbe\x96\x0c\x00\xd1\xe1m\xd7\xed;\xaf\n\xca\x8ah\xaa\x88\xc1\xb49\xbd\x91\xc6\xac\xde/\x1b\xf9\x8dn\xa3\xec\xd5\xc9\xd5"
                },
                # invalid script
                {
                    "script_pub_key": b"j] \x02\x03\x04\xfb\x8b\xdd\xe7\xe4\x9d\x9d\xaf\xcc\x8a\x93\xcd\xe0\xa2\x01\x05A\x06\x80\xc2\xd7/\n\xe8\x07\x08\x88\xa4\x01\x16\x01"
                },
            ],
        )
        == 1
    )

    assert (
        gettxinfo.select_utxo_destination(
            [
                # op_return
                {
                    "script_pub_key": b"j)\x83\xe4b\x1dIm\xbe\x96\x0c\x00\xd1\xe1m\xd7\xed;\xaf\n\xca\x8ah\xaa\x88\xc1\xb49\xbd\x91\xc6\xac\xde/\x1b\xf9\x8dn\xa3\xec\xd5\xc9\xd5"
                },
                # valid script
                {
                    "script_pub_key": b"\x00\x14\xc1\xbe\xe0\x1c\xc5L\xeeK\xa0\x8e\xfc\xe5\xd8\xd3\xfe\x14\xd7C\xaf\x8d"
                },
                # invalid script
                {
                    "script_pub_key": b"j] \x02\x03\x04\xfb\x8b\xdd\xe7\xe4\x9d\x9d\xaf\xcc\x8a\x93\xcd\xe0\xa2\x01\x05A\x06\x80\xc2\xd7/\n\xe8\x07\x08\x88\xa4\x01\x16\x01"
                },
            ],
        )
        == 1
    )

    assert (
        gettxinfo.select_utxo_destination(
            [
                # invalid script
                {
                    "script_pub_key": b"j] \x02\x03\x04\xfb\x8b\xdd\xe7\xe4\x9d\x9d\xaf\xcc\x8a\x93\xcd\xe0\xa2\x01\x05A\x06\x80\xc2\xd7/\n\xe8\x07\x08\x88\xa4\x01\x16\x01"
                },
                # op_return
                {
                    "script_pub_key": b"j)\x83\xe4b\x1dIm\xbe\x96\x0c\x00\xd1\xe1m\xd7\xed;\xaf\n\xca\x8ah\xaa\x88\xc1\xb49\xbd\x91\xc6\xac\xde/\x1b\xf9\x8dn\xa3\xec\xd5\xc9\xd5"
                },
                # valid script
                {
                    "script_pub_key": b"\x00\x14\xc1\xbe\xe0\x1c\xc5L\xeeK\xa0\x8e\xfc\xe5\xd8\xd3\xfe\x14\xd7C\xaf\x8d"
                },
            ],
        )
        == 0
    )


def test_sighash_flag(monkeymodule, bitcoind_mock):
    # disable is_valid_der mock (hackish)
    mocked_is_valid_der = bitcoind_mock.is_valid_der
    gettxinfo.is_valid_der = bitcoind_mock.original_is_valid_der

    assert (
        gettxinfo.get_der_signature_sighash_flag(
            b'0E\x02!\x00\xc2\x19\xa5"\xe6\\\xa8P\x0e\xbe\x05\xa7\rZI\xd8@\xcc\xc1_*\xfaN\xe9\xdfx?\x06\xb2\xa3"1\x02 H\x9aF\xc3\x7f\xeb3\xf5,Xm\xa2\\p\x11;\x8e\xeaA!d@\xeb\x84w\x1c\xb6zg\xfd\xb6\x8c\x01'
        )
        == b"\x01"
    )

    assert (
        gettxinfo.get_der_signature_sighash_flag(
            b"0B\x02\x1exV_=\xe8\xb3\xb5&\xee\x9c:\x07\xb3\x96\xf4\xe1\x8e\x08/w\x17_J\xa4D\xb6?f\xc9\xad\x02 X\x13\xea\x17z\xc1\xd9\xb2\xdb\xb4?c\xcd:\x00\xd4z:R_00\xc5#;\x82@#\x9f\x9c\x15\xe4\x01"
        )
        == b"\x01"
    )

    assert (
        gettxinfo.get_der_signature_sighash_flag(
            binascii.unhexlify(
                "3044022063c96d6644f7d325bc7fed3362fd6cc81d81bf4a4af8df8d5f13147d6c74267a02201340b3b01b1f29d2d0e180abf5e3d14cc832b412cb27a5a68135f98493bb006e01"
            )
        )
        == b"\x01"
    )

    assert (
        gettxinfo.get_der_signature_sighash_flag(
            binascii.unhexlify(
                "3045022100c219a522e65ca8500ebe05a70d5a49d840ccc15f2afa4ee9df783f06b2a322310220489a46c37feb33f52c586da25c70113b8eea41216440eb84771cb67a67fdb68c01"
            )
        )
        == b"\x01"
    )

    assert (
        gettxinfo.get_der_signature_sighash_flag(
            binascii.unhexlify(
                "3046022100d8697a511eea7c0949f4295dc185d3e19cbd80aed547a2c0d29dd635b04430ef022100b334f949949ad19a3e78c9c3eb82320d877a5acc094e7ed3b15987a45ffca89101"
            ),
        )
        == b"\x01"
    )

    assert (
        gettxinfo.get_der_signature_sighash_flag(
            binascii.unhexlify(
                "304600022100c219a522e65ca8500ebe05a70d5840ccc15f2afa4ee9df783f06b2a322310220489a46c37feb33f52c586da25c70113b8eea41216440eb84771cb67a67fdb68c01"
            )
        )
        is None
    )

    assert (
        gettxinfo.get_schnorr_signature_sighash_flag(
            binascii.unhexlify(
                "b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae"
            )
        )
        == b"\x01"
    )

    assert (
        gettxinfo.get_schnorr_signature_sighash_flag(
            binascii.unhexlify(
                "b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae01"
            )
        )
        == b"\x01"
    )

    assert (
        gettxinfo.get_schnorr_signature_sighash_flag(
            binascii.unhexlify(
                "b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae83"
            )
        )
        == b"\x83"
    )

    assert gettxinfo.collect_sighash_flags(
        binascii.unhexlify(
            "483045022100c219a522e65ca8500ebe05a70d5a49d840ccc15f2afa4ee9df783f06b2a322310220489a46c37feb33f52c586da25c70113b8eea41216440eb84771cb67a67fdb68c01"
        ),
        [],
    ) == [b"\x01"]

    assert gettxinfo.collect_sighash_flags(
        binascii.unhexlify(
            "483045022100c233c3a8a510e03ad18b0a24694ef00c78101bfd5ac075b8c1037952ce26e91e02205aa5f8f88f29bb4ad5808ebc12abfd26bd791256f367b04c6d955f01f28a7724012103f0609c81a45f8cab67fc2d050c21b1acd3d37c7acfd54041be6601ab4cef4f31"
        ),
        [],
    ) == [b"\x01"]

    assert gettxinfo.collect_sighash_flags(
        binascii.unhexlify(
            "00483045022100af204ef91b8dba5884df50f87219ccef22014c21dd05aa44470d4ed800b7f6e40220428fe058684db1bb2bfb6061bff67048592c574effc217f0d150daedcf36787601483045022100e8547aa2c2a2761a5a28806d3ae0d1bbf0aeff782f9081dfea67b86cacb321340220771a166929469c34959daf726a2ac0c253f9aff391e58a3c7cb46d8b7e0fdc4801"
        ),
        [],
    ) == [b"\x01", b"\x01"]

    assert gettxinfo.collect_sighash_flags(
        b"",
        [
            "3045022100c7fb3bd38bdceb315a28a0793d85f31e4e1d9983122b4a5de741d6ddca5caf8202207b2821abd7a1a2157a9d5e69d2fdba3502b0a96be809c34981f8445555bdafdb01",
            "03f465315805ed271eb972e43d84d2a9e19494d10151d9f6adb32b8534bfd764ab",
        ],
    ) == [b"\x01"]

    assert gettxinfo.collect_sighash_flags(
        b"",
        [
            "b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae01"
        ],
    ) == [b"\x01"]

    assert gettxinfo.collect_sighash_flags(
        b"",
        [
            "b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae",
            "5387",
            "c1a2fc329a085d8cfc4fa28795993d7b666cee024e94c40115141b8e9be4a29fa41324300a84045033ec539f60c70d582c48b9acf04150da091694d83171b44ec9bf2c4bf1ca72f7b8538e9df9bdfd3ba4c305ad11587f12bbfafa00d58ad6051d54962df196af2827a86f4bde3cf7d7c1a9dcb6e17f660badefbc892309bb145f",
        ],
    ) == [b"\x01"]

    assert (
        gettxinfo.check_signatures_sighash_flag(
            {"tx_id": "c8091f1ef768a2f00d48e6d0f7a2c2d272a5d5c8063db78bf39977adcb12e103"},
        )
        is None
    )

    assert (
        gettxinfo.check_signatures_sighash_flag(
            {
                "tx_id": "tx_id",
                "segwit": False,
                "vin": [
                    {
                        "script_sig": binascii.unhexlify(
                            "483045022100c219a522e65ca8500ebe05a70d5a49d840ccc15f2afa4ee9df783f06b2a322310220489a46c37feb33f52c586da25c70113b8eea41216440eb84771cb67a67fdb68c01"
                        ),
                    }
                ],
            },
        )
        is None
    )

    with pytest.raises(
        gettxinfo.SighashFlagError, match="invalid SIGHASH flag for transaction tx_id"
    ):
        gettxinfo.check_signatures_sighash_flag(
            {
                "tx_id": "tx_id",
                "segwit": False,
                "vin": [
                    {
                        "script_sig": binascii.unhexlify(
                            "483045022100c219a522e65ca8500ebe05a70d5a49d840ccc15f2afa4ee9df783f06b2a322310220489a46c37feb33f52c586da25c70113b8eea41216440eb84771cb67a67fdb68c83"
                        ),
                    }
                ],
            },
        )

    assert (
        gettxinfo.check_signatures_sighash_flag(
            {
                "tx_id": "tx_id",
                "segwit": False,
                "vin": [
                    {
                        "script_sig": binascii.unhexlify(
                            "483045022100c233c3a8a510e03ad18b0a24694ef00c78101bfd5ac075b8c1037952ce26e91e02205aa5f8f88f29bb4ad5808ebc12abfd26bd791256f367b04c6d955f01f28a7724012103f0609c81a45f8cab67fc2d050c21b1acd3d37c7acfd54041be6601ab4cef4f31"
                        ),
                    }
                ],
            },
        )
        is None
    )

    with pytest.raises(
        gettxinfo.SighashFlagError, match="invalid SIGHASH flag for transaction tx_id"
    ):
        gettxinfo.check_signatures_sighash_flag(
            {
                "tx_id": "tx_id",
                "segwit": False,
                "vin": [
                    {
                        "script_sig": binascii.unhexlify(
                            "483045022100c233c3a8a510e03ad18b0a24694ef00c78101bfd5ac075b8c1037952ce26e91e02205aa5f8f88f29bb4ad5808ebc12abfd26bd791256f367b04c6d955f01f28a7724832103f0609c81a45f8cab67fc2d050c21b1acd3d37c7acfd54041be6601ab4cef4f31"
                        ),
                    }
                ],
            },
        )

    assert (
        gettxinfo.check_signatures_sighash_flag(
            {
                "tx_id": "tx_id",
                "segwit": True,
                "vin": [
                    {
                        "script_sig": b"",
                    }
                ],
                "vtxinwit": [
                    [
                        "3045022100c7fb3bd38bdceb315a28a0793d85f31e4e1d9983122b4a5de741d6ddca5caf8202207b2821abd7a1a2157a9d5e69d2fdba3502b0a96be809c34981f8445555bdafdb01",
                        "03f465315805ed271eb972e43d84d2a9e19494d10151d9f6adb32b8534bfd764ab",
                    ]
                ],
            },
        )
        is None
    )

    with pytest.raises(
        gettxinfo.SighashFlagError, match="invalid SIGHASH flag for transaction tx_id"
    ):
        gettxinfo.check_signatures_sighash_flag(
            {
                "tx_id": "tx_id",  # c8091f1ef768a2f00d48e6d0f7a2c2d272a5d5c8063db78bf39977adcb12e103
                "segwit": True,
                "vin": [
                    {
                        "script_sig": b"",
                    },
                    {
                        "script_sig": b"",
                    },
                ],
                "vtxinwit": [
                    [
                        "304502210095dfc652a9c03911b7c4a0bc7de574ee4764cd1de78ab6599c196c69c741efbe022078ba83e9756e7d0751cb97402f031886bb34e00c70758710b4507db17649795983",
                        "03fef14a1660447a52f507af16a81b6e05ca8e579e0b74b11b44c6d9db6109a415",
                    ],
                    [
                        "3044022031150e6703f6fb7e924446b021211a1d216724693d78634c5a47a43c4edf8e1102203652e2879e9bd62dc1e5994045d81fdb4adacaec4b6c366cb18be74fc020d99601",
                        "031e9c58fa7828643a91fa06cc0146d97fe75b982218bf38745d6579309cfba5fe",
                    ],
                ],
            },
        )

    assert (
        gettxinfo.check_signatures_sighash_flag(
            {
                "tx_id": "tx_id",
                "segwit": True,
                "vin": [
                    {
                        "script_sig": b"",
                    }
                ],
                "vtxinwit": [
                    [
                        "b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae01"
                    ]
                ],
            },
        )
        is None
    )

    with pytest.raises(
        gettxinfo.SighashFlagError, match="invalid SIGHASH flag for transaction tx_id"
    ):
        gettxinfo.check_signatures_sighash_flag(
            {
                "tx_id": "tx_id",
                "segwit": True,
                "vin": [
                    {
                        "script_sig": b"",
                    }
                ],
                "vtxinwit": [
                    [
                        "b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae83"
                    ]
                ],
            },
        )

    assert (
        gettxinfo.check_signatures_sighash_flag(
            {
                "tx_id": "tx_id",
                "segwit": True,
                "vin": [
                    {
                        "script_sig": b"",
                    }
                ],
                "vtxinwit": [
                    [
                        "b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae",
                        "5387",
                        "c1a2fc329a085d8cfc4fa28795993d7b666cee024e94c40115141b8e9be4a29fa41324300a84045033ec539f60c70d582c48b9acf04150da091694d83171b44ec9bf2c4bf1ca72f7b8538e9df9bdfd3ba4c305ad11587f12bbfafa00d58ad6051d54962df196af2827a86f4bde3cf7d7c1a9dcb6e17f660badefbc892309bb145f",
                    ]
                ],
            },
        )
        is None
    )

    with pytest.raises(
        gettxinfo.SighashFlagError, match="invalid SIGHASH flag for transaction tx_id"
    ):
        gettxinfo.check_signatures_sighash_flag(
            {
                "tx_id": "tx_id",
                "segwit": True,
                "vin": [
                    {
                        "script_sig": b"",
                    }
                ],
                "vtxinwit": [
                    [
                        "b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae83",
                        "5387",
                        "c1a2fc329a085d8cfc4fa28795993d7b666cee024e94c40115141b8e9be4a29fa41324300a84045033ec539f60c70d582c48b9acf04150da091694d83171b44ec9bf2c4bf1ca72f7b8538e9df9bdfd3ba4c305ad11587f12bbfafa00d58ad6051d54962df196af2827a86f4bde3cf7d7c1a9dcb6e17f660badefbc892309bb145f",
                    ]
                ],
            },
        )

    assert (
        gettxinfo.check_signatures_sighash_flag(
            {
                "tx_id": "fa7e8c4a582b4284bd4726de620cd87dfef6b634ee3ebb043ed0dc08901eee83",
                "segwit": True,
                "vin": [
                    {
                        "script_sig": binascii.unhexlify(
                            "16001415a13032cb59a7b51dd761223e189a48a7f67338"
                        ),
                    }
                ],
                "vtxinwit": [
                    [
                        "3045022100ceeccea697ed5fc7583387ba298ba1a84b6cdc24eeb97cf4021e967d795b27ca022070b398697abb41eb402994984c122fc6b4edccaeed819188be5c5ef40b8c685a01",
                        "039db968bfd35439d215dd26196266e8859a1fae89c462b587416779f0b8854e48",
                    ]
                ],
            },
        )
        is None
    )

    with pytest.raises(
        gettxinfo.SighashFlagError,
        match="invalid SIGHASH flag for transaction fa7e8c4a582b4284bd4726de620cd87dfef6b634ee3ebb043ed0dc08901eee83",
    ):
        gettxinfo.check_signatures_sighash_flag(
            {
                "tx_id": "fa7e8c4a582b4284bd4726de620cd87dfef6b634ee3ebb043ed0dc08901eee83",
                "segwit": True,
                "vin": [
                    {
                        "script_sig": binascii.unhexlify(
                            "16001415a13032cb59a7b51dd761223e189a48a7f67338"
                        ),
                    }
                ],
                "vtxinwit": [
                    [
                        "3045022100ceeccea697ed5fc7583387ba298ba1a84b6cdc24eeb97cf4021e967d795b27ca022070b398697abb41eb402994984c122fc6b4edccaeed819188be5c5ef40b8c685a83",
                        "039db968bfd35439d215dd26196266e8859a1fae89c462b587416779f0b8854e48",
                    ]
                ],
            },
        )

    gettxinfo.is_valid_der = mocked_is_valid_der


def test_decode_checkmultisig():
    # tx_hash mainnet: 3b1f71fb0a3905d8462db52171763c76ea1261d55a2c8b12ef5db0eb76be59a5
    asm = [
        2,
        b"\x04'\xdb@Y\xd2K\xab\x05\xdf?k\xccv\x8f\xb0\x1b\xd9v\xb9s\xf9>r\xcc\xe2\xdf\xbf\xbe\xd5\xa3 V\xc9\x04\n,.\xa4\xc1\x0c\x81*T\xfe\xd7\xff.j\x91}\xbc\x843b\xd3\x98\xf6\xac\xe4\x00\x0f\xaf\xa5\xc6",
        b"\x04>\x12\xa6\xcb\x1c|\x15ox\x91\x10\xab\xf89{q@GAKZ2\xc7B\xf1|\xcf\x93\xff#\xbd\xf3\x12\x8f\x94b\x07\x08k\xce\xf0\x12U\x82@\xcd\x16\x18,t\x11#\xe9>\xd1\x83'\xc4\xcdn\xba\xc6h\xa9",
        b'\x04\xe4\x16\x8c\x17"\x83\xc7\xdf\xaa\x85\xd2\x00Ov:(\xbfm\x0f\x16\x02\xfc\x14R\xcc\xecb\xa7\xc8\xa6nB*\xf1A\x0f\xbf$\xa4sU\xdd\xc4=\xfe4\x91\xcb\x1b\x80et\xcc\xd1\xc44h\x04f\xdc\xff\x92o\x01',
        3,
        b"\xae",
    ]
    decoded_tx = {
        "vin": [
            {
                "hash": binascii.hexlify(
                    b"H\x1b:T<\x05\x96\x1c\x0c!\x9b\xfd>;\xfb\xb0;\xdb\x9c\xcf\xf3\xd5=\n\x9b\xaa\xeeqw\xa8P\x05"
                )
            }
        ]
    }
    config.ADDRESSVERSION = config.ADDRESSVERSION_MAINNET
    assert gettxinfo.decode_checkmultisig(asm, decoded_tx) == (
        "2_16KsHvVQj6aGvVQpAUgRcfpVug3regjiUs_17yjtboB7RjK2BoQ78k51NtJ4cDQGYZQyb_1NNXBUF3rqXtFbWhK5nujSpvt9yApsRUT7_3",
        None,
    )


def test_errors(ledger_db, monkeypatch):
    with pytest.raises(exceptions.DecodeError, match="invalid OP_CHECKSIG"):
        gettxinfo.get_checksig([b"\x00"])

    with pytest.raises(exceptions.DecodeError, match="invalid OP_CHECKSIG"):
        gettxinfo.get_checksig([b"\x00", b"\x00", b"\x00", b"\x00", b"\x00"])

    with pytest.raises(exceptions.DecodeError, match="invalid OP_CHECKMULTISIG"):
        gettxinfo.get_checkmultisig([b"\x00", b"\x00", b"\x00", b"\x00", b"\x00"])

    pubkeyhash = ARC4(binascii.unhexlify("abcdef")).encrypt(b"0" + config.PREFIX + b"pubkeyhash")
    asm = [
        opcodes.OP_DUP,
        opcodes.OP_HASH160,
        pubkeyhash,
        opcodes.OP_EQUALVERIFY,
        opcodes.OP_CHECKSIG,
    ]
    assert gettxinfo.decode_checksig(asm, {"vin": [{"hash": "abcdef"}]}) == (None, b"pubkeyhash")

    monkeypatch.setattr(gettxinfo, "get_checkmultisig", lambda asm: (asm[1:4], asm[0]))
    data = ARC4(binascii.unhexlify("abcdef")).encrypt(b"0" + config.PREFIX + b"pubkeyhash")
    asm = [
        1,
        b"0" + data[0 : len(data) // 2] + b"0",
        b"0" + data[len(data) // 2 :] + b"0",
        b"\x03\x19\xf6\xe0{\x0b\x8duaV9K\x9d\xcf;\x01\x1f\xe9\xac\x19\xf2p\x0b\xd6\xb6\x9aj\x17\x83\xdb\xb8\xb9w",
        3,
        opcodes.OP_CHECKMULTISIG,  # noqa: F405
    ]
    assert gettxinfo.decode_checkmultisig(asm, {"vin": [{"hash": "abcdef"}]}) == (
        None,
        b"pubkeyhash",
    )


def test_get_transaction_sources_checksig(monkeypatch, monkeymodule):
    def get_decoded_transaction(*args, **lwargs):
        raise exceptions.BitcoindRPCError("error")

    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.get_decoded_transaction", get_decoded_transaction
    )
    # mocked_get_vin_info = backend.bitcoind.get_vin_info
    # backend.bitcoind.get_vin_info = original_get_vin_info
    # monkeymodule.setattr("counterpartycore.lib.backend.bitcoind.get_vin_info", original_get_vin_info)

    with pytest.raises(exceptions.DecodeError, match="vin not found"):
        gettxinfo.get_transaction_sources({"vin": [{"hash": "abcdef"}]})

    with pytest.raises(
        gettxinfo.SighashFlagError,
        match="impossible to determine SIGHASH flag for transaction abcdef",
    ):
        gettxinfo.check_signatures_sighash_flag(
            {"tx_id": "abcdef", "segwit": False, "vin": [{"script_sig": b""}]}
        )

    def get_vin_info_mock_2(*args, **lwargs):
        op_checksig_script = "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
        return (10000, binascii.unhexlify(op_checksig_script), False)

    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.get_vin_info", get_vin_info_mock_2)
    assert gettxinfo.get_transaction_sources({"vin": [{"hash": "abcdef"}]}) == (
        "1FwkKA9cqpNRFTpVaokdRjT9Xamvebrwcu",
        10000,
    )

    pubkeyhash = ARC4(binascii.unhexlify("abcdef")).encrypt(b"0" + config.PREFIX + b"pubkeyhash")
    asm = [
        opcodes.OP_DUP,
        opcodes.OP_HASH160,
        pubkeyhash,
        opcodes.OP_EQUALVERIFY,
        opcodes.OP_CHECKSIG,
    ]
    monkeypatch.setattr("counterpartycore.lib.utils.script.script_to_asm", lambda x: asm)
    with pytest.raises(exceptions.DecodeError, match="data in source"):
        gettxinfo.get_transaction_sources({"vin": [{"hash": "abcdef"}]})

    # monkeymodule.setattr("counterpartycore.lib.backend.bitcoind.get_vin_info", get_vin_info)

    # backend.bitcoind.get_vin_info = mocked_get_vin_info


def test_get_transaction_sources_multisig(monkeypatch):
    def get_vin_info_mock_2(*args, **lwargs):
        op_checksig_script = "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
        return (10000, binascii.unhexlify(op_checksig_script), False)

    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.get_vin_info", get_vin_info_mock_2)

    data = ARC4(binascii.unhexlify("abcdef")).encrypt(b"0" + config.PREFIX + b"pubkeyhash")
    monkeypatch.setattr(
        "counterpartycore.lib.utils.script.script_to_asm",
        lambda x: [
            1,
            b"0" + data[0 : len(data) // 2] + b"0",
            b"0" + data[len(data) // 2 :] + b"0",
            b"\x03\x19\xf6\xe0{\x0b\x8duaV9K\x9d\xcf;\x01\x1f\xe9\xac\x19\xf2p\x0b\xd6\xb6\x9aj\x17\x83\xdb\xb8\xb9w",
            3,
            opcodes.OP_CHECKMULTISIG,  # noqa: F405
        ],
    )
    with pytest.raises(exceptions.DecodeError, match="data in source"):
        gettxinfo.get_transaction_sources({"vin": [{"hash": "abcdef"}]})


def test_get_transaction_sources_unknown_type(monkeypatch):
    def get_vin_info_mock_2(*args, **lwargs):
        op_checksig_script = "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
        return (10000, binascii.unhexlify(op_checksig_script), False)

    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.get_vin_info", get_vin_info_mock_2)

    monkeypatch.setattr(
        "counterpartycore.lib.utils.script.script_to_asm",
        lambda x: [
            opcodes.OP_CHECKSIG,
            b"\x03\x19\xf6\xe0{\x0b\x8duaV9K\x9d\xcf;\x01\x1f\xe9\xac\x19\xf2p\x0b\xd6\xb6\x9aj\x17\x83\xdb\xb8\xb9w",
            3,
        ],
    )
    with pytest.raises(exceptions.DecodeError, match="unrecognised source type"):
        gettxinfo.get_transaction_sources({"vin": [{"hash": "abcdef"}]})


def test_decode_scripthash():
    assert gettxinfo.decode_scripthash(
        [opcodes.OP_HASH160, b"H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607"]
    ) == ("2Myq6jrmWb7bxTtT94AvBRj1roFPTLpa6m7", None)

    assert gettxinfo.decode_scripthash([opcodes.OP_HASH160, b""]) == ("PA7wHSw", None)


def test_is_valid_der_non_bytes(monkeymodule):
    monkeymodule.setattr(gettxinfo, "is_valid_der", original_is_valid_der)
    # Un DER valide typique pour une signature ECDSA
    valid_der = binascii.unhexlify(
        "3045022100c219a522e65ca8500ebe05a70d5a49d840ccc15f2afa4ee9df783f06b2a322310220489a46c37feb33f52c586da25c70113b8eea41216440eb84771cb67a67fdb68c"
    )
    assert gettxinfo.is_valid_der(valid_der)

    # invalid first marker
    invalid_der = binascii.unhexlify(
        "3045032100c219a522e65ca8500ebe05a70d5a49d840ccc15f2afa4ee9df783f06b2a322310220489a46c37feb33f52c586da25c70113b8eea41216440eb84771cb67a67fdb68c"
    )
    assert not gettxinfo.is_valid_der(invalid_der)

    # invalid second marker
    invalid_der = binascii.unhexlify(
        "3045022100c219a522e65ca8500ebe05a70d5a49d840ccc15f2afa4ee9df783f06b2a322310320489a46c37feb33f52c586da25c70113b8eea41216440eb84771cb67a67fdb68c"
    )
    assert not gettxinfo.is_valid_der(invalid_der)

    invalid_der = binascii.unhexlify(
        "3045022100c219a522e65ca8500ebe05a70d5a49d840ccc15f2afa4ee9df783f06b2a322310221489a46c37feb33f52c586da25c70113b8eea41216440eb84771cb67a67fdb68c"
    )
    assert not gettxinfo.is_valid_der(invalid_der)

    assert not gettxinfo.is_valid_der("not bytes")


def test_is_valid_schnorr_non_bytes():
    assert not gettxinfo.is_valid_schnorr("not bytes")
    assert not gettxinfo.is_valid_schnorr(123)
    assert not gettxinfo.is_valid_schnorr(None)
    assert not gettxinfo.is_valid_schnorr([1, 2, 3])
    assert not gettxinfo.is_valid_schnorr(b"")  # Vide
    assert not gettxinfo.is_valid_schnorr(b"\x00" * 63)  # Trop court
    assert not gettxinfo.is_valid_schnorr(b"\x00" * 66)  # Trop long


def test_is_valid_schnorr_invalid_r_value():
    # r value >= p
    p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
    p_bytes = p.to_bytes(32, byteorder="big")
    invalid_r = bytes(p_bytes)  # A value that is exactly p

    test_signature = invalid_r + b"\x00" * 32
    assert not gettxinfo.is_valid_schnorr(test_signature)

    # r value > p
    p_plus_one = p + 1
    p_plus_one_bytes = p_plus_one.to_bytes(32, byteorder="big")
    invalid_r = bytes(p_plus_one_bytes)

    test_signature = invalid_r + b"\x00" * 32
    assert not gettxinfo.is_valid_schnorr(test_signature)


def test_is_valid_schnorr_invalid_s_value():
    """Test signatures with invalid s values"""
    # s value >= n
    n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
    n_bytes = n.to_bytes(32, byteorder="big")
    invalid_s = bytes(n_bytes)  # A value that is exactly n

    test_signature = b"\x01" * 32 + invalid_s
    assert not gettxinfo.is_valid_schnorr(test_signature)

    # s value > n
    n_plus_one = n + 1
    n_plus_one_bytes = n_plus_one.to_bytes(32, byteorder="big")
    invalid_s = bytes(n_plus_one_bytes)

    test_signature = b"\x01" * 32 + invalid_s
    assert not gettxinfo.is_valid_schnorr(test_signature)


def test_is_valid_schnorr_with_recovery_byte():
    """Test signatures with a recovery byte"""
    # 65-byte signature with a recovery byte
    valid_signature_with_recovery = b"\x01" * 64 + b"\x00"
    assert gettxinfo.is_valid_schnorr(valid_signature_with_recovery)

    # 65-byte signature with an invalid recovery byte
    invalid_signature_with_recovery = b"\x01" * 64 + b"\x02"
    assert gettxinfo.is_valid_schnorr(invalid_signature_with_recovery)


def test_get_transaction_source_from_p2sh(monkeypatch):
    def get_vin_info_mock_2(*args, **lwargs):
        op_checksig_script = "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
        return (10000, binascii.unhexlify(op_checksig_script), False)

    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.get_vin_info", get_vin_info_mock_2)

    with ProtocolChangesDisabled(["prevout_segwit_fix"]):
        assert gettxinfo.get_transaction_source_from_p2sh(
            {"vin": [{"script_sig": "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"}]},
            p2sh_is_segwit=True,
        ) == (None, b"", 10000)


def test_get_dispensers_outputs(ledger_db, monkeypatch, defaults):
    dispensers = markets.get_dispensers(ledger_db, status=0)

    def is_dispensable_mock(db, destination, amount):
        return True if amount else False

    monkeypatch.setattr(
        "counterpartycore.lib.messages.dispenser.is_dispensable", is_dispensable_mock
    )

    potential_dispensers = [
        (dispensers[0]["source"], None),
        (dispensers[0]["source"], 5),
        (dispensers[1]["source"], 10),
    ]

    assert gettxinfo.get_dispensers_outputs(ledger_db, potential_dispensers) == [
        (dispensers[0]["source"], 5),
        (dispensers[1]["source"], 10),
    ]


def test_get_dispensers_tx_info(ledger_db, defaults):
    dispensers = markets.get_dispensers(ledger_db, status=0)
    assert gettxinfo.get_dispensers_tx_info(
        defaults["addresses"][0],
        [
            (dispensers[0]["source"], 5),
            (dispensers[1]["source"], 10),
            (dispensers[0]["source"], None),
            (None, 5),
        ],
    ) == (
        defaults["addresses"][0],
        dispensers[0]["source"],
        10,
        0,
        b"\r\x00",
        [
            {"btc_amount": 5, "destination": dispensers[0]["source"], "out_index": 0},
            {"btc_amount": 10, "destination": dispensers[1]["source"], "out_index": 1},
        ],
    )

    with ProtocolChangesDisabled(["multiple_dispenses"]):
        assert gettxinfo.get_dispensers_tx_info(
            defaults["addresses"][0],
            [
                (dispensers[0]["source"], 5),
                (dispensers[1]["source"], 10),
            ],
        ) == (defaults["addresses"][0], dispensers[0]["source"], 5, 0, b"\r\x00", [])


def test_get_tx_info_new_3(ledger_db, current_block_index, defaults, monkeypatch):
    with pytest.raises(exceptions.DecodeError, match="coinbase transaction"):
        gettxinfo.get_tx_info_new(ledger_db, {"coinbase": True}, current_block_index)

    with pytest.raises(exceptions.DecodeError, match="no parsed_vouts in decoded_tx"):
        gettxinfo.get_tx_info_new(ledger_db, {"coinbase": False}, current_block_index)

    with pytest.raises(exceptions.DecodeError, match="error from rust"):
        gettxinfo.get_tx_info_new(
            ledger_db,
            {"coinbase": False, "parsed_vouts": Exception("error from rust")},
            current_block_index,
        )

    with pytest.raises(exceptions.DecodeError, match="unrecognised output type"):
        gettxinfo.get_tx_info_new(
            ledger_db, {"coinbase": False, "parsed_vouts": "DecodeError"}, current_block_index
        )

    source = defaults["addresses"][1]
    destinations = [defaults["addresses"][0]]
    btc_amount = 100
    fee = 0
    data = b"P2SH"
    potential_dispensers = [
        (defaults["addresses"][0], None),
        (defaults["addresses"][0], 5),
        (defaults["addresses"][0], 10),
    ]
    monkeypatch.setattr(
        gettxinfo, "get_transaction_source_from_p2sh", lambda *args: (source, b"", btc_amount)
    )

    with pytest.raises(exceptions.BTCOnlyError, match="no data and not unspendable"):
        gettxinfo.get_tx_info_new(
            ledger_db,
            {
                "coinbase": False,
                "parsed_vouts": (destinations, btc_amount, fee, data, potential_dispensers),
            },
            current_block_index,
        )

    with ProtocolChangesDisabled(["disable_vanilla_btc_dispense"]):
        with pytest.raises(exceptions.BTCOnlyError, match="no data and not unspendable"):
            gettxinfo.get_tx_info_new(
                ledger_db,
                {
                    "coinbase": False,
                    "parsed_vouts": (destinations, btc_amount, fee, data, potential_dispensers),
                },
                current_block_index,
            )

    with ProtocolChangesDisabled(["disable_vanilla_btc_dispense"]):
        with pytest.raises(exceptions.BTCOnlyError, match="no data and not unspendable"):
            gettxinfo.get_tx_info_new(
                ledger_db,
                {
                    "coinbase": False,
                    "parsed_vouts": (destinations, btc_amount, fee, data, potential_dispensers),
                },
                current_block_index,
                composing=True,
            )

    assert gettxinfo.get_tx_info_new(
        ledger_db,
        {
            "coinbase": False,
            "parsed_vouts": ([config.UNSPENDABLE], btc_amount, fee, data, potential_dispensers),
        },
        current_block_index,
        composing=True,
    ) == (defaults["addresses"][1], config.UNSPENDABLE, 100, 100, b"", [])

    monkeypatch.setattr(
        gettxinfo,
        "get_dispensers_outputs",
        lambda *args: [
            (defaults["addresses"][0], 5),
            (defaults["addresses"][0], 10),
        ],
    )
    with ProtocolChangesDisabled(["disable_vanilla_btc_dispense"]):
        assert gettxinfo.get_tx_info_new(
            ledger_db,
            {
                "coinbase": False,
                "parsed_vouts": (destinations, btc_amount, fee, data, potential_dispensers),
            },
            current_block_index,
        ) == (
            defaults["addresses"][1],
            defaults["addresses"][0],
            10,
            0,
            b"\r\x00",
            [
                {"btc_amount": 5, "destination": defaults["addresses"][0], "out_index": 0},
                {"btc_amount": 10, "destination": defaults["addresses"][0], "out_index": 1},
            ],
        )

    monkeypatch.setattr(
        gettxinfo, "get_transaction_sources", lambda *args: (defaults["addresses"][1], 10000)
    )
    monkeypatch.setattr(gettxinfo, "check_signatures_sighash_flag", lambda *args: None)

    def unpack_mock(*args):
        raise struct.error("error")

    monkeypatch.setattr("counterpartycore.lib.parser.messagetype.unpack", unpack_mock)

    assert gettxinfo.get_tx_info_new(
        ledger_db,
        {
            "coinbase": False,
            "parsed_vouts": (destinations, btc_amount, fee, b"z", potential_dispensers),
        },
        current_block_index,
    ) == (defaults["addresses"][1], defaults["addresses"][0], 100, 10000, b"z", [])


def test_get_tx_info_new_3b(ledger_db, current_block_index, defaults, monkeypatch):
    destinations = [defaults["addresses"][0]]
    btc_amount = 100
    fee = 0
    potential_dispensers = [
        (defaults["addresses"][0], None),
        (defaults["addresses"][0], 5),
        (defaults["addresses"][0], 10),
    ]
    monkeypatch.setattr(
        gettxinfo, "get_transaction_sources", lambda *args: (defaults["addresses"][1], 10000)
    )
    monkeypatch.setattr(gettxinfo, "check_signatures_sighash_flag", lambda *args: None)

    def unpack_mock(*args):
        return dispenser.DISPENSE_ID, b""

    monkeypatch.setattr("counterpartycore.lib.parser.messagetype.unpack", unpack_mock)

    assert gettxinfo.get_tx_info_new(
        ledger_db,
        {
            "coinbase": False,
            "parsed_vouts": (destinations, btc_amount, fee, b"z", potential_dispensers),
        },
        current_block_index,
    ) == (
        defaults["addresses"][1],
        defaults["addresses"][0],
        10,
        0,
        b"\r\x00",
        [
            {"destination": defaults["addresses"][0], "btc_amount": 5, "out_index": 0},
            {"destination": defaults["addresses"][0], "btc_amount": 10, "out_index": 1},
        ],
    )


def test_get_tx_info_4(ledger_db, defaults, monkeypatch):
    destinations = [defaults["addresses"][0]]
    btc_amount = 100
    fee = 0
    potential_dispensers = [
        (defaults["addresses"][0], None),
        (defaults["addresses"][0], 5),
        (defaults["addresses"][0], 10),
    ]
    monkeypatch.setattr(
        gettxinfo, "get_transaction_sources", lambda *args: (defaults["addresses"][1], 10000)
    )
    monkeypatch.setattr(gettxinfo, "check_signatures_sighash_flag", lambda *args: None)

    def unpack_mock(*args):
        return dispenser.DISPENSE_ID, b""

    monkeypatch.setattr("counterpartycore.lib.parser.messagetype.unpack", unpack_mock)

    assert gettxinfo._get_tx_info(
        ledger_db,
        {
            "coinbase": False,
            "parsed_vouts": (destinations, btc_amount, fee, b"z", potential_dispensers),
        },
        block_index=None,
    ) == (
        defaults["addresses"][1],
        defaults["addresses"][0],
        10,
        0,
        b"\r\x00",
        [
            {"destination": defaults["addresses"][0], "btc_amount": 5, "out_index": 0},
            {"destination": defaults["addresses"][0], "btc_amount": 10, "out_index": 1},
        ],
    )

    with ProtocolChangesDisabled(["p2sh_addresses"]):
        assert gettxinfo._get_tx_info(
            ledger_db,
            {
                "coinbase": False,
                "parsed_vouts": (destinations, btc_amount, fee, b"z", potential_dispensers),
            },
            block_index=None,
        ) == (
            defaults["addresses"][1],
            defaults["addresses"][0],
            10,
            0,
            b"\r\x00",
            [
                {"destination": defaults["addresses"][0], "btc_amount": 5, "out_index": 0},
                {"destination": defaults["addresses"][0], "btc_amount": 10, "out_index": 1},
            ],
        )

    with ProtocolChangesDisabled(["p2sh_addresses", "multisig_addresses"]):
        with pytest.raises(KeyError):
            assert gettxinfo._get_tx_info(
                ledger_db,
                {
                    "coinbase": False,
                    "parsed_vouts": (destinations, btc_amount, fee, b"z", potential_dispensers),
                },
                block_index=None,
            ) == (
                defaults["addresses"][1],
                defaults["addresses"][0],
                10,
                0,
                b"\r\x00",
                [
                    {"destination": defaults["addresses"][0], "btc_amount": 5, "out_index": 0},
                    {"destination": defaults["addresses"][0], "btc_amount": 10, "out_index": 1},
                ],
            )


def test_select_utxo_destination_2():
    assert (
        gettxinfo.select_utxo_destination(
            [
                {"script_pub_key": "6a0b68656c6c6f20776f726c64"},  # OP_RETURN
                {"script_pub_key": "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"},  # P2PKH
            ]
        )
        == 1
    )

    assert (
        gettxinfo.select_utxo_destination(
            [
                {"script_pub_key": "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"},  # P2PKH
                {"script_pub_key": "6a0b68656c6c6f20776f726c64"},  # OP_RETURN
                {"script_pub_key": "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"},  # P2PKH
            ]
        )
        == 0
    )

    assert (
        gettxinfo.select_utxo_destination(
            [
                {"script_pub_key": "6a0b68656c6c6f20776f726c64"},  # OP_RETURN
            ]
        )
        is None
    )


def test_get_inputs_with_balance(ledger_db, defaults):
    utxo = ledger_db.execute(
        "SELECT * FROM balances WHERE utxo_address = ? AND quantity > 0",
        (defaults["addresses"][0],),
    ).fetchone()["utxo"]
    txid, vout = utxo.split(":")

    assert gettxinfo.get_inputs_with_balance(ledger_db, {"vin": [{"hash": txid, "n": vout}]}) == [
        utxo
    ]


def test_get_first_non_op_return_output():
    assert (
        gettxinfo.get_first_non_op_return_output(
            {
                "tx_hash": "tx_hash",
                "vout": [
                    {"script_pub_key": "6a0b68656c6c6f20776f726c64"},  # OP_RETURN
                    {
                        "script_pub_key": "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
                    },  # P2PKH
                ],
            }
        )
        == "tx_hash:1"
    )

    assert (
        gettxinfo.get_first_non_op_return_output(
            {
                "tx_hash": "tx_hash",
                "vout": [
                    {
                        "script_pub_key": "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
                    },  # P2PKH
                    {"script_pub_key": "6a0b68656c6c6f20776f726c64"},  # OP_RETURN
                    {
                        "script_pub_key": "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
                    },  # P2PKH
                ],
            }
        )
        == "tx_hash:0"
    )

    assert (
        gettxinfo.get_first_non_op_return_output(
            {
                "tx_hash": "tx_hash",
                "vout": [
                    {"script_pub_key": "6a0b68656c6c6f20776f726c64"},  # OP_RETURN
                ],
            }
        )
        is None
    )


def test_get_op_return_vout():
    assert (
        gettxinfo.get_op_return_vout({"vout": [{"script_pub_key": "6a0b68656c6c6f20776f726c64"}]})
        == 0
    )

    assert (
        gettxinfo.get_op_return_vout(
            {"vout": [{"script_pub_key": "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"}]}
        )
        is None
    )

    assert (
        gettxinfo.get_op_return_vout(
            {
                "vout": [
                    {"script_pub_key": "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"},
                    {"script_pub_key": "6a0b68656c6c6f20776f726c64"},
                ]
            }
        )
        == 1
    )

    assert gettxinfo.get_op_return_vout({"vout": [{"script_pub_key": "z"}]}) is None


def test_get_utxos_info(ledger_db, defaults):
    utxo = ledger_db.execute(
        "SELECT * FROM balances WHERE utxo_address = ? AND quantity > 0",
        (defaults["addresses"][0],),
    ).fetchone()["utxo"]
    txid, vout = utxo.split(":")

    assert gettxinfo.get_utxos_info(
        ledger_db,
        {
            "tx_id": "tx_id",
            "tx_hash": "tx_hash",
            "vin": [{"hash": txid, "n": vout}],
            "vout": [{"script_pub_key": "6a0b68656c6c6f20776f726c64"}],
        },
    ) == [utxo, "", "1", "0"]

    assert gettxinfo.get_utxos_info(
        ledger_db,
        {
            "tx_id": "tx_id",
            "tx_hash": "tx_hash",
            "vin": [{"hash": txid, "n": vout}],
            "vout": [{"script_pub_key": "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"}],
        },
    ) == [utxo, "tx_hash:0", "1", ""]

    assert gettxinfo.get_utxos_info(
        ledger_db,
        {
            "tx_id": "tx_id",
            "tx_hash": "tx_hash",
            "vin": [{"hash": txid, "n": vout}],
            "vout": [
                {"script_pub_key": "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"},
                {"script_pub_key": "6a0b68656c6c6f20776f726c64"},
            ],
        },
    ) == [utxo, "tx_hash:0", "2", "1"]

    assert gettxinfo.get_utxos_info(
        ledger_db,
        {
            "tx_id": "tx_id",
            "tx_hash": "tx_hash",
            "vin": [{"hash": txid, "n": vout}],
            "vout": [{"script_pub_key": "z"}],
        },
    ) == [utxo, "tx_hash:0", "1", ""]

    assert (
        gettxinfo.get_utxos_info(
            ledger_db,
            {
                "tx_id": "c80143886181ebbc782d23a50acca0f5ea7ac005d3164d7c76fc5e14f72d47c8",  # in KNOWN_SOURCES
                "tx_hash": "tx_hash",
                "vin": [{"hash": txid, "n": vout}],
                "vout": [{"script_pub_key": "z"}],
            },
        )
        == ["", "tx_hash:0", "1", ""]
    )


def test_update_utxo_balances_cache(ledger_db, defaults, current_block_index):
    utxo = ledger_db.execute(
        "SELECT * FROM balances WHERE utxo_address = ? AND quantity > 0",
        (defaults["addresses"][0],),
    ).fetchone()["utxo"]

    utxos_info = [utxo, "tx_hash:0", "2", "1"]

    assert ledger.caches.UTXOBalancesCache(ledger_db).has_balance(utxo)

    gettxinfo.update_utxo_balances_cache(
        ledger_db, utxos_info, b"", defaults["addresses"][1], current_block_index
    )

    assert not ledger.caches.UTXOBalancesCache().has_balance(utxo)
    assert ledger.caches.UTXOBalancesCache().has_balance("tx_hash:0")


def test_get_tx_info_5(ledger_db, defaults, monkeypatch, current_block_index):
    source = defaults["addresses"][1]
    destinations = [defaults["addresses"][0]]
    btc_amount = 100
    fee = 0
    data = b"P2SH"
    potential_dispensers = [
        (defaults["addresses"][0], None),
        (defaults["addresses"][0], 5),
        (defaults["addresses"][0], 10),
    ]
    monkeypatch.setattr(
        gettxinfo, "get_transaction_source_from_p2sh", lambda *args: (source, b"", btc_amount)
    )

    utxo = ledger_db.execute(
        "SELECT * FROM balances WHERE utxo_address = ? AND quantity > 0",
        (defaults["addresses"][0],),
    ).fetchone()["utxo"]
    txid, vout = utxo.split(":")

    with ProtocolChangesDisabled(["disable_vanilla_btc_dispense"]):
        result = gettxinfo.get_tx_info(
            ledger_db,
            {
                "coinbase": False,
                "parsed_vouts": (destinations, btc_amount, fee, data, potential_dispensers),
                "tx_id": "tx_id",
                "tx_hash": "tx_hash",
                "vin": [{"hash": txid, "n": vout}],
                "vout": [{"script_pub_key": "6a0b68656c6c6f20776f726c64"}],
            },
            current_block_index,
        )
        assert result == (b"", None, None, None, None, None, [utxo, "", "1", "0"])
