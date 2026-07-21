import json

import pytest
from counterpartycore.lib import config
from counterpartycore.lib.api import apiserver, apiv1
from counterpartycore.lib.utils.database import LedgerDBConnectionPool, StateDBConnectionPool


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
    config.DISABLE_API_CACHE = True
    yield app


def rpc_call(client, method, params):
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
    # Reopen the connection pools if they were closed by a previous test
    ledger_pool = LedgerDBConnectionPool()
    if ledger_pool.closed:
        ledger_pool.closed = False
    state_pool = StateDBConnectionPool()
    if state_pool.closed:
        state_pool.closed = False

    client = apiv1_app.test_client()

    def call(method, params):
        return rpc_call(client, method, params)

    return call


@pytest.fixture()
def apiv2_client(apiv2_app, ledger_db, state_db):
    return apiv2_app.test_client()
