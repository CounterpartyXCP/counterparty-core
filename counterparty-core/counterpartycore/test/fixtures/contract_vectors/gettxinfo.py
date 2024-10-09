from counterpartycore.lib import deserialize, exceptions

from ..params import DEFAULT_PARAMS as DP

GETTXINFO_VECTOR = {
    "gettxinfo": {
        "get_tx_info": [
            # data in OP_CHECKSIG script
            {
                "in": (
                    deserialize.deserialize_tx(
                        "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0636150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac36150000000000001976a9147da51ea175f108a1c63588683dc4c43a7146c46788ac36150000000000001976a9147da51ea175f108a1c6358868173e34e8ca75a06788ac36150000000000001976a9147da51ea175f108a1c637729895c4c468ca75a06788ac36150000000000001976a9147fa51ea175f108a1c63588682ed4c468ca7fa06788ace24ff505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    5430,
                    10000,
                    b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
                    [],
                    ["4f4a408d8bd90ca994e1f6b0969a8fe1a6bcf33211a4b5bad876d26b6f3a666b:0"],
                ),
            },
            # data in OP_CHECKMULTISIG script
            {
                "in": (
                    deserialize.deserialize_tx(
                        "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    5430,
                    10000,
                    b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
                    [],
                    ["564501b070077eb6e978a547ae28a3e8ec4505da3de856f03a0d127750a44f11:0"],
                ),
            },
            # data in OP_CHECKMULTISIG script, destination = p2sh
            {
                "in": (
                    deserialize.deserialize_tx(
                        "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff03361500000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
                    5430,
                    10000,
                    b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
                    [],
                    ["1f9b910792994070699d898d59217df052bc3568d7b8e4e5d5bba485aa62c73a:0"],
                ),
            },
            {
                # 2 sources is actually invalid, but pre-first_input_is_source this was the consensus!
                "mock_protocol_changes": {"first_input_is_source": False},
                "comment": "data in OP_CHECKMULTISIG script , without first_input_is_source, 2 sources",
                "in": (
                    deserialize.deserialize_tx(
                        "0100000002ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff5ef833190e74ad47d8ae693f841a8b1b500ded7e23ee66b29898b72ec4914fdc0100000000ffffffff03361500000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed2fe7c11000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns-mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
                    "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
                    5430,
                    10000,
                    b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
                    [],
                    ["3481e0520d4f928617e86c0695f3d49faabb10b5432d44eb02e01141a4e6fc4d:0"],
                ),
            },
            {
                "comment": "data in OP_CHECKMULTISIG script, with first_input_is_source, 1 source",
                "in": (
                    deserialize.deserialize_tx(
                        "0100000002ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff5ef833190e74ad47d8ae693f841a8b1b500ded7e23ee66b29898b72ec4914fdc0100000000ffffffff03361500000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed2fe7c11000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
                    5430,
                    10000,
                    b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
                    [],
                    ["3481e0520d4f928617e86c0695f3d49faabb10b5432d44eb02e01141a4e6fc4d:0"],
                ),
            },
        ],
        "get_tx_info_legacy": [
            # data in OP_CHECKSIG script
            {
                "in": (
                    deserialize.deserialize_tx(
                        "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0636150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac36150000000000001976a9147da51ea175f108a1c63588683dc4c43a7146c46788ac36150000000000001976a9147da51ea175f108a1c6358868173e34e8ca75a06788ac36150000000000001976a9147da51ea175f108a1c637729895c4c468ca75a06788ac36150000000000001976a9147fa51ea175f108a1c63588682ed4c468ca7fa06788ace24ff505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    5430,
                    10000,
                    b"\x00\x00\x00(\x00\x00R\xbb3d\x00TESTXXXX\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00TESTXXXX\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00TESTXXXX\x00\x00\x00;\x10\x00\x00\x00\n\x9b\xb3Q\x92(6\xc8\x86\x81i\x87\xe1\x0b\x03\xb8_8v\x8b",
                    [],
                ),
            },
            # # data in OP_CHECKMULTISIG script, unsupported by get_tx_info1
            # {
            #     'in': (b'0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000', DP['default_block_index']),
            #     'error': (exceptions.DecodeError, 'no prefix')
            # },
            # # data in OP_CHECKSIG script, destination = p2sh, unsupported by get_tx_info1
            # {
            #     'in': (b'0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff06361500000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e8736150000000000001976a9147da51ea175f108a1c63588683dc4c43a7146c46788ac36150000000000001976a9147da51ea175f108a1c6358868173e34e8ca75a06788ac36150000000000001976a9147da51ea175f108a1c637729895c4c468ca75a06788ac36150000000000001976a9147fa51ea175f108a1c63588682ed4c468ca7fa06788ace24ff505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000', DP['default_block_index']),
            #     'error': (exceptions.DecodeError, 'no prefix')
            # }
        ],
        "get_tx_info_new": [
            # data in OP_CHECKSIG script
            {
                "in": (
                    deserialize.deserialize_tx(
                        "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0636150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac36150000000000001976a9147da51ea175f108a1c63588683dc4c43a7146c46788ac36150000000000001976a9147da51ea175f108a1c6358868173e34e8ca75a06788ac36150000000000001976a9147da51ea175f108a1c637729895c4c468ca75a06788ac36150000000000001976a9147fa51ea175f108a1c63588682ed4c468ca7fa06788ace24ff505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    5430,
                    10000,
                    b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
                    [],
                ),
            },
            # data in OP_CHECKMULTISIG script
            {
                "in": (
                    deserialize.deserialize_tx(
                        "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    5430,
                    10000,
                    b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
                    [],
                ),
            },
            # data in OP_CHECKMULTISIG script, destination = p2sh, unsupported by get_tx_info2
            {
                "in": (
                    deserialize.deserialize_tx(
                        "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff03361500000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
                    5430,
                    10000,
                    b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
                    [],
                ),
            },
            #'get_tx_info3'
            # data in OP_CHECKSIG script
            {
                "in": (
                    deserialize.deserialize_tx(
                        "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0636150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac36150000000000001976a9147da51ea175f108a1c63588683dc4c43a7146c46788ac36150000000000001976a9147da51ea175f108a1c6358868173e34e8ca75a06788ac36150000000000001976a9147da51ea175f108a1c637729895c4c468ca75a06788ac36150000000000001976a9147fa51ea175f108a1c63588682ed4c468ca7fa06788ace24ff505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                    None,
                    True,
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    5430,
                    10000,
                    b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
                    [],
                ),
            },
            # data in OP_CHECKMULTISIG script
            {
                "in": (
                    deserialize.deserialize_tx(
                        "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                    None,
                    True,
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    5430,
                    10000,
                    b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
                    [],
                ),
            },
            # data in OP_CHECKMULTISIG script, destination = p2sh, unsupported by get_tx_info2
            {
                "in": (
                    deserialize.deserialize_tx(
                        "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff03361500000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                    None,
                    True,
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
                    5430,
                    10000,
                    b"\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n",
                    [],
                ),
            },
            {
                "in": (
                    deserialize.deserialize_tx(
                        "0100000001aee668de98ef5f37d4962b620b0ec3deed8bbd4c2fb8ddedaf36c2e8ca5e51a7060000001976a914f3a6b6e4a093e5a5b9da76977a5270fd4d62553e88acffffffff04781e000000000000695121027c6a5e4412be80b5ccd5aa0ea685a21e7a577a5e390d138288841d06514b47992103b00007171817fb044e8a5464e3e274210dd64cf68cca9ea9c3e06df384aae6b22103d928d7d5bbe6f435da935ed382a0061c4a22bdc9b60a2ce6deb7d0f134d22eef53ae781e000000000000695121037c6a5e4412be80b5cc13bde2d9b04fd2cd1fc7ff664c0d3b6d8133163857b08f2103bb6fba40bee91bb02b54835b32f14b9e04016bfa34411ec64f09e3a9586efd5d2103d928d7d5bbe6f435da935ed382a0061c4a22bdc9b60a2ce6deb7d0f134d22eef53ae781e00000000000069512102696a5e4412be80b5ccd6aa0ac9a95e43ca49a21d40f762fadc1aab1c25909fb02102176c68252c6b855d7967aee372f14b772c963b2aa0411ec64f09e3a951eefd3e2103d928d7d5bbe6f435da935ed382a0061c4a22bdc9b60a2ce6deb7d0f134d22eef53aea8d37700000000001976a914f3a6b6e4a093e5a5b9da76977a5270fd4d62553e88ac00000000",
                        use_txid=True,
                    ),
                    DP["default_block_index"],
                    None,
                    True,
                ),
                "error": (exceptions.BTCOnlyError, "no data and not unspendable"),
                #'out': (0,)
            },
        ],
        "select_utxo_destination": [
            {
                # invalid script
                "in": (
                    [
                        {
                            "script_pub_key": b"j] \x02\x03\x04\xfb\x8b\xdd\xe7\xe4\x9d\x9d\xaf\xcc\x8a\x93\xcd\xe0\xa2\x01\x05A\x06\x80\xc2\xd7/\n\xe8\x07\x08\x88\xa4\x01\x16\x01"
                        }
                    ],
                ),
                "out": 0,
            },
            {
                "in": (
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
                ),
                "out": 1,
            },
            {
                "in": (
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
                ),
                "out": 1,
            },
            {
                "in": (
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
                ),
                "out": 0,
            },
        ],
    },
}
