import logging

import apsw
import apsw.bestpractice

from counterpartycore.lib import config, exceptions  # noqa: E402, F401

apsw.bestpractice.apply(apsw.bestpractice.recommended)  # includes WAL mode
logger = logging.getLogger(config.LOGGER_NAME)


def rowtracer(cursor, sql):
    """Converts fetched SQL data into dict-style"""
    dictionary = {}
    for index, (name, type_) in enumerate(cursor.getdescription()):  # noqa: B007
        dictionary[name] = sql[index]
    return dictionary


def get_connection(read_only=True):
    """Connects to the SQLite database, returning a db `Connection` object"""
    logger.debug(f"Creating connection to `{config.DATABASE}`.")

    if read_only:
        db = apsw.Connection(config.DATABASE, flags=apsw.SQLITE_OPEN_READONLY)
    else:
        db = apsw.Connection(config.DATABASE)
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


def update_version(db):
    cursor = db.cursor()
    user_version = (config.VERSION_MAJOR * 1000) + config.VERSION_MINOR
    cursor.execute(f"PRAGMA user_version = {user_version}")  # Syntax?!
    logger.info("Database version number updated.")


def vacuum(db):
    logger.info("Starting database VACUUM. This may take awhile...")
    cursor = db.cursor()
    cursor.execute("VACUUM")
    logger.info("Database VACUUM completed.")


def optimize(db):
    logger.info("Running PRAGMA optimize...")
    cursor = db.cursor()
    cursor.execute("PRAGMA optimize")
    logger.info("PRAGMA optimize done.")


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
