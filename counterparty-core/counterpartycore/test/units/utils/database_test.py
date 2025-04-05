import os
import queue
import tempfile
import threading
import time
from unittest.mock import patch

import apsw
import pytest
from counterpartycore.lib import config

# Import required modules
from counterpartycore.lib.utils.database import APSWConnectionPool, update_version


def test_version(ledger_db, test_helpers):
    update_version(ledger_db)
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
def temp_db_file():
    """Creates a temporary database file for testing."""
    fd, db_file = tempfile.mkstemp(suffix=".db")
    os.close(fd)

    # Initialize the database
    conn = apsw.Connection(db_file)
    cursor = conn.cursor()
    cursor.execute("CREATE TABLE test (id INTEGER PRIMARY KEY, value TEXT)")
    conn.close()

    yield db_file

    # Clean up
    try:
        os.unlink(db_file)
    except FileNotFoundError:
        pass  # File might have been deleted already


@pytest.fixture
def connection_pool(temp_db_file):
    """Creates a connection pool for testing."""
    pool = APSWConnectionPool(temp_db_file, "test_pool")
    yield pool
    pool.close()


def test_init(temp_db_file):
    """Tests the correct initialization of the connection pool."""
    pool = APSWConnectionPool(temp_db_file, "test_init")

    assert pool.db_file == temp_db_file
    assert pool.name == "test_init"
    assert pool.closed is False
    assert pool.connection_count == 0
    assert hasattr(pool, "thread_local")
    assert hasattr(pool, "lock")

    pool.close()


def test_basic_connection(connection_pool, temp_db_file):
    """Tests basic connection acquisition and release."""
    # Get a connection
    with connection_pool.connection() as conn:
        assert conn is not None

        # Test that we can use the connection
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        assert result == {"1": 1}

    # The connection should be in the pool
    assert hasattr(connection_pool.thread_local, "connections")
    assert len(connection_pool.thread_local.connections) == 1
    assert connection_pool.connection_count == 1


def test_connection_reuse(connection_pool):
    """Tests that connections are reused."""
    # Get a connection the first time
    with connection_pool.connection() as conn1:
        conn1_id = id(conn1)

    # Get a connection the second time
    with connection_pool.connection() as conn2:
        conn2_id = id(conn2)

    # Should be the same connection object
    assert conn1_id == conn2_id

    # The connection should be back in the pool
    assert len(connection_pool.thread_local.connections) == 1
    assert connection_pool.connection_count == 1


def test_pool_full(connection_pool, monkeypatch):
    """Tests that connections are correctly managed when many are created."""
    # It seems the pool implementation always keeps one connection, so we'll validate that

    # Create several connections
    connections_created = []
    for _ in range(3):
        with connection_pool.connection() as conn:
            connections_created.append(id(conn))

    # Verify that we have at least one connection in the pool
    assert len(connection_pool.thread_local.connections) == 1

    # Verify the connection count is correct
    assert connection_pool.connection_count == 1


def test_closed_pool(connection_pool):
    """Tests the behavior when the pool is closed."""
    connection_pool.close()

    # Should be able to get a temporary connection
    with connection_pool.connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        assert result == {"1": 1}

    # The connection should be closed, not added to the pool
    assert len(getattr(connection_pool.thread_local, "connections", [])) == 0
    # The connection count should not have changed (the temporary connection is not counted)
    assert connection_pool.connection_count == 0


def test_multithreaded_use(connection_pool):
    """Tests the connection pool in a multi-threaded environment."""
    results = queue.Queue()

    def worker():
        try:
            # Get a connection in a separate thread
            with connection_pool.connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                assert result == {"1": 1}

                # Sleep a bit to simulate work
                time.sleep(0.01)

                # Return success
                results.put(True)
        except Exception as e:
            results.put(f"Error: {str(e)}")

    # Create and start multiple threads
    threads = []
    num_threads = 5
    for _ in range(num_threads):
        t = threading.Thread(target=worker)
        threads.append(t)
        t.start()

    # Wait for all threads to finish
    for t in threads:
        t.join()

    # Verify that all threads succeeded
    failures = []
    while not results.empty():
        result = results.get()
        if result is not True:
            failures.append(result)

    assert not failures, f"Thread failures: {failures}"

    # The total number of connections should be greater than 0
    # We can't predict the exact number because of thread timing
    assert connection_pool.connection_count > 0


def test_close_with_active_connections(connection_pool):
    """Tests closing the pool while connections are active."""
    # Get a connection
    with connection_pool.connection() as conn:
        # Close the pool while the connection is still in use
        connection_pool.close()

        # The connection should still be usable
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        assert result == {"1": 1}

    # The connection should have been closed, not returned to the pool
    assert len(getattr(connection_pool.thread_local, "connections", [])) == 0
    # The connection count should be 0 as it is decremented after use
    assert connection_pool.connection_count == 0


def test_connection_exception(connection_pool):
    """Tests that exceptions in the with block are propagated."""
    expected_error = ValueError("Test exception")

    try:
        with connection_pool.connection():
            raise expected_error
    except ValueError as e:
        assert str(e) == str(expected_error)

    # The connection should still be in the pool
    assert len(connection_pool.thread_local.connections) == 1
    assert connection_pool.connection_count == 1


def test_concurrent_close(connection_pool):
    """Tests closing the pool while multiple threads are using it."""
    event = threading.Event()
    connections_made = []

    def worker():
        # Wait for the signal before getting a connection
        event.wait()

        try:
            # Get a connection
            with connection_pool.connection() as conn:
                # Record that we got a connection
                connections_made.append(1)
                # Sleep to give time for the pool to be closed
                time.sleep(0.05)

                # Try to use the connection
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                assert result == {"1": 1}
        except Exception:
            # If we get an exception, it should be after the pool is closed
            assert connection_pool.closed

    # Start the threads
    threads = []
    for _ in range(5):
        t = threading.Thread(target=worker)
        t.daemon = True
        threads.append(t)
        t.start()

    # Signal threads to start getting connections
    event.set()

    # Give them a moment to get connections
    time.sleep(0.01)

    # Close the pool
    connection_pool.close()

    # Wait for all threads to finish
    for t in threads:
        t.join()

    # All threads should have been able to get a connection
    assert len(connections_made) == 5

    # All connections should be closed
    assert len(getattr(connection_pool.thread_local, "connections", [])) == 0


# Handle connection validation errors with a different approach
def test_threading_violation_error(connection_pool):
    """Tests handling of ThreadingViolationError by injecting a faulty connection."""
    # First, create a connection to populate the pool
    with connection_pool.connection() as conn:
        pass

    # Now we have a connection in the pool - retrieve it
    original_connection = connection_pool.thread_local.connections[0]

    # Create a wrapper for the original connection that will fail validation
    class ValidationFailingConnection:
        def __init__(self, real_conn):
            self.real_conn = real_conn
            self.validation_tried = False

        def execute(self, query, *args, **kwargs):
            # Fail only on the validation query and only once
            if query == "SELECT 1" and not self.validation_tried:
                self.validation_tried = True
                raise apsw.ThreadingViolationError("Simulated threading error")
            return self.real_conn.execute(query, *args, **kwargs)

        def __getattr__(self, name):
            return getattr(self.real_conn, name)

    # Replace the real connection with our failing connection
    connection_pool.thread_local.connections[0] = ValidationFailingConnection(original_connection)

    # Get a connection from the pool - should trigger validation failure
    with connection_pool.connection() as conn:
        # Verify we can use the new connection
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        assert result == {"1": 1}

    # The connection count should have increased because a new connection
    # should have been created when validation failed
    assert connection_pool.connection_count > 1


def test_busy_error(connection_pool):
    """Tests handling of BusyError by injecting a faulty connection."""
    # First, create a connection to populate the pool
    with connection_pool.connection() as conn:
        pass

    # Now we have a connection in the pool - retrieve it
    original_connection = connection_pool.thread_local.connections[0]

    # Create a wrapper for the original connection that will fail validation
    class ValidationFailingConnection:
        def __init__(self, real_conn):
            self.real_conn = real_conn
            self.validation_tried = False

        def execute(self, query, *args, **kwargs):
            # Fail only on the validation query and only once
            if query == "SELECT 1" and not self.validation_tried:
                self.validation_tried = True
                raise apsw.BusyError("Simulated busy error")
            return self.real_conn.execute(query, *args, **kwargs)

        def __getattr__(self, name):
            return getattr(self.real_conn, name)

    # Replace the real connection with our failing connection
    connection_pool.thread_local.connections[0] = ValidationFailingConnection(original_connection)

    # Get a connection from the pool - should trigger validation failure
    with connection_pool.connection() as conn:
        # Verify we can use the new connection
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        assert result == {"1": 1}

    # The connection count should have increased because a new connection
    # should have been created when validation failed
    assert connection_pool.connection_count > 1


def test_connection_count_increment(connection_pool):
    """Tests that the connection count is incremented when creating connections."""
    # The initial count should be 0
    assert connection_pool.connection_count == 0

    # Create a connection
    with connection_pool.connection():
        # Just get a connection
        pass

    # The count should be 1
    assert connection_pool.connection_count == 1


def test_explicit_connection_close(connection_pool):
    """Tests what happens when a connection is explicitly closed."""
    # Since we can't patch the close method directly, we'll test the behavior indirectly

    # Get a connection
    with connection_pool.connection() as conn:
        # Call close() which will trigger close in the __exit__ of the connection context
        conn.close()

        # Validate that attempting to use the connection would raise an exception
        with pytest.raises(Exception):  # noqa
            cursor = conn.cursor()
            cursor.execute("SELECT 1")

    # Connection count should still be 1 since the pool will handle closed connections
    # by automatically creating a new one when needed
    assert connection_pool.connection_count == 1


def test_pool_close(connection_pool):
    """Tests the close() method of the connection pool."""
    # Create a connection
    with connection_pool.connection():
        pass

    # Verify that there is a connection in the pool
    assert len(connection_pool.thread_local.connections) == 1

    # Close the pool
    connection_pool.close()

    # Verify that the pool is marked as closed
    assert connection_pool.closed

    # Verify that the connections list is empty
    assert len(connection_pool.thread_local.connections) == 0


def test_close_with_threading_violation(connection_pool):
    """Tests closing the pool when threading issues occur."""
    # Since we can't patch apsw.Connection.close, we'll test this indirectly
    # by patching the logger and monitoring for the expected messages

    # Create a connection in the pool
    with connection_pool.connection():
        pass

    # Create a function to simulate ThreadingViolationError during pool.close
    trace_called = [False]

    def mock_trace(*args, **kwargs):
        if "ThreadingViolationError" in args[0]:
            trace_called[0] = True

    # Use helper class to simulate exception during close
    class ConnectionCloseRaiser:
        def __init__(self, real_conn):
            self.real_conn = real_conn

        def close(self):
            # Simulate ThreadingViolationError
            raise apsw.ThreadingViolationError(
                "ThreadingViolationError occurred while closing connection."
            )

        def __getattr__(self, name):
            return getattr(self.real_conn, name)

    # Replace connections with our wrapper
    original_connections = connection_pool.thread_local.connections.copy()
    wrapped_connections = [ConnectionCloseRaiser(conn) for conn in original_connections]
    connection_pool.thread_local.connections = wrapped_connections

    # Patch logger.trace
    with patch("counterpartycore.lib.utils.database.logger.trace", mock_trace):
        # Close the pool
        connection_pool.close()

        # Verify that trace was called with the expected message
        assert trace_called[0], "ThreadingViolationError was not logged"


def test_multithreaded_init(temp_db_file):
    """Tests pool initialization in multiple threads."""
    pool = APSWConnectionPool(temp_db_file, "test_mt_init")
    results = queue.Queue()

    def worker():
        try:
            # Verify that thread_local.connections does not yet exist
            assert not hasattr(pool.thread_local, "connections")

            # Get a connection that will initialize thread_local.connections
            with pool.connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                assert result == {"1": 1}

            # Verify that thread_local.connections is initialized
            assert hasattr(pool.thread_local, "connections")
            assert len(pool.thread_local.connections) == 1

            results.put(True)
        except Exception as e:
            results.put(f"Error: {str(e)}")

    # Create and start multiple threads
    threads = []
    for _ in range(3):
        t = threading.Thread(target=worker)
        threads.append(t)
        t.start()

    # Wait for all threads to finish
    for t in threads:
        t.join()

    # Verify that all threads succeeded
    failures = []
    while not results.empty():
        result = results.get()
        if result is not True:
            failures.append(result)

    assert not failures, f"Thread failures: {failures}"

    # Clean up
    pool.close()


def test_logger_trace_output(connection_pool):
    """Tests that logger trace messages are correctly emitted."""
    # Mock the logger.trace
    with patch("counterpartycore.lib.utils.database.logger.trace") as mock_trace:
        # Close the pool to trigger the trace message
        connection_pool.close()

        # Verify that the trace message was called
        mock_trace.assert_called()

        # At least one call should have "Closing all connections" in the arguments
        found_message = False
        for call in mock_trace.call_args_list:
            args = call[0]
            if args and isinstance(args[0], str) and "Closing all connections in pool" in args[0]:
                found_message = True
                break

        assert found_message, "Expected log message not found"


def test_edge_case_config_pool_size_zero(monkeypatch):
    """Tests behavior when DB_CONNECTION_POOL_SIZE is 0."""
    # Set the pool size to 0
    monkeypatch.setattr(config, "DB_CONNECTION_POOL_SIZE", 0)

    # Create a temporary file for the database
    fd, db_file = tempfile.mkstemp(suffix=".db")
    os.close(fd)

    try:
        # Initialize the database
        conn = apsw.Connection(db_file)
        cursor = conn.cursor()
        cursor.execute("CREATE TABLE test (id INTEGER PRIMARY KEY, value TEXT)")
        conn.close()

        # Create the pool
        pool = APSWConnectionPool(db_file, "test_zero_pool")

        # Get multiple connections
        for _ in range(3):
            with pool.connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                assert result == {"1": 1}

        # All connections should be closed after use
        # because the pool size is 0
        assert len(getattr(pool.thread_local, "connections", [])) == 0

        # Clean up
        pool.close()
    finally:
        # Clean up
        try:
            os.unlink(db_file)
        except FileNotFoundError:
            pass  # File might have been deleted already
