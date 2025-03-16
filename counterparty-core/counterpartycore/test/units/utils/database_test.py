import logging
import threading
from unittest.mock import MagicMock, patch

import apsw
import pytest
from counterpartycore.lib import config
from counterpartycore.lib.utils import database

logger = logging.getLogger(config.LOGGER_NAME)


def test_version(ledger_db, test_helpers):
    database.update_version(ledger_db)
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "config",
                "values": {
                    "name": "VERSION_STRING",
                    "value": config.VERSION_STRING,
                },
            }
        ],
    )


@pytest.fixture
def mock_environment():
    """Set up the test environment with all necessary mocks."""
    with patch("counterpartycore.lib.utils.database.get_db_connection") as mock_get_db:
        # Configure mocks
        config.DB_CONNECTION_POOL_SIZE = 3
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db

        yield {
            "get_db_connection": mock_get_db,
            "db": mock_db,
        }


def test_init(mock_environment):
    """Test proper initialization of the connection pool."""
    from counterpartycore.lib.utils import database

    pool = database.APSWConnectionPool("test.db", "test_pool")

    assert pool.db_file == "test.db"
    assert pool.name == "test_pool"
    assert pool.closed is False
    assert isinstance(pool.thread_local, threading.local)
    assert pool.lock.__class__.__name__ == "RLock"
    assert pool.all_connections == set()


def test_connection_context_manager(mock_environment):
    """Test that the connection() context manager works correctly."""
    from counterpartycore.lib.utils import database

    mock_get_db = mock_environment["get_db_connection"]
    mock_db = mock_environment["db"]

    pool = database.APSWConnectionPool("test.db", "test_pool")

    # Use a connection
    with pool.connection() as conn:
        assert conn is mock_db
        mock_get_db.assert_called_once_with("test.db", read_only=True, check_wal=False)

    # The connection should be returned to the pool
    assert hasattr(pool.thread_local, "connections")
    assert len(pool.thread_local.connections) == 1
    assert pool.all_connections == {mock_db}


def test_connection_reuse(mock_environment):
    """Test that connections are reused from the thread-local pool."""
    from counterpartycore.lib.utils import database

    mock_get_db = mock_environment["get_db_connection"]
    mock_db = mock_environment["db"]

    pool = database.APSWConnectionPool("test.db", "test_pool")

    # First connection
    with pool.connection() as conn1:
        assert conn1 is mock_db

    # Reset the mock to verify it's not called again
    mock_get_db.reset_mock()

    # Second connection (should reuse the first one)
    with pool.connection() as conn2:
        assert conn2 is mock_db
        mock_get_db.assert_not_called()  # Should not create a new connection


def test_pool_size_limit(mock_environment, caplog, test_helpers):
    """Test that the pool respects the size limit."""

    from counterpartycore.lib.utils import database

    # Mock the config directly instead of using a global variable
    config.DB_CONNECTION_POOL_SIZE = 2

    # Mock for close to verify it gets called
    mock_db = mock_environment["db"]

    pool = database.APSWConnectionPool("test.db", "test_pool")

    # Use nested with blocks to keep multiple connections active simultaneously
    with test_helpers.capture_log(caplog, "Closing connection due to pool size limit"):
        with pool.connection():
            print("Connection 1 active")
            # The first connection is active, now let's get a second one
            with pool.connection():
                print("Connections 1 and 2 active")
                # The first two connections are active, now let's get a third one
                with pool.connection():
                    print("Connections 1, 2, and 3 all active simultaneously")
                    # At this point, we have 3 active connections, but the pool can only hold 2
                    # When conn3 is released, it should be closed instead of being returned to the pool

    assert mock_db.close.called, (
        "Expected db.close() to be called at least once when exceeding pool size"
    )


def test_close_pool(mock_environment, caplog, test_helpers):
    """Test closing the pool and all its connections."""
    from counterpartycore.lib.utils import database

    mock_db = mock_environment["db"]

    pool = database.APSWConnectionPool("test.db", "test_pool")

    # Create a connection
    with pool.connection():
        pass

    # Close the pool
    with test_helpers.capture_log(caplog, "Closing all connections in pool"):
        pool.close()

    # The pool should be marked as closed
    assert pool.closed is True

    # All connections should be closed
    mock_db.close.assert_called_once()
    assert pool.all_connections == set()


def test_closed_pool_behavior(mock_environment, caplog, test_helpers):
    """Test behavior when the pool is already closed."""
    from counterpartycore.lib.utils import database

    mock_get_db = mock_environment["get_db_connection"]
    mock_db = mock_environment["db"]

    pool = database.APSWConnectionPool("test.db", "test_pool")
    pool.close()

    # Reset mocks
    mock_get_db.reset_mock()
    mock_db.reset_mock()

    # Create a connection with a closed pool
    # Note: When pool is already closed, it doesn't log "Connection pool is closed. Closing connection"
    # Instead, it creates a temporary connection and closes it without adding to the pool
    with pool.connection() as conn:
        assert conn is mock_db
        mock_get_db.assert_called_once_with("test.db", read_only=True, check_wal=False)

    # The connection should be closed immediately, not returned to the pool
    mock_db.close.assert_called_once()


def test_threading_violation_error(mock_environment, caplog, test_helpers):
    """Test handling of ThreadingViolationError when closing connections."""
    from counterpartycore.lib.utils import database

    mock_db = mock_environment["db"]

    # Configure the mock to raise an exception when close() is called
    mock_db.close.side_effect = apsw.ThreadingViolationError("Test error")

    pool = database.APSWConnectionPool("test.db", "test_pool")

    # Create a connection
    with pool.connection():
        pass

    # Close the pool, which should handle the exception
    with test_helpers.capture_log(
        caplog, "ThreadingViolationError occurred while closing connection during pool shutdown"
    ):
        pool.close()


def test_multithreading(mock_environment):
    """Test that connections are isolated by thread."""
    from counterpartycore.lib.utils import database

    # Create unique connections for each thread call
    connections = []

    def get_new_connection(*args, **kwargs):
        conn = MagicMock()
        connections.append(conn)
        return conn

    mock_environment["get_db_connection"].side_effect = get_new_connection

    pool = database.APSWConnectionPool("test.db", "test_pool")

    # Store connections used in each thread
    thread_connections = []

    def thread_func():
        with pool.connection() as conn:
            # Add the connection to the shared list
            thread_connections.append(conn)

    # Run two threads
    threads = [threading.Thread(target=thread_func) for _ in range(2)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()

    # Each thread should get its own connection
    assert len(thread_connections) == 2
    assert thread_connections[0] is not thread_connections[1]

    # The pool should know about all connections
    assert len(pool.all_connections) == 2


def test_error_handling(mock_environment):
    """Test that connections are properly returned to the pool even in case of error."""
    from counterpartycore.lib.utils import database

    mock_db = mock_environment["db"]

    pool = database.APSWConnectionPool("test.db", "test_pool")

    # Simulate an error during connection use
    try:
        with pool.connection():
            raise ValueError("Test error")
    except ValueError:
        pass

    # The connection should still be returned to the pool despite the error
    assert len(pool.thread_local.connections) == 1
    assert pool.all_connections == {mock_db}
