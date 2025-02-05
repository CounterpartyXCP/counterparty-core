import bitcoin as bitcoinlib
from counterpartycore.lib import config
from counterpartycore.lib.ledger.currentstate import CurrentState


def set_mainnet_network(monkeypatch, block_index=400000):
    config.NETWORK_NAME = "mainnet"
    config.UNSPENDABLE = config.UNSPENDABLE_MAINNET
    bitcoinlib.SelectParams("mainnet")
    config.ADDRESSVERSION = config.ADDRESSVERSION_MAINNET
    CurrentState().set_current_block_index(block_index)
    monkeypatch.setattr(
        "counterpartycore.lib.ledger.currentstate.get_backend_height", lambda: block_index
    )
    CurrentState().last_update = 0
    assert CurrentState().current_backend_height() == block_index


def restore_network():
    config.NETWORK_NAME = "regtest"
    config.UNSPENDABLE = config.UNSPENDABLE_REGTEST
    bitcoinlib.SelectParams("regtest")
    config.ADDRESSVERSION = config.ADDRESSVERSION_REGTEST


def test_healthz_light(apiv2_client, monkeypatch, current_block_index):
    set_mainnet_network(monkeypatch)
    assert apiv2_client.get("/healthz").json == {"result": {"status": "Healthy"}}
    assert apiv2_client.get("/healthz?check_type=heavy").json == {"result": {"status": "Healthy"}}
    restore_network()
