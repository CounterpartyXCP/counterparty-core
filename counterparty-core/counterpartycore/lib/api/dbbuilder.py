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

MIGRATIONS_AFTER_ROLLBACK = [
    "0003.populate_assets_info",
    "0004.populate_events_count",
    "0005.populate_consolidated_tables",
    "0006.populate_fairminters_counters",
]


def copy_ledger_db():
    for ext in ["", "-wal", "-shm"]:
        if os.path.exists(config.STATE_DATABASE + ext):
            os.unlink(config.STATE_DATABASE + ext)

    # ensure the database is closed an no wall file is present
    ledger_db = database.get_db_connection(config.DATABASE, read_only=False, check_wal=True)
    ledger_db.close()

    for ext in ["", "-wal", "-shm"]:
        if os.path.exists(config.DATABASE + ext):
            shutil.copyfile(config.DATABASE + ext, config.STATE_DATABASE + ext)


def filter_migrations(migrations, wanted_ids):
    filtered_migrations = (m for m in migrations if m.id in wanted_ids)
    return migrations.__class__(topological_sort(filtered_migrations), migrations.post_apply)


def apply_migration(migration_ids=None):
    backend = get_backend(f"sqlite:///{config.STATE_DATABASE}")

    migrations = read_migrations(MIGRATIONS_DIR)
    if migration_ids is not None:
        migrations = filter_migrations(migrations, migration_ids)

    # Apply migrations
    with backend.lock():
        backend.apply_migrations(migrations, force=False)

    backend.connection.close()


def rollback_tables(block_index):
    logger.info(f"Delete tables to block index {block_index}")
    start_time = time.time()

    state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
    state_db.execute("""PRAGMA foreign_keys=OFF""")

    for table in ROLLBACKABLE_TABLES:
        state_db.execute(f"DELETE FROM {table} WHERE block_index >= ?", (block_index,))  # noqa S608

    state_db.execute("""PRAGMA foreign_keys=ON""")
    state_db.close()
    logger.info(f"Tables deleted in {time.time() - start_time} seconds")


def build_state_db():
    logger.info("Building state db")
    start_time = time.time()

    with log.Spinner("Copying ledger database to state database"):
        copy_ledger_db()
    with log.Spinner("Applying migrations"):
        apply_migration()

    logger.info(f"State db built in {time.time() - start_time} seconds")


def rollback_state_db(block_index):
    logger.info(f"Rolling back state db to block index {block_index}")
    start_time = time.time()

    rollback_tables(block_index)
    apply_migration(MIGRATIONS_AFTER_ROLLBACK)

    logger.info(f"State db rolled back in {time.time() - start_time} seconds")
