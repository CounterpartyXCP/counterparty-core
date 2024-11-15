import logging
import os
import shutil
import time

from counterpartycore.lib import config, database, log
from yoyo import get_backend, read_migrations
from yoyo.exceptions import LockTimeout

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))
MIGRATIONS_DIR = os.path.join(CURRENT_DIR, "migrations")

CONSOLIDATED_TABLES = {
    "fairminters": "tx_hash",
    "balances": "address, asset",
    "addresses": "address",
    "dispensers": "source, asset",
    "bet_matches": "id",
    "bets": "tx_hash",
    "order_matches": "id",
    "orders": "tx_hash",
    "rps": "tx_hash",
    "rps_matches": "id",
}

EXPIRATION_TABLES = {
    "order_expirations": "order_hash",
    "order_match_expirations": "order_match_id",
    "bet_expirations": "bet_hash",
    "bet_match_expirations": "bet_match_id",
    "rps_expirations": "rps_hash",
    "rps_match_expirations": "rps_match_id",
}

REGULAR_TABLES = [
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
] + list(EXPIRATION_TABLES.keys())

ROLLBACKABLE_TABLES = REGULAR_TABLES + [
    "all_expirations",
    "address_events",
]

NON_ROLLBACKABLE_TABLES = list(CONSOLIDATED_TABLES.keys()) + [
    "assets_info",
    "events_count",
]


def copy_ledger_db():
    if os.path.exists(config.STATE_DATABASE):
        os.unlink(config.STATE_DATABASE)
    if os.path.exists(config.STATE_DATABASE + "-wal"):
        os.unlink(config.STATE_DATABASE + "-wal")
    if os.path.exists(config.STATE_DATABASE + "-shm"):
        os.unlink(config.STATE_DATABASE + "-shm")

    # ensure the database is closed an no wall file is present
    ledger_db = database.get_db_connection(config.DATABASE, read_only=False, check_wal=True)
    ledger_db.close()

    shutil.copyfile(config.DATABASE, config.STATE_DATABASE)
    if os.path.exists(config.DATABASE + "-wal"):
        shutil.copyfile(config.DATABASE + "-wal", config.STATE_DATABASE + "-wal")
    if os.path.exists(config.DATABASE + "-shm"):
        shutil.copyfile(config.DATABASE + "-shm", config.STATE_DATABASE + "-shm")


def apply_migration():
    # Apply migrations
    backend = get_backend(f"sqlite:///{config.STATE_DATABASE}")
    migrations = read_migrations(MIGRATIONS_DIR)
    try:
        with backend.lock():
            # Apply any outstanding migrations
            backend.apply_migrations(backend.to_apply(migrations), force=False)
    except LockTimeout:
        logger.info("API Watcher - Migration lock timeout. Breaking lock and retrying...")
        backend.break_lock()
        backend.apply_migrations(backend.to_apply(migrations))
    backend.connection.close()


def build_consolidated_table(state_db, table_name):
    logger.info(f"Copying consolidated table `{table_name}` to state db")
    start_time = time.time()

    state_db.execute(f"DELETE FROM {table_name}")  # noqa S608

    columns = [column["name"] for column in state_db.execute(f"PRAGMA table_info({table_name})")]

    if table_name in ["fairminters"]:
        for field in ["earned_quantity", "commission", "paid_quantity"]:
            columns = [f"NULL AS {x}" if x == field else x for x in columns]

    select_fields = ", ".join(columns)

    sql = f"""
        INSERT INTO {table_name} 
            SELECT {select_fields} FROM (
                SELECT *, MAX(rowid) as rowid FROM ledger_db.{table_name}
                GROUP BY {CONSOLIDATED_TABLES[table_name]}
            )
    """  # noqa S608
    state_db.execute(sql)
    logger.info(f"Consolidated table `{table_name}` copied in {time.time() - start_time} seconds")


def copy_tables_from_ledger_db():
    state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)

    state_db.execute("""PRAGMA foreign_keys=OFF""")
    state_db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    for table in CONSOLIDATED_TABLES.keys():
        build_consolidated_table(state_db, table)

    state_db.execute("DETACH DATABASE ledger_db")
    state_db.execute("""PRAGMA foreign_keys=ON""")
    state_db.close()


def rollback_tables(block_index):
    logger.info(f"Delete tables to block index {block_index}")
    start_time = time.time()

    state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
    state_db.execute("""PRAGMA foreign_keys=OFF""")

    for table in ROLLBACKABLE_TABLES:
        state_db.execute(f"DELETE FROM {table} WHERE block_index >= ?", (block_index,))  # noqa S608

    for table in NON_ROLLBACKABLE_TABLES:
        state_db.execute(f"DELETE FROM {table}")  # noqa S608

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
    with log.Spinner("Copying tables from ledger db"):
        copy_tables_from_ledger_db()

    logger.info(f"State db built in {time.time() - start_time} seconds")


def rollback_state_db(block_index):
    logger.info(f"Rolling back state db to block index {block_index}")
    start_time = time.time()

    rollback_tables(block_index)
    apply_migration()
    copy_tables_from_ledger_db()

    logger.info(f"State db rolled back in {time.time() - start_time} seconds")
