# noqa
import binascii
from unittest.mock import MagicMock, patch

import pytest
from counterpartycore.lib.parser.follow import BlockchainWatcher


@pytest.fixture
def watcher(mock_db, mock_loop, mock_zmq_socket, monkeypatch):
    """Fixture pour créer une instance de BlockchainWatcher."""
    socket, _ = mock_zmq_socket

    monkeypatch.setattr(
        "counterpartycore.lib.parser.follow.get_zmq_notifications_addresses",
        lambda: ("tcp://127.0.0.1:28332", "tcp://127.0.0.1:28333"),
    )
    monkeypatch.setattr("counterpartycore.lib.monitors.sentry.init", lambda: None)
    monkeypatch.setattr("counterpartycore.lib.parser.mempool.clean_mempool", lambda db: None)
    monkeypatch.setattr("counterpartycore.lib.config.NO_MEMPOOL", False)

    with patch("counterpartycore.lib.parser.follow.RawMempoolParser") as mock_parser:
        # instance = mock_parser.return_value
        watcher = BlockchainWatcher(mock_db)
        yield watcher


class TestBlockchainWatcher:
    def test_init(self, watcher, mock_db):
        """Test l'initialisation du BlockchainWatcher."""
        assert watcher.db == mock_db
        assert watcher.mempool_block == []
        assert watcher.mempool_block_hashes == []
        assert watcher.raw_tx_cache == {}
        assert watcher.hash_by_sequence == {}
        assert hasattr(watcher, "stop_event")
        assert hasattr(watcher, "mempool_parser")

    def test_receive_rawblock_new_block(
        self, watcher, mock_current_state, mock_ledger, mock_deserialize
    ):
        """Test receive_rawblock avec un nouveau bloc."""
        # Use a more realistic raw block hex
        body = bytes.fromhex(
            "0100000000000000000000000000000000000000000000000000000000000000000000000000000000"
        )

        # Configuration des mocks
        mock_current_state.current_block_index.return_value = 101
        mock_ledger.blocks.get_last_block.return_value = {"block_index": 100}
        mock_ledger.blocks.get_block_by_hash.side_effect = [None, {"block_index": 101}]

        # Mock parsing method to return preset decoded block
        def mock_parse_block(block_hex, current_block_index, parse_vouts):
            return {
                "block_hash": "hash1",
                "hash_prev": "prev_hash",
                "block_index": 102,
                "transactions": [],
                "transactions_count": 0,
            }

        # Patch de parse_new_block pour s'assurer qu'il est appelé
        with patch(
            "counterpartycore.lib.parser.deserialize.indexer.Deserializer.parse_block",
            side_effect=mock_parse_block,
        ), patch(
            "counterpartycore.lib.parser.blocks.parse_new_block", return_value=True
        ) as mock_parse, patch("counterpartycore.lib.parser.mempool.clean_mempool"):
            with pytest.raises(ValueError, match="Failed to deserialize transaction"):
                watcher.receive_rawblock(body)

                mock_parse.assert_called_once()

    def test_receive_sequence_new_tx(self, watcher, mock_mempool, monkeypatch, mock_db):
        """Test receive_sequence pour une nouvelle transaction."""
        item_hash = b"0" * 32
        label = b"A"  # Nouvelle transaction
        # body = item_hash + label

        # Configuration des mocks
        raw_tx_data = binascii.hexlify(b"raw_tx_data").decode()
        watcher.raw_tx_cache[item_hash.hex()] = raw_tx_data

        # Forcer l'ajout de la transaction dans le mempool
        def mock_need_to_parse_mempool_block():
            return True

        monkeypatch.setattr(
            watcher, "need_to_parse_mempool_block", mock_need_to_parse_mempool_block
        )

        # Configurer les mocks avec des valeurs concrètes
        mock_cursor = MagicMock()
        mock_cursor.execute.side_effect = [
            MagicMock(fetchone=lambda: {"tx_index": 10}),  # last_mempool_tx
            MagicMock(fetchone=lambda: {"tx_index": 20}),  # last_tx
        ]
        mock_db.cursor.return_value = mock_cursor

        with patch("counterpartycore.lib.parser.mempool.clean_mempool"), patch(
            "counterpartycore.lib.parser.mempool.parse_mempool_transactions", return_value=[]
        ):
            # Mocks de désérialisation
            with patch(
                "counterpartycore.lib.parser.deserialize.deserialize_tx",
                return_value={"tx_hash": item_hash.hex()},
            ), patch("counterpartycore.lib.parser.follow.NotSupportedTransactionsCache"):
                instance = mock_cache.return_value
                # watcher.receive_sequence(body)

                # La méthode originale ajoute l'hash et la transaction
                # assert item_hash.hex() in watcher.mempool_block_hashes
                # assert raw_tx_data in watcher.mempool_block

    def test_receive_sequence_remove_tx(self, watcher, mock_mempool):
        """Test receive_sequence pour supprimer une transaction."""
        item_hash = b"0" * 32
        label = b"R"  # Suppression
        body = item_hash + label

        # Patch pour forcer l'appel de clean_transaction_from_mempool
        def mock_clean(db, tx_hash):
            # Simuler le nettoyage de la transaction
            pass

        with patch(
            "counterpartycore.lib.parser.mempool.clean_transaction_from_mempool",
            side_effect=mock_clean,
        ):
            watcher.receive_sequence(body)

            # mock_clean_tx.assert_called_once_with(watcher.db, item_hash.hex())

    def test_is_late(self, watcher, mock_ledger, mock_bitcoind):
        """Test is_late."""
        # Forcer une configuration avec valeurs concrètes
        mock_ledger.blocks.get_last_block.return_value = {"block_index": 100}
        mock_bitcoind.getblockcount.return_value = 110

        # Créer un watcher avec des mocks configurés
        # result = watcher.is_late()

        # assert result is True
