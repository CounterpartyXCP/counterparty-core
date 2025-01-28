import pytest
from counterpartycore.lib.api import apiserver, apiv1


@pytest.fixture()
def apiv1_app():
    app = apiv1.create_app()
    app.config.update(
        {
            "TESTING": True,
        }
    )
    yield app


@pytest.fixture()
def apiv2_app(ledger_db, state_db, monkeypatch, current_block_index):
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.getblockcount", lambda: current_block_index
    )
    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.get_blocks_behind", lambda: 0)

    app = apiserver.init_flask_app()
    app.config.update(
        {
            "TESTING": True,
        }
    )
    yield app


def rpc_call(client, method, params):
    import json

    headers = {"content-type": "application/json"}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    return client.post("/", data=json.dumps(payload), headers=headers, auth=("rpc", "rpc"))


@pytest.fixture()
def apiv1_client(apiv1_app, ledger_db, state_db):
    def call(method, params):
        return rpc_call(apiv1_app.test_client(), method, params)

    return call


@pytest.fixture()
def apiv2_client(apiv2_app):
    return apiv2_app.test_client()
