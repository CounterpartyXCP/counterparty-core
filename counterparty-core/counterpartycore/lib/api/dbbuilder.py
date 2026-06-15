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
    # 0002 / 0003 are included so that pre-existing state DBs built before the
    # compact-hash storage migration get rebuilt with the ``hex_lower(...)``
    # projection on the next rollback:
    #   - 0002 populates ``parsed_events.event_hash`` (TEXT) from
    #     ``ledger_db.messages.event_hash`` (now BLOB(32)); without the
    #     ``hex_lower`` projection, BLOBs end up stored in the TEXT column.
    #   - 0003 has the same problem on ``all_expirations.object_id``.
    # ``parsed_events`` and ``all_expirations`` are also in ``ROLLBACKABLE_TABLES``
    # (DELETE-only path); the DELETE is harmless since the table is dropped
    # and recreated by the migration apply.
    "0002.create_and_populate_parsed_events",
    "0003.create_and_populate_all_expirations",
    "0004.create_and_populate_assets_info",
    "0005.create_and_populate_events_count",
    "0006.create_and_populate_consolidated_tables",
    "0007.create_views",
    "0008.create_config_table",
    "0009.create_and_populate_transaction_types_count",
    "0011.create_orders_views",
    "0013.add_performance_indexes",
    "0014.add_pool_consolidated_tables",
    "0015.add_dispenser_origin_index",
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

    # The State DB migrations read from the Ledger DB schema (e.g. migration
    # 0006 references ``fairmints.fairminter_tx_index``, introduced by ledger
    # migration 0010). Make sure the Ledger DB is fully migrated before
    # building the State DB so this command works against bootstrap snapshots
    # that predate the latest Ledger DB migrations.
    with log.Spinner("Applying Ledger DB migrations"):
        database.apply_outstanding_migration(config.DATABASE, config.LEDGER_DB_MIGRATIONS_DIR)

    with log.Spinner("Applying migrations"):
        database.apply_outstanding_migration(config.STATE_DATABASE, config.STATE_DB_MIGRATIONS_DIR)

    with log.Spinner("Vacuuming State DB..."):
        state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
        database.vacuum(state_db)
        state_db.close()

    logger.info("State DB built in %.2f seconds", time.time() - start_time)


def record_balances_copied_block(state_db):
    """
    Record the current ledger_db block index to prevent double-counting of
    CREDIT/DEBIT events during catch-up.

    When state_db is rolled back, migration 0006 copies balances from ledger_db.
    However, ledger_db may already be ahead (reparsing after its own rollback).
    This creates a race condition where balances reflect block X, but parsed_events
    only go up to block Y < X. When catch_up processes events from Y to X,
    CREDIT/DEBIT events get applied twice.

    By recording the ledger_db block index at the time of the copy, we can skip
    CREDIT/DEBIT events that are already reflected in the copied balances.
    """
    cursor = state_db.cursor()

    # Check if ledger_db is already attached (migration 0006 may have attached it)
    already_attached = (
        cursor.execute(
            "SELECT COUNT(*) AS count FROM pragma_database_list WHERE name = ?", ("ledger_db",)
        ).fetchone()["count"]
        > 0
    )

    if not already_attached:
        cursor.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    result = cursor.execute("""
        SELECT MAX(block_index) as block_index 
        FROM ledger_db.messages 
        WHERE event = 'BLOCK_PARSED'
    """).fetchone()

    if not already_attached:
        cursor.execute("DETACH DATABASE ledger_db")

    if result and result["block_index"]:
        database.set_config_value(state_db, "BALANCES_COPIED_AT_BLOCK", str(result["block_index"]))
        logger.debug(
            "Recorded balances copied at block %s to prevent double-counting",
            result["block_index"],
        )


def rollback_state_db(state_db, block_index):
    logger.info("Rolling back State DB to block index %s...", block_index)
    start_time = time.time()

    with state_db:
        with log.Spinner("Rolling back State DB tables..."):
            rollback_tables(state_db, block_index)
        with log.Spinner("Re-applying migrations..."):
            reapply_migrations(state_db, MIGRATIONS_AFTER_ROLLBACK)
        # Record the ledger_db block index to prevent double-counting of balances
        # during catch-up (see record_balances_copied_block docstring for details)
        record_balances_copied_block(state_db)

    logger.info("State DB rolled back in %.2f seconds", time.time() - start_time)


def refresh_state_db(state_db):
    logger.info("Rebuilding non rollbackable tables in State DB...")
    start_time = time.time()

    with state_db:
        with log.Spinner("Re-applying migrations..."):
            reapply_migrations(state_db, MIGRATIONS_AFTER_ROLLBACK)
        # Record the ledger_db block index to prevent double-counting of balances
        # during catch-up (see record_balances_copied_block docstring for details)
        record_balances_copied_block(state_db)

    logger.info("State DB refreshed in %.2f seconds", time.time() - start_time)
