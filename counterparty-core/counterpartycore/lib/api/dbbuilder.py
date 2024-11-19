import logging
import os
import time

from counterpartycore.lib import config, database, log
from yoyo import get_backend, read_migrations
from yoyo.migrations import topological_sort

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))
MIGRATIONS_DIR = os.path.join(CURRENT_DIR, "migrations")

MIGRATIONS_AFTER_ROLLBACK = [
    "0004.create_and_populate_assets_info",
    "0005.create_and_populate_events_count",
    "0006.create_and_populate_consolidated_tables",
    "0007.create_views",
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


def create_state_db():
    for ext in ["", "-wal", "-shm"]:
        if os.path.exists(config.STATE_DATABASE + ext):
            os.unlink(config.STATE_DATABASE + ext)

    # create empty state db
    state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
    state_db.close()


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
        for migration in reversed(migrations):
            backend.rollback_one(migration)
        for migration in migrations:
            backend.apply_one(migration)

    backend.connection.close()


def build_state_db():
    logger.info("Building State DB...")
    start_time = time.time()

    with log.Spinner("Creating State DB..."):
        create_state_db()
    with log.Spinner("Applying database migrations..."):
        apply_all_migrations()

    # Set initial database version
    state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
    database.update_version(state_db)

    logger.info(f"Built State DB in {time.time() - start_time:.2f} seconds")


def rollback_state_db(state_db):
    logger.info("Rolling back state db...")
    start_time = time.time()

    with log.Spinner("Applying migrations"):
        reapply_migrations(MIGRATIONS_AFTER_ROLLBACK)

    logger.info(f"Rolled back State DB in {time.time() - start_time:.2f} seconds")
