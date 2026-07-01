import json
import re
import time
from unittest.mock import patch

import pytest
from bitcoinutils.transactions import Script
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.backend import bitcoind
from counterpartycore.lib.utils import helpers
from counterpartycore.test.fixtures import decodedtxs
from counterpartycore.test.mocks.bitcoind import original_get_vin_info
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled

ORIGINAL_GET_UTXO_ADDRESS_AND_VALUE = bitcoind.get_utxo_address_and_value
MULTISIG_PUBKEYS = [
    "0427db4059d24bab05df3f6bcc768fb01bd976b973f93e72cce2dfbfbed5a32056c9040a2c2ea4c10c812a54fed7ff2e6a917dbc843362d398f6ace4000fafa5c6",
    "043e12a6cb1c7c156f789110abf8397b714047414b5a32c742f17ccf93ff23bdf3128f946207086bcef012558240cd16182c741123e93ed18327c4cd6ebac668a9",
    "04e4168c172283c7dfaa85d2004f763a28bf6d0f1602fc1452ccec62a7c8a66e422af1410fbf24a47355ddc43dfe3491cb1b806574ccd1c434680466dcff926f01",
]
MULTISIG_ADDRESS = "2_16KsHvVQj6aGvVQpAUgRcfpVug3regjiUs_17yjtboB7RjK2BoQ78k51NtJ4cDQGYZQyb_1NNXBUF3rqXtFbWhK5nujSpvt9yApsRUT7_3"


def multisig_script_pub_key():
    return {
        "asm": f"2 {' '.join(MULTISIG_PUBKEYS)} 3 OP_CHECKMULTISIG",
        "hex": Script([2, *MULTISIG_PUBKEYS, 3, "OP_CHECKMULTISIG"]).to_hex(),
        "type": "multisig",
    }


def clear_get_utxo_address_and_value_cache():
    if hasattr(ORIGINAL_GET_UTXO_ADDRESS_AND_VALUE, "cache_clear"):
        ORIGINAL_GET_UTXO_ADDRESS_AND_VALUE.cache_clear()


class MockResponse:
    def __init__(self, status_code, json_data, reason=None):
        self.status_code = status_code
        self.json_data = json_data
        self.reason = reason
        self.text = json.dumps(json_data)

    def json(self):
        return self.json_data


def mock_requests_post(*args, **kwargs):
    payload = json.loads(kwargs["data"])
    if payload["method"] == "getblockhash":
        return MockResponse(200, {"error": {"message": "Block height out of range", "code": -8}})
    if payload["method"] == "return_none":
        return None
    if payload["method"] == "return_401":
        return MockResponse(401, {}, "Unauthorized")
    if payload["method"] == "return_800":
        return MockResponse(800, {}, "because I want a 500")
    if payload["method"] == "return_batch_list":
        return MockResponse(200, ["ok", "ok"])
    if payload["method"] == "return_200":
        return MockResponse(200, {"result": "ok"})
    if payload["method"] == "return_code_28":
        return MockResponse(200, {"error": {"message": "Error 28", "code": -28}})
    if payload["method"] == "return_code_5":
        return MockResponse(200, {"error": {"message": "Error 5", "code": -5}})
    if payload["method"] == "return_code_30":
        return MockResponse(200, {"error": {"message": "Error 30", "code": -30}})
    if payload["method"] == "return_none_error":
        return MockResponse(200, {"error": None})
    if payload["method"] == "return_result_and_error":
        return MockResponse(200, {"result": "ok", "error": {"message": "Error 30", "code": -30}})
    if payload["method"] == "return_none_result":
        return MockResponse(200, {"result": None})
    if payload["method"] == "return_empty":
        return MockResponse(200, {})
    if payload["method"] == "return_string":
        return MockResponse(200, "string")
    if payload["method"] == "return_error_string":
        return MockResponse(200, {"error": "an error"})


@pytest.fixture(scope="function")
def init_mock(monkeypatch):
    monkeypatch.setattr("requests.post", mock_requests_post)
    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.should_retry", lambda: False)
    # config.BACKEND_URL = "http://localhost:14000"
    # config.BACKEND_SSL_NO_VERIFY = True
    # config.REQUESTS_TIMEOUT = 5


def test_rpc_call(init_mock):
    with pytest.raises(exceptions.BlockOutOfRange):
        bitcoind.rpc("getblockhash", [1])

    with pytest.raises(exceptions.BitcoindRPCError) as exc_info:
        bitcoind.rpc("return_none", [])
    assert (
        str(exc_info.value)
        == "Cannot communicate with Bitcoin Core at `http://XXXXXXXX@localhost:18443`. (server is set to run on regtest, is backend?)"
    )

    with pytest.raises(exceptions.BitcoindRPCError) as exc_info:
        bitcoind.rpc("return_401", [])
    assert (
        str(exc_info.value)
        == "Authorization error connecting to http://XXXXXXXX@localhost:18443: 401 Unauthorized"
    )

    with pytest.raises(exceptions.BitcoindRPCError) as exc_info:
        bitcoind.rpc("return_500", [])
    assert (
        str(exc_info.value)
        == "Cannot communicate with Bitcoin Core at `http://XXXXXXXX@localhost:18443`. (server is set to run on regtest, is backend?)"
    )

    result = bitcoind.rpc("return_batch_list", [])
    assert result == ["ok", "ok"]

    result = bitcoind.rpc("return_200", [])
    assert result == "ok"

    with pytest.raises(exceptions.BitcoindRPCError) as exc_info:
        bitcoind.rpc("return_code_28", [])
    assert (
        str(exc_info.value)
        == "Error calling {'method': 'return_code_28', 'params': [], 'jsonrpc': '2.0', 'id': 0}: {'message': 'Error 28', 'code': -28}. Sleeping for ten seconds and retrying."
    )

    with pytest.raises(exceptions.BitcoindRPCError) as exc_info:
        bitcoind.rpc("return_code_5", [])
    assert (
        str(exc_info.value)
        == "Error calling {'method': 'return_code_5', 'params': [], 'jsonrpc': '2.0', 'id': 0}: {'message': 'Error 5', 'code': -5}. Sleeping for ten seconds and retrying. Is `txindex` enabled in Bitcoin Core?"
    )

    with pytest.raises(exceptions.BitcoindRPCError) as exc_info:
        bitcoind.rpc("return_code_30", [])
    assert str(exc_info.value) == "Error 30"

    time_before = time.time()
    with pytest.raises(
        exceptions.BitcoindRPCError,
        match='Received invalid JSON from backend with a response of 200: "string"',
    ):
        bitcoind.rpc("return_string", [])
    time_after = time.time()
    assert time_after - time_before >= 6 * 5  # 6 retries with 5 seconds wait time

    with pytest.raises(
        exceptions.BitcoindRPCError,
        match=re.escape(
            "Error calling {'method': 'return_error_string', 'params': [], 'jsonrpc': '2.0', 'id': 0}: {'message': 'an error', 'code': -1}. Sleeping for ten seconds and retrying."
        ),
    ):
        bitcoind.rpc("return_error_string", [])


def test_rpc_safe(init_mock):
    with pytest.raises(exceptions.BitcoindRPCError):
        bitcoind.safe_rpc("getblockhash", [1])

    with pytest.raises(exceptions.BitcoindRPCError) as exc_info:
        bitcoind.safe_rpc("return_none", [])
    assert (
        str(exc_info.value)
        == "Cannot communicate with Bitcoin Core at `http://XXXXXXXX@localhost:18443`. (server is set to run on regtest, is backend?)"
    )

    with pytest.raises(exceptions.BitcoindRPCError, match="Unknown error"):
        bitcoind.safe_rpc("return_none_error", [])

    result = bitcoind.safe_rpc("return_200", [])
    assert result == "ok"

    result = bitcoind.safe_rpc("return_result_and_error", [])
    assert result == "ok"

    with pytest.raises(exceptions.BitcoindRPCError, match="Error 30"):
        bitcoind.safe_rpc("return_code_30", [])

    with pytest.raises(exceptions.BitcoindRPCError, match="No result returned"):
        bitcoind.safe_rpc("return_none_result", [])

    with pytest.raises(exceptions.BitcoindRPCError, match="Error 28"):
        bitcoind.safe_rpc("return_code_28", [])

    with pytest.raises(exceptions.BitcoindRPCError, match="Error calling return_empty: 'result'"):
        bitcoind.safe_rpc("return_empty", [])


def test_search_pubkey_in_transactions(monkeypatch):
    helpers.setup_bitcoinutils("mainnet")

    # mainnet tx
    txhashes = ["db9f87cdc32a09f58e129d89f5f1d466e3ae0bae6f7d919d0a620385dc2f9070"]

    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.getrawtransaction",
        lambda x, y: decodedtxs.DECODED_TX_1,
    )

    assert (
        bitcoind.search_pubkey_in_transactions("1JDogZS6tQcSxwfxhv6XKKjcyicYA4Feev", txhashes)
        is None
    )

    assert (
        bitcoind.search_pubkey_in_transactions("17V7DyAbwt1CEM2WT3FPm1b9RpPmLRy1oY", txhashes)
        == "033b3ca7e4ef960cd8346e291524dacc93f6647d9df37ae5eedbb92b0f7b53b28d"
    )

    helpers.setup_bitcoinutils("regtest")


def test_search_pubkey_in_transactions_bech32(monkeypatch):
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.getrawtransaction",
        lambda x, y: {
            "txid": "f8d74847198e409c3aa79eeb2c101e8fbb894a03858493d2ac3deb7970d12015",
            "hash": "3eb5099f83612f406a4953c92692447da0b219182a7b29f1509c91a426a4db75",
            "version": 2,
            "size": 222,
            "vsize": 141,
            "weight": 561,
            "locktime": 0,
            "vin": [
                {
                    "txid": "e05a9501ac6f4cdc3f393a20e0e65a5079e6c346201722493294fe6033895219",
                    "vout": 1,
                    "scriptSig": {"asm": "", "hex": ""},
                    "txinwitness": [
                        "304402206c7475c0ef65f369ec2ff0bdb35b433f3ad2215b75b0856965e92b575f112d030220515a8aeeb4dc460a545e40c174879d80c9467b4926a328531078ab3d6c67e86101",
                        "03821862113e63dcc139fb2e2c752ddcf64b2aaf40bf13ad6a0a29790f3ead77ac",
                    ],
                    "sequence": 4294967295,
                }
            ],
            "vout": [
                {
                    "value": 0.00010000,
                    "n": 0,
                    "scriptPubKey": {
                        "asm": "0 ece41d226060118079cbea4f35ac5c1dbd11fe86",
                        "desc": "addr(tb1qanjp6gnqvqgcq7wtaf8nttzurk73rl5xqk08hs)#y2dx8ctv",
                        "hex": "0014ece41d226060118079cbea4f35ac5c1dbd11fe86",
                        "address": "tb1qanjp6gnqvqgcq7wtaf8nttzurk73rl5xqk08hs",
                        "type": "witness_v0_keyhash",
                    },
                },
                {
                    "value": 0.00487958,
                    "n": 1,
                    "scriptPubKey": {
                        "asm": "0 6150f9d41f5f0b7841f6be50eda0b5f9a7a81357",
                        "desc": "addr(tb1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a)#c0fuzzfc",
                        "hex": "00146150f9d41f5f0b7841f6be50eda0b5f9a7a81357",
                        "address": "tb1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a",
                        "type": "witness_v0_keyhash",
                    },
                },
            ],
            "hex": "020000000001011952893360fe94324922172046c3e679505ae6e0203a393fdc4c6fac01955ae00100000000ffffffff021027000000000000160014ece41d226060118079cbea4f35ac5c1dbd11fe8616720700000000001600146150f9d41f5f0b7841f6be50eda0b5f9a7a813570247304402206c7475c0ef65f369ec2ff0bdb35b433f3ad2215b75b0856965e92b575f112d030220515a8aeeb4dc460a545e40c174879d80c9467b4926a328531078ab3d6c67e861012103821862113e63dcc139fb2e2c752ddcf64b2aaf40bf13ad6a0a29790f3ead77ac00000000",
            "blockhash": "000000000bf9eab2adae97280fbf4a352385c932e93f0a042da4c125a4ec493e",
            "confirmations": 102,
            "time": 1738780028,
            "blocktime": 1738780028,
        },
    )

    helpers.setup_bitcoinutils("testnet")

    assert (
        bitcoind.search_pubkey_in_transactions(
            "tb1qanjp6gnqvqgcq7wtaf8nttzurk73rl5xqk08hs",
            ["e05a9501ac6f4cdc3f393a20e0e65a5079e6c346201722493294fe6033895219"],
        )
        is None
    )
    assert (
        bitcoind.search_pubkey_in_transactions(
            "tb1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a",
            ["e05a9501ac6f4cdc3f393a20e0e65a5079e6c346201722493294fe6033895219"],
        )
        == "03821862113e63dcc139fb2e2c752ddcf64b2aaf40bf13ad6a0a29790f3ead77ac"
    )

    helpers.setup_bitcoinutils("regtest")


def test_search_pubkey_in_transactions_p2wsh_multisig(monkeypatch):
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.getrawtransaction",
        lambda x, y: {
            "txid": "d4387de0bb04a9952e421caab34104e007f9776ffc3bbff023695f2fdd74b1ce",
            "hash": "fa6c4b77b577ec45ed56cbf0fdb575fdda574f5935bbef7366f2cb58d6346f87",
            "version": 1,
            "size": 382,
            "locktime": 0,
            "vin": [
                {
                    "txid": "f274037b92cd0a90d7cf6f34be025d02065e7d032980edf955a3f2c66c278bfb",
                    "vout": 1,
                    "scriptSig": {"asm": "", "hex": ""},
                    "txinwitness": [
                        "",
                        "30440220776030e83ebd30b9461169df4e6b9e4ff63f940564fdc5691db220a7c12387720220639257fe96ea4fb64128a110f16a5b3e6fab84cd843f4686cd405be9fe783e9f01",
                        "3044022042e06cf65a08aac0ee6d4db4eb1bae5518628583ca9e942120bb22c99c6b070e02204011dddbe64e8f14a23c8182dfe78e814d3deb3ac704d94ef19b38507a200d4701",
                        "52210209d604337bcb785d1fba1fec16556e6ed914d12ee08bc8a87e7fe4f81607c3fd210387d133ae86d83ae28c6615882b88e53cbcf9cad9aaeaf55816dfba9b55ee4f3a21024cc0c0ec7d678c70606cf07c373f1b7db86d0f41f404cea48512b37379395a6f53ae",
                    ],
                    "sequence": 4294967293,
                }
            ],
            "vout": [
                {
                    "value": 0.00102146,
                    "n": 0,
                    "scriptPubKey": {
                        "address": "14xyFwHGmrGJjGtMbjJoJHqrLZvf6MibYU",
                        "asm": "OP_DUP OP_HASH160 2b7e3776eb8e160e2fd628e8d1cacbe44cec013e OP_EQUALVERIFY OP_CHECKSIG",
                        "hex": "76a9142b7e3776eb8e160e2fd628e8d1cacbe44cec013e88ac",
                        "type": "pubkeyhash",
                    },
                },
            ],
            "hex": "01000000000101fb8b276cc6f2a355f9ed8029037d5e06025d02be346fcfd7900acd927b0374f20100000000fdffffff02028f0100000000001976a9142b7e3776eb8e160e2fd628e8d1cacbe44cec013e88ac152d2800000000002200203722913c3426c12d25a4747f93f351e4f00c96a1514b2d6f7c46cef1a463808c04004730440220776030e83ebd30b9461169df4e6b9e4ff63f940564fdc5691db220a7c12387720220639257fe96ea4fb64128a110f16a5b3e6fab84cd843f4686cd405be9fe783e9f01473044022042e06cf65a08aac0ee6d4db4eb1bae5518628583ca9e942120bb22c99c6b070e02204011dddbe64e8f14a23c8182dfe78e814d3deb3ac704d94ef19b38507a200d47016952210209d604337bcb785d1fba1fec16556e6ed914d12ee08bc8a87e7fe4f81607c3fd210387d133ae86d83ae28c6615882b88e53cbcf9cad9aaeaf55816dfba9b55ee4f3a21024cc0c0ec7d678c70606cf07c373f1b7db86d0f41f404cea48512b37379395a6f53ae00000000",
        },
    )

    helpers.setup_bitcoinutils("mainnet")

    assert (
        bitcoind.search_pubkey_in_transactions(
            "14xyFwHGmrGJjGtMbjJoJHqrLZvf6MibYU",
            ["d4387de0bb04a9952e421caab34104e007f9776ffc3bbff023695f2fdd74b1ce"],
        )
        is None
    )

    helpers.setup_bitcoinutils("regtest")


def test_search_pubkey_in_transactions_p2pkh(monkeypatch):
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.getrawtransaction",
        lambda x, y: {
            "txid": "c9affbbc45a8749dcb96632356976578fa9f72d4578a34b6bba23e9021b30b32",
            "hash": "c9affbbc45a8749dcb96632356976578fa9f72d4578a34b6bba23e9021b30b32",
            "version": 2,
            "size": 254,
            "vsize": 254,
            "weight": 1016,
            "locktime": 0,
            "vin": [
                {
                    "txid": "33e3ce1cd0c5a956ba6e253d6ebb9ce3b391bce1c7d07a95468c842ea4a07e02",
                    "vout": 1,
                    "scriptSig": {
                        "asm": "30440220087bd28db6494b706e59a8e019a00f98b47e04abc77c0aa1b6abdf9c79039c6a0220680eec608563c7827e69d50d199652e4e4ca61a1c6eba3711e87180658e4dde7[ALL] 03a3770379e091cf67ee8a30752c4df2b5bcc61e2bca1e061da78438f18efe8be6",
                        "hex": "4730440220087bd28db6494b706e59a8e019a00f98b47e04abc77c0aa1b6abdf9c79039c6a0220680eec608563c7827e69d50d199652e4e4ca61a1c6eba3711e87180658e4dde7012103a3770379e091cf67ee8a30752c4df2b5bcc61e2bca1e061da78438f18efe8be6",
                    },
                    "sequence": 4294967295,
                }
            ],
            "vout": [
                {
                    "value": 0.00000000,
                    "n": 0,
                    "scriptPubKey": {
                        "asm": "OP_RETURN 696f6e3a312e516d5a5a6534715150626774314d68453645534771464d57763855786f59505768735654355a59627535756d6947",
                        "desc": "raw(6a34696f6e3a312e516d5a5a6534715150626774314d68453645534771464d57763855786f59505768735654355a59627535756d6947)#6k5z85th",
                        "hex": "6a34696f6e3a312e516d5a5a6534715150626774314d68453645534771464d57763855786f59505768735654355a59627535756d6947",
                        "type": "nulldata",
                    },
                },
                {
                    "value": 0.52310396,
                    "n": 1,
                    "scriptPubKey": {
                        "asm": "OP_DUP OP_HASH160 412463039be25be1bef6e6dbc5eb8eb18cf95694 OP_EQUALVERIFY OP_CHECKSIG",
                        "desc": "addr(mmTPoijZbv5sLkCpbG6JkjFkWR89WCJL7G)#ajysks2a",
                        "hex": "76a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac",
                        "address": "mmTPoijZbv5sLkCpbG6JkjFkWR89WCJL7G",
                        "type": "pubkeyhash",
                    },
                },
            ],
            "hex": "0200000001027ea0a42e848c46957ad0c7e1bc91b3e39cbb6e3d256eba56a9c5d01ccee333010000006a4730440220087bd28db6494b706e59a8e019a00f98b47e04abc77c0aa1b6abdf9c79039c6a0220680eec608563c7827e69d50d199652e4e4ca61a1c6eba3711e87180658e4dde7012103a3770379e091cf67ee8a30752c4df2b5bcc61e2bca1e061da78438f18efe8be6ffffffff020000000000000000366a34696f6e3a312e516d5a5a6534715150626774314d68453645534771464d57763855786f59505768735654355a59627535756d69477c311e03000000001976a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac00000000",
            "blockhash": "0000000056ed6b0f69fb51d0a690b78b1ffaf44ef01f1380d3528fc430903f76",
            "confirmations": 2996,
            "time": 1737479508,
            "blocktime": 1737479508,
        },
    )

    helpers.setup_bitcoinutils("testnet")
    assert (
        bitcoind.search_pubkey_in_transactions(
            "mmTPoijZbv5sLkCpbG6JkjFkWR89WCJL7G",
            ["c9affbbc45a8749dcb96632356976578fa9f72d4578a34b6bba23e9021b30b32"],
        )
        == "03a3770379e091cf67ee8a30752c4df2b5bcc61e2bca1e061da78438f18efe8be6"
    )
    assert (
        bitcoind.search_pubkey_in_transactions(
            "tb1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a",
            ["c9affbbc45a8749dcb96632356976578fa9f72d4578a34b6bba23e9021b30b32"],
        )
        is None
    )
    helpers.setup_bitcoinutils("regtest")


def test_search_pubkey_in_transactions_p2pk(monkeypatch):
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.getrawtransaction",
        lambda x, y: {
            "txid": "c9affbbc45a8749dcb96632356976578fa9f72d4578a34b6bba23e9021b30b32",
            "hash": "c9affbbc45a8749dcb96632356976578fa9f72d4578a34b6bba23e9021b30b32",
            "version": 2,
            "size": 254,
            "vsize": 254,
            "weight": 1016,
            "locktime": 0,
            "vin": [
                {
                    "txid": "33e3ce1cd0c5a956ba6e253d6ebb9ce3b391bce1c7d07a95468c842ea4a07e02",
                    "vout": 1,
                    "scriptSig": {
                        "asm": "30440220087bd28db6494b706e59a8e019a00f98b47e04abc77c0aa1b6abdf9c79039c6a0220680eec608563c7827e69d50d199652e4e4ca61a1c6eba3711e87180658e4dde7[ALL] 03a3770379e091cf67ee8a30752c4df2b5bcc61e2bca1e061da78438f18efe8be6",
                        "hex": "4730440220087bd28db6494b706e59a8e019a00f98b47e04abc77c0aa1b6abdf9c79039c6a0220680eec608563c7827e69d50d199652e4e4ca61a1c6eba3711e87180658e4dde7012103a3770379e091cf67ee8a30752c4df2b5bcc61e2bca1e061da78438f18efe8be6",
                    },
                    "sequence": 4294967295,
                }
            ],
            "vout": [
                {
                    "value": 0.00000000,
                    "n": 0,
                    "scriptPubKey": {
                        "asm": "OP_RETURN 696f6e3a312e516d5a5a6534715150626774314d68453645534771464d57763855786f59505768735654355a59627535756d6947",
                        "desc": "raw(6a34696f6e3a312e516d5a5a6534715150626774314d68453645534771464d57763855786f59505768735654355a59627535756d6947)#6k5z85th",
                        "hex": "6a34696f6e3a312e516d5a5a6534715150626774314d68453645534771464d57763855786f59505768735654355a59627535756d6947",
                        "type": "nulldata",
                    },
                },
                {
                    "value": 0.52310396,
                    "n": 1,
                    "scriptPubKey": {
                        "asm": "OP_PUSHBYTES_65 049464205950188c29d377eebca6535e0f3699ce4069ecd77ffebfbd0bcf95e3c134cb7d2742d800a12df41413a09ef87a80516353a2f0a280547bb5512dc03da8 OP_CHECKSIG",
                        "desc": "addr(ms1J6ZT5X2n7vRiDdoJeNomprGsTrSEXUd)#ajysks2a",
                        "hex": "76a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac",
                        "address": "ms1J6ZT5X2n7vRiDdoJeNomprGsTrSEXUd",
                        "type": "p2pk",
                    },
                },
            ],
            "hex": "0200000001027ea0a42e848c46957ad0c7e1bc91b3e39cbb6e3d256eba56a9c5d01ccee333010000006a4730440220087bd28db6494b706e59a8e019a00f98b47e04abc77c0aa1b6abdf9c79039c6a0220680eec608563c7827e69d50d199652e4e4ca61a1c6eba3711e87180658e4dde7012103a3770379e091cf67ee8a30752c4df2b5bcc61e2bca1e061da78438f18efe8be6ffffffff020000000000000000366a34696f6e3a312e516d5a5a6534715150626774314d68453645534771464d57763855786f59505768735654355a59627535756d69477c311e03000000001976a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac00000000",
            "blockhash": "0000000056ed6b0f69fb51d0a690b78b1ffaf44ef01f1380d3528fc430903f76",
            "confirmations": 2996,
            "time": 1737479508,
            "blocktime": 1737479508,
        },
    )

    helpers.setup_bitcoinutils("testnet")
    assert (
        bitcoind.search_pubkey_in_transactions(
            "ms1J6ZT5X2n7vRiDdoJeNomprGsTrSEXUd",
            ["c9affbbc45a8749dcb96632356976578fa9f72d4578a34b6bba23e9021b30b32"],
        )
        == "049464205950188c29d377eebca6535e0f3699ce4069ecd77ffebfbd0bcf95e3c134cb7d2742d800a12df41413a09ef87a80516353a2f0a280547bb5512dc03da8"
    )
    assert (
        bitcoind.search_pubkey_in_transactions(
            "tb1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a",
            ["c9affbbc45a8749dcb96632356976578fa9f72d4578a34b6bba23e9021b30b32"],
        )
        is None
    )
    helpers.setup_bitcoinutils("regtest")


def test_get_vin_info(monkeypatch):
    monkeypatch.setattr(
        bitcoind,
        "get_decoded_transaction",
        lambda *args, **kwargs: {
            "vout": [
                {"value": 1, "script_pub_key": "76a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac"}
            ]
        },
    )
    assert original_get_vin_info({"hash": "hash", "n": 0}) == (
        1,
        "76a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac",
        False,
    )


def test_get_vin_info_legacy(monkeypatch):
    monkeypatch.setattr(
        bitcoind,
        "get_decoded_transaction",
        lambda *args, **kwargs: {
            "vout": [
                {"value": 1, "script_pub_key": "76a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac"}
            ]
        },
    )
    assert bitcoind.get_vin_info_legacy({"hash": "hash", "n": 0}) == (
        1,
        "76a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac",
        False,
    )


def test_get_vin_info_legacy_error_halts_during_catchup(monkeypatch):
    """During catch-up (a confirmed block) a failure to resolve the parent
    transaction must HALT (raise), never be swallowed into a silent skip.
    Silently skipping a confirmed Counterparty tx forks the ledger -- this is
    the regression that caused the block 510556 divergence. The diagnostic must
    point operators at the cause (parent txid + `txindex`)."""

    def raise_error(*args, **kwargs):
        raise exceptions.BitcoindRPCError("No such mempool or blockchain transaction")

    monkeypatch.setattr(bitcoind, "get_decoded_transaction", raise_error)
    monkeypatch.setattr(bitcoind.CurrentState, "parsing_mempool", lambda self: False)
    monkeypatch.setattr(bitcoind.CurrentState, "stopping", lambda self: False)

    parent_txid = "fba2aa8d334a6c74eaa8b0998be6c29477ff4d927449e9a07efa0ec374fc73bf"
    with pytest.raises(exceptions.BitcoindRPCError, match="Refusing to silently skip") as exc:
        bitcoind.get_vin_info_legacy({"hash": parent_txid, "n": 1})
    assert parent_txid in str(exc.value)
    assert "txindex" in str(exc.value)


def test_get_vin_info_legacy_error_skips_in_mempool(monkeypatch):
    """While parsing the mempool an unresolvable parent is acceptable: the
    *unconfirmed* tx is skipped (DecodeError) and a warning is logged. It is
    re-evaluated once it confirms."""

    def raise_error(*args, **kwargs):
        raise exceptions.BitcoindRPCError

    monkeypatch.setattr(bitcoind, "get_decoded_transaction", raise_error)
    monkeypatch.setattr(bitcoind.CurrentState, "parsing_mempool", lambda self: True)

    parent_txid = "fba2aa8d334a6c74eaa8b0998be6c29477ff4d927449e9a07efa0ec374fc73bf"
    with patch.object(bitcoind.logger, "warning") as mock_warning:
        with pytest.raises(exceptions.DecodeError, match="vin not found"):
            bitcoind.get_vin_info_legacy({"hash": parent_txid, "n": 1})

    mock_warning.assert_called_once()
    logged_message = mock_warning.call_args[0][0] % mock_warning.call_args[0][1:]
    assert parent_txid in logged_message


def test_get_vin_info_falls_back_to_legacy(monkeypatch):
    """When Rust VIN info is None, get_vin_info falls back to legacy lookup."""
    monkeypatch.setattr(
        bitcoind,
        "get_decoded_transaction",
        lambda *args, **kwargs: {
            "vout": [
                {
                    "value": 10554,
                    "script_pub_key": "76a9140132c2887759f123166b3048b5ec599ea0d5b8f988ac",
                }
            ]
        },
    )
    vin = {
        "hash": "01f38776b07990118cb3720b9143adbde3725af12e0394cdd02c36458c6b3a03",
        "n": 0,
        "info": None,
    }
    value, script_pub_key, is_segwit = original_get_vin_info(vin)
    assert value == 10554
    assert script_pub_key == "76a9140132c2887759f123166b3048b5ec599ea0d5b8f988ac"
    assert is_segwit is False


def test_get_vin_info_fallback_halts_during_catchup(monkeypatch):
    """When Rust VIN info is None AND the legacy fallback also fails during
    catch-up, the node must HALT rather than silently skip the confirmed
    transaction. This is the scenario that silently forked a user's ledger at
    block 510556."""

    def raise_error(*args, **kwargs):
        raise exceptions.BitcoindRPCError("No such mempool or blockchain transaction")

    monkeypatch.setattr(bitcoind, "get_decoded_transaction", raise_error)
    monkeypatch.setattr(bitcoind.CurrentState, "parsing_mempool", lambda self: False)
    monkeypatch.setattr(bitcoind.CurrentState, "stopping", lambda self: False)

    parent_txid = "01f38776b07990118cb3720b9143adbde3725af12e0394cdd02c36458c6b3a03"
    vin_without_info = {"hash": parent_txid, "n": 1, "info": None}

    with pytest.raises(exceptions.BitcoindRPCError, match="Refusing to silently skip") as exc:
        original_get_vin_info(vin_without_info)
    assert parent_txid in str(exc.value)


def test_reset_caches_clears_dicts():
    """reset_caches() must clear TRANSACTIONS_CACHE and BLOCKS_CACHE so that
    a reorg does not leave block-indexed deserialised data behind."""
    bitcoind.TRANSACTIONS_CACHE["sentinel_tx"] = {"foo": "bar"}
    bitcoind.BLOCKS_CACHE[123] = {"baz": "qux"}

    bitcoind.reset_caches()

    assert "sentinel_tx" not in bitcoind.TRANSACTIONS_CACHE
    assert 123 not in bitcoind.BLOCKS_CACHE


def test_get_multisig_address_from_script_pub_key():
    old_address_version = config.ADDRESSVERSION
    config.ADDRESSVERSION = config.ADDRESSVERSION_MAINNET
    try:
        address = bitcoind.get_multisig_address_from_script_pub_key(multisig_script_pub_key())
    finally:
        config.ADDRESSVERSION = old_address_version

    assert address == MULTISIG_ADDRESS


def test_get_utxo_address_and_value_supports_multisig_when_protocol_enabled(monkeypatch):
    def mock_getrawtransaction(*args, **kwargs):
        return {"vout": [{"scriptPubKey": multisig_script_pub_key(), "value": 0.001}]}

    old_address_version = config.ADDRESSVERSION
    config.ADDRESSVERSION = config.ADDRESSVERSION_MAINNET
    clear_get_utxo_address_and_value_cache()
    monkeypatch.setattr(bitcoind, "getrawtransaction", mock_getrawtransaction)
    try:
        assert ORIGINAL_GET_UTXO_ADDRESS_AND_VALUE("multisig-txid:0") == (
            MULTISIG_ADDRESS,
            0.001,
        )
    finally:
        clear_get_utxo_address_and_value_cache()
        config.ADDRESSVERSION = old_address_version


def test_get_utxo_address_and_value_rejects_multisig_when_protocol_disabled(monkeypatch):
    def mock_getrawtransaction(*args, **kwargs):
        return {"vout": [{"scriptPubKey": multisig_script_pub_key(), "value": 0.001}]}

    old_address_version = config.ADDRESSVERSION
    config.ADDRESSVERSION = config.ADDRESSVERSION_MAINNET
    clear_get_utxo_address_and_value_cache()
    monkeypatch.setattr(bitcoind, "getrawtransaction", mock_getrawtransaction)
    try:
        with ProtocolChangesDisabled(["multisig_utxo_addresses"]):
            with pytest.raises(exceptions.InvalidUTXOError, match="vout does not have an address"):
                ORIGINAL_GET_UTXO_ADDRESS_AND_VALUE("legacy-multisig-txid:0")
    finally:
        clear_get_utxo_address_and_value_cache()
        config.ADDRESSVERSION = old_address_version


def test_reset_caches_handles_missing_lru_cache_clear(monkeypatch):
    """Test fixtures monkey-patch lru_cache wrappers with plain functions
    that don't carry a `cache_clear` attribute. reset_caches() must guard
    against this with hasattr() instead of raising AttributeError."""

    def fake_func(*args, **kwargs):
        return None

    monkeypatch.setattr(bitcoind, "getrawtransaction", fake_func)
    monkeypatch.setattr(bitcoind, "get_utxo_address_and_value", fake_func)

    assert not hasattr(fake_func, "cache_clear")

    bitcoind.reset_caches()
