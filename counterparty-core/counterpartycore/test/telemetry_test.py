import time
from unittest.mock import MagicMock, patch

from counterpartycore.lib.telemetry.collector import TelemetryCollectorLive
from counterpartycore.lib.telemetry.daemon import TelemetryDaemon


class TestTelemetryDaemon:
    def test_init(self):
        collector = MagicMock()
        client = MagicMock()
        daemon = TelemetryDaemon(collector, client)
        assert daemon.client == client
        assert daemon.collector == collector
        assert daemon.interval == 60

    def test_init_with_custom_interval(self):
        collector = MagicMock()
        client = MagicMock()
        daemon = TelemetryDaemon(collector, client, interval=10)
        assert daemon.client == client
        assert daemon.collector == collector
        assert daemon.interval == 10

    def test_send_at_intervals(self):
        collector = MagicMock()
        client = MagicMock()
        daemon = TelemetryDaemon(collector, client, interval=0.1)
        daemon.start()
        assert daemon.is_running == True  # noqa: E712
        time.sleep(0.5)
        daemon.stop()
        assert daemon.is_running == False  # noqa: E712
        assert client.send.call_count > 1
        assert collector.collect.call_count > 1


class TestTelemetryCollectorLive:
    @patch("counterpartycore.lib.telemetry.util.config")
    @patch("counterpartycore.lib.telemetry.collector.ledger")
    def test_collect(self, mock_ledger, mock_config):
        mock_db = MagicMock()
        mock_ledger.last_message.return_value = {"block_index": 12345}
        mock_config.__version__ = "1.2.3"
        mock_config.ADDRINDEXRS_VERSION = "4.5.6"
        mock_config.TESTNET = False
        mock_config.FORCE = False

        collector = TelemetryCollectorLive(mock_db)
        time.sleep(0.1)
        data = collector.collect()

        print("\n\n\n", data)

        mock_ledger.last_message.assert_called_with(mock_db)
        mock_db.cursor().execute.assert_called_with(
            "SELECT * FROM blocks where block_index = ?", [12345]
        )

        assert data["version"] == "1.2.3"
        assert data["addrindexrs_version"] == "4.5.6"
        assert data["uptime"] > 0
        assert data["network"] == "MAINNET"
        assert data["docker"] == False  # noqa: E712
        assert data["force_enabled"] == False  # noqa: E712

    @patch("counterpartycore.lib.telemetry.collector.ledger")
    @patch("counterpartycore.lib.telemetry.collector.os.path.exists")
    def test_collect_with_docker(self, mock_exists, mock_ledger):
        mock_db = MagicMock()
        mock_exists.return_value = True
        mock_ledger.last_message.return_value = {"block_index": 12345}
        collector = TelemetryCollectorLive(mock_db)
        data = collector.collect()
        assert data["docker"] == True  # noqa: E712
