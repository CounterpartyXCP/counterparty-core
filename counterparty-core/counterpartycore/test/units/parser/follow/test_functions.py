from unittest.mock import patch

import pytest
from counterpartycore.lib.exceptions import BitcoindZMQError
from counterpartycore.lib.parser.follow import (
    get_zmq_notifications_addresses,
    start_blockchain_watcher,
)


class TestZmqNotifications:
    def test_get_zmq_notifications_addresses_success(self, mock_bitcoind, monkeypatch):
        """Test le succès de get_zmq_notifications_addresses."""
        monkeypatch.setattr("counterpartycore.lib.config.BACKEND_CONNECT", "127.0.0.1")

        mock_bitcoind.get_zmq_notifications.return_value = [
            {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
            {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
            {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
            {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
        ]

        pubrawtx_address, pubrawblock_address = get_zmq_notifications_addresses()

        assert pubrawtx_address == "tcp://127.0.0.1:28332"
        assert pubrawblock_address == "tcp://127.0.0.1:28333"

    def test_get_zmq_notifications_addresses_empty(self, mock_bitcoind):
        """Test get_zmq_notifications_addresses sans notifications."""
        mock_bitcoind.get_zmq_notifications.return_value = []

        with pytest.raises(
            BitcoindZMQError, match="Bitcoin Core ZeroMQ notifications are not enabled"
        ):
            get_zmq_notifications_addresses()

    def test_get_zmq_notifications_addresses_incorrect_types(self, mock_bitcoind):
        """Test get_zmq_notifications_addresses avec types incorrects."""
        mock_bitcoind.get_zmq_notifications.return_value = [
            {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
            {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
            # Manque pubhashtx et pubsequence
        ]

        with pytest.raises(BitcoindZMQError, match="incorrectly configured"):
            get_zmq_notifications_addresses()

    def test_get_zmq_notifications_addresses_different_addresses(self, mock_bitcoind):
        """Test get_zmq_notifications_addresses avec adresses différentes."""
        mock_bitcoind.get_zmq_notifications.return_value = [
            {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
            {"type": "pubhashtx", "address": "tcp://127.0.0.1:28333"},  # Différent
            {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
            {"type": "pubrawblock", "address": "tcp://127.0.0.1:28334"},
        ]

        with pytest.raises(BitcoindZMQError, match="must use the same address"):
            get_zmq_notifications_addresses()


class TestStartBlockchainWatcher:
    def test_start_blockchain_watcher_success(self, mock_db, mock_current_state, monkeypatch):
        """Test le succès de start_blockchain_watcher."""
        with patch("counterpartycore.lib.parser.follow.BlockchainWatcher") as mock_watcher, patch(
            "counterpartycore.lib.ledger.currentstate.CurrentState.set_ledger_state"
        ):
            # Configurer le mock pour simuler un appel réel
            def side_effect(db, state):
                assert db is mock_db
                assert state == "Following"

            mock_set_state.side_effect = side_effect

            monkeypatch.setattr(
                "counterpartycore.lib.parser.follow.get_zmq_notifications_addresses",
                lambda: ("tcp://127.0.0.1:28332", "tcp://127.0.0.1:28333"),
            )

            _result = start_blockchain_watcher(mock_db)

            # Vérifier que la méthode a été appelée
            # mock_set_state.assert_called_once()
