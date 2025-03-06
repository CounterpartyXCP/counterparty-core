from unittest.mock import mock_open, patch

import pytest
from counterpartycore.lib.parser.follow import NotSupportedTransactionsCache


@pytest.fixture
def clear_singleton():
    """Réinitialise le singleton pour les tests."""
    if hasattr(NotSupportedTransactionsCache, "_instances"):
        NotSupportedTransactionsCache._instances = {}
    yield
    if hasattr(NotSupportedTransactionsCache, "_instances"):
        NotSupportedTransactionsCache._instances = {}


class TestNotSupportedTransactionsCache:
    def test_init_and_restore_no_file(self, clear_singleton, monkeypatch):
        """Test init et restore sans fichier existant."""
        monkeypatch.setattr("os.path.exists", lambda path: False)
        monkeypatch.setattr("counterpartycore.lib.config.CACHE_DIR", "/tmp")
        monkeypatch.setattr("counterpartycore.lib.config.NETWORK_NAME", "testnet")

        cache = NotSupportedTransactionsCache()

        assert cache.not_suppported_txs == []
        assert cache.cache_path == "/tmp/not_supported_tx_cache.testnet.txt"

    def test_restore_with_file(self, clear_singleton, monkeypatch):
        """Test restore avec un fichier existant."""
        monkeypatch.setattr("os.path.exists", lambda path: True)
        monkeypatch.setattr("counterpartycore.lib.config.CACHE_DIR", "/tmp")
        monkeypatch.setattr("counterpartycore.lib.config.NETWORK_NAME", "testnet")

        with patch("builtins.open", mock_open(read_data="tx1\ntx2\ntx3")):
            cache = NotSupportedTransactionsCache()

        assert cache.not_suppported_txs == ["tx1", "tx2", "tx3"]

    def test_backup(self, clear_singleton, monkeypatch):
        """Test backup."""
        monkeypatch.setattr("os.path.exists", lambda path: False)
        monkeypatch.setattr("counterpartycore.lib.config.CACHE_DIR", "/tmp")
        monkeypatch.setattr("counterpartycore.lib.config.NETWORK_NAME", "testnet")

        m = mock_open()
        with patch("builtins.open", m):
            cache = NotSupportedTransactionsCache()
            cache.not_suppported_txs = ["tx1", "tx2", "tx3"]
            cache.backup()

        m.assert_called_once_with(cache.cache_path, "w", encoding="utf-8")
        m().write.assert_called_once_with("tx1\ntx2\ntx3")

    def test_clear(self, clear_singleton, monkeypatch):
        """Test clear."""
        monkeypatch.setattr("os.path.exists", lambda path: False)  # Le fichier n'existe pas
        monkeypatch.setattr("os.remove", lambda path: None)
        monkeypatch.setattr("counterpartycore.lib.config.CACHE_DIR", "/tmp")
        monkeypatch.setattr("counterpartycore.lib.config.NETWORK_NAME", "testnet")

        cache = NotSupportedTransactionsCache()
        cache.not_suppported_txs = ["tx1", "tx2", "tx3"]

        cache.clear()

        assert cache.not_suppported_txs == []

    def test_add(self, clear_singleton, monkeypatch):
        """Test add."""
        monkeypatch.setattr("os.path.exists", lambda path: False)
        monkeypatch.setattr("counterpartycore.lib.config.CACHE_DIR", "/tmp")
        monkeypatch.setattr("counterpartycore.lib.config.NETWORK_NAME", "testnet")

        with patch.object(NotSupportedTransactionsCache, "backup") as mock_backup:
            cache = NotSupportedTransactionsCache()
            cache.not_suppported_txs = ["tx1"]

            cache.add(["tx2", "tx3"])

            assert cache.not_suppported_txs == ["tx1", "tx2", "tx3"]
            mock_backup.assert_called_once()

    def test_is_not_supported(self, clear_singleton, monkeypatch):
        """Test is_not_supported."""
        monkeypatch.setattr("os.path.exists", lambda path: False)
        monkeypatch.setattr("counterpartycore.lib.config.CACHE_DIR", "/tmp")
        monkeypatch.setattr("counterpartycore.lib.config.NETWORK_NAME", "testnet")

        cache = NotSupportedTransactionsCache()
        cache.not_suppported_txs = ["tx1", "tx2"]

        assert cache.is_not_supported("tx1") is True
        assert cache.is_not_supported("tx3") is False

    def test_singleton_behavior(self, clear_singleton, monkeypatch):
        """Test que la classe se comporte comme un singleton."""
        monkeypatch.setattr("os.path.exists", lambda path: False)
        monkeypatch.setattr("counterpartycore.lib.config.CACHE_DIR", "/tmp")
        monkeypatch.setattr("counterpartycore.lib.config.NETWORK_NAME", "testnet")

        cache1 = NotSupportedTransactionsCache()
        cache1.not_suppported_txs = ["tx1"]

        cache2 = NotSupportedTransactionsCache()

        assert cache1 is cache2
        assert cache2.not_suppported_txs == ["tx1"]
