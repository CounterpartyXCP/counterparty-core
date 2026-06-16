"""
Tests for counterpartycore.lib.parser.follow module.
"""

import asyncio
import os
import tempfile
import threading
import time
from unittest import mock

import pytest
import zmq
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.parser import follow
from counterpartycore.lib.utils import helpers

# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def mock_zmq_context():
    """Fixture to mock ZMQ context and sockets"""
    with mock.patch("zmq.asyncio.Context") as mock_context:
        mock_socket = mock.MagicMock()
        mock_context.return_value.socket.return_value = mock_socket
        yield mock_context, mock_socket


@pytest.fixture
def mock_backend_bitcoind():
    """Fixture to mock backend.bitcoind methods"""
    with mock.patch("counterpartycore.lib.backend.bitcoind") as mock_bitcoind:
        yield mock_bitcoind


@pytest.fixture
def mock_current_state():
    """Fixture to mock CurrentState"""
    with mock.patch("counterpartycore.lib.parser.follow.CurrentState") as mock_cs:
        mock_instance = mock.MagicMock()
        mock_cs.return_value = mock_instance
        yield mock_cs, mock_instance


@pytest.fixture
def temp_cache_dir():
    """Fixture to create a temporary cache directory"""
    original_cache_dir = config.CACHE_DIR
    original_network = config.NETWORK_NAME
    with tempfile.TemporaryDirectory() as tmpdir:
        config.CACHE_DIR = tmpdir
        config.NETWORK_NAME = "regtest"
        yield tmpdir
        config.CACHE_DIR = original_cache_dir
        config.NETWORK_NAME = original_network


@pytest.fixture
def reset_not_supported_cache():
    """Fixture to reset the NotSupportedTransactionsCache singleton"""
    # Clear the singleton instance before and after each test
    if hasattr(helpers.SingletonMeta, "_instances"):
        if follow.NotSupportedTransactionsCache in helpers.SingletonMeta._instances:
            del helpers.SingletonMeta._instances[follow.NotSupportedTransactionsCache]
    yield
    if hasattr(helpers.SingletonMeta, "_instances"):
        if follow.NotSupportedTransactionsCache in helpers.SingletonMeta._instances:
            del helpers.SingletonMeta._instances[follow.NotSupportedTransactionsCache]


# ============================================================================
# Tests for get_zmq_notifications_addresses()
# ============================================================================


def test_get_zmq_notifications_addresses_success(mock_backend_bitcoind):
    """Test get_zmq_notifications_addresses with valid configuration"""
    mock_backend_bitcoind.get_zmq_notifications.return_value = [
        {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
    ]

    original_backend_connect = config.BACKEND_CONNECT
    config.BACKEND_CONNECT = "127.0.0.1"

    try:
        pubrawtx_address, pubrawblock_address = follow.get_zmq_notifications_addresses()
        assert pubrawtx_address == "tcp://127.0.0.1:28332"
        assert pubrawblock_address == "tcp://127.0.0.1:28333"
    finally:
        config.BACKEND_CONNECT = original_backend_connect


def test_get_zmq_notifications_addresses_rpc_error(mock_backend_bitcoind):
    """Test get_zmq_notifications_addresses when RPC error occurs"""
    mock_backend_bitcoind.get_zmq_notifications.side_effect = exceptions.BitcoindRPCError(
        "RPC error"
    )

    with pytest.raises(exceptions.BitcoindZMQError, match="Error getting ZMQ notifications"):
        follow.get_zmq_notifications_addresses()


def test_get_zmq_notifications_addresses_no_notifications(mock_backend_bitcoind):
    """Test get_zmq_notifications_addresses when no notifications configured"""
    mock_backend_bitcoind.get_zmq_notifications.return_value = []

    with pytest.raises(
        exceptions.BitcoindZMQError, match="Bitcoin Core ZeroMQ notifications are not enabled"
    ):
        follow.get_zmq_notifications_addresses()


def test_get_zmq_notifications_addresses_wrong_types(mock_backend_bitcoind):
    """Test get_zmq_notifications_addresses with wrong notification types"""
    mock_backend_bitcoind.get_zmq_notifications.return_value = [
        {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
        # Missing pubsequence and pubrawblock
    ]

    with pytest.raises(exceptions.BitcoindZMQError, match="incorrectly configured"):
        follow.get_zmq_notifications_addresses()


def test_get_zmq_notifications_addresses_different_addresses(mock_backend_bitcoind):
    """Test get_zmq_notifications_addresses when addresses don't match"""
    mock_backend_bitcoind.get_zmq_notifications.return_value = [
        {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubhashtx", "address": "tcp://127.0.0.1:28333"},  # Different address
        {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubrawblock", "address": "tcp://127.0.0.1:28334"},
    ]

    with pytest.raises(exceptions.BitcoindZMQError, match="must use the same address"):
        follow.get_zmq_notifications_addresses()


# ============================================================================
# Tests for start_blockchain_watcher()
# ============================================================================


def test_start_blockchain_watcher_success(
    mock_backend_bitcoind, mock_current_state, mock_zmq_context
):
    """Test start_blockchain_watcher successful initialization"""
    mock_cs, mock_instance = mock_current_state

    mock_backend_bitcoind.get_zmq_notifications.return_value = [
        {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
    ]

    original_backend_connect = config.BACKEND_CONNECT
    original_no_mempool = config.NO_MEMPOOL
    config.BACKEND_CONNECT = "127.0.0.1"
    config.NO_MEMPOOL = True

    db = mock.MagicMock()

    try:
        with mock.patch("counterpartycore.lib.monitors.sentry.init"):
            with mock.patch("asyncio.new_event_loop"):
                with mock.patch("asyncio.set_event_loop"):
                    watcher = follow.start_blockchain_watcher(db)
                    assert watcher is not None
                    mock_instance.set_ledger_state.assert_called_with(db, "Following")
    finally:
        config.BACKEND_CONNECT = original_backend_connect
        config.NO_MEMPOOL = original_no_mempool


def test_start_blockchain_watcher_zmq_error_retry(
    mock_backend_bitcoind, mock_current_state, caplog
):
    """Test start_blockchain_watcher retries on ZMQ error"""
    mock_cs, mock_instance = mock_current_state

    # First call raises error, second succeeds
    call_count = [0]

    def mock_get_zmq():
        call_count[0] += 1
        if call_count[0] == 1:
            raise exceptions.BitcoindZMQError("ZMQ error")
        return [
            {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
            {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
            {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
            {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
        ]

    mock_backend_bitcoind.get_zmq_notifications.side_effect = mock_get_zmq

    original_backend_connect = config.BACKEND_CONNECT
    original_no_mempool = config.NO_MEMPOOL
    config.BACKEND_CONNECT = "127.0.0.1"
    config.NO_MEMPOOL = True

    db = mock.MagicMock()

    try:
        with mock.patch("counterpartycore.lib.monitors.sentry.init"):
            with mock.patch("asyncio.new_event_loop"):
                with mock.patch("asyncio.set_event_loop"):
                    with mock.patch("counterpartycore.lib.parser.blocks.catch_up"):
                        with mock.patch("time.sleep"):
                            watcher = follow.start_blockchain_watcher(db)
                            assert watcher is not None
                            assert call_count[0] == 2
    finally:
        config.BACKEND_CONNECT = original_backend_connect
        config.NO_MEMPOOL = original_no_mempool


# ============================================================================
# Tests for BlockchainWatcher class
# ============================================================================


class TestBlockchainWatcher:
    """Tests for BlockchainWatcher class methods"""

    @pytest.fixture
    def watcher_setup(self, mock_backend_bitcoind, mock_current_state, mock_zmq_context):
        """Setup a BlockchainWatcher instance for testing"""
        mock_cs, mock_instance = mock_current_state
        mock_instance.current_block_index.return_value = 100

        mock_backend_bitcoind.get_zmq_notifications.return_value = [
            {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
            {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
            {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
            {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
        ]

        original_backend_connect = config.BACKEND_CONNECT
        original_no_mempool = config.NO_MEMPOOL
        config.BACKEND_CONNECT = "127.0.0.1"
        config.NO_MEMPOOL = True

        db = mock.MagicMock()

        with mock.patch("counterpartycore.lib.monitors.sentry.init"):
            with mock.patch("asyncio.new_event_loop") as mock_loop:
                mock_loop_instance = mock.MagicMock()
                mock_loop.return_value = mock_loop_instance
                with mock.patch("asyncio.set_event_loop"):
                    watcher = follow.BlockchainWatcher(db)

        yield watcher, db, mock_backend_bitcoind, mock_instance

        config.BACKEND_CONNECT = original_backend_connect
        config.NO_MEMPOOL = original_no_mempool

    def test_init(self, watcher_setup):
        """Test BlockchainWatcher initialization"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        assert watcher.db == db
        assert watcher.mempool_block == []
        assert watcher.mempool_block_hashes == []
        assert watcher.raw_tx_cache == {}
        assert watcher.hash_by_sequence == {}

    def test_check_software_version_if_needed_checks(self, watcher_setup):
        """Test check_software_version_if_needed performs check"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        watcher.last_software_version_check_time = 0

        with mock.patch("counterpartycore.lib.parser.check.software_version") as mock_check:
            mock_check.return_value = True
            watcher.check_software_version_if_needed()
            mock_check.assert_called_once()
            assert watcher.last_software_version_check_time > 0

    def test_check_software_version_if_needed_skips(self, watcher_setup):
        """Test check_software_version_if_needed skips when recent"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        watcher.last_software_version_check_time = time.time()

        with mock.patch("counterpartycore.lib.parser.check.software_version") as mock_check:
            watcher.check_software_version_if_needed()
            mock_check.assert_not_called()

    def test_receive_hashtx(self, watcher_setup):
        """Test receive_hashtx stores hash by sequence"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        body = bytes.fromhex("abcd1234" * 8)
        sequence = "12345"

        watcher.receive_hashtx(body, sequence)

        assert watcher.hash_by_sequence[sequence] == body.hex()

    def test_receive_rawtx_first_time(self, watcher_setup):
        """Test receive_rawtx caches transaction first time"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        tx_hash = "abcd1234" * 8
        body = bytes.fromhex("0100000001" + "00" * 50)
        sequence = "12345"

        watcher.hash_by_sequence[sequence] = tx_hash

        with mock.patch("counterpartycore.lib.parser.deserialize.deserialize_tx") as mock_deser:
            mock_deser.return_value = {"tx_hash": tx_hash}
            watcher.receive_rawtx(body, sequence)

        assert tx_hash in watcher.raw_tx_cache
        assert sequence not in watcher.hash_by_sequence

    def test_receive_rawtx_second_time(self, watcher_setup):
        """Test receive_rawtx removes from cache on second time"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        tx_hash = "abcd1234" * 8
        body = bytes.fromhex("0100000001" + "00" * 50)
        sequence = "12345"

        # Pre-populate cache
        watcher.raw_tx_cache[tx_hash] = body.hex()
        watcher.hash_by_sequence[sequence] = tx_hash

        watcher.receive_rawtx(body, sequence)

        assert tx_hash not in watcher.raw_tx_cache

    def test_receive_rawtx_no_hash_in_sequence(self, watcher_setup):
        """Test receive_rawtx when hash not in sequence map"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        tx_hash = "abcd1234" * 8
        body = bytes.fromhex("0100000001" + "00" * 50)
        sequence = "12345"

        with mock.patch("counterpartycore.lib.parser.deserialize.deserialize_tx") as mock_deser:
            mock_deser.return_value = {"tx_hash": tx_hash}
            watcher.receive_rawtx(body, sequence)

        assert tx_hash in watcher.raw_tx_cache

    def test_need_to_parse_mempool_block_empty(self, watcher_setup):
        """Test need_to_parse_mempool_block returns False for empty block"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        watcher.mempool_block = []

        assert watcher.need_to_parse_mempool_block() is False

    def test_need_to_parse_mempool_block_max_size(self, watcher_setup):
        """Test need_to_parse_mempool_block returns True at max size"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        # For regtest, max size is 1
        watcher.mempool_block = ["tx1"]

        assert watcher.need_to_parse_mempool_block() is True

    def test_need_to_parse_mempool_block_timeout(self, watcher_setup):
        """Test need_to_parse_mempool_block returns True on timeout"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        watcher.mempool_block = ["tx1"]
        watcher.last_mempool_parsing_time = time.time() - 100  # Old time

        # For regtest, timeout is 5 seconds
        assert watcher.need_to_parse_mempool_block() is True

    def test_receive_sequence_add_new_tx(self, watcher_setup):
        """Test receive_sequence adds new transaction and parses mempool block"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        tx_hash = bytes.fromhex("abcd1234" * 8)
        label = b"A"
        body = tx_hash + label

        watcher.raw_tx_cache[tx_hash.hex()] = "raw_tx_data"

        with mock.patch(
            "counterpartycore.lib.parser.mempool.parse_mempool_transactions"
        ) as mock_parse:
            mock_parse.return_value = []
            with mock.patch.object(follow, "NotSupportedTransactionsCache") as mock_cache:
                mock_cache.return_value.add = mock.MagicMock()
                watcher.receive_sequence(body)
                # For regtest, max size is 1, so mempool block is parsed immediately
                mock_parse.assert_called_once()
                # The mempool block is cleared after parsing
                assert watcher.mempool_block == []
                assert watcher.mempool_block_hashes == []

    def test_receive_sequence_remove_tx(self, watcher_setup):
        """Test receive_sequence removes transaction from mempool"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        tx_hash = bytes.fromhex("abcd1234" * 8)
        label = b"R"
        body = tx_hash + label

        with mock.patch(
            "counterpartycore.lib.parser.mempool.clean_transaction_from_mempool"
        ) as mock_clean:
            watcher.receive_sequence(body)
            mock_clean.assert_called_once_with(db, tx_hash.hex())

    def test_receive_sequence_tx_not_in_cache(self, watcher_setup):
        """Test receive_sequence gets tx from bitcoind if not in cache"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        tx_hash = bytes.fromhex("abcd1234" * 8)
        label = b"A"
        body = tx_hash + label

        mock_bitcoind.getrawtransaction.return_value = "raw_tx_from_rpc"

        with mock.patch(
            "counterpartycore.lib.parser.mempool.parse_mempool_transactions"
        ) as mock_parse:
            mock_parse.return_value = []
            with mock.patch.object(follow, "NotSupportedTransactionsCache") as mock_cache:
                mock_cache.return_value.add = mock.MagicMock()
                watcher.receive_sequence(body)
                # Verify parse was called with the transaction from RPC
                assert mock_parse.called
                call_args = mock_parse.call_args[0]
                assert "raw_tx_from_rpc" in call_args[1]

    def test_receive_sequence_tx_not_found(self, watcher_setup, caplog):
        """Test receive_sequence handles transaction not found"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        tx_hash = bytes.fromhex("abcd1234" * 8)
        label = b"A"
        body = tx_hash + label

        mock_bitcoind.getrawtransaction.side_effect = exceptions.BitcoindRPCError("Not found")

        watcher.receive_sequence(body)

        # Transaction should not be added
        assert len(watcher.mempool_block) == 0

    def test_receive_message_rawblock(self, watcher_setup):
        """Test receive_message for rawblock topic"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup

        with mock.patch.object(watcher, "receive_rawblock") as mock_recv:
            watcher.receive_message(b"rawblock", b"body", b"\x01\x00\x00\x00")
            mock_recv.assert_called_once_with(b"body")

    def test_receive_message_hashtx(self, watcher_setup):
        """Test receive_message for hashtx topic"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup

        with mock.patch.object(watcher, "receive_hashtx") as mock_recv:
            watcher.receive_message(b"hashtx", b"body", b"\x01\x00\x00\x00")
            mock_recv.assert_called_once_with(b"body", "1")

    def test_receive_message_rawtx(self, watcher_setup):
        """Test receive_message for rawtx topic"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup

        with mock.patch.object(watcher, "receive_rawtx") as mock_recv:
            watcher.receive_message(b"rawtx", b"body", b"\x01\x00\x00\x00")
            mock_recv.assert_called_once_with(b"body", "1")

    def test_receive_message_sequence(self, watcher_setup):
        """Test receive_message for sequence topic"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup

        with mock.patch.object(watcher, "receive_sequence") as mock_recv:
            watcher.receive_message(b"sequence", b"body", b"\x01\x00\x00\x00")
            mock_recv.assert_called_once_with(b"body")

    def test_receive_message_unknown_sequence_length(self, watcher_setup):
        """Test receive_message with unknown sequence length"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup

        with mock.patch.object(watcher, "receive_rawblock") as mock_recv:
            # Invalid sequence length (not 4 bytes)
            watcher.receive_message(b"rawblock", b"body", b"\x01\x00")
            mock_recv.assert_called_once_with(b"body")

    def test_is_late_not_late(self, watcher_setup):
        """Test is_late returns False when up to date"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup

        with mock.patch("counterpartycore.lib.ledger.blocks.get_last_block") as mock_last:
            mock_last.return_value = {"block_index": 100}
            mock_bitcoind.getblockcount.return_value = 100

            assert watcher.is_late() is False

    def test_is_late_is_late(self, watcher_setup):
        """Test is_late returns True when behind"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup

        with mock.patch("counterpartycore.lib.ledger.blocks.get_last_block") as mock_last:
            mock_last.return_value = {"block_index": 100}
            mock_bitcoind.getblockcount.return_value = 105

            assert watcher.is_late() is True

    def test_is_late_no_block(self, watcher_setup):
        """Test is_late returns False when no blocks parsed"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup

        with mock.patch("counterpartycore.lib.ledger.blocks.get_last_block") as mock_last:
            mock_last.return_value = None

            assert watcher.is_late() is False

    def test_receive_rawblock_new_block(self, watcher_setup):
        """Test receive_rawblock parses new block"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup

        original_no_mempool = config.NO_MEMPOOL
        original_no_telemetry = config.NO_TELEMETRY
        config.NO_MEMPOOL = True
        config.NO_TELEMETRY = True

        decoded_block = {
            "block_hash": "newhash",
            "hash_prev": "prevhash",
        }

        try:
            with mock.patch(
                "counterpartycore.lib.parser.deserialize.deserialize_block"
            ) as mock_deser:
                mock_deser.return_value = decoded_block
                with mock.patch("counterpartycore.lib.ledger.blocks.get_block_by_hash") as mock_get:
                    # Block doesn't exist yet
                    mock_get.side_effect = [None, {"block_index": 99}]
                    with mock.patch(
                        "counterpartycore.lib.parser.blocks.parse_new_block"
                    ) as mock_parse:
                        watcher.receive_rawblock(b"block_data")
                        mock_parse.assert_called_once()
        finally:
            config.NO_MEMPOOL = original_no_mempool
            config.NO_TELEMETRY = original_no_telemetry

    def test_receive_rawblock_already_parsed(self, watcher_setup):
        """Test receive_rawblock skips already parsed block"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup

        decoded_block = {
            "block_hash": "existinghash",
            "hash_prev": "prevhash",
        }

        with mock.patch("counterpartycore.lib.parser.deserialize.deserialize_block") as mock_deser:
            mock_deser.return_value = decoded_block
            with mock.patch("counterpartycore.lib.ledger.blocks.get_block_by_hash") as mock_get:
                # Block already exists
                mock_get.return_value = {"block_index": 100}
                with mock.patch("counterpartycore.lib.parser.blocks.parse_new_block") as mock_parse:
                    watcher.receive_rawblock(b"block_data")
                    mock_parse.assert_not_called()

    def test_receive_rawblock_previous_block_missing(self, watcher_setup):
        """Test receive_rawblock catches up when previous block missing"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup

        original_no_mempool = config.NO_MEMPOOL
        original_no_telemetry = config.NO_TELEMETRY
        config.NO_MEMPOOL = True
        config.NO_TELEMETRY = True

        decoded_block = {
            "block_hash": "newhash",
            "hash_prev": "prevhash",
        }

        try:
            with mock.patch(
                "counterpartycore.lib.parser.deserialize.deserialize_block"
            ) as mock_deser:
                mock_deser.return_value = decoded_block
                with mock.patch("counterpartycore.lib.ledger.blocks.get_block_by_hash") as mock_get:
                    # New block doesn't exist, previous block also doesn't exist
                    mock_get.side_effect = [None, None]
                    with mock.patch("counterpartycore.lib.parser.blocks.catch_up") as mock_catch:
                        watcher.receive_rawblock(b"block_data")
                        mock_catch.assert_called_once_with(db)
        finally:
            config.NO_MEMPOOL = original_no_mempool
            config.NO_TELEMETRY = original_no_telemetry

    def test_stop(self, watcher_setup):
        """Test stop method"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        watcher.task = mock.MagicMock()
        watcher.task.done.return_value = False
        watcher.loop = mock.MagicMock()
        watcher.loop.is_running.return_value = True
        watcher.zmq_context = mock.MagicMock()
        watcher.zmq_sub_socket_sequence = mock.MagicMock()
        watcher.zmq_sub_socket_rawblock = mock.MagicMock()
        watcher.mempool_parser = None

        watcher.stop()

        assert watcher.stop_event.is_set()
        watcher.task.cancel.assert_called_once()
        watcher.loop.call_soon_threadsafe.assert_called_once()
        watcher.zmq_context.term.assert_called_once()

    def test_stop_with_mempool_parser(self, watcher_setup):
        """Test stop method with mempool parser"""
        watcher, db, mock_bitcoind, mock_cs = watcher_setup
        watcher.task = mock.MagicMock()
        watcher.task.done.return_value = True
        watcher.loop = mock.MagicMock()
        watcher.loop.is_running.return_value = False
        watcher.zmq_context = mock.MagicMock()
        watcher.mempool_parser = mock.MagicMock()

        watcher.stop()

        watcher.mempool_parser.stop.assert_called_once()


# ============================================================================
# Tests for get_raw_mempool()
# ============================================================================


def test_get_raw_mempool_empty(mock_backend_bitcoind, reset_not_supported_cache, temp_cache_dir):
    """Test get_raw_mempool with empty mempool"""
    mock_backend_bitcoind.getrawmempool.return_value = {}

    db = mock.MagicMock()
    cursor = mock.MagicMock()
    db.cursor.return_value = cursor

    chunks, timestamps = follow.get_raw_mempool(db)

    assert chunks == []
    assert timestamps == {}


def test_get_raw_mempool_with_transactions(
    mock_backend_bitcoind, reset_not_supported_cache, temp_cache_dir
):
    """Test get_raw_mempool with transactions"""
    mock_backend_bitcoind.getrawmempool.return_value = {
        "tx1": {"time": 12345},
        "tx2": {"time": 12346},
    }

    db = mock.MagicMock()
    cursor = mock.MagicMock()
    cursor.execute.return_value.fetchone.return_value = None
    db.cursor.return_value = cursor

    # Clear singleton
    follow.NotSupportedTransactionsCache()

    chunks, timestamps = follow.get_raw_mempool(db)

    assert len(timestamps) == 2
    assert timestamps["tx1"] == 12345
    assert timestamps["tx2"] == 12346


def test_get_raw_mempool_skips_existing(
    mock_backend_bitcoind, reset_not_supported_cache, temp_cache_dir
):
    """Test get_raw_mempool skips existing transactions"""
    mock_backend_bitcoind.getrawmempool.return_value = {
        "tx1": {"time": 12345},
        "tx2": {"time": 12346},
    }

    db = mock.MagicMock()
    cursor = mock.MagicMock()
    # First tx exists in mempool, second doesn't
    cursor.execute.return_value.fetchone.side_effect = [{"tx_hash": "tx1"}, None]
    db.cursor.return_value = cursor

    follow.NotSupportedTransactionsCache()

    chunks, timestamps = follow.get_raw_mempool(db)

    assert "tx1" not in timestamps
    assert "tx2" in timestamps


def test_get_raw_mempool_skips_not_supported(
    mock_backend_bitcoind, reset_not_supported_cache, temp_cache_dir
):
    """Test get_raw_mempool skips not supported transactions"""
    mock_backend_bitcoind.getrawmempool.return_value = {
        "tx1": {"time": 12345},
        "tx2": {"time": 12346},
    }

    db = mock.MagicMock()
    cursor = mock.MagicMock()
    cursor.execute.return_value.fetchone.return_value = None
    db.cursor.return_value = cursor

    cache = follow.NotSupportedTransactionsCache()
    cache.add(["tx1"])

    chunks, timestamps = follow.get_raw_mempool(db)

    assert "tx1" not in timestamps
    assert "tx2" in timestamps


# ============================================================================
# Tests for RawMempoolParser class
# ============================================================================


def test_raw_mempool_parser_init(mock_backend_bitcoind, reset_not_supported_cache, temp_cache_dir):
    """Test RawMempoolParser initialization"""
    mock_backend_bitcoind.getrawmempool.return_value = {}

    db = mock.MagicMock()
    cursor = mock.MagicMock()
    db.cursor.return_value = cursor

    parser = follow.RawMempoolParser(db)

    assert parser.db == db
    assert parser.daemon is True
    assert isinstance(parser.stop_event, threading.Event)


def test_raw_mempool_parser_run(mock_backend_bitcoind, reset_not_supported_cache, temp_cache_dir):
    """Test RawMempoolParser run method"""
    mock_backend_bitcoind.getrawmempool.return_value = {
        "tx1": {"time": 12345},
    }
    mock_backend_bitcoind.getrawtransaction_batch.return_value = ["raw_tx1"]

    db = mock.MagicMock()
    cursor = mock.MagicMock()
    cursor.execute.return_value.fetchone.return_value = None
    db.cursor.return_value = cursor

    # Clear RAW_MEMPOOL before test
    follow.RAW_MEMPOOL.clear()

    parser = follow.RawMempoolParser(db)
    parser.run()

    assert len(follow.RAW_MEMPOOL) == 1
    assert follow.RAW_MEMPOOL[0] == ["raw_tx1"]

    # Clean up
    follow.RAW_MEMPOOL.clear()


def test_raw_mempool_parser_stop(mock_backend_bitcoind, reset_not_supported_cache, temp_cache_dir):
    """Test RawMempoolParser stop method"""
    mock_backend_bitcoind.getrawmempool.return_value = {}

    db = mock.MagicMock()
    cursor = mock.MagicMock()
    db.cursor.return_value = cursor

    parser = follow.RawMempoolParser(db)
    parser.start()
    time.sleep(0.1)
    parser.stop()

    assert parser.stop_event.is_set()
    db.interrupt.assert_called_once()


# ============================================================================
# Tests for NotSupportedTransactionsCache class
# ============================================================================


class TestNotSupportedTransactionsCache:
    """Tests for NotSupportedTransactionsCache class"""

    def test_init_no_existing_cache(self, reset_not_supported_cache, temp_cache_dir):
        """Test initialization with no existing cache file"""
        cache = follow.NotSupportedTransactionsCache()

        assert len(cache.not_suppported_txs) == 0
        assert len(cache._ordered_txs) == 0

    def test_init_with_existing_cache(self, reset_not_supported_cache, temp_cache_dir):
        """Test initialization with existing cache file"""
        cache_path = os.path.join(temp_cache_dir, "not_supported_tx_cache.regtest.txt")
        with open(cache_path, "w", encoding="utf-8") as f:
            f.write("tx1\ntx2\ntx3")

        cache = follow.NotSupportedTransactionsCache()

        assert len(cache.not_suppported_txs) == 3
        assert "tx1" in cache.not_suppported_txs
        assert "tx2" in cache.not_suppported_txs
        assert "tx3" in cache.not_suppported_txs

    def test_add_transactions(self, reset_not_supported_cache, temp_cache_dir):
        """Test adding transactions to cache"""
        cache = follow.NotSupportedTransactionsCache()

        cache.add(["tx1", "tx2"])

        assert "tx1" in cache.not_suppported_txs
        assert "tx2" in cache.not_suppported_txs
        assert cache._ordered_txs == ["tx1", "tx2"]

    def test_add_duplicate_transactions(self, reset_not_supported_cache, temp_cache_dir):
        """Test adding duplicate transactions"""
        cache = follow.NotSupportedTransactionsCache()

        cache.add(["tx1"])
        cache.add(["tx1", "tx2"])

        assert len(cache.not_suppported_txs) == 2
        assert cache._ordered_txs == ["tx1", "tx2"]

    def test_is_not_supported(self, reset_not_supported_cache, temp_cache_dir):
        """Test is_not_supported check"""
        cache = follow.NotSupportedTransactionsCache()
        cache.add(["tx1"])

        assert cache.is_not_supported("tx1") is True
        assert cache.is_not_supported("tx2") is False

    def test_backup(self, reset_not_supported_cache, temp_cache_dir):
        """Test backup saves to file"""
        cache = follow.NotSupportedTransactionsCache()
        cache.add(["tx1", "tx2"])

        cache.backup()

        cache_path = os.path.join(temp_cache_dir, "not_supported_tx_cache.regtest.txt")
        assert os.path.exists(cache_path)
        with open(cache_path, "r", encoding="utf-8") as f:
            content = f.read()
        assert "tx1" in content
        assert "tx2" in content

    def test_clear(self, reset_not_supported_cache, temp_cache_dir):
        """Test clear removes cache"""
        cache = follow.NotSupportedTransactionsCache()
        cache.add(["tx1", "tx2"])
        cache.backup()

        cache_path = os.path.join(temp_cache_dir, "not_supported_tx_cache.regtest.txt")
        assert os.path.exists(cache_path)

        cache.clear()

        assert len(cache.not_suppported_txs) == 0
        assert len(cache._ordered_txs) == 0
        assert not os.path.exists(cache_path)

    def test_restore(self, reset_not_supported_cache, temp_cache_dir):
        """Test restore loads from file"""
        cache_path = os.path.join(temp_cache_dir, "not_supported_tx_cache.regtest.txt")
        with open(cache_path, "w", encoding="utf-8") as f:
            f.write("tx1\ntx2")

        cache = follow.NotSupportedTransactionsCache()
        # restore() is called in __init__

        assert "tx1" in cache.not_suppported_txs
        assert "tx2" in cache.not_suppported_txs

    def test_max_size_eviction(self, reset_not_supported_cache, temp_cache_dir, monkeypatch):
        """Test oldest entries are evicted when MAX_SIZE is exceeded"""
        monkeypatch.setattr(follow.NotSupportedTransactionsCache, "MAX_SIZE", 3)
        cache = follow.NotSupportedTransactionsCache()

        cache.add(["tx1", "tx2", "tx3"])
        cache.add(["tx4", "tx5"])

        assert cache._ordered_txs == ["tx3", "tx4", "tx5"]
        assert cache.not_suppported_txs == {"tx3", "tx4", "tx5"}
        assert cache.is_not_supported("tx1") is False

        # The compacted file matches the in-memory state
        cache_path = os.path.join(temp_cache_dir, "not_supported_tx_cache.regtest.txt")
        with open(cache_path, "r", encoding="utf-8") as f:
            assert [line.strip() for line in f] == ["tx3", "tx4", "tx5"]

    def test_restore_trims_to_max_size(
        self, reset_not_supported_cache, temp_cache_dir, monkeypatch
    ):
        """Test restore keeps only the most recent MAX_SIZE entries"""
        monkeypatch.setattr(follow.NotSupportedTransactionsCache, "MAX_SIZE", 2)
        cache_path = os.path.join(temp_cache_dir, "not_supported_tx_cache.regtest.txt")
        with open(cache_path, "w", encoding="utf-8") as f:
            f.write("tx1\ntx2\ntx3\n")

        cache = follow.NotSupportedTransactionsCache()

        assert cache._ordered_txs == ["tx2", "tx3"]
        # The oversized file is compacted on restore
        with open(cache_path, "r", encoding="utf-8") as f:
            assert [line.strip() for line in f] == ["tx2", "tx3"]

    def test_add_appends_to_legacy_file(self, reset_not_supported_cache, temp_cache_dir):
        """Test appending after restoring a legacy file without trailing newline"""
        cache_path = os.path.join(temp_cache_dir, "not_supported_tx_cache.regtest.txt")
        with open(cache_path, "w", encoding="utf-8") as f:
            f.write("tx1\ntx2")  # legacy format: no trailing newline

        cache = follow.NotSupportedTransactionsCache()
        cache.add(["tx3"])

        with open(cache_path, "r", encoding="utf-8") as f:
            assert [line.strip() for line in f] == ["tx1", "tx2", "tx3"]

    def test_persistence_across_restart(self, reset_not_supported_cache, temp_cache_dir):
        """Test appended entries survive a singleton reset (process restart)"""
        cache = follow.NotSupportedTransactionsCache()
        cache.add(["tx1", "tx2"])
        cache.add(["tx3"])

        del helpers.SingletonMeta._instances[follow.NotSupportedTransactionsCache]
        restored = follow.NotSupportedTransactionsCache()

        assert restored._ordered_txs == ["tx1", "tx2", "tx3"]
        assert restored.not_suppported_txs == {"tx1", "tx2", "tx3"}


# ============================================================================
# Tests for receive_multipart (using asyncio.run)
# ============================================================================


def test_receive_multipart_success():
    """Test receive_multipart successful receive"""

    async def run_test():
        with mock.patch("counterpartycore.lib.backend.bitcoind") as mock_bitcoind:
            mock_bitcoind.get_zmq_notifications.return_value = [
                {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
            ]

            original_backend_connect = config.BACKEND_CONNECT
            original_no_mempool = config.NO_MEMPOOL
            config.BACKEND_CONNECT = "127.0.0.1"
            config.NO_MEMPOOL = True

            try:
                with mock.patch("counterpartycore.lib.monitors.sentry.init"):
                    with mock.patch("zmq.asyncio.Context"):
                        with mock.patch("asyncio.new_event_loop"):
                            with mock.patch("asyncio.set_event_loop"):
                                with mock.patch("counterpartycore.lib.parser.follow.CurrentState"):
                                    db = mock.MagicMock()
                                    watcher = follow.BlockchainWatcher(db)

                                    mock_socket = mock.AsyncMock()
                                    mock_socket.recv_multipart.return_value = (
                                        b"rawblock",
                                        b"body",
                                        b"\x01\x00\x00\x00",
                                    )

                                    with mock.patch.object(watcher, "receive_message") as mock_recv:
                                        await watcher.receive_multipart(mock_socket, "rawblock")
                                        mock_recv.assert_called_once()
            finally:
                config.BACKEND_CONNECT = original_backend_connect
                config.NO_MEMPOOL = original_no_mempool

    asyncio.run(run_test())


def test_receive_multipart_eagain():
    """Test receive_multipart handles EAGAIN error"""

    async def run_test():
        with mock.patch("counterpartycore.lib.backend.bitcoind") as mock_bitcoind:
            mock_bitcoind.get_zmq_notifications.return_value = [
                {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
            ]

            original_backend_connect = config.BACKEND_CONNECT
            original_no_mempool = config.NO_MEMPOOL
            config.BACKEND_CONNECT = "127.0.0.1"
            config.NO_MEMPOOL = True

            try:
                with mock.patch("counterpartycore.lib.monitors.sentry.init"):
                    with mock.patch("zmq.asyncio.Context"):
                        with mock.patch("asyncio.new_event_loop"):
                            with mock.patch("asyncio.set_event_loop"):
                                with mock.patch("counterpartycore.lib.parser.follow.CurrentState"):
                                    db = mock.MagicMock()
                                    watcher = follow.BlockchainWatcher(db)

                                    mock_socket = mock.AsyncMock()
                                    error = zmq.ZMQError(zmq.EAGAIN, "No message")
                                    mock_socket.recv_multipart.side_effect = error

                                    # Should not raise, just return
                                    await watcher.receive_multipart(mock_socket, "rawblock")
            finally:
                config.BACKEND_CONNECT = original_backend_connect
                config.NO_MEMPOOL = original_no_mempool

    asyncio.run(run_test())


def test_receive_multipart_other_error():
    """Test receive_multipart handles other ZMQ errors"""

    async def run_test():
        with mock.patch("counterpartycore.lib.backend.bitcoind") as mock_bitcoind:
            mock_bitcoind.get_zmq_notifications.return_value = [
                {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
            ]

            original_backend_connect = config.BACKEND_CONNECT
            original_no_mempool = config.NO_MEMPOOL
            config.BACKEND_CONNECT = "127.0.0.1"
            config.NO_MEMPOOL = True

            try:
                with mock.patch("counterpartycore.lib.monitors.sentry.init"):
                    with mock.patch("zmq.asyncio.Context"):
                        with mock.patch("asyncio.new_event_loop"):
                            with mock.patch("asyncio.set_event_loop"):
                                with mock.patch("counterpartycore.lib.parser.follow.CurrentState"):
                                    db = mock.MagicMock()
                                    watcher = follow.BlockchainWatcher(db)

                                    mock_socket = mock.AsyncMock()
                                    error = zmq.ZMQError(zmq.ETERM, "Context terminated")
                                    mock_socket.recv_multipart.side_effect = error

                                    with pytest.raises(zmq.ZMQError):
                                        await watcher.receive_multipart(mock_socket, "rawblock")
            finally:
                config.BACKEND_CONNECT = original_backend_connect
                config.NO_MEMPOOL = original_no_mempool

    asyncio.run(run_test())


def test_receive_multipart_general_exception():
    """Test receive_multipart handles general exceptions"""

    async def run_test():
        with mock.patch("counterpartycore.lib.backend.bitcoind") as mock_bitcoind:
            mock_bitcoind.get_zmq_notifications.return_value = [
                {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
            ]

            original_backend_connect = config.BACKEND_CONNECT
            original_no_mempool = config.NO_MEMPOOL
            config.BACKEND_CONNECT = "127.0.0.1"
            config.NO_MEMPOOL = True

            try:
                with mock.patch("counterpartycore.lib.monitors.sentry.init"):
                    with mock.patch("zmq.asyncio.Context"):
                        with mock.patch("asyncio.new_event_loop"):
                            with mock.patch("asyncio.set_event_loop"):
                                with mock.patch("counterpartycore.lib.parser.follow.CurrentState"):
                                    with mock.patch(
                                        "counterpartycore.lib.parser.follow.capture_exception"
                                    ):
                                        db = mock.MagicMock()
                                        watcher = follow.BlockchainWatcher(db)

                                        mock_socket = mock.AsyncMock()
                                        mock_socket.recv_multipart.side_effect = RuntimeError(
                                            "Connection lost"
                                        )

                                        with mock.patch.object(watcher, "connect_to_zmq"):
                                            # Should reconnect and return
                                            await watcher.receive_multipart(mock_socket, "rawblock")
            finally:
                config.BACKEND_CONNECT = original_backend_connect
                config.NO_MEMPOOL = original_no_mempool

    asyncio.run(run_test())


def test_receive_multipart_message_processing_error():
    """Test receive_multipart handles message processing errors"""

    async def run_test():
        with mock.patch("counterpartycore.lib.backend.bitcoind") as mock_bitcoind:
            mock_bitcoind.get_zmq_notifications.return_value = [
                {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
            ]

            original_backend_connect = config.BACKEND_CONNECT
            original_no_mempool = config.NO_MEMPOOL
            config.BACKEND_CONNECT = "127.0.0.1"
            config.NO_MEMPOOL = True

            try:
                with mock.patch("counterpartycore.lib.monitors.sentry.init"):
                    with mock.patch("zmq.asyncio.Context"):
                        with mock.patch("asyncio.new_event_loop"):
                            with mock.patch("asyncio.set_event_loop"):
                                with mock.patch("counterpartycore.lib.parser.follow.CurrentState"):
                                    with mock.patch(
                                        "counterpartycore.lib.parser.follow.capture_exception"
                                    ):
                                        db = mock.MagicMock()
                                        watcher = follow.BlockchainWatcher(db)

                                        mock_socket = mock.AsyncMock()
                                        mock_socket.recv_multipart.return_value = (
                                            b"rawblock",
                                            b"body",
                                            b"\x01\x00\x00\x00",
                                        )

                                        with mock.patch.object(
                                            watcher,
                                            "receive_message",
                                            side_effect=ValueError("Parse error"),
                                        ):
                                            with pytest.raises(ValueError):
                                                await watcher.receive_multipart(
                                                    mock_socket, "rawblock"
                                                )
            finally:
                config.BACKEND_CONNECT = original_backend_connect
                config.NO_MEMPOOL = original_no_mempool

    asyncio.run(run_test())


def test_receive_multipart_swallows_interrupt_during_shutdown():
    """When stop() has interrupted the shared DB connection mid-parse, the
    resulting ParseTransactionError("interrupted") must be treated as expected
    teardown noise: logged at debug, NOT sent to Sentry, and NOT re-raised
    (which would force a spurious "fail loud" restart of an already-stopping
    process). Pins the stop_event guard in receive_multipart."""

    async def run_test():
        with mock.patch("counterpartycore.lib.backend.bitcoind") as mock_bitcoind:
            mock_bitcoind.get_zmq_notifications.return_value = [
                {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
                {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
            ]

            original_backend_connect = config.BACKEND_CONNECT
            original_no_mempool = config.NO_MEMPOOL
            config.BACKEND_CONNECT = "127.0.0.1"
            config.NO_MEMPOOL = True

            try:
                with mock.patch("counterpartycore.lib.monitors.sentry.init"):
                    with mock.patch("zmq.asyncio.Context"):
                        with mock.patch("asyncio.new_event_loop"):
                            with mock.patch("asyncio.set_event_loop"):
                                with mock.patch("counterpartycore.lib.parser.follow.CurrentState"):
                                    with mock.patch(
                                        "counterpartycore.lib.parser.follow.capture_exception"
                                    ) as mock_capture:
                                        db = mock.MagicMock()
                                        watcher = follow.BlockchainWatcher(db)
                                        # Simulate shutdown already in progress.
                                        watcher.stop_event.set()

                                        mock_socket = mock.AsyncMock()
                                        mock_socket.recv_multipart.return_value = (
                                            b"rawblock",
                                            b"body",
                                            b"\x01\x00\x00\x00",
                                        )

                                        with mock.patch.object(
                                            watcher,
                                            "receive_message",
                                            side_effect=exceptions.ParseTransactionError(
                                                "interrupted"
                                            ),
                                        ):
                                            # MUST NOT raise during shutdown...
                                            await watcher.receive_multipart(
                                                mock_socket, "rawblock"
                                            )
                                            # ...and MUST NOT page Sentry.
                                            mock_capture.assert_not_called()
            finally:
                config.BACKEND_CONNECT = original_backend_connect
                config.NO_MEMPOOL = original_no_mempool

    asyncio.run(run_test())


# ============================================================================
# Tests for receive_rawblock generic exception handler (lines 189-190)
# ============================================================================


def test_receive_rawblock_swallows_generic_exception(
    mock_backend_bitcoind, mock_current_state, mock_zmq_context, caplog
):
    """A non-ParseTransactionError raised inside receive_rawblock must be
    logged + sent to Sentry but not torn down -- next ZMQ msg / is_late()
    tick will trigger catch_up() to recover. This pins the wide-except
    branch from the receive_rawblock hardening."""
    mock_cs, mock_instance = mock_current_state
    mock_instance.current_block_index.return_value = 100
    mock_backend_bitcoind.get_zmq_notifications.return_value = [
        {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
    ]

    original_backend_connect = config.BACKEND_CONNECT
    original_no_mempool = config.NO_MEMPOOL
    config.BACKEND_CONNECT = "127.0.0.1"
    config.NO_MEMPOOL = True

    try:
        with mock.patch("counterpartycore.lib.monitors.sentry.init"):
            with mock.patch("asyncio.new_event_loop"):
                with mock.patch("asyncio.set_event_loop"):
                    with mock.patch(
                        "counterpartycore.lib.parser.deserialize.deserialize_block",
                        side_effect=RuntimeError("malformed rawblock"),
                    ):
                        with mock.patch(
                            "counterpartycore.lib.parser.follow.capture_exception"
                        ) as mock_capture:
                            db = mock.MagicMock()
                            watcher = follow.BlockchainWatcher(db)
                            # MUST NOT raise
                            watcher.receive_rawblock(b"\x00" * 80)
                            mock_capture.assert_called_once()
    finally:
        config.BACKEND_CONNECT = original_backend_connect
        config.NO_MEMPOOL = original_no_mempool


# ============================================================================
# Tests for is_late RPC failure (lines 300, 303-304)
# ============================================================================


def test_is_late_returns_false_on_rpc_error(
    mock_backend_bitcoind, mock_current_state, mock_zmq_context, caplog
):
    """is_late must NOT tear down the watcher when bitcoind RPC fails;
    a transient auth/proxy flap should return False so the outer handle
    loop keeps running."""
    mock_cs, mock_instance = mock_current_state
    mock_instance.current_block_index.return_value = 100
    mock_backend_bitcoind.get_zmq_notifications.return_value = [
        {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
    ]
    mock_backend_bitcoind.getblockcount.side_effect = exceptions.BitcoindRPCError(
        "401 Unauthorized"
    )

    original_backend_connect = config.BACKEND_CONNECT
    original_no_mempool = config.NO_MEMPOOL
    config.BACKEND_CONNECT = "127.0.0.1"
    config.NO_MEMPOOL = True

    try:
        with mock.patch("counterpartycore.lib.monitors.sentry.init"):
            with mock.patch("asyncio.new_event_loop"):
                with mock.patch("asyncio.set_event_loop"):
                    db = mock.MagicMock()
                    watcher = follow.BlockchainWatcher(db)
                    with mock.patch(
                        "counterpartycore.lib.ledger.blocks.get_last_block",
                        return_value={"block_index": 100},
                    ):
                        # MUST return False, MUST NOT raise
                        assert watcher.is_late() is False
    finally:
        config.BACKEND_CONNECT = original_backend_connect
        config.NO_MEMPOOL = original_no_mempool


# ============================================================================
# Tests for need_to_parse_mempool_block timeout return False path (line 221)
# ============================================================================


def test_need_to_parse_mempool_block_returns_false_when_no_timeout(
    mock_backend_bitcoind, mock_current_state, mock_zmq_context
):
    """When the mempool block is non-empty but under the size limit AND
    the time-since-last-parse is below the timeout, the helper must
    return False (the previously uncovered tail of the function)."""
    mock_cs, mock_instance = mock_current_state
    mock_instance.current_block_index.return_value = 100
    mock_backend_bitcoind.get_zmq_notifications.return_value = [
        {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
    ]

    original_backend_connect = config.BACKEND_CONNECT
    original_no_mempool = config.NO_MEMPOOL
    original_network = config.NETWORK_NAME
    config.BACKEND_CONNECT = "127.0.0.1"
    config.NO_MEMPOOL = True
    config.NETWORK_NAME = "mainnet"  # timeout is 60s on mainnet

    try:
        with mock.patch("counterpartycore.lib.monitors.sentry.init"):
            with mock.patch("asyncio.new_event_loop"):
                with mock.patch("asyncio.set_event_loop"):
                    db = mock.MagicMock()
                    watcher = follow.BlockchainWatcher(db)
                    # 1 tx, but mainnet limit is 100; just-now parse time
                    watcher.mempool_block = ["tx1"]
                    watcher.last_mempool_parsing_time = time.time()
                    assert watcher.need_to_parse_mempool_block() is False
    finally:
        config.BACKEND_CONNECT = original_backend_connect
        config.NO_MEMPOOL = original_no_mempool
        config.NETWORK_NAME = original_network


# ============================================================================
# Tests for stop() ZMQ cleanup exception handler (lines 388-389)
# ============================================================================


def test_stop_handles_zmq_cleanup_failure(
    mock_backend_bitcoind, mock_current_state, mock_zmq_context, caplog
):
    """If a ZMQ socket close raises during stop() the watcher must still
    finish shutdown cleanly (logged at debug, no propagation)."""
    mock_cs, mock_instance = mock_current_state
    mock_backend_bitcoind.get_zmq_notifications.return_value = [
        {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
    ]

    original_backend_connect = config.BACKEND_CONNECT
    original_no_mempool = config.NO_MEMPOOL
    config.BACKEND_CONNECT = "127.0.0.1"
    config.NO_MEMPOOL = True

    try:
        with mock.patch("counterpartycore.lib.monitors.sentry.init"):
            with mock.patch("asyncio.new_event_loop"):
                with mock.patch("asyncio.set_event_loop"):
                    db = mock.MagicMock()
                    watcher = follow.BlockchainWatcher(db)
                    watcher.task = mock.MagicMock()
                    watcher.task.done.return_value = True
                    watcher.loop = mock.MagicMock()
                    watcher.loop.is_running.return_value = False
                    watcher.zmq_sub_socket_sequence = mock.MagicMock()
                    watcher.zmq_sub_socket_sequence.close.side_effect = RuntimeError(
                        "socket already closed"
                    )
                    watcher.zmq_sub_socket_rawblock = mock.MagicMock()
                    watcher.zmq_context = mock.MagicMock()
                    watcher.mempool_parser = None

                    # MUST NOT raise
                    watcher.stop()
                    assert watcher.stop_event.is_set()
    finally:
        config.BACKEND_CONNECT = original_backend_connect
        config.NO_MEMPOOL = original_no_mempool


# ============================================================================
# Tests for stop() KeyboardInterrupt swallowing (line ~395)
# ============================================================================


def test_stop_swallows_keyboard_interrupt(
    mock_backend_bitcoind, mock_current_state, mock_zmq_context
):
    """A repeated Ctrl+C during shutdown must NOT crash the watcher."""
    mock_cs, mock_instance = mock_current_state
    mock_backend_bitcoind.get_zmq_notifications.return_value = [
        {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
    ]

    original_backend_connect = config.BACKEND_CONNECT
    original_no_mempool = config.NO_MEMPOOL
    config.BACKEND_CONNECT = "127.0.0.1"
    config.NO_MEMPOOL = True

    try:
        with mock.patch("counterpartycore.lib.monitors.sentry.init"):
            with mock.patch("asyncio.new_event_loop"):
                with mock.patch("asyncio.set_event_loop"):
                    db = mock.MagicMock()
                    watcher = follow.BlockchainWatcher(db)
                    watcher.task = mock.MagicMock()
                    watcher.task.done.return_value = True
                    watcher.loop = mock.MagicMock()
                    watcher.loop.is_running.return_value = False
                    watcher.zmq_sub_socket_sequence = mock.MagicMock()
                    watcher.zmq_sub_socket_rawblock = mock.MagicMock()
                    watcher.zmq_context = mock.MagicMock()
                    watcher.mempool_parser = None

                    # Force the inner shutdown to raise KeyboardInterrupt
                    # to exercise the catch-and-pass guard.
                    with mock.patch.object(
                        watcher.stop_event, "set", side_effect=KeyboardInterrupt
                    ):
                        watcher.stop()  # MUST NOT raise
    finally:
        config.BACKEND_CONNECT = original_backend_connect
        config.NO_MEMPOOL = original_no_mempool


# ============================================================================
# Tests for RawMempoolParser KeyboardInterrupt during stop (lines 454-455)
# ============================================================================


def test_raw_mempool_parser_stop_swallows_keyboard_interrupt(
    mock_backend_bitcoind, reset_not_supported_cache, temp_cache_dir
):
    """Repeated Ctrl+C during RawMempoolParser shutdown must be ignored."""
    mock_backend_bitcoind.getrawmempool.return_value = {}

    db = mock.MagicMock()
    cursor = mock.MagicMock()
    db.cursor.return_value = cursor

    parser = follow.RawMempoolParser(db)
    db.interrupt.side_effect = KeyboardInterrupt
    # MUST NOT raise
    parser.stop()


# ============================================================================
# Tests for clean_mempool sweep after catch_up paths
# ============================================================================


def test_receive_rawblock_previous_block_missing_calls_clean_mempool(
    mock_backend_bitcoind, mock_current_state, mock_zmq_context
):
    """The `previous_block is None` branch in receive_rawblock falls
    back to RPC catch_up. It must follow up with clean_mempool for
    the same reason as the ZMQ-late branch: confirmed-tx mempool rows
    only get pruned by clean_mempool, never by parse_new_block."""
    mock_cs, mock_instance = mock_current_state
    mock_backend_bitcoind.get_zmq_notifications.return_value = [
        {"type": "pubrawtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubhashtx", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubsequence", "address": "tcp://127.0.0.1:28332"},
        {"type": "pubrawblock", "address": "tcp://127.0.0.1:28333"},
    ]

    original_backend_connect = config.BACKEND_CONNECT
    original_no_mempool = config.NO_MEMPOOL
    original_no_telemetry = config.NO_TELEMETRY
    config.BACKEND_CONNECT = "127.0.0.1"
    config.NO_MEMPOOL = False
    config.NO_TELEMETRY = True

    decoded_block = {"block_hash": "newhash", "hash_prev": "prevhash"}

    try:
        with mock.patch("counterpartycore.lib.monitors.sentry.init"):
            with mock.patch("asyncio.new_event_loop"):
                with mock.patch("asyncio.set_event_loop"):
                    with mock.patch("counterpartycore.lib.parser.mempool.clean_mempool"):
                        with mock.patch("counterpartycore.lib.parser.follow.RawMempoolParser"):
                            db = mock.MagicMock()
                            watcher = follow.BlockchainWatcher(db)

                    with mock.patch(
                        "counterpartycore.lib.parser.deserialize.deserialize_block",
                        return_value=decoded_block,
                    ):
                        with mock.patch(
                            "counterpartycore.lib.ledger.blocks.get_block_by_hash",
                            side_effect=[None, None],
                        ):
                            with mock.patch(
                                "counterpartycore.lib.parser.blocks.catch_up"
                            ) as mock_catch:
                                with mock.patch(
                                    "counterpartycore.lib.parser.mempool.clean_mempool"
                                ) as mock_clean:
                                    watcher.receive_rawblock(b"block_data")
                                    mock_catch.assert_called_once_with(db)
                                    mock_clean.assert_called_once_with(db)
    finally:
        config.BACKEND_CONNECT = original_backend_connect
        config.NO_MEMPOOL = original_no_mempool
        config.NO_TELEMETRY = original_no_telemetry
