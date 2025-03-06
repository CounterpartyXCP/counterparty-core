from unittest.mock import MagicMock

import pytest
from counterpartycore.lib.parser.follow import RawMempoolParser, get_raw_mempool


class TestGetRawMempool:
    def test_get_raw_mempool(self, mock_db, mock_bitcoind, monkeypatch):
        """Test get_raw_mempool."""
        # Configuration des mocks
        mock_bitcoind.getrawmempool.return_value = {
            "tx1": {"time": 1000},
            "tx2": {"time": 1100},
            "tx3": {"time": 1200},
        }

        # Préparer le mock pour l'insertion
        mock_cursor = mock_db.cursor.return_value
        mock_cursor.execute.return_value.fetchone.return_value = None

        # Mock NotSupportedTransactionsCache pour filtrer tx3
        cache_mock = MagicMock()
        cache_mock.is_not_supported.side_effect = lambda tx_hash: tx_hash == "tx3"
        monkeypatch.setattr(
            "counterpartycore.lib.parser.follow.NotSupportedTransactionsCache", lambda: cache_mock
        )

        # Mock helpers.chunkify
        def mock_chunkify(tx_list, size):
            return [tx_list]

        monkeypatch.setattr("counterpartycore.lib.utils.helpers.chunkify", mock_chunkify)
        monkeypatch.setattr("counterpartycore.lib.config.MAX_RPC_BATCH_SIZE", 10)

        # Exécution
        chunks, timestamps = get_raw_mempool(mock_db)

        # Vérification
        assert chunks == [[]]  # tx3 est filtrée
        assert timestamps == {}

        # Vérifier que les méthodes ont été appelées correctement
        mock_bitcoind.getrawmempool.assert_called_once_with(verbose=True)
        mock_cursor.execute.assert_called()


class TestRawMempoolParser:
    @pytest.fixture
    def parser(self, mock_db, monkeypatch):
        """Fixture pour créer un RawMempoolParser."""
        monkeypatch.setattr(
            "counterpartycore.lib.parser.follow.get_raw_mempool",
            lambda db: ([["tx1", "tx2"]], {"tx1": 1000, "tx2": 1100}),
        )

        return RawMempoolParser(mock_db)

    def test_init(self, parser, mock_db):
        """Test l'initialisation du RawMempoolParser."""
        assert parser.db == mock_db
        assert parser.daemon is True
        assert parser.tx_hashes_chunks == [["tx1", "tx2"]]
        assert parser.timestamps == {"tx1": 1000, "tx2": 1100}

    def test_run(self, parser, mock_bitcoind, monkeypatch):
        """Test run."""
        # Réinitialiser RAW_MEMPOOL globalement
        global RAW_MEMPOOL
        RAW_MEMPOOL.clear()

        # Configurer les mocks
        mock_bitcoind.getrawtransaction_batch.return_value = ["raw_tx1", "raw_tx2"]

        # Pour arrêter après une itération
        parser.stop_event.is_set = MagicMock(side_effect=[False, True])

        # Exécution
        parser.run()

        # Vérification
        mock_bitcoind.getrawtransaction_batch.assert_called_once_with(["tx1", "tx2"])
        assert RAW_MEMPOOL == [["raw_tx1", "raw_tx2"]]

        # Vérifier que le thread s'arrête correctement
        assert parser.stop_event.is_set()

    def test_stop(self, parser):
        """Test stop."""
        # Mock des méthodes nécessaires
        parser.join = MagicMock()

        # Exécuter la méthode stop
        parser.stop()

        # Vérifications
        parser.db.interrupt.assert_called_once()
        assert parser.stop_event.is_set()
        parser.join.assert_called_once()
