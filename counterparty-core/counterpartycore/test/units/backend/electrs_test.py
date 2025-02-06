from counterpartycore.lib.backend import electrs
from counterpartycore.lib.utils import helpers


def test_search_pubkey_bech32(monkeypatch):
    monkeypatch.setattr(
        "counterpartycore.lib.backend.electrs.get_history",
        lambda x: [
            {
                "txid": "f8d74847198e409c3aa79eeb2c101e8fbb894a03858493d2ac3deb7970d12015",
                "version": 2,
                "locktime": 0,
                "vin": [
                    {
                        "txid": "e05a9501ac6f4cdc3f393a20e0e65a5079e6c346201722493294fe6033895219",
                        "vout": 1,
                        "prevout": {
                            "scriptpubkey": "00146150f9d41f5f0b7841f6be50eda0b5f9a7a81357",
                            "scriptpubkey_asm": "OP_0 OP_PUSHBYTES_20 6150f9d41f5f0b7841f6be50eda0b5f9a7a81357",
                            "scriptpubkey_type": "v0_p2wpkh",
                            "scriptpubkey_address": "tb1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a",
                            "value": 499368,
                        },
                        "scriptsig": "",
                        "scriptsig_asm": "",
                        "witness": [
                            "304402206c7475c0ef65f369ec2ff0bdb35b433f3ad2215b75b0856965e92b575f112d030220515a8aeeb4dc460a545e40c174879d80c9467b4926a328531078ab3d6c67e86101",
                            "03821862113e63dcc139fb2e2c752ddcf64b2aaf40bf13ad6a0a29790f3ead77ac",
                        ],
                        "is_coinbase": False,
                        "sequence": 4294967295,
                    }
                ],
                "vout": [
                    {
                        "scriptpubkey": "0014ece41d226060118079cbea4f35ac5c1dbd11fe86",
                        "scriptpubkey_asm": "OP_0 OP_PUSHBYTES_20 ece41d226060118079cbea4f35ac5c1dbd11fe86",
                        "scriptpubkey_type": "v0_p2wpkh",
                        "scriptpubkey_address": "tb1qanjp6gnqvqgcq7wtaf8nttzurk73rl5xqk08hs",
                        "value": 10000,
                    },
                    {
                        "scriptpubkey": "00146150f9d41f5f0b7841f6be50eda0b5f9a7a81357",
                        "scriptpubkey_asm": "OP_0 OP_PUSHBYTES_20 6150f9d41f5f0b7841f6be50eda0b5f9a7a81357",
                        "scriptpubkey_type": "v0_p2wpkh",
                        "scriptpubkey_address": "tb1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a",
                        "value": 487958,
                    },
                ],
                "size": 222,
                "weight": 561,
                "sigops": 1,
                "fee": 1410,
                "status": {
                    "confirmed": True,
                    "block_height": 68994,
                    "block_hash": "000000000bf9eab2adae97280fbf4a352385c932e93f0a042da4c125a4ec493e",
                    "block_time": 1738780028,
                },
            }
        ],
    )

    helpers.setup_bitcoinutils("testnet")

    assert electrs.search_pubkey("tb1qanjp6gnqvqgcq7wtaf8nttzurk73rl5xqk08hs") is None
    assert (
        electrs.search_pubkey("tb1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a")
        == "03821862113e63dcc139fb2e2c752ddcf64b2aaf40bf13ad6a0a29790f3ead77ac"
    )

    helpers.setup_bitcoinutils("regtest")


def test_search_pubkey_p2pkh(monkeypatch):
    monkeypatch.setattr(
        "counterpartycore.lib.backend.electrs.get_history",
        lambda x: [
            {
                "txid": "c9affbbc45a8749dcb96632356976578fa9f72d4578a34b6bba23e9021b30b32",
                "version": 2,
                "locktime": 0,
                "vin": [
                    {
                        "txid": "33e3ce1cd0c5a956ba6e253d6ebb9ce3b391bce1c7d07a95468c842ea4a07e02",
                        "vout": 1,
                        "prevout": {
                            "scriptpubkey": "76a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac",
                            "scriptpubkey_asm": "OP_DUP OP_HASH160 OP_PUSHBYTES_20 412463039be25be1bef6e6dbc5eb8eb18cf95694 OP_EQUALVERIFY OP_CHECKSIG",
                            "scriptpubkey_type": "p2pkh",
                            "scriptpubkey_address": "mmTPoijZbv5sLkCpbG6JkjFkWR89WCJL7G",
                            "value": 52385296,
                        },
                        "scriptsig": "4730440220087bd28db6494b706e59a8e019a00f98b47e04abc77c0aa1b6abdf9c79039c6a0220680eec608563c7827e69d50d199652e4e4ca61a1c6eba3711e87180658e4dde7012103a3770379e091cf67ee8a30752c4df2b5bcc61e2bca1e061da78438f18efe8be6",
                        "scriptsig_asm": "OP_PUSHBYTES_71 30440220087bd28db6494b706e59a8e019a00f98b47e04abc77c0aa1b6abdf9c79039c6a0220680eec608563c7827e69d50d199652e4e4ca61a1c6eba3711e87180658e4dde701 OP_PUSHBYTES_33 03a3770379e091cf67ee8a30752c4df2b5bcc61e2bca1e061da78438f18efe8be6",
                        "is_coinbase": False,
                        "sequence": 4294967295,
                    }
                ],
                "vout": [
                    {
                        "scriptpubkey": "6a34696f6e3a312e516d5a5a6534715150626774314d68453645534771464d57763855786f59505768735654355a59627535756d6947",
                        "scriptpubkey_asm": "OP_RETURN OP_PUSHBYTES_52 696f6e3a312e516d5a5a6534715150626774314d68453645534771464d57763855786f59505768735654355a59627535756d6947",
                        "scriptpubkey_type": "op_return",
                        "value": 0,
                    },
                    {
                        "scriptpubkey": "76a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac",
                        "scriptpubkey_asm": "OP_DUP OP_HASH160 OP_PUSHBYTES_20 412463039be25be1bef6e6dbc5eb8eb18cf95694 OP_EQUALVERIFY OP_CHECKSIG",
                        "scriptpubkey_type": "p2pkh",
                        "scriptpubkey_address": "mmTPoijZbv5sLkCpbG6JkjFkWR89WCJL7G",
                        "value": 52310396,
                    },
                ],
                "size": 254,
                "weight": 1016,
                "sigops": 4,
                "fee": 74900,
                "status": {
                    "confirmed": True,
                    "block_height": 66100,
                    "block_hash": "0000000056ed6b0f69fb51d0a690b78b1ffaf44ef01f1380d3528fc430903f76",
                    "block_time": 1737479508,
                },
            }
        ],
    )

    helpers.setup_bitcoinutils("testnet")
    assert (
        electrs.search_pubkey("mmTPoijZbv5sLkCpbG6JkjFkWR89WCJL7G")
        == "03a3770379e091cf67ee8a30752c4df2b5bcc61e2bca1e061da78438f18efe8be6"
    )
    assert electrs.search_pubkey("tb1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a") is None
    helpers.setup_bitcoinutils("regtest")


def test_search_pubkey_p2pk(monkeypatch):
    monkeypatch.setattr(
        "counterpartycore.lib.backend.electrs.get_history",
        lambda x: [
            {
                "txid": "c9affbbc45a8749dcb96632356976578fa9f72d4578a34b6bba23e9021b30b32",
                "version": 2,
                "locktime": 0,
                "vin": [
                    {
                        "txid": "33e3ce1cd0c5a956ba6e253d6ebb9ce3b391bce1c7d07a95468c842ea4a07e02",
                        "vout": 1,
                        "prevout": {
                            "scriptpubkey": "76a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac",
                            "scriptpubkey_asm": "OP_DUP OP_HASH160 OP_PUSHBYTES_20 412463039be25be1bef6e6dbc5eb8eb18cf95694 OP_EQUALVERIFY OP_CHECKSIG",
                            "scriptpubkey_type": "p2pkh",
                            "scriptpubkey_address": "mmTPoijZbv5sLkCpbG6JkjFkWR89WCJL7G",
                            "value": 52385296,
                        },
                        "scriptsig": "4730440220087bd28db6494b706e59a8e019a00f98b47e04abc77c0aa1b6abdf9c79039c6a0220680eec608563c7827e69d50d199652e4e4ca61a1c6eba3711e87180658e4dde7012103a3770379e091cf67ee8a30752c4df2b5bcc61e2bca1e061da78438f18efe8be6",
                        "scriptsig_asm": "OP_PUSHBYTES_71 30440220087bd28db6494b706e59a8e019a00f98b47e04abc77c0aa1b6abdf9c79039c6a0220680eec608563c7827e69d50d199652e4e4ca61a1c6eba3711e87180658e4dde701 OP_PUSHBYTES_33 03a3770379e091cf67ee8a30752c4df2b5bcc61e2bca1e061da78438f18efe8be6",
                        "is_coinbase": False,
                        "sequence": 4294967295,
                    }
                ],
                "vout": [
                    {
                        "scriptpubkey": "6a34696f6e3a312e516d5a5a6534715150626774314d68453645534771464d57763855786f59505768735654355a59627535756d6947",
                        "scriptpubkey_asm": "OP_RETURN OP_PUSHBYTES_52 696f6e3a312e516d5a5a6534715150626774314d68453645534771464d57763855786f59505768735654355a59627535756d6947",
                        "scriptpubkey_type": "op_return",
                        "value": 0,
                    },
                    {
                        "scriptpubkey": "76a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac",
                        "scriptpubkey_asm": "OP_PUSHBYTES_65 049464205950188c29d377eebca6535e0f3699ce4069ecd77ffebfbd0bcf95e3c134cb7d2742d800a12df41413a09ef87a80516353a2f0a280547bb5512dc03da8 OP_CHECKSIG",
                        "scriptpubkey_type": "p2pk",
                        "scriptpubkey_address": "ms1J6ZT5X2n7vRiDdoJeNomprGsTrSEXUd",
                        "value": 52310396,
                    },
                ],
                "size": 254,
                "weight": 1016,
                "sigops": 4,
                "fee": 74900,
                "status": {
                    "confirmed": True,
                    "block_height": 66100,
                    "block_hash": "0000000056ed6b0f69fb51d0a690b78b1ffaf44ef01f1380d3528fc430903f76",
                    "block_time": 1737479508,
                },
            }
        ],
    )

    helpers.setup_bitcoinutils("testnet")
    assert (
        electrs.search_pubkey("ms1J6ZT5X2n7vRiDdoJeNomprGsTrSEXUd")
        == "049464205950188c29d377eebca6535e0f3699ce4069ecd77ffebfbd0bcf95e3c134cb7d2742d800a12df41413a09ef87a80516353a2f0a280547bb5512dc03da8"
    )
    assert electrs.search_pubkey("tb1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a") is None
    helpers.setup_bitcoinutils("regtest")
