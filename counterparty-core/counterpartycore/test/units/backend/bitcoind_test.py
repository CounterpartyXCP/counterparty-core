import json

import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.backend import bitcoind


class MockResponse:
    def __init__(self, status_code, json_data, reason=None):
        self.status_code = status_code
        self.json_data = json_data
        self.reason = reason

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
