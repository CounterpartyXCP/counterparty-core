import logging
import os
import shutil
import time

from counterpartycore.lib import config, database, log
from yoyo import get_backend, read_migrations
from yoyo.migrations import topological_sort

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))
MIGRATIONS_DIR = os.path.join(CURRENT_DIR, "migrations")

MIGRATIONS_AFTER_ROLLBACK = [
    "0003.populate_assets_info",
    "0004.populate_events_count",
    "0005.populate_consolidated_tables",
    "0006.populate_fairminters_counters",
]

ROLLBACKABLE_TABLES = [
    "blocks",
    "transactions",
    "transaction_outputs",
    "debits",
    "credits",
    "sends",
    "assets",
    "destructions",
    "btcpays",
    "broadcasts",
    "dividends",
    "burns",
    "cancels",
    "rpsresolves",
    "sweeps",
    "dispenses",
    "dispenser_refills",
    "fairmints",
    "transaction_count",
    "issuances",
    "messages",
    "bet_match_resolutions",
    "order_expirations",
    "order_match_expirations",
    "bet_expirations",
    "bet_match_expirations",
    "rps_expirations",
    "rps_match_expirations",
    # state db tables
    "all_expirations",
    "address_events",
]


def copy_ledger_db():
    for ext in ["", "-wal", "-shm"]:
        if os.path.exists(config.STATE_DATABASE + ext):
            os.unlink(config.STATE_DATABASE + ext)

    # ensure the database is closed an no wall file is present
    ledger_db = database.get_db_connection(config.DATABASE, read_only=False, check_wal=False)
    ledger_db.close()

    for ext in ["", "-wal", "-shm"]:
        if os.path.exists(config.DATABASE + ext):
            shutil.copyfile(config.DATABASE + ext, config.STATE_DATABASE + ext)


def filter_migrations(migrations, wanted_ids):
    filtered_migrations = (m for m in migrations if m.id in wanted_ids)
    return migrations.__class__(topological_sort(filtered_migrations), migrations.post_apply)


def apply_all_migrations():
    backend = get_backend(f"sqlite:///{config.STATE_DATABASE}")

    migrations = read_migrations(MIGRATIONS_DIR)

    # Apply migrations
    with backend.lock():
        backend.apply_migrations(migrations, force=False)

    backend.connection.close()


def reapply_migrations(migration_ids):
    backend = get_backend(f"sqlite:///{config.STATE_DATABASE}")

    migrations = read_migrations(MIGRATIONS_DIR)
    migrations = filter_migrations(migrations, migration_ids)

    # Apply migrations
    with backend.lock():
        for migration in migrations:
            backend.rollback_one(migration)
            backend.apply_one(migration)

    backend.connection.close()


def rollback_tables(state_db, block_index):
    cursor = state_db.cursor()
    cursor.execute("""PRAGMA foreign_keys=OFF""")

    for table in ROLLBACKABLE_TABLES:
        logger.debug(f"Rolling back table {table}")
        cursor.execute(f"DELETE FROM {table} WHERE block_index >= ?", (block_index,))  # noqa S608

    cursor.execute("""PRAGMA foreign_keys=ON""")
    cursor.close()


def build_state_db():
    logger.info("Building state db")
    start_time = time.time()

    with log.Spinner("Copying ledger database to state database"):
        copy_ledger_db()
    with log.Spinner("Applying migrations"):
        apply_all_migrations()
    with log.Spinner("Set initial database version"):
        state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
        database.update_version(state_db)

    logger.info(f"State db built in {time.time() - start_time} seconds")


def rollback_state_db(state_db, block_index):
    logger.info(f"Rolling back state db to block index {block_index}")
    start_time = time.time()

    with log.Spinner("Rolling back State DB tables"):
        rollback_tables(state_db, block_index)
    with log.Spinner("Applying migrations"):
        reapply_migrations(MIGRATIONS_AFTER_ROLLBACK)

    logger.info(f"State db rolled back in {time.time() - start_time} seconds")
