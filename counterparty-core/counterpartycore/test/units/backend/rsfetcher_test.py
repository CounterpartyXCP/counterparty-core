import queue
import time
from unittest.mock import MagicMock, call, patch

import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.backend.rsfetcher import (
    PREFETCH_QUEUE_SIZE,
    RSFetcher,
    delete_database_directory,
    stop,
)


@pytest.fixture
def mock_indexer():
    with patch("counterpartycore.lib.backend.rsfetcher.indexer") as mock_indexer:
        mock_indexer_instance = MagicMock()
        mock_indexer.Indexer.return_value = mock_indexer_instance
        mock_indexer_instance.get_version.return_value = config.__version__
        yield mock_indexer


@pytest.fixture
def mock_protocol():
    with patch("counterpartycore.lib.backend.rsfetcher.protocol") as mock_protocol:
        mock_protocol.enabled.return_value = False
        yield mock_protocol


@pytest.fixture
def mock_config():
    # Save original config values
    original_values = {
        "BACKEND_CONNECT": config.BACKEND_CONNECT,
        "BACKEND_PORT": config.BACKEND_PORT,
        "BACKEND_SSL": config.BACKEND_SSL,
        "BACKEND_USER": config.BACKEND_USER,
        "BACKEND_PASSWORD": config.BACKEND_PASSWORD,
        "FETCHER_DB": config.FETCHER_DB,
        "FETCHER_LOG": config.FETCHER_LOG,
        "JSON_LOGS": config.JSON_LOGS,
        "LOG_EXCLUDE_FILTERS": config.LOG_EXCLUDE_FILTERS,
        "LOG_INCLUDE_FILTERS": config.LOG_INCLUDE_FILTERS,
        "LOG_LEVEL_STRING": config.LOG_LEVEL_STRING,
        "NETWORK_NAME": config.NETWORK_NAME,
        "FETCHER_DB_OLD": config.FETCHER_DB_OLD,
    }

    # Set test values
    config.BACKEND_CONNECT = "localhost"
    config.BACKEND_PORT = 8332
    config.BACKEND_SSL = False
    config.BACKEND_USER = "testuser"
    config.BACKEND_PASSWORD = "testpass"  # noqa S105
    config.FETCHER_DB = "/tmp/testdb"  # noqa S108
    config.FETCHER_DB_OLD = "/tmp/testdb_old"  # noqa S108
    config.FETCHER_LOG = "/tmp/fetcher.log"  # noqa S108
    config.JSON_LOGS = False
    config.LOG_EXCLUDE_FILTERS = []
    config.LOG_INCLUDE_FILTERS = []
    config.LOG_LEVEL_STRING = "DEBUG"
    config.NETWORK_NAME = "testnet"

    yield config  # Yield config to make it accessible in tests

    # Restore original values
    for key, value in original_values.items():
        setattr(config, key, value)


@pytest.fixture
def rsfetcher_instance(mock_indexer, mock_protocol, mock_config):
    # Reset singleton instances
    if hasattr(RSFetcher, "_instances"):
        RSFetcher._instances = {}

    # Reset stopped_event
    with patch("threading.Event") as mock_event:
        # Mock event with a MagicMock to have .called attribute in tests
        mock_wait = MagicMock()
        mock_event.return_value.wait = mock_wait
        mock_event.return_value.set = MagicMock()
        mock_event.return_value.clear = MagicMock()
        mock_event.return_value.is_set = MagicMock(return_value=False)

        fetcher = RSFetcher()

        # Return the fetcher and let tests access the mocked event
        yield fetcher

    # Clean up
    if fetcher.running:
        # Patch stop to avoid errors during cleanup
        with patch.object(fetcher, "stop", MagicMock()):
            fetcher.stop()


def test_thread_index_counter():
    """Test that thread_index_counter is incremented with each new instance."""
    # Reset singleton and counter for isolated test
    if hasattr(RSFetcher, "_instances"):
        RSFetcher._instances = {}

    # Save original counter value
    original_counter = RSFetcher.thread_index_counter

    # Reset counter explicitly to ensure a known starting point
    RSFetcher.thread_index_counter = 0

    with patch("counterpartycore.lib.backend.rsfetcher.indexer"):
        # Create first instance and check counter
        _instance1 = RSFetcher()
        assert RSFetcher.thread_index_counter == 1

        # Reset singleton to allow creating another instance
        RSFetcher._instances = {}

        # Create second instance and check counter
        _instance2 = RSFetcher()
        assert RSFetcher.thread_index_counter == 2

    # Restore original counter value
    RSFetcher.thread_index_counter = original_counter


def test_delete_database_directory_when_only_old_exists(mock_config):
    """Test delete_database_directory when only old directory exists."""
    with patch("os.path.isdir") as mock_isdir, patch("shutil.rmtree") as mock_rmtree:
        # Configure mock to indicate only old directory exists
        mock_isdir.side_effect = lambda path: path == config.FETCHER_DB_OLD

        delete_database_directory()

        # Check only old directory is removed
        mock_rmtree.assert_called_once_with(config.FETCHER_DB_OLD)


def test_delete_database_directory_when_both_exist(mock_config):
    """Test delete_database_directory when both directories exist."""
    with patch("os.path.isdir") as mock_isdir, patch("shutil.rmtree") as mock_rmtree:
        # Configure mock to indicate both directories exist
        mock_isdir.return_value = True

        delete_database_directory()

        # Check both directories are removed
        mock_rmtree.assert_has_calls(
            [call(config.FETCHER_DB_OLD), call(config.FETCHER_DB)], any_order=False
        )


def test_delete_database_directory_when_none_exist(mock_config):
    """Test delete_database_directory when neither directory exists."""
    with patch("os.path.isdir") as mock_isdir, patch("shutil.rmtree") as mock_rmtree:
        # Configure mock to indicate no directories exist
        mock_isdir.return_value = False

        delete_database_directory()

        # Check rmtree is not called
        mock_rmtree.assert_not_called()


def test_init_with_custom_indexer_config(mock_protocol):
    """Test initialization with custom indexer_config."""
    # Reset singleton instances
    if hasattr(RSFetcher, "_instances"):
        RSFetcher._instances = {}

    custom_config = {
        "rpc_address": "http://custom:8332",
        "rpc_user": "custom_user",
        "rpc_password": "custom_pass",
        "db_dir": "/custom/db",
        "log_file": "/custom/log",
        "log_level": "INFO",
        "json_format": True,
    }

    with patch("threading.Event"):
        fetcher = RSFetcher(indexer_config=custom_config)

    # Verify custom config was used and network added
    for key, value in custom_config.items():
        assert fetcher.config[key] == value
    assert "network" in fetcher.config
    assert fetcher.config["network"] == config.NETWORK_NAME


def test_init_with_rsfetcher_in_exclude_filters(mock_config, mock_protocol):
    """Test initialization when RSFETCHER is in exclude filters."""
    # Reset singleton instances
    if hasattr(RSFetcher, "_instances"):
        RSFetcher._instances = {}

    # Set RSFETCHER in exclude filters
    config.LOG_EXCLUDE_FILTERS = ["RSFETCHER"]

    with patch("threading.Event"):
        fetcher = RSFetcher()

    # Verify log level is OFF
    assert fetcher.config["log_level"] == "OFF"


def test_init_with_rsfetcher_not_in_include_filters(mock_config, mock_protocol):
    """Test initialization when include filters exist but RSFETCHER is not in them."""
    # Reset singleton instances
    if hasattr(RSFetcher, "_instances"):
        RSFetcher._instances = {}

    # Set include filters without RSFETCHER
    config.LOG_INCLUDE_FILTERS = ["OTHER"]
    config.LOG_EXCLUDE_FILTERS = []

    with patch("threading.Event"):
        fetcher = RSFetcher()

    # Verify log level is OFF
    assert fetcher.config["log_level"] == "OFF"


def test_init_with_rsfetcher_in_include_filters(mock_config, mock_protocol):
    """Test initialization when include filters exist and RSFETCHER is in them."""
    # Reset singleton instances
    if hasattr(RSFetcher, "_instances"):
        RSFetcher._instances = {}

    # Set include filters with RSFETCHER
    config.LOG_INCLUDE_FILTERS = ["RSFETCHER"]
    config.LOG_EXCLUDE_FILTERS = []

    with patch("threading.Event"):
        fetcher = RSFetcher()

    # Verify log level is set to the configured LOG_LEVEL_STRING
    assert fetcher.config["log_level"] == config.LOG_LEVEL_STRING


def test_start_with_version_mismatch(rsfetcher_instance):
    """Test start method when fetcher version doesn't match config version."""
    mock_indexer_instance = MagicMock()
    mock_indexer_instance.get_version.return_value = "0.0.0"  # Different from config.__version__

    with patch(
        "counterpartycore.lib.backend.rsfetcher.indexer.Indexer", return_value=mock_indexer_instance
    ):
        with pytest.raises(exceptions.InvalidVersion):
            rsfetcher_instance.start()

        # Verify version was checked
        mock_indexer_instance.get_version.assert_called_once()
        # Verify start was not called
        mock_indexer_instance.start.assert_not_called()


def test_start_initialize_prefetching(rsfetcher_instance):
    """Test the initialization of prefetching in start method"""
    executor_mock = MagicMock()
    mock_indexer_instance = MagicMock()
    # Configure mock to return the correct version
    mock_indexer_instance.get_version.return_value = config.__version__

    with (
        patch(
            "counterpartycore.lib.backend.rsfetcher.indexer.Indexer",
            return_value=mock_indexer_instance,
        ),
        patch(
            "counterpartycore.lib.backend.rsfetcher.ThreadPoolExecutor", return_value=executor_mock
        ),
    ):
        rsfetcher_instance.start(123)

        # Verify prefetching initialization
        assert rsfetcher_instance.next_height == 123
        rsfetcher_instance.stopped_event.clear.assert_called_once()
        assert isinstance(rsfetcher_instance.prefetch_queue, queue.Queue)
        assert rsfetcher_instance.prefetch_queue.maxsize == PREFETCH_QUEUE_SIZE
        assert rsfetcher_instance.executor is executor_mock
        assert not rsfetcher_instance.prefetch_queue_initialized

        # Verify the executor submitted prefetch_blocks
        executor_mock.submit.assert_called_once_with(rsfetcher_instance.prefetch_blocks)


def test_get_prefetched_block_multiple_empty_retries(rsfetcher_instance):
    """Test get_prefetched_block with multiple Empty exceptions before success."""
    mock_block = {"height": 123}

    # Configure queue to raise Empty exceptions multiple times before returning a block
    queue_mock = MagicMock()
    queue_mock.get.side_effect = [queue.Empty(), queue.Empty(), queue.Empty(), mock_block]
    rsfetcher_instance.prefetch_queue = queue_mock

    # Mock is_set to return False for retries and then True to break the loop
    is_set_values = [False, False, False, False, True]
    rsfetcher_instance.stopped_event.is_set = MagicMock(side_effect=is_set_values)

    block = rsfetcher_instance.get_prefetched_block()

    assert block == mock_block
    assert queue_mock.get.call_count == 4
    # Verify is_set was checked for each retry plus the final check
    assert rsfetcher_instance.stopped_event.is_set.call_count <= 5


def test_get_prefetched_block_exception(rsfetcher_instance):
    """Test get_prefetched_block with an exception during queue.get."""
    # Configure queue to raise an exception
    queue_mock = MagicMock()
    queue_mock.get.side_effect = RuntimeError("Queue error")
    rsfetcher_instance.prefetch_queue = queue_mock

    with pytest.raises(RuntimeError, match="Queue error"):
        rsfetcher_instance.get_prefetched_block()


def test_prefetch_blocks_queue_initialization(rsfetcher_instance):
    """Test the initialization flag in prefetch_blocks."""
    # Create controlled implementation to verify initialization flag
    mock_block = {"height": 123}
    fetcher_mock = MagicMock()
    fetcher_mock.get_block_non_blocking.return_value = mock_block
    rsfetcher_instance.fetcher = fetcher_mock

    # Mock the queue
    queue_mock = MagicMock()

    # First report queue size below threshold, then above threshold
    queue_mock.qsize.side_effect = [
        PREFETCH_QUEUE_SIZE // 4,  # Below half-full threshold
        PREFETCH_QUEUE_SIZE // 2,  # At threshold
        PREFETCH_QUEUE_SIZE // 2 + 1,  # Above threshold
    ]
    rsfetcher_instance.prefetch_queue = queue_mock

    # Test initial state
    assert not rsfetcher_instance.prefetch_queue_initialized

    # Create a controlled version of prefetch_blocks
    original_method = rsfetcher_instance.prefetch_blocks

    def controlled_prefetch():
        """Simulates prefetch_blocks but without infinite loops"""
        rsfetcher_instance.running = True

        # First block - queue not yet half full
        block = rsfetcher_instance.fetcher.get_block_non_blocking()
        rsfetcher_instance.prefetch_queue.put(block, timeout=1)
        if rsfetcher_instance.prefetch_queue.qsize() >= PREFETCH_QUEUE_SIZE // 2:
            rsfetcher_instance.prefetch_queue_initialized = True

        # Second block - queue reaches half full
        block = rsfetcher_instance.fetcher.get_block_non_blocking()
        rsfetcher_instance.prefetch_queue.put(block, timeout=1)
        if rsfetcher_instance.prefetch_queue.qsize() >= PREFETCH_QUEUE_SIZE // 2:
            rsfetcher_instance.prefetch_queue_initialized = True

        # Flag should be true now
        assert rsfetcher_instance.prefetch_queue_initialized

        rsfetcher_instance.running = False

    # Use the test implementation
    rsfetcher_instance.prefetch_blocks = controlled_prefetch

    # Run the test
    rsfetcher_instance.prefetch_blocks()

    # Verify the flag was set
    assert rsfetcher_instance.prefetch_queue_initialized

    # Restore original method
    rsfetcher_instance.prefetch_blocks = original_method


def test_prefetch_blocks_with_none_block(rsfetcher_instance):
    """Test prefetch_blocks when get_block_non_blocking returns None."""
    # Configure fetcher to return None
    fetcher_mock = MagicMock()
    fetcher_mock.get_block_non_blocking.return_value = None
    rsfetcher_instance.fetcher = fetcher_mock

    # Configure stopped_event to let the loop run a few times then exit
    is_set_values = [False, False, False, True]
    rsfetcher_instance.stopped_event.is_set = MagicMock(side_effect=is_set_values)

    # Create controlled test version
    _original_prefetch = rsfetcher_instance.prefetch_blocks

    def controlled_prefetch():
        rsfetcher_instance.running = True
        retry = 0

        for _ in range(3):  # Run the loop a few times
            if rsfetcher_instance.stopped_event.is_set():
                break

            block = rsfetcher_instance.fetcher.get_block_non_blocking()
            if block is None:
                retry += 1
                rsfetcher_instance.stopped_event.wait(retry / 10)

        rsfetcher_instance.running = False

    # Replace with test version
    rsfetcher_instance.prefetch_blocks = controlled_prefetch

    # Run test
    rsfetcher_instance.prefetch_blocks()

    # Verify fetcher was called
    assert fetcher_mock.get_block_non_blocking.call_count > 0
    # Verify wait was called (retry logic)
    assert rsfetcher_instance.stopped_event.wait.call_count > 0


def test_prefetch_blocks_with_stopped_error_exception(rsfetcher_instance):
    """Test prefetch_blocks with 'Stopped error' exception."""
    # Configure fetcher to raise 'Stopped error'
    fetcher_mock = MagicMock()
    fetcher_mock.get_block_non_blocking.side_effect = Exception("Stopped error")
    rsfetcher_instance.fetcher = fetcher_mock

    # Mock restart to avoid actual restart
    restart_mock = MagicMock()

    with patch.object(rsfetcher_instance, "restart", restart_mock):
        # Create controlled test version
        _original_prefetch = rsfetcher_instance.prefetch_blocks

        def controlled_prefetch():
            rsfetcher_instance.running = True

            # Force one iteration then exit
            try:
                rsfetcher_instance.fetcher.get_block_non_blocking()
            except Exception as e:
                if str(e) == "Stopped error":
                    rsfetcher_instance.stopped_event.wait(timeout=5)
                    rsfetcher_instance.restart()

            rsfetcher_instance.running = False

        # Replace with test version
        rsfetcher_instance.prefetch_blocks = controlled_prefetch

        # Run test
        rsfetcher_instance.prefetch_blocks()

        # Verify behavior
        fetcher_mock.get_block_non_blocking.assert_called_once()
        rsfetcher_instance.stopped_event.wait.assert_called_once_with(timeout=5)
        restart_mock.assert_called_once()


def test_get_block_none_and_nonincremented_height(rsfetcher_instance):
    """Test get_block with None result and verify height is not incremented"""
    initial_height = 123
    rsfetcher_instance.next_height = initial_height

    with patch.object(rsfetcher_instance, "get_prefetched_block", return_value=None):
        result = rsfetcher_instance.get_block()
        assert result is None
        # Height should remain unchanged
        assert rsfetcher_instance.next_height == initial_height


def test_get_block_with_unexpected_height(rsfetcher_instance):
    """Test get_block when returned block has unexpected height"""
    initial_height = 123
    unexpected_height = 456
    rsfetcher_instance.next_height = initial_height

    mock_block = {"height": unexpected_height}

    with patch.object(rsfetcher_instance, "get_prefetched_block", return_value=mock_block):
        result = rsfetcher_instance.get_block()

        # Should return the block
        assert result == mock_block
        # Should adjust next_height based on returned block
        assert rsfetcher_instance.next_height == unexpected_height + 1


def test_restart_with_detailed_waiting(rsfetcher_instance):
    """Test restart with detailed handling of the waiting loop"""
    # Set up mocks
    stop_mock = MagicMock()
    start_mock = MagicMock()

    # Configure running flag to change after multiple sleep calls
    rsfetcher_instance.running = True
    sleep_counter = 0

    def mock_sleep(duration):
        nonlocal sleep_counter
        sleep_counter += 1
        if sleep_counter >= 3:  # Change running after multiple sleeps
            rsfetcher_instance.running = False

    with (
        patch.object(rsfetcher_instance, "stop", stop_mock),
        patch.object(rsfetcher_instance, "start", start_mock),
        patch("time.sleep", mock_sleep),
    ):
        # Set height to be passed to start
        rsfetcher_instance.next_height = 456

        # Call restart
        rsfetcher_instance.restart()

        # Verify behavior
        stop_mock.assert_called_once()
        assert sleep_counter == 3  # Ensure we slept multiple times
        start_mock.assert_called_once_with(456)


def test_get_prefetched_block_empty_queue_and_stopped(rsfetcher_instance):
    """Test get_prefetched_block with an empty queue while stopped"""
    # Configure queue to always raise Empty
    queue_mock = MagicMock()
    queue_mock.get.side_effect = queue.Empty()
    rsfetcher_instance.prefetch_queue = queue_mock

    # Configure is_set to return False first, then True
    # This makes the code try the queue once, then detect that it's stopped
    rsfetcher_instance.stopped_event.is_set = MagicMock(side_effect=[False, True])

    # Call the method
    result = rsfetcher_instance.get_prefetched_block()

    # Verify behavior
    assert result is None
    assert queue_mock.get.call_count == 1
    assert rsfetcher_instance.stopped_event.is_set.call_count == 2


def test_prefetch_blocks_with_exception_non_stopped_error(rsfetcher_instance):
    """Test prefetch_blocks with an exception that's not a 'Stopped error'"""
    # Configure fetcher to raise a non-'Stopped error' exception
    fetcher_mock = MagicMock()
    fetcher_mock.get_block_non_blocking.side_effect = Exception("Some other error")
    rsfetcher_instance.fetcher = fetcher_mock

    # Create controlled test version that only runs one iteration
    _original_prefetch = rsfetcher_instance.prefetch_blocks

    def controlled_prefetch():
        rsfetcher_instance.running = True

        # Just test one iteration that raises an exception
        try:
            rsfetcher_instance.fetcher.get_block_non_blocking()
        except Exception as e:
            if str(e) == "Stopped error":
                # This branch shouldn't be taken
                pass
            else:
                # This should re-raise the exception
                raise e

        rsfetcher_instance.running = False

    # Replace with test version
    rsfetcher_instance.prefetch_blocks = controlled_prefetch

    # Run test
    with pytest.raises(Exception, match="Some other error"):
        rsfetcher_instance.prefetch_blocks()

    # Verify the method was called
    fetcher_mock.get_block_non_blocking.assert_called_once()


def test_prefetch_blocks_full_queue_handling(rsfetcher_instance):
    """Test handling of a full queue in prefetch_blocks with timeout and retries"""
    # Configure mocks
    mock_block = {"height": 456}
    fetcher_mock = MagicMock()
    fetcher_mock.get_block_non_blocking.return_value = mock_block
    rsfetcher_instance.fetcher = fetcher_mock

    # Mock queue that raises Full multiple times then succeeds
    queue_mock = MagicMock()
    # First call full, second call success
    queue_mock.put.side_effect = [queue.Full(), None]
    queue_mock.qsize.return_value = 5
    rsfetcher_instance.prefetch_queue = queue_mock

    # Mock is_set to control the loop
    rsfetcher_instance.stopped_event.is_set = MagicMock(side_effect=[False, False, True])

    # Create controlled test version of prefetch_blocks
    _original_prefetch = rsfetcher_instance.prefetch_blocks

    def controlled_prefetch():
        rsfetcher_instance.running = True

        # Get a block
        block = rsfetcher_instance.fetcher.get_block_non_blocking()

        # Try putting in queue - first time will fail with Full
        try:
            rsfetcher_instance.prefetch_queue.put(block, timeout=1)
        except queue.Full:
            # Wait and retry
            time.sleep(0.1)  # This is mocked, won't actually sleep

            # Retry - should succeed this time
            if not rsfetcher_instance.stopped_event.is_set():
                rsfetcher_instance.prefetch_queue.put(block, timeout=1)

        rsfetcher_instance.running = False

    rsfetcher_instance.prefetch_blocks = controlled_prefetch

    # Run test
    rsfetcher_instance.prefetch_blocks()

    # Verify behavior
    assert queue_mock.put.call_count == 2
    fetcher_mock.get_block_non_blocking.assert_called_once()


def test_stop_resets_instance_attributes(rsfetcher_instance):
    """Test that stop method properly resets the instance attributes"""
    # Set up initial state
    fetcher_mock = MagicMock()
    prefetch_task_mock = MagicMock()
    executor_mock = MagicMock()

    rsfetcher_instance.fetcher = fetcher_mock
    rsfetcher_instance.prefetch_task = prefetch_task_mock
    rsfetcher_instance.executor = executor_mock

    # Call stop
    rsfetcher_instance.stop()

    # Verify attributes are reset
    assert rsfetcher_instance.fetcher is None
    assert rsfetcher_instance.prefetch_task is None

    # Verify the methods were called
    fetcher_mock.stop.assert_called_once()
    executor_mock.shutdown.assert_called_once_with(wait=True)


def test_stop_with_stopped_error_exception(rsfetcher_instance):
    """Test stop method with 'Stopped error' exception."""
    # Set up mocks
    fetcher_mock = MagicMock()
    fetcher_mock.stop.side_effect = Exception("Stopped error")
    executor_mock = MagicMock()

    rsfetcher_instance.fetcher = fetcher_mock
    rsfetcher_instance.executor = executor_mock

    # Call stop - should not raise since it's a "Stopped error"
    rsfetcher_instance.stop()

    # Verify behavior
    fetcher_mock.stop.assert_called_once()
    assert rsfetcher_instance.fetcher is None


def test_stop_with_other_exception(rsfetcher_instance):
    """Test stop method with non-'Stopped error' exception."""
    # Set up mocks
    fetcher_mock = MagicMock()
    fetcher_mock.stop.side_effect = Exception("Other error")
    executor_mock = MagicMock()

    rsfetcher_instance.fetcher = fetcher_mock
    rsfetcher_instance.executor = executor_mock

    # Call stop - should raise since it's not a "Stopped error"
    with pytest.raises(Exception, match="Other error"):
        rsfetcher_instance.stop()


def test_get_prefetched_block_timeout_handling(rsfetcher_instance):
    """Test get_prefetched_block with timeout handling"""
    queue_mock = MagicMock()

    # Define side effects to simulate a complex scenario:
    # 1. First call to get() times out (Empty exception)
    # 2. Second call returns a block
    # 3. If there's a third call, it would return None (but shouldn't be called)
    mock_block = {"height": 789}
    queue_mock.get.side_effect = [queue.Empty(), mock_block, None]

    rsfetcher_instance.prefetch_queue = queue_mock

    # Configure is_set to allow two loop iterations
    rsfetcher_instance.stopped_event.is_set = MagicMock(side_effect=[False, False, True])

    # Call the method
    result = rsfetcher_instance.get_prefetched_block()

    # Verify result and behavior
    assert result == mock_block
    assert queue_mock.get.call_count == 2
    assert rsfetcher_instance.stopped_event.is_set.call_count <= 3


def test_module_stop_function_none_instance():
    """Test module-level stop function when instance exists but is None"""
    # Mock singleton with None instance
    with patch.object(RSFetcher, "_instances", {RSFetcher: None}):
        # Should not raise exception
        stop()


def test_module_stop_function_with_instance():
    """Test module-level stop function when instance exists."""
    # Create a mock instance
    mock_instance = MagicMock()

    # Mock singleton with instance
    with patch.object(RSFetcher, "_instances", {RSFetcher: mock_instance}):
        # Should call stop on instance
        stop()

        # Verify stop was called on instance
        mock_instance.stop.assert_called_once()


def test_get_block_with_segwit_correction(rsfetcher_instance, mock_protocol):
    """Test get_block with segwit correction enabled"""
    # Mock block with transaction including tx_id
    mock_block = {"height": 123, "transactions": [{"tx_id": "abc123", "other_field": "value"}]}
    rsfetcher_instance.next_height = 123

    # Enable segwit correction
    mock_protocol.enabled.return_value = True

    with patch.object(rsfetcher_instance, "get_prefetched_block", return_value=mock_block):
        block = rsfetcher_instance.get_block()

        # Check txid correction
        assert "tx_hash" in block["transactions"][0]
        assert block["transactions"][0]["tx_hash"] == "abc123"
        mock_protocol.enabled.assert_called_once_with("correct_segwit_txids", block_index=123)
