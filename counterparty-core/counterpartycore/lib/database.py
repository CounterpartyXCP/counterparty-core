import logging
import os
from contextlib import contextmanager

import apsw
import apsw.bestpractice
import apsw.ext
import psutil
from termcolor import cprint

from counterpartycore.lib import config, exceptions, ledger, util

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
    elif hasattr(config, "API_DATABASE") and db_file == config.API_DATABASE:
        db_file_name = "API DB"
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


# Minimalistic but sufficient connection pool
class APSWConnectionPool:
    def __init__(self, db_file, name):
        self.connections = []
        self.db_file = db_file
        self.closed = False
        self.name = name

    @contextmanager
    def connection(self):
        if self.connections:
            # Reusing connection
            db = self.connections.pop(0)
        else:
            # New db connection
            db = get_db_connection(self.db_file, read_only=True, check_wal=False)
        try:
            yield db
        finally:
            if self.closed:
                logger.trace("Connection pool is closed. Closing connection (%s).", self.name)
                db.close()
            elif len(self.connections) < config.DB_CONNECTION_POOL_SIZE:
                # Add connection to pool
                self.connections.append(db)
            else:
                # Too much connections in the pool: closing connection
                logger.warning("Closing connection due to pool size limit (%s).", self.name)
                try:
                    db.close()
                except apsw.ThreadingViolationError:
                    # This should never happen, and yet it has happened..
                    # let's ignore this harmless error so as not to return a 500 error to the user.
                    logger.trace("ThreadingViolationError occurred while closing connection.")
                    pass

    def close(self):
        logger.trace(
            "Closing all connections in pool (%s)... (%s)", self.name, len(self.connections)
        )
        self.closed = True
        while len(self.connections) > 0:
            db = self.connections.pop()
            db.close()


class DBConnectionPool(APSWConnectionPool, metaclass=util.SingletonMeta):
    def __init__(self):
        super().__init__(config.DATABASE, "Ledger DB")


class APIDBConnectionPool(APSWConnectionPool, metaclass=util.SingletonMeta):
    def __init__(self):
        super().__init__(config.API_DATABASE, "API DB")


def initialise_db():
    if config.FORCE:
        cprint("THE OPTION `--force` IS NOT FOR USE ON PRODUCTION SYSTEMS.", "yellow")

    # Database
    logger.info(f"Connecting to database... (SQLite {apsw.apswversion()})")
    db = get_connection(read_only=False)

    util.CURRENT_BLOCK_INDEX = ledger.last_db_index(db)

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
            logger.debug(f"Foreign Key Error: {row}")
        raise exceptions.DatabaseError("Foreign key check failed.")

    logger.info("Foreign key check completed.")


def intergrity_check(db):
    cursor = db.cursor()

    logger.info("Checking database integrity...")

    cursor.execute("PRAGMA integrity_check")
    rows = cursor.fetchall()
    if not (len(rows) == 1 and rows[0]["integrity_check"] == "ok"):
        for row in rows:
            logger.debug(f"Integrity Error: {row}")
        raise exceptions.DatabaseError("Integrity check failed.")

    logger.info("Integrity check completed.")


def version(db):
    cursor = db.cursor()
    user_version = cursor.execute("PRAGMA user_version").fetchall()[0]["user_version"]
    # manage old user_version
    if user_version == config.VERSION_MINOR:
        version_minor = user_version
        version_major = config.VERSION_MAJOR
        user_version = (config.VERSION_MAJOR * 1000) + version_minor
        cursor.execute(f"PRAGMA user_version = {user_version}")
    else:
        version_minor = user_version % 1000
        version_major = user_version // 1000
    return version_major, version_minor


def init_config_table(db):
    cursor = db.cursor()

    query = "SELECT name FROM sqlite_master WHERE type='table' AND name='config'"
    if len(list(cursor.execute(query))) == 1:
        return

    sql = """
        CREATE TABLE IF NOT EXISTS config (
            name TEXT PRIMARY KEY,
            value TEXT
        )
    """
    cursor.execute(sql)
    cursor.execute("CREATE INDEX IF NOT EXISTS config_config_name_idx ON config (name)")


def set_config_value(db, name, value):
    init_config_table(db)
    cursor = db.cursor()
    cursor.execute("INSERT OR REPLACE INTO config (name, value) VALUES (?, ?)", (name, value))


def get_config_value(db, name):
    init_config_table(db)
    cursor = db.cursor()
    cursor.execute("SELECT value FROM config WHERE name = ?", (name,))
    rows = cursor.fetchall()
    if rows:
        return rows[0]["value"]
    return None


def update_version(db):
    cursor = db.cursor()
    user_version = (config.VERSION_MAJOR * 1000) + config.VERSION_MINOR
    cursor.execute(f"PRAGMA user_version = {user_version}")  # Syntax?!
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
    db.close()
    DBConnectionPool().close()


def field_is_pk(cursor, table, field):
    cursor.execute(f"PRAGMA table_info({table})")
    for row in cursor:
        if row["name"] == field and row["pk"] == 1:
            return True
    return False


def has_fk_on(cursor, table, foreign_key):
    cursor.execute(f"PRAGMA foreign_key_list ({table})")
    for row in cursor:
        if f"{row['table']}.{row['to']}" == foreign_key:
            return True
    return False


def index_exists(cursor, table, index):
    cursor.execute(f"PRAGMA index_list({table})")
    for row in cursor:
        if row["name"] == index:
            return True
    return False


def create_indexes(cursor, table, indexes, unique=False):
    for index in indexes:
        field_names = [field.split(" ")[0] for field in index]
        index_name = f"{table}_{'_'.join(field_names)}_idx"
        fields = ", ".join(index)
        unique_clause = "UNIQUE" if unique else ""
        query = f"""
            CREATE {unique_clause} INDEX IF NOT EXISTS {index_name} ON {table} ({fields})
        """
        cursor.execute(query)


def drop_indexes(cursor, indexes):
    for index_name in [indexes]:
        cursor.execute(f"""DROP INDEX IF EXISTS {index_name}""")


# called by contracts, no sql injection
def copy_old_table(cursor, table_name, new_create_query):
    cursor.execute(f"""ALTER TABLE {table_name} RENAME TO old_{table_name}""")
    cursor.execute(new_create_query)
    cursor.execute(f"""INSERT INTO {table_name} SELECT * FROM old_{table_name}""")  # nosec B608  # noqa: S608
    cursor.execute(f"""DROP TABLE old_{table_name}""")


def table_exists(cursor, table):
    table_name = cursor.execute(
        f"SELECT name FROM sqlite_master WHERE type='table' AND name='{table}'"  # nosec B608  # noqa: S608
    ).fetchone()
    return table_name is not None


def lock_update(db, table):
    cursor = db.cursor()
    cursor.execute(
        f"""CREATE TRIGGER IF NOT EXISTS block_update_{table}
            BEFORE UPDATE ON {table} BEGIN
                SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
            END;
        """
    )


def unlock_update(db, table):
    cursor = db.cursor()
    cursor.execute(f"DROP TRIGGER IF EXISTS block_update_{table}")
