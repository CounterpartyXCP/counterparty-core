import logging
import os
import shutil
import time

from counterpartycore.lib import config, database
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

TABLES = [
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
    "bet_match_resolutions",
    "order_expirations",
    "order_match_expirations",
    "bet_expirations",
    "bet_match_expirations",
    "rps_expirations",
    "rps_match_expirations",
    "messages",
]

ADDITIONAL_FIELDS = {
    "fairminters": ["earned_quantity INTEGER", "paid_quantity INTEGER", "commission INTEGER"],
    "issuances": ["asset_events TEXT"],
    "dispenses": ["btc_amount TEXT"],
}


def copy_ledger_db(state_db_path):
    if os.path.exists(state_db_path):
        os.unlink(state_db_path)
    if os.path.exists(state_db_path + "-wal"):
        os.unlink(state_db_path + "-wal")
    if os.path.exists(state_db_path + "-shm"):
        os.unlink(state_db_path + "-shm")

    start_time = time.time()
    logger.info("Copying ledger database to state database")

    # ensure the database is closed an no wall file is present
    ledger_db = database.get_db_connection(config.DATABASE, read_only=False, check_wal=True)
    ledger_db.close()

    shutil.copyfile(config.DATABASE, state_db_path)
    if os.path.exists(config.DATABASE + "-wal"):
        shutil.copyfile(config.DATABASE + "-wal", state_db_path + "-wal")
    if os.path.exists(config.DATABASE + "-shm"):
        shutil.copyfile(config.DATABASE + "-shm", state_db_path + "-shm")

    logger.info(f"Ledger database copied in {time.time() - start_time} seconds")


def pre_migration(state_db_path):
    # Add additional fields to tables already in the state db
    state_db = database.get_db_connection(state_db_path, read_only=False)
    state_db.execute("""PRAGMA foreign_keys=OFF""")
    state_db.execute("DROP VIEW IF EXISTS all_expirations")
    for table, fields in ADDITIONAL_FIELDS.items():
        for field in fields:
            state_db.execute(f"ALTER TABLE {table} ADD COLUMN {field}")  # noqa S608
    state_db.execute("""PRAGMA foreign_keys=OFF""")
    state_db.close()


def apply_migration(state_db_path):
    logger.info("Applying migrations...")
    start_time = time.time()

    pre_migration(state_db_path)

    # Apply migrations
    backend = get_backend(f"sqlite:///{state_db_path}")
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
    logger.info(f"Copying consolidated table {table_name} to state db")
    start_time = time.time()

    state_db.execute(f"DELETE FROM {table_name}")  # noqa S608
    database.unlock_update(state_db, table_name)

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
    logger.info(f"Consolidated table {table_name} copied in {time.time() - start_time} seconds")


def copy_tables_from_ledger_db(state_db_path):
    state_db = database.get_db_connection(state_db_path, read_only=False)

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
    logger.info("Building all_expirations table")
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

    logger.info(f"All_expirations table built in {time.time() - start_time} seconds")


def build_assets_info_table(state_db):
    logger.info("Building assets_info table")
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

    logger.info(f"Assets_info table built in {time.time() - start_time} seconds")


def update_issuances(state_db):
    logger.info("Updating issuances table")
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
    logger.info(f"Issuances table updated in {time.time() - start_time} seconds")


def update_dispenses_table(state_db):
    logger.info("Updating dispenses table")
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
    logger.info(f"Dispenses table updated in {time.time() - start_time} seconds")


def build_state_tables(state_db_path):
    logger.info("Building state tables")
    start_time = time.time()

    state_db = database.get_db_connection(state_db_path, read_only=False)
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


def build_state_db():
    logger.info("Building state db")
    start_time = time.time()

    state_db_path = config.API_DATABASE.replace("api.", "state.")

    copy_ledger_db(state_db_path)
    apply_migration(state_db_path)
    copy_tables_from_ledger_db(state_db_path)
    build_state_tables(state_db_path)

    logger.info(f"State db built in {time.time() - start_time} seconds")
