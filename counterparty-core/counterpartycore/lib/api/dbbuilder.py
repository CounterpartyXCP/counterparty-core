import importlib.util
import logging
import os
import sys
import time

from counterpartycore.lib import config
from counterpartycore.lib.cli import log
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
    "0009.create_and_populate_transaction_types_count",
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
    logger.info("Applying migrations...")
    # Apply migrations
    backend = get_backend(f"sqlite:///{config.STATE_DATABASE}")
    migrations = read_migrations(MIGRATIONS_DIR)
    try:
        # with backend.lock():
        backend.apply_migrations(backend.to_apply(migrations))
    except LockTimeout:
        logger.debug("API Watcher - Migration lock timeout. Breaking lock and retrying...")
        backend.break_lock()
        backend.apply_migrations(backend.to_apply(migrations))
    backend.connection.close()


def import_from_path(module_name, file_path):
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


def import_migration(migration_id):
    migration_path = os.path.join(MIGRATIONS_DIR, f"{migration_id}.py")
    module_name = "apsw_" + migration_id.split(".")[1]
    return import_from_path(module_name, migration_path)


def apply_migration(state_db, migration_id):
    module = import_migration(migration_id)
    module.apply(state_db)


def rollback_migration(state_db, migration_id):
    module = import_migration(migration_id)
    module.rollback(state_db)


def rollback_migrations(state_db, migration_ids):
    for migration_id in reversed(migration_ids):
        logger.debug(f"Rolling back migration `{migration_id}`...")
        rollback_migration(state_db, migration_id)


def apply_migrations(state_db, migration_ids):
    for migration_id in migration_ids:
        logger.debug(f"Applying migration `{migration_id}`...")
        apply_migration(state_db, migration_id)


def reapply_migrations(state_db, migration_ids):
    rollback_migrations(state_db, migration_ids)
    apply_migrations(state_db, migration_ids)


def rollback_tables(state_db, block_index):
    cursor = state_db.cursor()
    cursor.execute("""PRAGMA foreign_keys=OFF""")

    for table in ROLLBACKABLE_TABLES:
        logger.debug(f"Rolling back table `{table}`...")
        cursor.execute(f"DELETE FROM {table} WHERE block_index >= ?", (block_index,))  # noqa S608

    cursor.execute("""PRAGMA foreign_keys=ON""")
    cursor.close()


def build_state_db():
    logger.info("Building State DB...")
    start_time = time.time()

    # Remove existing State DB
    for ext in ["", "-wal", "-shm"]:
        if os.path.exists(config.STATE_DATABASE + ext):
            os.unlink(config.STATE_DATABASE + ext)

    with log.Spinner("Applying migrations"):
        apply_outstanding_migration()

    logger.info(f"State DB built in {time.time() - start_time:.2f} seconds")


def rollback_state_db(state_db, block_index):
    logger.info(f"Rolling back State DB to block index {block_index}...")
    start_time = time.time()

    with state_db:
        with log.Spinner("Rolling back State DB tables..."):
            rollback_tables(state_db, block_index)
        with log.Spinner("Re-applying migrations..."):
            reapply_migrations(state_db, MIGRATIONS_AFTER_ROLLBACK)

    logger.info(f"State DB rolled back in {time.time() - start_time:.2f} seconds")


def refresh_state_db(state_db):
    logger.info("Rebuilding non rollbackable tables in State DB...")
    start_time = time.time()

    with state_db:
        with log.Spinner("Re-applying migrations..."):
            reapply_migrations(state_db, MIGRATIONS_AFTER_ROLLBACK)

    logger.info(f"State DB refreshed in {time.time() - start_time:.2f} seconds")
