import logging
import os
import threading
import time
from contextlib import contextmanager

import apsw
import apsw.bestpractice
import apsw.ext
import psutil
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.utils import hashcodec, helpers
from termcolor import cprint
from yoyo import get_backend, read_migrations
from yoyo.exceptions import LockTimeout

apsw.bestpractice.apply(apsw.bestpractice.recommended)  # includes WAL mode

logger = logging.getLogger(config.LOGGER_NAME)
apsw.ext.log_sqlite(logger=logger)


# Local reference for the rowtracer hot path: avoids the per-call attribute
# lookup ``hashcodec.HASH_COLUMN_NAMES``. The rowtracer runs once per row per
# column so trimming a few attribute lookups matters in the load test.
_HASH_COLUMN_NAMES = hashcodec.HASH_COLUMN_NAMES


def _convert_value(name, field_type, value):
    # Fast path: most columns are non-NULL primitives (int, str, ...) and
    # not BOOL/BLOB hashes. Putting the cheapest checks first avoids the
    # ``isinstance(..., bytes)`` and ``str(field_type) == "BOOL"``
    # allocations that previously ran for every cell.
    if value is None:
        # Preserve the pre-optimization rowtracer contract: ``BOOL`` columns
        # always materialize as a real Python bool, even when the underlying
        # SQLite value is NULL (``bool(None) == False``). Several handlers
        # and serialized events rely on this.
        if field_type == "BOOL":
            return False
        return None
    # Columns storing 256-bit hashes are BLOB(32) at rest after the size
    # optimization migration, but the rest of the codebase (consensus,
    # API, tests) expects 64-char lowercase hex strings. Convert lazily
    # in the rowtracer so downstream code is unchanged. ``bytes.hex()`` is
    # ~1.6x faster than ``binascii.hexlify(value).decode("ascii")``.
    if value.__class__ is bytes and name in _HASH_COLUMN_NAMES:
        return value.hex()
    if field_type == "BOOL":
        return bool(value)
    return value


def rowtracer(cursor, sql):
    """Converts fetched SQL data into dict-style. Auto-converts BLOB hash
    columns back to lowercase hex strings, preserving the legacy contract that
    ``row['tx_hash']`` etc. are hex strings.
    """
    return {
        name: _convert_value(name, field_type, value)
        for (name, field_type), value in zip(cursor.getdescription(), sql, strict=True)
    }


def get_file_openers(filename):
    pids = []
    for proc in psutil.process_iter():
        try:
            # this returns the list of opened files by the current process
            flist = proc.open_files()
            if flist:
                for nt in flist:
                    if filename in nt.path:
                        pids.append(proc.pid)
                        break
        # This catches a race condition where a process ends
        # before we can examine its files
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
    return pids


def check_wal_file(db_file):
    wal_file = f"{db_file}-wal"
    if os.path.exists(wal_file):
        pids = get_file_openers(wal_file)
        if len(pids) > 0:
            raise exceptions.DatabaseError(f"Database already opened by a process ({pids}).")
        raise exceptions.WALFileFoundError("Found WAL file. Database may be corrupted.")


def _should_attach_ledger_db(read_only, db_file):
    """Return True when a read-only State DB connection should ATTACH the
    Ledger DB so that hash-FK projections can JOIN against ``transactions``.
    """
    if not read_only:
        return False
    if not hasattr(config, "STATE_DATABASE") or db_file != config.STATE_DATABASE:
        return False
    if not hasattr(config, "DATABASE") or not config.DATABASE:
        return False
    return os.path.exists(config.DATABASE)


def get_db_connection(db_file, read_only=True, check_wal=False):
    """Connects to the SQLite database, returning a db `Connection` object"""

    if hasattr(config, "DATABASE") and db_file == config.DATABASE:
        db_file_name = "Ledger DB"
    elif hasattr(config, "STATE_DATABASE") and db_file == config.STATE_DATABASE:
        db_file_name = "State DB"
    else:
        db_file_name = db_file
    if hasattr(logger, "trace"):
        logger.trace(f"Creating connection to {db_file_name}...")

    if not read_only and check_wal:
        try:
            check_wal_file(db_file)
        except exceptions.WALFileFoundError:
            logger.warning(
                "Database WAL file detected. To ensure no data corruption has occurred, run `counterpary-server check-db`."
            )

    if read_only:
        db = apsw.Connection(db_file, flags=apsw.SQLITE_OPEN_READONLY)
    else:
        db = apsw.Connection(db_file)

    # Register UDFs before opening any cursor. SQLite 3.41+ ships a built-in
    # ``unhex``; overriding a built-in fails with SQLITE_BUSY when there are
    # active prepared statements on the connection, so we must register here
    # before any cursor/PRAGMA work creates such statements.
    hashcodec.register_db_functions(db)

    cursor = db.cursor()

    # Make case sensitive the `LIKE` operator.
    # For insensitive queries use 'UPPER(fieldname) LIKE value.upper()''
    cursor.execute("PRAGMA case_sensitive_like = ON")
    cursor.execute("PRAGMA foreign_keys = ON")
    cursor.execute("PRAGMA defer_foreign_keys = ON")
    if not read_only:
        cursor.execute("PRAGMA auto_vacuum = 1")
        cursor.execute("PRAGMA synchronous = normal")
        cursor.execute("PRAGMA journal_size_limit = 6144000")

    # State DB read-only connections (used by API request handlers) need to
    # see ``ledger_db.transactions`` so that hash-FK projections that
    # re-hydrate ``order_tx_hash`` / ``dispenser_tx_hash`` from their
    # ``*_tx_index`` foreign keys can JOIN against it. We do this only for
    # read-only connections to avoid taking a write lock on ledger_db
    # (which would conflict with the ledger writer / test fixtures).
    if _should_attach_ledger_db(read_only, db_file):
        try:
            attached_row = cursor.execute(
                "SELECT COUNT(*) FROM pragma_database_list WHERE name = ?",
                ("ledger_db",),
            ).fetchone()
            already_attached = (attached_row[0] if attached_row else 0) > 0
            if not already_attached:
                cursor.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))
        except apsw.SQLError:
            # Ledger DB may not exist yet during early bootstrap; the caller
            # will retry once it's available.
            pass

    db.setrowtrace(rowtracer)

    cursor.close()
    return db


def get_connection(read_only=True, check_wal=True):
    return get_db_connection(config.DATABASE, read_only=read_only, check_wal=check_wal)


class APSWConnectionPool:
    def __init__(self, db_file, name):
        self.db_file = db_file
        self.name = name
        self.closed = False
        # Thread-local storage for connections
        self.thread_local = threading.local()
        # Lock for connection count management
        self.lock = threading.RLock()
        # Condition variable for waiting when at max connections
        self.connection_available = threading.Condition(self.lock)
        # Use a counter instead of tracking every connection
        self.connection_count = 0
        # Max connections (0 = unlimited)
        self.max_connections = getattr(config, "DB_MAX_CONNECTIONS", 50)
        # Track peak connections for monitoring
        self.peak_connection_count = 0

    def _create_connection_with_limit(self):
        """Create a new connection, waiting if at max_connections limit."""
        wait_start = None
        with self.connection_available:
            # Wait if at max connections (0 = unlimited)
            if self.max_connections > 0:
                while self.connection_count >= self.max_connections and not self.closed:
                    if wait_start is None:
                        wait_start = time.time()
                        logger.warning(
                            "CONTENTION: %s at %d/%d, thread=%s waiting",
                            self.name,
                            self.connection_count,
                            self.max_connections,
                            threading.current_thread().name,
                        )
                    else:
                        logger.debug(
                            "Connection pool %s at max (%d), waiting...",
                            self.name,
                            self.max_connections,
                        )
                    # Wait up to 30 seconds for a connection to become available
                    if not self.connection_available.wait(timeout=30):
                        raise exceptions.DatabaseError(
                            f"Timeout waiting for database connection (pool {self.name} at max {self.max_connections})"
                        )
                    # Check if pool was closed while waiting
                    if self.closed:
                        raise exceptions.DatabaseError(
                            f"Connection pool {self.name} closed while waiting for connection"
                        )

            # Log wait time if we waited
            if wait_start is not None:
                wait_ms = (time.time() - wait_start) * 1000
                logger.warning(
                    "Connection acquired after %.0fms wait (%s, thread=%s)",
                    wait_ms,
                    self.name,
                    threading.current_thread().name,
                )

            self.connection_count += 1

            # Track peak connection count
            self.peak_connection_count = max(self.peak_connection_count, self.connection_count)

        return get_db_connection(self.db_file, read_only=True, check_wal=False)

    def _release_connection(self):
        """Decrement connection count and notify waiters."""
        with self.connection_available:
            self.connection_count -= 1
            self.connection_available.notify()

    @contextmanager
    def connection(self):
        # Fast path: initialize thread-local storage if needed
        if not hasattr(self.thread_local, "connections"):
            self.thread_local.connections = []

        # Quick check without acquiring lock
        if self.closed:
            # Create a temporary connection if pool is closed
            db = get_db_connection(self.db_file, read_only=True, check_wal=False)
            try:
                yield db
            finally:
                db.close()
            return

        # Get or create a connection
        if self.thread_local.connections:
            # Reuse existing connection - fast path without locking
            db = self.thread_local.connections.pop()
            try:
                # Minimal validation - use a cheap operation
                cursor = db.execute("SELECT 1")
                cursor.fetchone()
            except (apsw.ThreadingViolationError, apsw.BusyError):
                # Close the bad connection before creating a new one
                try:
                    db.close()
                except apsw.Error:  # noqa: S110
                    pass  # Connection may already be closed or in bad state
                db = self._create_connection_with_limit()
        else:
            db = self._create_connection_with_limit()

        try:
            yield db
        finally:
            # Check closed status without lock first
            if self.closed:
                db.close()
                self._release_connection()
            else:
                # Fast path: return to local pool without locking
                if len(self.thread_local.connections) < config.DB_CONNECTION_POOL_SIZE:
                    self.thread_local.connections.append(db)
                else:
                    # Close connection and notify waiters
                    db.close()
                    self._release_connection()

    def close(self):
        # Set closed flag first - fast path for new connection requests
        self.closed = True

        with self.connection_available:
            logger.trace(
                "Closing all connections in pool (%s)... (%s)", self.name, self.connection_count
            )
            # Wake up any threads waiting for connections
            self.connection_available.notify_all()

        # Close connections in current thread
        if hasattr(self.thread_local, "connections"):
            for db in self.thread_local.connections:
                try:
                    db.close()
                except apsw.ThreadingViolationError:
                    logger.trace("ThreadingViolationError occurred while closing connection.")
            # Clear thread local connections
            self.thread_local.connections = []

    def get_stats(self):
        """Get current connection pool statistics."""
        with self.lock:
            utilization = (
                (self.connection_count / self.max_connections * 100)
                if self.max_connections > 0
                else 0
            )
            return {
                "current": self.connection_count,
                "max": self.max_connections,
                "peak": self.peak_connection_count,
                "utilization": utilization,
            }


class LedgerDBConnectionPool(APSWConnectionPool, metaclass=helpers.SingletonMeta):
    def __init__(self):
        super().__init__(config.DATABASE, "Ledger DB")


class StateDBConnectionPool(APSWConnectionPool, metaclass=helpers.SingletonMeta):
    def __init__(self):
        super().__init__(config.STATE_DATABASE, "API DB")


def initialise_db():
    if config.FORCE:
        cprint("THE OPTION `--force` IS NOT FOR USE ON PRODUCTION SYSTEMS.", "yellow")

    # Database
    logger.debug("Connecting to database... (SQLite %s)", apsw.apswversion())
    db = get_connection(read_only=False)

    return db


class DatabaseIntegrityError(exceptions.DatabaseError):
    pass


def check_foreign_keys(db):
    cursor = db.cursor()

    logger.info("Checking database foreign keys...")

    cursor.execute("PRAGMA foreign_key_check")
    rows = cursor.fetchall()
    if rows:
        for row in rows:
            logger.debug("Foreign Key Error: %s", row)
        raise exceptions.DatabaseError("Foreign key check failed.")

    logger.info("Foreign key check completed.")


def intergrity_check(db):
    cursor = db.cursor()

    logger.info("Checking database integrity...")

    cursor.execute("PRAGMA integrity_check")
    rows = cursor.fetchall()
    if not (len(rows) == 1 and rows[0]["integrity_check"] == "ok"):
        for row in rows:
            logger.debug("Integrity Error: %s", row)
        raise exceptions.DatabaseError("Integrity check failed.")

    logger.info("Integrity check completed.")


def set_config_value(db, name, value):
    cursor = db.cursor()
    cursor.execute("INSERT OR REPLACE INTO config (name, value) VALUES (?, ?)", (name, value))


def get_config_value(db, name):
    cursor = db.cursor()
    cursor.execute("SELECT value FROM config WHERE name = ?", (name,))
    rows = cursor.fetchall()
    if rows:
        return rows[0]["value"]
    return None


def update_version(db):
    set_config_value(db, "VERSION_STRING", config.VERSION_STRING)
    logger.info("Database version number updated.")


def vacuum(db):
    logger.info("Starting database VACUUM... this may take a while!")
    cursor = db.cursor()
    cursor.execute("VACUUM")
    logger.info("Database VACUUM completed.")


def optimize(db):
    logger.info("Running PRAGMA optimize...")
    cursor = db.cursor()
    cursor.execute("PRAGMA optimize")
    logger.debug("PRAGMA optimize completed.")


def close(db):
    logger.info("Closing database connections...")
    LedgerDBConnectionPool().close()
    db.close()  # always close connection with write access last


_VACUUM_AFTER_MIGRATIONS = {"0010.compact_hash_storage"}


def apply_outstanding_migration(db_file, migration_dir):
    logger.info("Applying migrations to %s...", db_file)
    backend = get_backend(f"sqlite:///{db_file}")
    migrations = read_migrations(migration_dir)
    to_apply = backend.to_apply(migrations)
    needs_vacuum = any(any(name in m.id for name in _VACUUM_AFTER_MIGRATIONS) for m in to_apply)
    try:
        backend.apply_migrations(to_apply)
    except LockTimeout:
        logger.debug("API Watcher - Migration lock timeout. Breaking lock and retrying...")
        backend.break_lock()
        backend.apply_migrations(backend.to_apply(migrations))
    backend.connection.close()
    if needs_vacuum:
        logger.info("Running VACUUM after compact-hash migration to reclaim disk space...")
        conn = apsw.Connection(db_file)
        conn.cursor().execute("VACUUM")
        conn.close()
        logger.info("VACUUM completed.")


def rollback_all_migrations(db_file, migration_dir):
    logger.info("Rolling back all migrations from %s...", db_file)
    backend = get_backend(f"sqlite:///{db_file}")
    migrations = read_migrations(migration_dir)
    backend.rollback_migrations(backend.to_rollback(migrations))
