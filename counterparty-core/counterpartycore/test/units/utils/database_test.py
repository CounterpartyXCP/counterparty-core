import gc
import os
import queue
import tempfile
import threading
import time
from unittest.mock import MagicMock, patch

import apsw
import psutil
import pytest
from counterpartycore.lib import config, exceptions

# Import required modules
from counterpartycore.lib.utils import database
from counterpartycore.lib.utils.database import (
    APSWConnectionPool,
    DatabaseIntegrityError,
    apply_outstanding_migration,
    check_foreign_keys,
    check_wal_file,
    get_config_value,
    get_connection,
    get_db_connection,
    get_file_openers,
    initialise_db,
    intergrity_check,
    optimize,
    rollback_all_migrations,
    rowtracer,
    set_config_value,
    update_version,
    vacuum,
)
from counterpartycore.lib.utils.helpers import SingletonMeta
from yoyo.exceptions import LockTimeout


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
    assert hasattr(connection_pool.thread_local, "state")
    assert len(connection_pool.thread_local.state.connections) == 1
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
    assert len(connection_pool.thread_local.state.connections) == 1
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
    assert len(connection_pool.thread_local.state.connections) == 1

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
    assert len(connection_pool.thread_local.state.connections) == 0
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

    # After all threads exit, _ThreadLocalConnections.__del__ releases their
    # cached connections, so the pool count returns to 0 (no leak).
    assert connection_pool.connection_count == 0


def test_thread_exit_releases_connections(connection_pool):
    """Regression test: connection_count must return to 0 when short-lived threads exit.

    This guards against the v1 API leak where Werkzeug's threaded=True spawns a
    new thread per request and each thread left its cached connections counted
    permanently in connection_count.
    """

    def use_pool():
        with connection_pool.connection():
            pass  # acquire then release to thread-local cache

    num_threads = 10
    threads = []
    for _ in range(num_threads):
        t = threading.Thread(target=use_pool)
        threads.append(t)
        t.start()

    for t in threads:
        t.join()

    # Force GC so __del__ fires on any lingering _ThreadLocalConnections objects
    gc.collect()

    assert connection_pool.connection_count == 0, (
        f"connection_count leaked to {connection_pool.connection_count} after threads exited"
    )


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
    assert len(connection_pool.thread_local.state.connections) == 0
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
    assert len(connection_pool.thread_local.state.connections) == 1
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
    state = getattr(connection_pool.thread_local, "state", None)
    assert state is None or len(state.connections) == 0


# Handle connection validation errors with a different approach
def test_threading_violation_error(connection_pool):
    """Tests handling of ThreadingViolationError by injecting a faulty connection."""
    # First, create a connection to populate the pool
    with connection_pool.connection() as conn:
        pass

    # Now we have a connection in the pool - retrieve it
    original_connection = connection_pool.thread_local.state.connections[0]

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
    connection_pool.thread_local.state.connections[0] = ValidationFailingConnection(
        original_connection
    )

    # Get a connection from the pool - should trigger validation failure
    with connection_pool.connection() as conn:
        # Verify we can use the new connection
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        assert result == {"1": 1}

    # The bad connection slot is released and a new one created: net count stays at 1
    assert connection_pool.connection_count == 1


def test_busy_error(connection_pool):
    """Tests handling of BusyError by injecting a faulty connection."""
    # First, create a connection to populate the pool
    with connection_pool.connection() as conn:
        pass

    # Now we have a connection in the pool - retrieve it
    original_connection = connection_pool.thread_local.state.connections[0]

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
    connection_pool.thread_local.state.connections[0] = ValidationFailingConnection(
        original_connection
    )

    # Get a connection from the pool - should trigger validation failure
    with connection_pool.connection() as conn:
        # Verify we can use the new connection
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        assert result == {"1": 1}

    # The bad connection slot is released and a new one created: net count stays at 1
    assert connection_pool.connection_count == 1


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
    assert len(connection_pool.thread_local.state.connections) == 1

    # Close the pool
    connection_pool.close()

    # Verify that the pool is marked as closed
    assert connection_pool.closed

    # Verify that the connections list is empty
    assert len(connection_pool.thread_local.state.connections) == 0


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
    original_connections = connection_pool.thread_local.state.connections.copy()
    wrapped_connections = [ConnectionCloseRaiser(conn) for conn in original_connections]
    connection_pool.thread_local.state.connections = wrapped_connections

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
            # Verify that thread_local.state does not yet exist
            assert not hasattr(pool.thread_local, "state")

            # Get a connection that will initialize thread_local.state
            with pool.connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                assert result == {"1": 1}

            # Verify that thread_local.state is initialized
            assert hasattr(pool.thread_local, "state")
            assert len(pool.thread_local.state.connections) == 1

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
        assert len(pool.thread_local.state.connections) == 0

        # Clean up
        pool.close()
    finally:
        # Clean up
        try:
            os.unlink(db_file)
        except FileNotFoundError:
            pass  # File might have been deleted already


# =============================================================================
# Tests for rowtracer function
# =============================================================================


def test_rowtracer_basic():
    """Tests the rowtracer function converts rows to dicts correctly."""
    # Create a mock cursor with getdescription method
    mock_cursor = MagicMock()
    mock_cursor.getdescription.return_value = [
        ("id", "INTEGER"),
        ("name", "TEXT"),
        ("active", "BOOL"),
    ]

    sql_row = (1, "test", 1)
    result = rowtracer(mock_cursor, sql_row)

    assert result == {"id": 1, "name": "test", "active": True}


def test_rowtracer_bool_false():
    """Tests the rowtracer function handles BOOL false values."""
    mock_cursor = MagicMock()
    mock_cursor.getdescription.return_value = [("active", "BOOL")]

    sql_row = (0,)
    result = rowtracer(mock_cursor, sql_row)

    assert result == {"active": False}


def test_rowtracer_null_values():
    """Tests the rowtracer function handles NULL values."""
    mock_cursor = MagicMock()
    mock_cursor.getdescription.return_value = [("value", "TEXT")]

    sql_row = (None,)
    result = rowtracer(mock_cursor, sql_row)

    assert result == {"value": None}


# =============================================================================
# Tests for get_file_openers function (lines 32-46)
# =============================================================================


def test_get_file_openers_no_match(temp_db_file):
    """Tests get_file_openers when no process has the file open."""
    result = get_file_openers("/nonexistent/path/to/file.db")
    assert result == []


def test_get_file_openers_with_open_file(temp_db_file):
    """Tests get_file_openers when a process has the file open."""
    # Open the file and check that our process is in the list
    with open(temp_db_file, "r"):
        pids = get_file_openers(temp_db_file)
        # Our current process should have the file open
        assert os.getpid() in pids


def test_get_file_openers_handles_exceptions():
    """Tests get_file_openers handles psutil exceptions gracefully."""
    with patch("counterpartycore.lib.utils.database.psutil.process_iter") as mock_iter:
        # Create a mock process that raises NoSuchProcess
        mock_proc = MagicMock()
        mock_proc.open_files.side_effect = psutil.NoSuchProcess(pid=1234)
        mock_iter.return_value = [mock_proc]

        # Should not raise, should return empty list
        result = get_file_openers("/some/file.db")
        assert result == []


def test_get_file_openers_handles_access_denied():
    """Tests get_file_openers handles psutil AccessDenied exception."""
    with patch("counterpartycore.lib.utils.database.psutil.process_iter") as mock_iter:
        # Create a mock process that raises AccessDenied
        mock_proc = MagicMock()
        mock_proc.open_files.side_effect = psutil.AccessDenied(pid=1234)
        mock_iter.return_value = [mock_proc]

        # Should not raise, should return empty list
        result = get_file_openers("/some/file.db")
        assert result == []


# =============================================================================
# Tests for check_wal_file function (lines 50-55)
# =============================================================================


def test_check_wal_file_no_wal(temp_db_file):
    """Tests check_wal_file when no WAL file exists."""
    # Should not raise any exception
    check_wal_file(temp_db_file)


def test_check_wal_file_with_wal_no_opener(temp_db_file):
    """Tests check_wal_file when WAL file exists but no process has it open."""
    wal_file = f"{temp_db_file}-wal"
    # Create a WAL file
    with open(wal_file, "w") as f:
        f.write("test")

    try:
        with pytest.raises(exceptions.WALFileFoundError) as exc_info:
            check_wal_file(temp_db_file)
        assert "Found WAL file" in str(exc_info.value)
    finally:
        os.unlink(wal_file)


def test_check_wal_file_with_wal_and_opener(temp_db_file):
    """Tests check_wal_file when WAL file exists and a process has it open."""
    wal_file = f"{temp_db_file}-wal"

    # Create and keep the WAL file open
    with open(wal_file, "w") as f:
        f.write("test")
        f.flush()

        # Mock get_file_openers to return a PID
        with patch(
            "counterpartycore.lib.utils.database.get_file_openers", return_value=[os.getpid()]
        ):
            with pytest.raises(exceptions.DatabaseError) as exc_info:
                check_wal_file(temp_db_file)
            assert "already opened by a process" in str(exc_info.value)

    os.unlink(wal_file)


# =============================================================================
# Tests for get_db_connection function (lines 71-74)
# =============================================================================


def test_get_db_connection_read_only(temp_db_file):
    """Tests get_db_connection in read-only mode."""
    db = get_db_connection(temp_db_file, read_only=True, check_wal=False)
    assert db is not None

    # Should not be able to write
    cursor = db.cursor()
    with pytest.raises(apsw.ReadOnlyError):
        cursor.execute("INSERT INTO test (value) VALUES ('test')")

    db.close()


def test_get_db_connection_write_mode(temp_db_file):
    """Tests get_db_connection in write mode."""
    db = get_db_connection(temp_db_file, read_only=False, check_wal=False)
    assert db is not None

    # Should be able to write
    cursor = db.cursor()
    cursor.execute("INSERT INTO test (value) VALUES ('test')")

    db.close()


def test_get_db_connection_with_wal_check_warning(temp_db_file):
    """Tests get_db_connection logs warning when WAL file exists (lines 71-74)."""
    wal_file = f"{temp_db_file}-wal"

    # Create a WAL file
    with open(wal_file, "w") as f:
        f.write("test")

    try:
        with patch("counterpartycore.lib.utils.database.logger.warning") as mock_warning:
            # Should not raise, but should log warning
            db = get_db_connection(temp_db_file, read_only=False, check_wal=True)
            db.close()

            # Verify warning was logged
            mock_warning.assert_called_once()
            assert "WAL file detected" in mock_warning.call_args[0][0]
    finally:
        if os.path.exists(wal_file):
            os.unlink(wal_file)


def test_get_db_connection_with_known_db_names():
    """Tests get_db_connection with known database names for logging."""
    fd, db_file = tempfile.mkstemp(suffix=".db")
    os.close(fd)

    # Initialize the database
    conn = apsw.Connection(db_file)
    conn.close()

    try:
        # Test with DATABASE config
        with patch.object(config, "DATABASE", db_file):
            with patch("counterpartycore.lib.utils.database.logger") as mock_logger:
                mock_logger.trace = MagicMock()
                db = get_db_connection(db_file, read_only=True, check_wal=False)
                db.close()

        # Test with STATE_DATABASE config
        with patch.object(config, "STATE_DATABASE", db_file):
            with patch("counterpartycore.lib.utils.database.logger") as mock_logger:
                mock_logger.trace = MagicMock()
                db = get_db_connection(db_file, read_only=True, check_wal=False)
                db.close()
    finally:
        os.unlink(db_file)


# =============================================================================
# Tests for get_connection function (line 100)
# =============================================================================


def test_get_connection(temp_db_file, monkeypatch):
    """Tests get_connection function uses config.DATABASE."""
    monkeypatch.setattr(config, "DATABASE", temp_db_file)

    db = get_connection(read_only=True, check_wal=False)
    assert db is not None

    cursor = db.cursor()
    cursor.execute("SELECT 1")
    result = cursor.fetchone()
    assert result == {"1": 1}

    db.close()


# =============================================================================
# Tests for connection pool contention (lines 128-150, 156-157)
# =============================================================================


def test_connection_pool_max_connections_wait(temp_db_file, monkeypatch):
    """Tests connection pool waits when at max connections."""
    # Set a very low max connections
    monkeypatch.setattr(config, "DB_MAX_CONNECTIONS", 2)
    monkeypatch.setattr(config, "DB_CONNECTION_POOL_SIZE", 1)

    pool = APSWConnectionPool(temp_db_file, "test_max_wait")

    results = queue.Queue()

    def worker1():
        """First worker holds a connection."""
        with pool.connection():
            time.sleep(0.2)  # Hold the connection briefly
            results.put("worker1_done")

    def worker2():
        """Second worker gets connection (within limit)."""
        time.sleep(0.05)  # Small delay
        with pool.connection():
            results.put("worker2_got_connection")

    t1 = threading.Thread(target=worker1)
    t2 = threading.Thread(target=worker2)

    t1.start()
    t2.start()

    t1.join(timeout=5)
    t2.join(timeout=5)

    # Both workers should have completed
    results_list = []
    while not results.empty():
        results_list.append(results.get())

    assert "worker1_done" in results_list
    assert "worker2_got_connection" in results_list

    pool.close()


def test_connection_pool_timeout(temp_db_file, monkeypatch):
    """Tests connection pool raises timeout when waiting too long."""
    # Set a very low max connections
    monkeypatch.setattr(config, "DB_MAX_CONNECTIONS", 1)
    monkeypatch.setattr(config, "DB_CONNECTION_POOL_SIZE", 1)

    pool = APSWConnectionPool(temp_db_file, "test_timeout")

    # Artificially set connection count to max without actually creating connections
    pool.connection_count = 1

    # Mock wait to always return False (timeout)
    original_wait = pool.connection_available.wait

    def mock_wait(timeout=None):
        return False  # Simulate timeout

    pool.connection_available.wait = mock_wait

    try:
        with pytest.raises(exceptions.DatabaseError) as exc_info:
            with pool.connection():
                pass
        assert "Timeout waiting for database connection" in str(exc_info.value)
    finally:
        pool.connection_available.wait = original_wait
        pool.connection_count = 0
        pool.close()


def test_connection_pool_closed_while_waiting(temp_db_file, monkeypatch):
    """Tests connection pool raises error when closed while waiting."""
    monkeypatch.setattr(config, "DB_MAX_CONNECTIONS", 1)
    monkeypatch.setattr(config, "DB_CONNECTION_POOL_SIZE", 1)

    pool = APSWConnectionPool(temp_db_file, "test_closed_waiting")

    # Artificially set connection count to max
    pool.connection_count = 1

    # Mock wait to simulate pool being closed during wait
    def mock_wait(timeout=None):
        pool.closed = True
        return True  # Return True but pool is now closed

    pool.connection_available.wait = mock_wait

    try:
        with pytest.raises(exceptions.DatabaseError) as exc_info:
            with pool.connection():
                pass
        assert "closed while waiting" in str(exc_info.value)
    finally:
        pool.connection_count = 0


def test_connection_pool_contention_logging(temp_db_file, monkeypatch):
    """Tests that contention warning is logged when at max connections."""
    monkeypatch.setattr(config, "DB_MAX_CONNECTIONS", 1)
    monkeypatch.setattr(config, "DB_CONNECTION_POOL_SIZE", 1)

    pool = APSWConnectionPool(temp_db_file, "test_contention_log")
    warning_logged = []

    def mock_warning(msg, *args, **kwargs):
        warning_logged.append(msg % args if args else msg)

    # Artificially set connection count to max
    pool.connection_count = 1

    # Track if wait was called
    wait_called = []

    def mock_wait(timeout=None):
        wait_called.append(True)
        # Reset connection count to allow connection
        pool.connection_count = 0
        return True

    pool.connection_available.wait = mock_wait

    with patch("counterpartycore.lib.utils.database.logger.warning", mock_warning):
        with pool.connection():
            pass

    # The contention warning should have been logged
    assert any("CONTENTION" in msg for msg in warning_logged)
    assert wait_called

    pool.close()


# =============================================================================
# Tests for get_stats method (lines 246-252)
# =============================================================================


def test_get_stats_basic(connection_pool):
    """Tests get_stats returns correct statistics."""
    stats = connection_pool.get_stats()

    assert "current" in stats
    assert "max" in stats
    assert "peak" in stats
    assert "utilization" in stats

    assert stats["current"] == 0
    assert stats["max"] == connection_pool.max_connections
    assert stats["peak"] == 0
    assert stats["utilization"] == 0


def test_get_stats_with_connections(connection_pool):
    """Tests get_stats updates with connections."""
    # Create a connection
    with connection_pool.connection():
        pass

    stats = connection_pool.get_stats()

    assert stats["current"] == 1
    assert stats["peak"] == 1
    # Utilization should be calculated correctly
    expected_utilization = 1 / connection_pool.max_connections * 100
    assert stats["utilization"] == expected_utilization


def test_get_stats_unlimited_connections(temp_db_file):
    """Tests get_stats with unlimited connections (max=0)."""
    pool = APSWConnectionPool(temp_db_file, "test_stats_unlimited")
    pool.max_connections = 0  # Unlimited

    stats = pool.get_stats()

    assert stats["utilization"] == 0  # Should be 0 when max is 0

    pool.close()


# =============================================================================
# Tests for initialise_db function (lines 271-278)
# =============================================================================


def test_initialise_db(temp_db_file, monkeypatch):
    """Tests initialise_db function."""
    monkeypatch.setattr(config, "DATABASE", temp_db_file)
    monkeypatch.setattr(config, "FORCE", False)

    db = initialise_db()
    assert db is not None

    # Should be able to write to the database
    cursor = db.cursor()
    cursor.execute("INSERT INTO test (value) VALUES ('test')")

    db.close()


def test_initialise_db_with_force(temp_db_file, monkeypatch, capsys):
    """Tests initialise_db function with FORCE=True (lines 271-272)."""
    monkeypatch.setattr(config, "DATABASE", temp_db_file)
    monkeypatch.setattr(config, "FORCE", True)

    db = initialise_db()
    assert db is not None

    # Check that the warning was printed (message contains --force)
    captured = capsys.readouterr()
    assert "--force" in captured.out or "force" in captured.out.lower()

    db.close()


# =============================================================================
# Tests for check_foreign_keys function (lines 286-297)
# =============================================================================


def test_check_foreign_keys_success(temp_db_file):
    """Tests check_foreign_keys with no foreign key violations."""
    # Create a database with foreign keys
    conn = apsw.Connection(temp_db_file)
    cursor = conn.cursor()
    cursor.execute("DROP TABLE IF EXISTS test")
    cursor.execute("CREATE TABLE parent (id INTEGER PRIMARY KEY)")
    cursor.execute(
        "CREATE TABLE child (id INTEGER PRIMARY KEY, parent_id INTEGER REFERENCES parent(id))"
    )
    cursor.execute("INSERT INTO parent (id) VALUES (1)")
    cursor.execute("INSERT INTO child (id, parent_id) VALUES (1, 1)")

    # Should not raise
    check_foreign_keys(conn)

    conn.close()


def test_check_foreign_keys_failure(temp_db_file):
    """Tests check_foreign_keys with foreign key violations."""
    conn = apsw.Connection(temp_db_file)
    cursor = conn.cursor()

    # Temporarily disable foreign keys to create violation
    cursor.execute("PRAGMA foreign_keys = OFF")
    cursor.execute("DROP TABLE IF EXISTS test")
    cursor.execute("DROP TABLE IF EXISTS child")
    cursor.execute("DROP TABLE IF EXISTS parent")
    cursor.execute("CREATE TABLE parent (id INTEGER PRIMARY KEY)")
    cursor.execute(
        "CREATE TABLE child (id INTEGER PRIMARY KEY, parent_id INTEGER REFERENCES parent(id))"
    )
    # Insert child without parent (violation)
    cursor.execute("INSERT INTO child (id, parent_id) VALUES (1, 999)")

    with pytest.raises(exceptions.DatabaseError) as exc_info:
        check_foreign_keys(conn)
    assert "Foreign key check failed" in str(exc_info.value)

    conn.close()


# =============================================================================
# Tests for intergrity_check function (lines 301-312)
# =============================================================================


def test_intergrity_check_success(temp_db_file):
    """Tests intergrity_check with healthy database."""
    conn = apsw.Connection(temp_db_file)
    conn.setrowtrace(rowtracer)

    # Should not raise
    intergrity_check(conn)

    conn.close()


def test_intergrity_check_failure():
    """Tests intergrity_check with corrupted database."""
    # Create a mock connection that returns integrity errors
    mock_conn = MagicMock()
    mock_cursor = MagicMock()
    mock_conn.cursor.return_value = mock_cursor
    mock_cursor.fetchall.return_value = [
        {"integrity_check": "row 1 missing"},
        {"integrity_check": "row 2 missing"},
    ]

    with pytest.raises(exceptions.DatabaseError) as exc_info:
        intergrity_check(mock_conn)
    assert "Integrity check failed" in str(exc_info.value)


# =============================================================================
# Tests for set_config_value and get_config_value functions
# =============================================================================


def test_set_and_get_config_value(ledger_db):
    """Tests set_config_value and get_config_value functions."""
    set_config_value(ledger_db, "TEST_KEY", "test_value")
    result = get_config_value(ledger_db, "TEST_KEY")
    assert result == "test_value"


def test_get_config_value_not_found(ledger_db):
    """Tests get_config_value returns None for non-existent key."""
    result = get_config_value(ledger_db, "NONEXISTENT_KEY")
    assert result is None


# =============================================================================
# Tests for vacuum function (lines 335-338)
# =============================================================================


def test_vacuum(temp_db_file):
    """Tests vacuum function."""
    conn = apsw.Connection(temp_db_file)
    cursor = conn.cursor()

    # Add and delete some data to create fragmentation
    cursor.execute("INSERT INTO test (value) VALUES ('test1')")
    cursor.execute("INSERT INTO test (value) VALUES ('test2')")
    cursor.execute("DELETE FROM test")

    # Should not raise
    vacuum(conn)

    conn.close()


# =============================================================================
# Tests for optimize function (lines 342-345)
# =============================================================================


def test_optimize(temp_db_file):
    """Tests optimize function."""
    conn = apsw.Connection(temp_db_file)

    # Should not raise
    optimize(conn)

    conn.close()


# =============================================================================
# Tests for close function (lines 349-351)
# =============================================================================


def test_close_function(temp_db_file, monkeypatch):
    """Tests the close function properly closes connections."""
    monkeypatch.setattr(config, "DATABASE", temp_db_file)

    # Reset the singleton for LedgerDBConnectionPool
    if database.LedgerDBConnectionPool in SingletonMeta._instances:
        del SingletonMeta._instances[database.LedgerDBConnectionPool]

    # Create a connection pool
    pool = database.LedgerDBConnectionPool()

    # Create a write connection
    db = apsw.Connection(temp_db_file)

    with patch("counterpartycore.lib.utils.database.LedgerDBConnectionPool", return_value=pool):
        database.close(db)

    # Pool should be closed
    assert pool.closed

    # Clean up singleton
    if database.LedgerDBConnectionPool in SingletonMeta._instances:
        del SingletonMeta._instances[database.LedgerDBConnectionPool]


# =============================================================================
# Tests for apply_outstanding_migration function (lines 362-365)
# =============================================================================


def test_apply_outstanding_migration_success(temp_db_file):
    """Tests apply_outstanding_migration with no migrations."""
    # Create a temporary migration directory
    migration_dir = tempfile.mkdtemp()

    try:
        # Should not raise (no migrations to apply)
        apply_outstanding_migration(temp_db_file, migration_dir)
    finally:
        os.rmdir(migration_dir)


def test_apply_outstanding_migration_lock_timeout(temp_db_file):
    """Tests apply_outstanding_migration handles LockTimeout (lines 362-365)."""
    migration_dir = tempfile.mkdtemp()

    try:
        # Create mock backend
        mock_backend = MagicMock()
        mock_backend.apply_migrations.side_effect = [LockTimeout(), None]
        mock_backend.to_apply.return_value = []

        with patch("counterpartycore.lib.utils.database.get_backend", return_value=mock_backend):
            with patch("counterpartycore.lib.utils.database.read_migrations", return_value=[]):
                apply_outstanding_migration(temp_db_file, migration_dir)

        # break_lock should have been called
        mock_backend.break_lock.assert_called_once()
    finally:
        os.rmdir(migration_dir)


# =============================================================================
# Tests for rollback_all_migrations function (lines 370-373)
# =============================================================================


def test_rollback_all_migrations(temp_db_file):
    """Tests rollback_all_migrations function."""
    migration_dir = tempfile.mkdtemp()

    try:
        # Create mock backend
        mock_backend = MagicMock()
        mock_backend.to_rollback.return_value = []

        with patch("counterpartycore.lib.utils.database.get_backend", return_value=mock_backend):
            with patch("counterpartycore.lib.utils.database.read_migrations", return_value=[]):
                rollback_all_migrations(temp_db_file, migration_dir)

        mock_backend.rollback_migrations.assert_called_once()
    finally:
        os.rmdir(migration_dir)


# =============================================================================
# Additional edge case tests
# =============================================================================


def test_database_integrity_error_class():
    """Tests DatabaseIntegrityError is a subclass of DatabaseError."""
    error = DatabaseIntegrityError("test error")
    assert isinstance(error, exceptions.DatabaseError)


def test_ledger_db_connection_pool_singleton(temp_db_file, monkeypatch):
    """Tests LedgerDBConnectionPool is a singleton."""
    monkeypatch.setattr(config, "DATABASE", temp_db_file)

    # Reset the singleton
    if database.LedgerDBConnectionPool in SingletonMeta._instances:
        del SingletonMeta._instances[database.LedgerDBConnectionPool]

    pool1 = database.LedgerDBConnectionPool()
    pool2 = database.LedgerDBConnectionPool()

    assert pool1 is pool2

    pool1.close()

    # Clean up singleton
    if database.LedgerDBConnectionPool in SingletonMeta._instances:
        del SingletonMeta._instances[database.LedgerDBConnectionPool]


def test_state_db_connection_pool_singleton(temp_db_file, monkeypatch):
    """Tests StateDBConnectionPool is a singleton."""
    monkeypatch.setattr(config, "STATE_DATABASE", temp_db_file)

    # Reset the singleton
    if database.StateDBConnectionPool in SingletonMeta._instances:
        del SingletonMeta._instances[database.StateDBConnectionPool]

    pool1 = database.StateDBConnectionPool()
    pool2 = database.StateDBConnectionPool()

    assert pool1 is pool2

    pool1.close()

    # Clean up singleton
    if database.StateDBConnectionPool in SingletonMeta._instances:
        del SingletonMeta._instances[database.StateDBConnectionPool]
