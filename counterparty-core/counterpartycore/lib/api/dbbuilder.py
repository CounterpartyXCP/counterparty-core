import logging
import os
import time

from counterpartycore.lib import config, log
from yoyo import get_backend, read_migrations
from yoyo.exceptions import LockTimeout
from yoyo.migrations import topological_sort

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))
MIGRATIONS_DIR = os.path.join(CURRENT_DIR, "migrations")

MIGRATIONS_AFTER_ROLLBACK = [
    "0004.create_and_populate_assets_info",
    "0005.create_and_populate_events_count",
    "0006.create_and_populate_consolidated_tables",
    "0007.create_views",
    "0008.create_config_table",
]

ROLLBACKABLE_TABLES = [
    "all_expirations",
    "address_events",
    "parsed_events",
]


def filter_migrations(migrations, wanted_ids):
    filtered_migrations = (m for m in migrations if m.id in wanted_ids)
    return migrations.__class__(topological_sort(filtered_migrations), migrations.post_apply)


def apply_outstanding_migration():
    logger.debug("API Watcher - Applying migrations...")
    # Apply migrations
    backend = get_backend(f"sqlite:///{config.STATE_DATABASE}")
    migrations = read_migrations(MIGRATIONS_DIR)
    try:
        with backend.lock():
            backend.apply_migrations(backend.to_apply(migrations))
    except LockTimeout:
        logger.debug("API Watcher - Migration lock timeout. Breaking lock and retrying...")
        backend.break_lock()
        backend.apply_migrations(backend.to_apply(migrations))
    backend.connection.close()


def rollback_migrations(migration_ids):
    backend = get_backend(f"sqlite:///{config.STATE_DATABASE}")

    migrations = read_migrations(MIGRATIONS_DIR)
    migrations = filter_migrations(migrations, migration_ids)

    # Apply migrations
    with backend.lock():
        for migration in reversed(migrations):
            backend.rollback_one(migration)

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

    # Remove existing state db
    for ext in ["", "-wal", "-shm"]:
        if os.path.exists(config.STATE_DATABASE + ext):
            os.unlink(config.STATE_DATABASE + ext)

    with log.Spinner("Applying migrations"):
        apply_outstanding_migration()

    logger.info(f"State db built in {time.time() - start_time} seconds")


def rollback_state_db(state_db, block_index):
    logger.info(f"Rolling back state db to block index {block_index}")
    start_time = time.time()

    with log.Spinner("Rolling back State DB tables"):
        rollback_tables(state_db, block_index)
    with log.Spinner("Rollback migrations"):
        rollback_migrations(MIGRATIONS_AFTER_ROLLBACK)
    with log.Spinner("Re-applying migrations"):
        apply_outstanding_migration()

    logger.info(f"State db rolled back in {time.time() - start_time} seconds")
