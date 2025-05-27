from unittest.mock import Mock, patch

import pytest
from counterpartycore.lib.monitors.telemetry.collectors.base import (
    TelemetryCollectorBase,
    TelemetryCollectorKwargs,
)
from counterpartycore.lib.monitors.telemetry.collectors.influxdb import TelemetryCollectorInfluxDB
from counterpartycore.lib.monitors.telemetry.collectors.interface import TelemetryCollectorI


def test_telemetry_collector_interface():
    collector = TelemetryCollectorI()
    with pytest.raises(NotImplementedError):
        collector.collect()

    with pytest.raises(NotImplementedError):
        collector.close()


def test_telemetry_collector_kwargs():
    collector = TelemetryCollectorKwargs(test_key="test_value")
    assert collector.collect() == {"test_key": "test_value"}
    # close() is a no-op but should be called for coverage
    collector.close()


def test_telemetry_collector_base():
    # Mock the database and cursor
    mock_db = Mock()
    mock_cursor = Mock()
    mock_db.cursor.return_value = mock_cursor

    # Mock last_message result
    with patch(
        "counterpartycore.lib.ledger.events.last_message", return_value={"block_index": 123}
    ):
        # Mock cursor.execute().fetchone() result
        mock_cursor.execute.return_value.fetchone.return_value = {
            "block_index": 123,
            "block_hash": "hash123",
            "ledger_hash": "ledger_hash123",
            "txlist_hash": "txlist_hash123",
            "messages_hash": "messages_hash123",
        }

        # Mock utility functions
        with (
            patch("counterpartycore.lib.monitors.telemetry.util.get_version", return_value="1.0.0"),
            patch("counterpartycore.lib.monitors.telemetry.util.get_uptime", return_value=60),
            patch("counterpartycore.lib.monitors.telemetry.util.is_docker", return_value=True),
            patch(
                "counterpartycore.lib.monitors.telemetry.util.get_network", return_value="TESTNET"
            ),
            patch(
                "counterpartycore.lib.monitors.telemetry.util.is_force_enabled", return_value=True
            ),
            patch("counterpartycore.lib.monitors.telemetry.util.get_system", return_value="TestOS"),
        ):
            collector = TelemetryCollectorBase(mock_db, extra_key="extra_value")
            result = collector.collect()

            assert result["version"] == "1.0.0"
            assert result["uptime"] == 60
            assert result["dockerized"] is True
            assert result["network"] == "TESTNET"
            assert result["force_enabled"] is True
            assert result["platform"] == "TestOS"
            assert result["extra_key"] == "extra_value"
            assert result["last_block"]["block_index"] == 123


def test_telemetry_collector_base_no_block():
    # Test when no block is found
    mock_db = Mock()
    mock_cursor = Mock()
    mock_db.cursor.return_value = mock_cursor

    with patch(
        "counterpartycore.lib.ledger.events.last_message", return_value={"block_index": 123}
    ):
        # Mock cursor.execute().fetchone() returning None
        mock_cursor.execute.return_value.fetchone.return_value = None

        collector = TelemetryCollectorBase(mock_db)
        result = collector.collect()

        assert result is None


def test_telemetry_collector_influxdb():
    # Mock the database and cursor
    mock_db = Mock()
    mock_cursor = Mock()
    mock_db.cursor.return_value = mock_cursor

    # Mock last_message result
    with patch(
        "counterpartycore.lib.ledger.events.last_message", return_value={"block_index": 123}
    ):
        # Mock cursor.execute().fetchone() result
        mock_cursor.execute.return_value.fetchone.return_value = {
            "block_index": 123,
            "block_hash": "hash123",
            "ledger_hash": "ledger_hash123",
            "txlist_hash": "txlist_hash123",
            "messages_hash": "messages_hash123",
        }

        # Mock utility functions
        with (
            patch("counterpartycore.lib.monitors.telemetry.util.get_version", return_value="1.0.0"),
            patch("counterpartycore.lib.monitors.telemetry.util.get_uptime", return_value=60),
            patch("counterpartycore.lib.monitors.telemetry.util.is_docker", return_value=True),
            patch(
                "counterpartycore.lib.monitors.telemetry.util.get_network", return_value="TESTNET"
            ),
            patch(
                "counterpartycore.lib.monitors.telemetry.util.is_force_enabled", return_value=True
            ),
            patch("counterpartycore.lib.monitors.telemetry.util.get_system", return_value="TestOS"),
        ):
            collector = TelemetryCollectorInfluxDB(mock_db)
            result = collector.collect()

            assert "__influxdb" in result
            assert "tags" in result["__influxdb"]
            assert "fields" in result["__influxdb"]
            assert "block_index" in result["__influxdb"]["fields"]
            assert result["block_index"] == 123


def test_is_running_in_docker():
    # Test the is_running_in_docker method in TelemetryCollectorBase
    mock_db = Mock()
    collector = TelemetryCollectorBase(mock_db)

    # Test when /.dockerenv exists
    with patch("os.path.exists", return_value=True):
        assert collector.is_running_in_docker() is True

    # Test when DOCKER_HOST in env
    with patch("os.path.exists", return_value=False):
        with patch.dict("os.environ", {"DOCKER_HOST": "tcp://docker:2375"}):
            assert collector.is_running_in_docker() is True

    # Test when KUBERNETES_SERVICE_HOST in env
    with patch("os.path.exists", return_value=False):
        with patch.dict("os.environ", {"KUBERNETES_SERVICE_HOST": "10.0.0.1"}):
            assert collector.is_running_in_docker() is True

    # Test when not in docker
    with patch("os.path.exists", return_value=False):
        with patch.dict("os.environ", {}, clear=True):
            assert collector.is_running_in_docker() is False
