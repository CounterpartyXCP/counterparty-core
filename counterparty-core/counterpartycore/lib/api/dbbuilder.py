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

LEDGER_TABLES = list(CONSOLIDATED_TABLES.keys()) + REGULAR_TABLES

ADDITIONAL_FIELDS = {
    "fairminters": ["earned_quantity INTEGER", "paid_quantity INTEGER", "commission INTEGER"],
    "issuances": ["asset_events TEXT"],
    "dispenses": ["btc_amount TEXT"],
}


def copy_ledger_db():
    if os.path.exists(config.STATE_DATABASE):
        os.unlink(config.STATE_DATABASE)
    if os.path.exists(config.STATE_DATABASE + "-wal"):
        os.unlink(config.STATE_DATABASE + "-wal")
    if os.path.exists(config.STATE_DATABASE + "-shm"):
        os.unlink(config.STATE_DATABASE + "-shm")

    start_time = time.time()
    logger.info("Copying ledger database to state database")

    # ensure the database is closed an no wall file is present
    ledger_db = database.get_db_connection(config.DATABASE, read_only=False, check_wal=True)
    ledger_db.close()

    shutil.copyfile(config.DATABASE, config.STATE_DATABASE)
    if os.path.exists(config.DATABASE + "-wal"):
        shutil.copyfile(config.DATABASE + "-wal", config.STATE_DATABASE + "-wal")
    if os.path.exists(config.DATABASE + "-shm"):
        shutil.copyfile(config.DATABASE + "-shm", config.STATE_DATABASE + "-shm")

    logger.info(f"Ledger database copied in {time.time() - start_time} seconds")


def pre_migration():
    # Add additional fields to tables already in the state db
    state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
    state_db.execute("""PRAGMA foreign_keys=OFF""")
    for table_name in LEDGER_TABLES:
        database.unlock_update(state_db, table_name)
    state_db.execute("DROP VIEW all_expirations")
    for table, fields in ADDITIONAL_FIELDS.items():
        for field in fields:
            state_db.execute(f"ALTER TABLE {table} ADD COLUMN {field}")  # noqa S608
    state_db.execute("""PRAGMA foreign_keys=OFF""")
    state_db.close()


def apply_migration():
    logger.info("Applying migrations...")
    start_time = time.time()
    # Apply migrations
    backend = get_backend(f"sqlite:///{config.STATE_DATABASE}")
    migrations = read_migrations(MIGRATIONS_DIR)
    try:
        with backend.lock():
            # Apply any outstanding migrations
            backend.apply_migrations(backend.to_apply(migrations), force=True)
    except LockTimeout:
        logger.info("API Watcher - Migration lock timeout. Breaking lock and retrying...")
        backend.break_lock()
        backend.apply_migrations(backend.to_apply(migrations))
    backend.connection.close()

    logger.info(f"Migrations applied in {time.time() - start_time} seconds")


def copy_consolidated_table(state_db, table_name):
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
        copy_consolidated_table(state_db, table)

    state_db.execute("DETACH DATABASE ledger_db")
    state_db.execute("""PRAGMA foreign_keys=ON""")
    state_db.close()


def gen_select_from_bindings(field_name, as_field=None):
    delta = len(field_name) + 4
    select = f"""
        substr(
            bindings, 
            instr(bindings, '"{field_name}":') + {delta}, 
            instr(substr(bindings, instr(bindings, '"{field_name}":') + {delta}), '"') - 1
        )
    """
    if as_field:
        select = f"{select} AS {as_field}"
    return select


def build_all_expirations_table(state_db):
    logger.info("Building `all_expirations` table")
    start_time = time.time()

    for table_name, object_id in EXPIRATION_TABLES.items():
        object_id_field = f"{object_id} AS object_id"
        object_type = table_name.replace("_expirations", "")
        object_type_field = f"'{object_type}' AS type"

        sql = f"""
            INSERT INTO all_expirations (object_id, block_index, type)
            SELECT {object_id_field}, block_index, {object_type_field}
            FROM {table_name}
        """  # noqa S608
        state_db.execute(sql)

    logger.info(f"`all_expirations` table built in {time.time() - start_time} seconds")


def build_assets_info_table(state_db):
    logger.info("Building `assets_info` table")
    start_time = time.time()

    sql = """
        INSERT INTO assets_info (asset, asset_id, asset_longname, first_issuance_block_index)
        SELECT asset_name AS asset, asset_id, asset_longname, block_index AS first_issuance_block_index
        FROM assets
    """
    state_db.execute(sql)

    sql = """
        UPDATE assets_info SET 
            divisible = (
                SELECT divisible FROM (
                    SELECT issuances.divisible AS divisible, issuances.rowid
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    ORDER BY issuances.rowid DESC
                    LIMIT 1
                )
            ),
            description = (
                SELECT description FROM (
                    SELECT issuances.description AS description, issuances.rowid
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    ORDER BY issuances.rowid DESC
                    LIMIT 1
                )
            ),
            owner = (
                SELECT issuer FROM (
                    SELECT issuances.issuer AS issuer, issuances.rowid
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    ORDER BY issuances.rowid DESC
                    LIMIT 1
                )
            ),
            last_issuance_block_index = (
                SELECT block_index FROM (
                    SELECT issuances.block_index AS block_index, issuances.rowid
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    ORDER BY issuances.rowid DESC
                    LIMIT 1
                )
            ),
            issuer = (
                SELECT issuer FROM (
                    SELECT issuances.issuer AS issuer, issuances.rowid
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    ORDER BY issuances.rowid ASC
                    LIMIT 1
                )
            ),
            supply = (
                SELECT supply FROM (
                    SELECT SUM(issuances.quantity) AS supply, issuances.asset
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    GROUP BY issuances.asset
                )
            ) - (
                SELECT quantity FROM (
                    SELECT SUM(destructions.quantity) AS quantity, destructions.asset
                    FROM destructions
                    WHERE assets_info.asset = destructions.asset AND status = 'valid'
                    GROUP BY destructions.asset
                )
            ),
            locked = (
                SELECT locked FROM (
                    SELECT SUM(issuances.locked) AS locked, issuances.asset
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    GROUP BY issuances.asset
                )
            );
    """
    state_db.execute(sql)

    logger.info(f"`assets_info` table built in {time.time() - start_time} seconds")


def rebuild_assets_info_table():
    state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
    state_db.execute("""PRAGMA foreign_keys=OFF""")
    build_assets_info_table(state_db)
    state_db.execute("""PRAGMA foreign_keys=ON""")
    state_db.close()


def update_issuances(state_db):
    logger.info("Updating `issuances` table")
    start_time = time.time()

    sql = f"""
        UPDATE issuances SET 
            asset_events = (
                SELECT
                {gen_select_from_bindings("asset_events")}
                FROM messages
                WHERE messages.tx_hash = issuances.tx_hash
            );
    """  # noqa S608
    state_db.execute(sql)
    logger.info(f"`issuances` table updated in {time.time() - start_time} seconds")


def update_dispenses_table(state_db):
    logger.info("Updating `dispenses` table")
    start_time = time.time()

    sql = """
        UPDATE dispenses SET 
            btc_amount = (
                SELECT
                CAST (
                    substr(bindings, instr(bindings, '"btc_amount":') + 13, instr(substr(bindings, instr(bindings, '"btc_amount":') + 13), ',') - 1)
                    AS INTEGER
                )
                FROM messages
                WHERE messages.tx_hash = dispenses.tx_hash
            );
    """
    state_db.execute(sql)
    logger.info(f"`dispenses` table updated in {time.time() - start_time} seconds")


def build_state_tables():
    logger.info("Building state tables")
    start_time = time.time()

    state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
    state_db.execute("""PRAGMA foreign_keys=OFF""")

    build_all_expirations_table(state_db)
    build_assets_info_table(state_db)
    update_issuances(state_db)
    update_dispenses_table(state_db)
    # build_events_count_table(state_db)
    # build_address_events_table(state_db)
    # update_fairminters_table(state_db)
    state_db.execute("""PRAGMA foreign_keys=ON""")
    state_db.close()

    logger.info(f"State tables built in {time.time() - start_time} seconds")


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
        pre_migration()
        apply_migration()
    with log.Spinner("Copying tables from ledger db"):
        copy_tables_from_ledger_db()
    with log.Spinner("Building state tables"):
        build_state_tables()

    logger.info(f"State db built in {time.time() - start_time} seconds")


def rollback_state_db(block_index):
    logger.info(f"Rolling back state db to block index {block_index}")
    start_time = time.time()

    rollback_tables(config.STATE_DATABASE, block_index)
    apply_migration(config.STATE_DATABASE)
    copy_tables_from_ledger_db(config.STATE_DATABASE)
    rebuild_assets_info_table(config.STATE_DATABASE)

    logger.info(f"State db rolled back in {time.time() - start_time} seconds")
