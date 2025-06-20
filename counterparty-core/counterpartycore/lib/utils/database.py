import logging
import os
import threading
from contextlib import contextmanager

import apsw
import apsw.bestpractice
import apsw.ext
import psutil
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.utils import helpers
from termcolor import cprint
from yoyo import get_backend, read_migrations
from yoyo.exceptions import LockTimeout

apsw.bestpractice.apply(apsw.bestpractice.recommended)  # includes WAL mode

logger = logging.getLogger(config.LOGGER_NAME)
apsw.ext.log_sqlite(logger=logger)


def rowtracer(cursor, sql):
    """Converts fetched SQL data into dict-style"""
    return {
        name: (bool(value) if str(field_type) == "BOOL" else value)
        for (name, field_type), value in zip(cursor.getdescription(), sql)
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
    cursor = db.cursor()

    # Make case sensitive the `LIKE` operator.
    # For insensitive queries use 'UPPER(fieldname) LIKE value.upper()''
    cursor.execute("PRAGMA case_sensitive_like = ON")
    cursor.execute("PRAGMA auto_vacuum = 1")
    cursor.execute("PRAGMA synchronous = normal")
    cursor.execute("PRAGMA journal_size_limit = 6144000")
    cursor.execute("PRAGMA foreign_keys = ON")
    cursor.execute("PRAGMA defer_foreign_keys = ON")

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
        # Lock only used when absolutely necessary
        self.lock = threading.RLock()
        # Use a counter instead of tracking every connection
        self.connection_count = 0

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
                # Only lock when creating a new connection
                with self.lock:
                    self.connection_count += 1
                db = get_db_connection(self.db_file, read_only=True, check_wal=False)
        else:
            # Only lock when creating a new connection
            with self.lock:
                self.connection_count += 1
            db = get_db_connection(self.db_file, read_only=True, check_wal=False)

        try:
            yield db
        finally:
            # Check closed status without lock first
            if self.closed:
                db.close()
                with self.lock:
                    self.connection_count -= 1
            else:
                # Fast path: return to local pool without locking
                if len(self.thread_local.connections) < config.DB_CONNECTION_POOL_SIZE:
                    self.thread_local.connections.append(db)
                else:
                    # Only if we need to close the connection
                    db.close()
                    with self.lock:
                        self.connection_count -= 1

    def close(self):
        # Set closed flag first - fast path for new connection requests
        self.closed = True

        with self.lock:
            logger.trace(
                "Closing all connections in pool (%s)... (%s)", self.name, self.connection_count
            )

        # Close connections in current thread
        if hasattr(self.thread_local, "connections"):
            for db in self.thread_local.connections:
                try:
                    db.close()
                except apsw.ThreadingViolationError:
                    logger.trace("ThreadingViolationError occurred while closing connection.")
            # Clear thread local connections
            self.thread_local.connections = []


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


def apply_outstanding_migration(db_file, migration_dir):
    logger.info("Applying migrations to %s...", db_file)
    # Apply migrations
    backend = get_backend(f"sqlite:///{db_file}")
    migrations = read_migrations(migration_dir)
    try:
        # with backend.lock():
        backend.apply_migrations(backend.to_apply(migrations))
    except LockTimeout:
        logger.debug("API Watcher - Migration lock timeout. Breaking lock and retrying...")
        backend.break_lock()
        backend.apply_migrations(backend.to_apply(migrations))
    backend.connection.close()


def rollback_all_migrations(db_file, migration_dir):
    logger.info("Rolling back all migrations from %s...", db_file)
    backend = get_backend(f"sqlite:///{db_file}")
    migrations = read_migrations(migration_dir)
    backend.rollback_migrations(backend.to_rollback(migrations))
