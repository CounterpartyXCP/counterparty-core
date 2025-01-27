import binascii

import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.parser import deserialize, gettxinfo


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

    assert gettxinfo.get_tx_info_new(
        ledger_db,
        deserialize.deserialize_tx(
            "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff03361500000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            parse_vouts=True,
            block_index=current_block_index,
        ),
        current_block_index,
        None,
        True,
    ) == (
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
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
                "segwit": False,
                "vin": [
                    {
                        "script_sig": binascii.unhexlify(
                            "00483045022100af204ef91b8dba5884df50f87219ccef22014c21dd05aa44470d4ed800b7f6e40220428fe058684db1bb2bfb6061bff67048592c574effc217f0d150daedcf36787601483045022100e8547aa2c2a2761a5a28806d3ae0d1bbf0aeff782f9081dfea67b86cacb321340220771a166929469c34959daf726a2ac0c253f9aff391e58a3c7cb46d8b7e0fdc4801"
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
                            "00483045022100af204ef91b8dba5884df50f87219ccef22014c21dd05aa44470d4ed800b7f6e40220428fe058684db1bb2bfb6061bff67048592c574effc217f0d150daedcf36787601483045022100e8547aa2c2a2761a5a28806d3ae0d1bbf0aeff782f9081dfea67b86cacb321340220771a166929469c34959daf726a2ac0c253f9aff391e58a3c7cb46d8b7e0fdc4883"
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
