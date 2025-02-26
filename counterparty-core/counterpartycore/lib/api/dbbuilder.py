import importlib.util
import logging
import os
import sys
import time

from yoyo.migrations import topological_sort

from counterpartycore.lib import config
from counterpartycore.lib.cli import log
from counterpartycore.lib.utils import database

logger = logging.getLogger(config.LOGGER_NAME)

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


def import_from_path(module_name, file_path):
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


def import_migration(migration_id):
    migration_path = os.path.join(config.STATE_DB_MIGRATIONS_DIR, f"{migration_id}.py")
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
        logger.debug("Rolling back migration `%s`...", migration_id)
        rollback_migration(state_db, migration_id)


def apply_migrations(state_db, migration_ids):
    for migration_id in migration_ids:
        logger.debug("Applying migration `%s`...", migration_id)
        apply_migration(state_db, migration_id)


def reapply_migrations(state_db, migration_ids):
    rollback_migrations(state_db, migration_ids)
    apply_migrations(state_db, migration_ids)


def rollback_tables(state_db, block_index):
    cursor = state_db.cursor()
    cursor.execute("""PRAGMA foreign_keys=OFF""")

    for table in ROLLBACKABLE_TABLES:
        logger.debug("Rolling back table `%s`...", table)
        cursor.execute(f"DELETE FROM {table} WHERE block_index >= ?", (block_index,))  # noqa S608 # nosec B608

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
        database.apply_outstanding_migration(config.STATE_DATABASE, config.STATE_DB_MIGRATIONS_DIR)

    logger.info("State DB built in %.2f seconds", time.time() - start_time)


def rollback_state_db(state_db, block_index):
    logger.info("Rolling back State DB to block index %s...", block_index)
    start_time = time.time()

    with state_db:
        with log.Spinner("Rolling back State DB tables..."):
            rollback_tables(state_db, block_index)
        with log.Spinner("Re-applying migrations..."):
            reapply_migrations(state_db, MIGRATIONS_AFTER_ROLLBACK)

    logger.info("State DB rolled back in %.2f seconds", time.time() - start_time)


def refresh_state_db(state_db):
    logger.info("Rebuilding non rollbackable tables in State DB...")
    start_time = time.time()

    with state_db:
        with log.Spinner("Re-applying migrations..."):
            reapply_migrations(state_db, MIGRATIONS_AFTER_ROLLBACK)

    logger.info("State DB refreshed in %.2f seconds", time.time() - start_time)
