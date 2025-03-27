import json
import re
import time

import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.backend import bitcoind
from counterpartycore.lib.utils import helpers
from counterpartycore.test.fixtures import decodedtxs
from counterpartycore.test.mocks.bitcoind import original_get_vin_info


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


def test_get_vin_info():
    with pytest.raises(exceptions.RSFetchError, match="No vin info found"):
        original_get_vin_info({})


def test_get_vin_info_legacy(monkeypatch):
    monkeypatch.setattr(
        bitcoind,
        "get_decoded_transaction",
        lambda *args, **kwargs: {"vout": [{"value": 1, "script_pub_key": "script_pub_key"}]},
    )
    assert bitcoind.get_vin_info_legacy({"hash": "hash", "n": 0}) == (1, "script_pub_key")


def test_get_vin_info_legacy_error(monkeypatch):
    def raise_error(*args, **kwargs):
        raise exceptions.BitcoindRPCError

    monkeypatch.setattr(bitcoind, "get_decoded_transaction", raise_error)

    with pytest.raises(exceptions.DecodeError, match="vin not found"):
        bitcoind.get_vin_info_legacy({"hash": "hash", "n": 0})
