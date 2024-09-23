from counterpartycore.lib import config, exceptions, script

from ..params import (
    ADDR,
    DP,
    P2SH_ADDR,
)

TRANSACTION_VECTOR = {
    "transaction": {
        "get_dust_return_pubkey": [
            {"in": (ADDR[1], None), "out": None},
            {
                "in": (ADDR[1], []),
                "out": b"\x03\x19\xf6\xe0{\x0b\x8duaV9K\x9d\xcf;\x01\x1f\xe9\xac\x19\xf2p\x0b\xd6\xb6\x9aj\x17\x83\xdb\xb8\xb9w",
            },
        ],
        "construct": [
            {
                "in": (
                    (
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        [("mvCounterpartyXXXXXXXXXXXXXXW24Hef", 62000000)],
                        None,
                    ),
                    {"encoding": "multisig", "fee": 1.0},
                ),
                "error": (exceptions.TransactionError, "Exact fees must be in satoshis."),
            },
            {
                "in": (
                    (
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        [("mvCounterpartyXXXXXXXXXXXXXXW24Hef", 62000000)],
                        None,
                    ),
                    {"encoding": "multisig", "fee_provided": 1.0},
                ),
                "error": (exceptions.TransactionError, "Fee provided must be in satoshis."),
            },
            {
                "in": (
                    (
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        [
                            (
                                "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                                config.DEFAULT_REGULAR_DUST_SIZE - 1,
                            )
                        ],
                        None,
                    ),
                    {"encoding": "singlesig", "regular_dust_size": DP["regular_dust_size"]},
                ),
                "error": (exceptions.TransactionError, "Destination output is dust."),
            },
            {
                "in": (
                    (
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        [
                            (
                                "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                                config.DEFAULT_MULTISIG_DUST_SIZE - 1,
                            )
                        ],
                        None,
                    ),
                    {"encoding": "multisig"},
                ),
                "error": (exceptions.TransactionError, "Destination output is dust."),
            },
            {
                "in": (
                    (
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        [("mvCounterpartyXXXXXXXXXXXXXXW24Hef", 62000000)],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    ),
                    {"encoding": "foobar"},
                ),
                "error": (exceptions.TransactionError, "Unknown encoding‐scheme."),
            },
            {
                "comment": "opreturn encoding with more data that fits in 80 bytes opreturn (73 bytes of data + 8 bytes for PREFIX)",
                "in": (
                    (
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        [("mvCounterpartyXXXXXXXXXXXXXXW24Hef", 62000000)],
                        b"\x00" * 73,
                    ),
                    {"encoding": "opreturn"},
                ),
                "error": (
                    exceptions.TransactionError,
                    "One `OP_RETURN` output per transaction.",
                ),
            },
            {
                "in": (
                    (
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        [("mvCounterpartyXXXXXXXXXXXXXXW24Hef", 2**30)],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    ),
                    {"encoding": "multisig"},
                ),
                "error": (
                    exceptions.BalanceError,
                    "Insufficient BTC at address mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns. Need: 10.73754999 BTC (Including fee: 0.00012175 BTC), available: 1.11121663 BTC. These fees are estimated for a confirmation target of 3 blocks, you can reduce them by using the `confirmation_target` parameter with a higher value or by manually setting the fees with the `fee` parameter. To spend unconfirmed coins, use the flag `--unconfirmed`. (Unconfirmed coins cannot be spent from multi‐sig addresses.)",
                ),
            },
            {
                "comment": "opreturn encoding with maximum possible data that fits in 80 bytes opreturn (72 bytes of data + 8 bytes for PREFIX)",
                "in": (
                    (
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        [("mvCounterpartyXXXXXXXXXXXXXXW24Hef", 62000000)],
                        b"\x00" * 72,
                    ),
                    {"encoding": "opreturn"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
                    "btc_change": 37992125,
                    "btc_fee": 7875,
                    "btc_in": 100000000,
                    "btc_out": 62000000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff03800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac0000000000000000536a4c503ab408a679f108a19e35886815c4c468ca75a06799f864a1fad6bc0813f5fe3260e421a30202f2e76f46acdb292c652371ca48b97460f7928ade8ecb02ea9fadc20c0b453de6676872c9e41fad801e8bbdb64302000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                },
            },
            {
                "comment": "burn",
                "in": (
                    (
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        [("mvCounterpartyXXXXXXXXXXXXXXW24Hef", 62000000)],
                        None,
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": None,
                    "btc_change": 37994375,
                    "btc_fee": 5625,
                    "btc_in": 100000000,
                    "btc_out": 62000000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac87bf4302000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                },
            },
            {
                "comment": "burn P2SH",
                "in": (
                    (P2SH_ADDR[0], [("mvCounterpartyXXXXXXXXXXXXXXW24Hef", 62000000)], None),
                    {"encoding": "multisig", "regular_dust_size": DP["regular_dust_size"]},
                ),
                "out": {
                    "data": None,
                    "btc_change": 37994375,
                    "btc_fee": 5625,
                    "btc_in": 100000000,
                    "btc_out": 62000000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "01000000015001af2c4c3bc2c43b6233261394910d10fb157a082d9b3038c65f2d01e4ff200000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87ffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac87bf43020000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e8700000000",
                },
            },
            {
                "comment": "multisig burn",
                "in": (
                    (
                        "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        [("mvCounterpartyXXXXXXXXXXXXXXW24Hef", 50000000)],
                        None,
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": None,
                    "btc_change": 49994375,
                    "btc_fee": 5625,
                    "btc_in": 100000000,
                    "btc_out": 50000000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff0280f0fa02000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac87dafa02000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000",
                },
            },
            {
                "comment": "send",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    ),
                    {"encoding": "multisig", "regular_dust_size": DP["regular_dust_size"]},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    "btc_change": 199895060,
                    "btc_fee": 7650,
                    "btc_in": 199909140,
                    "btc_out": 6430,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace8030000000000006951210262415bf04af834423d3dd7ada4dc727a030865759f9fba5aee78c9ea71e58798210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae1428ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "send with custom input which is too low",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    ),
                    {
                        "encoding": "multisig",
                        "regular_dust_size": DP["regular_dust_size"],
                        "inputs_set": [
                            {
                                "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                                "txhex": "0100000002eff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b000000006c493046022100ec6fa8316a4f5cfd69816e31011022acce0933bd3b01248caa8b49e60de1b98a022100987ba974b2a4f9976a8d61d94009cb7f7986a827dc5730e999de1fb748d2046c01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffffeff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b010000006a47304402201f8fb2d62df22592cb8d37c68ab26563dbb8e270f7f8409ac0f6d7b24ddb5c940220314e5c767fd12b20116528c028eab2bfbad30eb963bd849993410049cf14a83d01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffff02145fea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000346a32544553540000000a00000000000000010000000005f5e1000000000000000000000000000bebc2000032000000000000271000000000",
                                "confirmations": 74,
                                "vout": 0,
                                "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                                "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                                "amount": 0.00001,
                                "account": "",
                            }
                        ],
                    },
                ),
                "error": (
                    exceptions.BalanceError,
                    "Insufficient BTC at address mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc. Need: 0.0001408 BTC (Including fee: 0.0000765 BTC), available: 0.00001 BTC. These fees are estimated for a confirmation target of 3 blocks, you can reduce them by using the `confirmation_target` parameter with a higher value or by manually setting the fees with the `fee` parameter. To spend unconfirmed coins, use the flag `--unconfirmed`. (Unconfirmed coins cannot be spent from multi‐sig addresses.)",
                ),
            },
            {
                "comment": "send with custom input",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    ),
                    {
                        "encoding": "multisig",
                        "regular_dust_size": DP["regular_dust_size"],
                        "inputs_set": [
                            {
                                "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                                "txhex": "0100000002eff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b000000006c493046022100ec6fa8316a4f5cfd69816e31011022acce0933bd3b01248caa8b49e60de1b98a022100987ba974b2a4f9976a8d61d94009cb7f7986a827dc5730e999de1fb748d2046c01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffffeff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b010000006a47304402201f8fb2d62df22592cb8d37c68ab26563dbb8e270f7f8409ac0f6d7b24ddb5c940220314e5c767fd12b20116528c028eab2bfbad30eb963bd849993410049cf14a83d01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffff02145fea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000346a32544553540000000a00000000000000010000000005f5e1000000000000000000000000000bebc2000032000000000000271000000000",
                                "confirmations": 74,
                                "vout": 0,
                                "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                                "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                                "amount": 1.9990914,
                                "account": "",
                            }
                        ],
                    },
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    "btc_change": 199895060,
                    "btc_fee": 7650,
                    "btc_in": 199909140,
                    "btc_out": 6430,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace8030000000000006951210262415bf04af834423d3dd7ada4dc727a030865759f9fba5aee78c9ea71e58798210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae1428ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "send with multisig encoding and bytespersigop enabled for address with multiple UTXOs",
                "mock_protocol_changes": {"bytespersigop": True},
                "in": (
                    (
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        [("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", None)],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    ),
                    {"encoding": "multisig", "regular_dust_size": DP["regular_dust_size"]},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    "btc_change": 111103058,
                    "btc_fee": 12175,
                    "btc_in": 111121663,
                    "btc_out": 6430,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000002ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff85497c27fbc3ecfbfb41f49cbf983e252a91636ec92f2863cb7eb755a33afcb9000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ace8030000000000006951210372a51ea175f108a1c635886815c4c468ca75a06798f864a1fad446f893f5fef121023260e421a30202f2e76f46acdb292c652371ca48b97460f7928ade8ecb02ea66210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae524c9f06000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
                },
            },
            {
                "comment": "send, different dust pubkey",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    ),
                    {
                        "encoding": "multisig",
                        "regular_dust_size": DP["regular_dust_size"],
                        "dust_return_pubkey": "0319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b977",
                    },
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    "btc_change": 199895060,
                    "btc_fee": 7650,
                    "btc_in": 199909140,
                    "btc_out": 6430,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace8030000000000006951210262415bf04af834423d3dd7ada4dc727a030865759f9fba5aee78c9ea71e58798210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae1428ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "send, burn dust pubkey",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    ),
                    {
                        "encoding": "multisig",
                        "regular_dust_size": DP["regular_dust_size"],
                        "dust_return_pubkey": False,
                    },
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    "btc_change": 199895060,
                    "btc_fee": 7650,
                    "btc_in": 199909140,
                    "btc_out": 6430,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace8030000000000006951210262415bf04af834423d3dd7ada4dc727a030865759f9fba5aee78c9ea71e58798210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724472111111111111111111111111111111111111111111111111111111111111111111153ae1428ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "send from P2SH address, multsig encoding, no dust pubkey",
                "in": (
                    (
                        P2SH_ADDR[0],
                        [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    ),
                    {
                        "encoding": "multisig",
                        "dust_return_pubkey": False,
                        "regular_dust_size": DP["regular_dust_size"],
                    },
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    "btc_change": 99985920,
                    "btc_fee": 7650,
                    "btc_in": 100000000,
                    "btc_out": 6430,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "01000000015001af2c4c3bc2c43b6233261394910d10fb157a082d9b3038c65f2d01e4ff200000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87ffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace8030000000000006951210397b51de78b0f3a171f5ed27fff56d17dcba739c8b00035c8bbb9c380fdc4ed1321036932bcbeac2a4d8846b7feb4bf93b2b88efd02f2d8dc1fc0067bcc972257e3912111111111111111111111111111111111111111111111111111111111111111111153ae00aaf5050000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e8700000000",
                },
            },
            {
                "comment": "send to P2SH address",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [(P2SH_ADDR[0], None)],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    ),
                    {"encoding": "multisig", "regular_dust_size": DP["regular_dust_size"]},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                    "btc_change": 199895060,
                    "btc_fee": 7650,
                    "btc_in": 199909140,
                    "btc_out": 6430,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03361500000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87e8030000000000006951210262415bf04af834423d3dd7ada4dc727a030865759f9fba5aee78c9ea71e58798210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae1428ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "send dest multisig",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [
                            (
                                "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                                None,
                            )
                        ],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                    "btc_change": 199899490,
                    "btc_fee": 7650,
                    "btc_in": 199909140,
                    "btc_out": 2000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee8030000000000006951210362415bf04af834423d3dd7ada4dc727a030865759f9fba5aee7fc6fbf1e5875a210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae6239ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "send dest multisig exact_fee",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [
                            (
                                "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                                None,
                            )
                        ],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                    ),
                    {"encoding": "multisig", "fee": 1},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                    "btc_change": 199907139,
                    "btc_fee": 1,
                    "btc_in": 199909140,
                    "btc_out": 2000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee8030000000000006951210362415bf04af834423d3dd7ada4dc727a030865759f9fba5aee7fc6fbf1e5875a210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae4357ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "send dest opreturn",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [
                            (
                                "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                                None,
                            )
                        ],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                    ),
                    {"encoding": "opreturn"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                    "btc_change": 199901565,
                    "btc_fee": 6575,
                    "btc_in": 199909140,
                    "btc_out": 1000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000000000001e6a1c2a504df746f83442653dd7ada4dc727a030865749e9fba5aeb8fd21a7d41ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "send dest pubkeyhash",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [
                            (
                                "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                                None,
                            )
                        ],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                    ),
                    {"encoding": "pubkeyhash", "regular_dust_size": DP["regular_dust_size"]},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                    "btc_change": 199889955,
                    "btc_fee": 7325,
                    "btc_in": 199909140,
                    "btc_out": 11860,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff04e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae36150000000000001976a9146d415bf04af834423d3dd7ada4dc727a0308657588ac36150000000000001976a9146f415bf04af834423d3cd7ada4dc778fe208657588ac2314ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "send dest 1-of-1",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [("1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_1", None)],
                        b"\x00\x00\x00\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00",
                    ),
                    {"encoding": "multisig"},
                ),
                "error": (script.MultiSigAddressError, "Invalid signatures_possible."),
            },
            {
                "comment": "send source multisig",
                "in": (
                    (
                        "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        [("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", None)],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                    ),
                    {"encoding": "multisig", "regular_dust_size": DP["regular_dust_size"]},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                    "btc_change": 99985920,
                    "btc_fee": 7650,
                    "btc_in": 100000000,
                    "btc_out": 6430,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ace8030000000000006951210334caf7ca87f0fd78a01d9a0d68221e55beef3722da8be72d254dd351c26108892102bc14528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b57d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae00aaf505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000",
                },
            },
            {
                "comment": "send source and dest multisig",
                "in": (
                    (
                        "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        [
                            (
                                "1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                                None,
                            )
                        ],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                    "btc_change": 99990350,
                    "btc_fee": 7650,
                    "btc_in": 100000000,
                    "btc_out": 2000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff03e8030000000000004751210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b977210378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b52aee8030000000000006951210334caf7ca87f0fd78a01d9a0d68221e55beef3722da8be72d254dd351c26108892102bc14528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b57d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae4ebbf505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000",
                },
            },
            {
                "comment": "maximum quantity send",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
                        b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff",
                    ),
                    {"encoding": "multisig", "regular_dust_size": DP["regular_dust_size"]},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff",
                    "btc_change": 199895060,
                    "btc_fee": 7650,
                    "btc_in": 199909140,
                    "btc_out": 6430,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace8030000000000006951210362415bf04af834423d3dd7ada4dc727a0308664fa0e045a51185cce50ee58717210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae1428ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "issuance",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [],
                        b"\x00\x00\x00\x16\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0NULL",
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x16\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0NULL",
                    "btc_change": 199901340,
                    "btc_fee": 6800,
                    "btc_in": 199909140,
                    "btc_out": 1000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02e8030000000000006951210355415bf04af834423d3dd7adb2dc727a03086e897d9fba5aee7a331919e48780210254da540fb2663b75268d992d550ad0c2431643bab28ced783cd94079bbe7244d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae9c40ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "issuance",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
                        b"\x00\x00\x00\x16\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0NULL",
                    ),
                    {"encoding": "multisig", "regular_dust_size": DP["regular_dust_size"]},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x16\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0NULL",
                    "btc_change": 199895060,
                    "btc_fee": 7650,
                    "btc_in": 199909140,
                    "btc_out": 6430,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace8030000000000006951210355415bf04af834423d3dd7adb2dc727aa153863ef89fba5aee7a331af1e48750210254da540fb2663b75268d992d550ad0c2431643bab28ced783cd94079bbe7244d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae1428ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "multisig issuance",
                "in": (
                    (
                        "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        [],
                        b"\x00\x00\x00\x16\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0NULL",
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x16\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0NULL",
                    "btc_change": 99992200,
                    "btc_fee": 6800,
                    "btc_in": 100000000,
                    "btc_out": 1000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02e8030000000000006951210203caf7ca87f0fd78a01d9a0d7e221e55beef3cde388be72d254826b32a6008b62103bc14528340c27d009ae7b7dd73d8c032ffa94625307a450077125d580099b55a210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae88c2f505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000",
                },
            },
            {
                "comment": "maximum quantity issuance",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [],
                        b"\x00\x00\x00\x16\x00\x00\x00\x00\xdd\x96\xd2t\x7f\xff\xff\xff\xff\xff\xff\xff\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0NULL",
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x16\x00\x00\x00\x00\xdd\x96\xd2t\x7f\xff\xff\xff\xff\xff\xff\xff\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0NULL",
                    "btc_change": 199901340,
                    "btc_fee": 6800,
                    "btc_in": 199909140,
                    "btc_out": 1000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02e8030000000000006951210355415bf04af834423d3dd7adb2dc727a03d5f3a7eae045a51185cce50ee487c2210254da540fb2663b75268d992d550ad0c2431643bab28ced783cd94079bbe7244d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae9c40ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "transfer asset to multisig",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [
                            (
                                "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                                None,
                            )
                        ],
                        b"\x00\x00\x00\x16\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0NULL",
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x16\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0NULL",
                    "btc_change": 199899490,
                    "btc_fee": 7650,
                    "btc_in": 199909140,
                    "btc_out": 2000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee8030000000000006951210355415bf04af834423d3dd7adb2dc727aa153863ef89fba5aee7a331af1e48750210254da540fb2663b75268d992d550ad0c2431643bab28ced783cd94079bbe7244d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae6239ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "order",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [],
                        b"\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00",
                    ),
                    {"encoding": "multisig", "fee_provided": DP["fee_provided"]},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00",
                    "btc_change": 198908140,
                    "btc_fee": 1000000,
                    "btc_in": 199909140,
                    "btc_out": 1000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02e8030000000000006951210348415bf04af834423d3dd7adaedc727a030865759e9fba5aee78c9ea71e5870f210354da540fb2673b75e6c3c994f80ad0c8431643bab28ced783cd94079bbe72445210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aeec18db0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "multisig order",
                "in": (
                    (
                        "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        [],
                        b"\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00",
                    ),
                    {"encoding": "multisig", "fee_provided": DP["fee_provided"]},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00",
                    "btc_change": 98999000,
                    "btc_fee": 1000000,
                    "btc_in": 100000000,
                    "btc_out": 1000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02e803000000000000695121021ecaf7ca87f0fd78a01d9a0d62221e55beef3722db8be72d254adc40426108d02103bc14528340c37d005aa9e764ded8c038ffa94625307a450077125d580099b53b210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed89ae605000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000",
                },
            },
            {
                "comment": "multisig order",
                "in": (
                    (
                        "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        [],
                        b"\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0",
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0",
                    "btc_change": 99992200,
                    "btc_fee": 6800,
                    "btc_in": 100000000,
                    "btc_out": 1000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02e803000000000000695121031ecaf7ca87f0fd78a01d9a0d62221e55beef3722da8be72d254e649c8261083d2102bc14528340c27d005aa9e06bcf58c038ffa946253077fea077125d580099b5bb210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae88c2f505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000",
                },
            },
            {
                "comment": "maximum quantity order",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [],
                        b"\x00\x00\x00\n\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0",
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\n\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0",
                    "btc_change": 199901340,
                    "btc_fee": 6800,
                    "btc_in": 199909140,
                    "btc_out": 1000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02e8030000000000006951210248415bf04af834423d3dd7adaedc727a0308664fa0e045a51185cce50ee58759210354da540fb2673b75e6c3c994f80ad0c8431643bab28156d83cd94079bbe72452210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae9c40ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "dividend",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [],
                        b"\x00\x00\x002\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01",
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x002\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01",
                    "btc_change": 199901340,
                    "btc_fee": 6800,
                    "btc_in": 199909140,
                    "btc_out": 1000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02e803000000000000695121035a415bf04af834423d3dd7ad96dc727a030d90949e9fba5a4c21d05197e58735210254da540fb2673b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe7246f210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae9c40ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "dividend",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [],
                        b"\x00\x00\x002\x00\x00\x00\x00\x00\x00\x00\x01\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x00\x01",
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x002\x00\x00\x00\x00\x00\x00\x00\x01\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x00\x01",
                    "btc_change": 199901340,
                    "btc_fee": 6800,
                    "btc_in": 199909140,
                    "btc_out": 1000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02e803000000000000695121025a415bf04af834423d3dd7ad96dc727a030865759f9fbc9036a64c1197e587c8210254da540fb2673b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe7246f210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae9c40ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "free issuance",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [],
                        b"\x00\x00\x00\x16\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0NULL",
                    ),
                    {"encoding": "multisig"},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x16\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0NULL",
                    "btc_change": 199901340,
                    "btc_fee": 6800,
                    "btc_in": 199909140,
                    "btc_out": 1000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02e8030000000000006951210255415bf04af834423d3dd7adb2238d85fcf79a8a619fba5aee7a331919e4870d210254da540fb2663b75268d992d550ad0c2431643bab28ced783cd94079bbe7244d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae9c40ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
            {
                "comment": "large broadcast",
                "in": (
                    (
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        [],
                        b"\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00LK@lOver 80 characters test test test test test test test test test test test test test test test test test test",
                    ),
                    {},
                ),
                "out": {
                    "data": b"TESTXXXX\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00LK@lOver 80 characters test test test test test test test test test test test test test test test test test test",
                    "btc_change": 199895290,
                    "btc_fee": 10850,
                    "btc_in": 199909140,
                    "btc_out": 3000,
                    "unsigned_pretx_hex": None,
                    "unsigned_tx_hex": "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff04e8030000000000006951210343415bf04af834423d3dd7adba82d48f033795759e9fba5aee7a7f51b189c8c0210322bf262f8a561b168ea2be007a7eb5b0303637dfc1f8cd0c59aa3459cf825784210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aee8030000000000006951210343415bf04af834423d49f7d9c1af065a776d1601beebdf299a5a477f8291a7c4210220bf277b92125e0692e3b8046a7ef0b62665379ac6e99e0c1cad250acfc750c9210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aee8030000000000006951210361415bf04af834423d58a4d984a8170977281110edeb9a2e8b09473a8580f45d210220da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724dc210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aefa28ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                },
            },
        ],
    },
}
