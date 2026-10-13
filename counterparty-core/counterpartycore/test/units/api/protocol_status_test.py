from unittest.mock import MagicMock

import pytest
from counterpartycore.lib import config
from counterpartycore.lib.api import apiserver, apiv1, healthz_server
from counterpartycore.lib.utils import protocolstatus


def publish_upgrade(height):
    protocolstatus.current().publish(
        [
            {
                "change_name": "next_upgrade",
                "version": [config.VERSION_MAJOR + 1, 0, 0],
                "activation_height": height,
            }
        ]
    )


def test_upgrade_warning_is_visible_before_activation(apiv2_client, current_block_index):
    publish_upgrade(current_block_index + 1)
    root = apiv2_client.get("/v2/")
    assert root.status_code == 200
    assert root.json["result"]["protocol_status"]["status"] == "upgrade_pending"
    assert root.json["result"]["server_ready"] is True
    response = apiv2_client.get("/v2/blocks")
    assert response.status_code == 200
    assert response.headers["X-COUNTERPARTY-PROTOCOL-STATUS"] == "upgrade_pending"
    assert "X-COUNTERPARTY-PROTOCOL-STATUS" in response.headers["Access-Control-Expose-Headers"]


@pytest.mark.parametrize("api_only", [False, True])
def test_activated_upgrade_blocks_data_and_compose_but_not_diagnostics(
    apiv2_client, current_block_index, monkeypatch, api_only
):
    monkeypatch.setattr(config, "API_ONLY", api_only)
    publish_upgrade(current_block_index)
    for path in ("/v2/blocks", "/v2/addresses/source/compose/send", "/v2/healthz"):
        response = apiv2_client.get(path)
        assert response.status_code == 503
        assert response.json["error"] == "protocol_upgrade_required"
        assert response.json["protocol_status"]["activation_height"] == current_block_index
        assert response.headers["Cache-Control"] == "no-store"
        assert response.headers["X-COUNTERPARTY-READY"] == "False"
    root = apiv2_client.get("/v2/")
    assert root.status_code == 200
    assert root.json["result"]["server_ready"] is False
    assert root.json["result"]["protocol_status"]["status"] == "incompatible"
    assert apiv2_client.get("/v2/routes").status_code == 200


def test_cached_responses_cannot_hide_upgrade(apiv2_client, current_block_index, monkeypatch):
    monkeypatch.setattr(config, "DISABLE_API_CACHE", False)
    assert apiv2_client.get("/v2/blocks").status_code == 200
    publish_upgrade(current_block_index)
    assert apiv2_client.get("/v2/blocks").status_code == 503


def test_upgrade_discovered_during_request_replaces_success(
    apiv2_client, current_block_index, monkeypatch
):
    original = apiserver.api_root

    def root_then_upgrade():
        result = original()
        publish_upgrade(current_block_index)
        return result

    monkeypatch.setattr(apiserver, "api_root", root_then_upgrade)
    root = apiv2_client.get("/v2/")
    assert root.json["result"]["server_ready"] is False
    assert root.json["result"]["protocol_status"]["status"] == "incompatible"
    assert root.headers["X-COUNTERPARTY-PROTOCOL-STATUS"] == "incompatible"


def test_unknown_stale_and_force_are_distinct(apiv2_client, monkeypatch):
    protocolstatus.configure(protocolstatus.ProtocolStatus())
    assert apiv2_client.get("/v2/").json["result"]["protocol_status"]["status"] == "unknown"
    assert apiv2_client.get("/v2/blocks").status_code == 503
    protocolstatus.current().publish([])
    protocolstatus.current().unavailable()
    response = apiv2_client.get("/v2/blocks")
    assert response.status_code == 200
    assert response.headers["X-COUNTERPARTY-PROTOCOL-STATUS"] == "stale"
    monkeypatch.setattr(config, "FORCE", True)
    assert apiv2_client.get("/v2/").json["result"]["protocol_status"]["force_override"] is True
    assert apiv2_client.get("/v2/blocks").headers["X-COUNTERPARTY-PROTOCOL-STATUS"] == "bypassed"


def test_readiness_rejects_protocol_upgrade_without_changing_liveness(monkeypatch):
    publish_upgrade(100)
    sampler = healthz_server.HealthSampler(
        last_parsed_provider=lambda: 100,
        backend_height_provider=lambda: 100,
        block_time_provider=lambda: None,
    )
    sampler._tick()
    snap = sampler.current_snapshot()
    assert snap.ready is False
    assert snap.reason == "protocol_upgrade_required"
    handler = object.__new__(healthz_server.HealthRequestHandler)
    handler.server = MagicMock(sampler=sampler)
    assert handler._readiness()[0] == 503
    assert handler._liveness()[0] == 200


def test_legacy_api_cannot_bypass_upgrade_guard(apiv1_client, current_block_index):
    publish_upgrade(current_block_index)
    response = apiv1_client("get_running_info", {})
    assert response.status_code == 503
    assert response.json["error"]["message"] == "protocol_upgrade_required"
    assert response.json["error"]["data"]["status"] == "incompatible"
    assert response.headers["X-COUNTERPARTY-PROTOCOL-STATUS"] == "incompatible"
    assert "X-COUNTERPARTY-PROTOCOL-STATUS" in response.headers["Access-Control-Expose-Headers"]


def test_legacy_response_discovered_in_flight_cannot_bypass_guard(
    apiv1_client, current_block_index, monkeypatch
):
    original = apiv1.jsonrpc.JSONRPCResponseManager.handle

    def handle_then_upgrade(*args):
        result = original(*args)
        publish_upgrade(current_block_index)
        return result

    monkeypatch.setattr(apiv1.jsonrpc.JSONRPCResponseManager, "handle", handle_then_upgrade)
    response = apiv1_client("get_running_info", {})
    assert response.status_code == 503
    assert response.json["error"]["message"] == "protocol_upgrade_required"


def test_legacy_pending_upgrade_preserves_normal_response(apiv1_client, current_block_index):
    publish_upgrade(current_block_index + 1)
    response = apiv1_client("get_running_info", {})
    assert response.status_code == 200
    assert response.headers["X-COUNTERPARTY-PROTOCOL-STATUS"] == "upgrade_pending"
