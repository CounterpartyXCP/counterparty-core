import logging
import os
import tempfile
import time

from counterpartycore.lib import config, database
from counterpartycore.lib.api import api_watcher
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


def apply_migration(db_path):
    logger.debug("Applying migrations...")
    # Apply migrations
    backend = get_backend(f"sqlite:///{db_path}")
    migrations = read_migrations(MIGRATIONS_DIR)
    try:
        with backend.lock():
            # Apply any outstanding migrations
            backend.apply_migrations(backend.to_apply(migrations))
    except LockTimeout:
        logger.debug("API Watcher - Migration lock timeout. Breaking lock and retrying...")
        backend.break_lock()
        backend.apply_migrations(backend.to_apply(migrations))
    backend.connection.close()


def initialize_state_db():
    destination_path = config.API_DATABASE.replace("api.", "state.")
    if os.path.exists(destination_path):
        os.unlink(destination_path)
    apply_migration(destination_path)
    destination_db = database.get_db_connection(destination_path, read_only=False)

    return destination_db


def initialize_memory_state_db():
    temp_db_path = os.path.join(tempfile.gettempdir(), "counterparty_state.db")
    if os.path.exists(temp_db_path):
        os.unlink(temp_db_path)
    apply_migration(temp_db_path)
    temp_db = database.get_db_connection(temp_db_path, read_only=False)

    memory_db = database.get_db_connection(":memory:", read_only=False)
    with memory_db.backup("main", temp_db, "main") as backup:
        while not backup.done:
            backup.step(50)

    temp_db.close()
    os.unlink(temp_db_path)

    return memory_db


def save_memory_db(memory_db):
    logger.debug("Saving memory db to disk")
    start_time = time.time()

    # We will copy a disk database into this memory database
    destination_path = config.API_DATABASE.replace("api.", "state.")
    if os.path.exists(destination_path):
        os.unlink(destination_path)
    destination = database.get_db_connection(destination_path, read_only=False)

    # Copy into destination
    with destination.backup("main", memory_db, "main") as backup:
        # The source database can change while doing the backup
        # and the backup will still pick up those changes
        while not backup.done:
            backup.step(50)  # copy up to 50 pages each time
            # monitor progress
            # print(backup.remaining, backup.page_count)

    logger.debug(f"Memory db saved to disk in {time.time() - start_time} seconds")


def copy_table(state_db, table_name):
    logger.debug(f"Copying table {table_name} to state db")
    start_time = time.time()
    columns = [column["name"] for column in state_db.execute(f"PRAGMA table_info({table_name})")]

    if table_name == "issuances":
        columns = [f"NULL AS {x}" if x == "asset_events" else x for x in columns]
    elif table_name == "dispenses":
        columns = [f"NULL AS {x}" if x == "btc_amount" else x for x in columns]
    elif table_name == "messages":
        for field in ["previous_state", "insert_rowid"]:
            columns = [f"NULL AS {x}" if x == field else x for x in columns]

    select_fields = ", ".join(columns)

    state_db.execute(f"INSERT INTO {table_name} SELECT {select_fields} FROM ledger_db.{table_name}")  # noqa S608
    logger.debug(f"Table {table_name} copied in {time.time() - start_time} seconds")


def copy_consolidated_table(state_db, table_name):
    logger.debug(f"Copying consolidated table {table_name} to state db")
    start_time = time.time()

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
    logger.debug(f"Consolidated table {table_name} copied in {time.time() - start_time} seconds")


def build_events_count_table(state_db):
    logger.debug("Building events_count table")
    start_time = time.time()

    sql = """
        INSERT INTO events_count (event, count)
        SELECT event, COUNT(*) AS counter
        FROM messages
        GROUP BY event;
    """
    state_db.execute(sql)
    logger.debug(f"Events_count table built in {time.time() - start_time} seconds")


def build_all_expirations_table(state_db):
    logger.debug("Building all_expirations table")
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

    logger.debug(f"All_expirations table built in {time.time() - start_time} seconds")


def build_address_events_table(state_db):
    logger.debug("Building address_events table")
    start_time = time.time()

    event_count = state_db.execute("SELECT COUNT(*) AS count FROM messages").fetchone()["count"]
    parsed_event = 0

    sql = "SELECT * FROM messages ORDER BY message_index"
    cursor = state_db.cursor()
    cursor.execute(sql)
    for event in cursor:
        api_watcher.update_address_events(state_db, event)
        parsed_event += 1
        if parsed_event % 250000 == 0:
            logger.debug(f"{parsed_event} of {event_count} events processed")

    logger.debug(f"Address_events table built in {time.time() - start_time} seconds")


def build_assets_info_table(state_db):
    logger.debug("Building assets_info table")
    start_time = time.time()

    sql = """
        INSERT INTO assets_info (asset, asset_id, asset_longname, first_issuance_block_index)
        SELECT asset, asset_id, asset_longname, block_index AS first_issuance_block_index
        FROM assets
    """
    state_db.execute(sql)

    sql = """
        UPDATE assets_info SET 
            divisible = (
                SELECT divisible 
                FROM issuances 
                WHERE assets_info.asset = issuances.asset AND status = 'valid'
                ORDER BY rowid DESC
                LIMIT 1
            ),
            description = (
                SELECT description 
                FROM issuances 
                WHERE assets_info.asset = issuances.asset AND status = 'valid'
                ORDER BY rowid DESC
                LIMIT 1
            ),
            owner = (
                SELECT issuer 
                FROM issuances 
                WHERE assets_info.asset = issuances.asset AND status = 'valid'
                ORDER BY rowid DESC
                LIMIT 1
            ),
            last_issuance_block_index = (
                SELECT block_index 
                FROM issuances 
                WHERE assets_info.asset = issuances.asset AND status = 'valid'
                ORDER BY rowid DESC
                LIMIT 1
            ),
            issuer = (
                SELECT issuer 
                FROM issuances 
                WHERE assets_info.asset = issuances.asset AND status = 'valid'
                ORDER BY rowid ASC
                LIMIT 1
            ),
            supply = (
                SELECT SUM(quantity)
                FROM issuances
                WHERE assets_info.asset = issuances.asset AND status = 'valid'
                GROUP BY assets_info.asset
            ) - (
                SELECT SUM(quantity)
                FROM destructions
                WHERE assets_info.asset = issuances.asset AND status = 'valid'
                GROUP BY asset
            ),
            locked = (
                SELECT MAXSUM(locked) 
                FROM issuances 
                WHERE assets_info.asset = issuances.asset AND status = 'valid'
                GROUP BY assets_info.asset
            )
    """
    state_db.execute(sql)

    logger.debug(f"Assets_info table built in {time.time() - start_time} seconds")


def update_fairminters_table(state_db):
    logger.debug("Updating fairminters table")
    start_time = time.time()

    sql = """
        UPDATE fairminters SET 
            earned_quantity = (
                SELECT SUM(earn_quantity) 
                FROM fairmints 
                WHERE fairmints.fairminter_tx_hash = fairminters.tx_hash
            ),
            paid_quantity = (
                SELECT SUM(paid_quantity) 
                FROM fairmints 
                WHERE fairmints.fairminter_tx_hash = fairminters.tx_hash
            ),
            commission = (
                SELECT SUM(commission) 
                FROM fairmints 
                WHERE fairmints.fairminter_tx_hash = fairminters.tx_hash
            );
    """
    state_db.execute(sql)
    logger.debug(f"Fairminters table updated in {time.time() - start_time} seconds")


def update_issuances(state_db):
    logger.debug("Updating issuances table")
    start_time = time.time()

    sql = """
        UPDATE issuances SET 
            asset_events = (
                SELECT
                substr(bindings, instr(bindings, '"asset_events":') + 16, instr(substr(bindings, instr(bindings, '"asset_events":') + 16), '"') - 1)
                FROM messages
                WHERE messages.tx_hash = issuances.tx_hash
            );
    """
    state_db.execute(sql)
    logger.debug(f"Issuances table updated in {time.time() - start_time} seconds")


def update_dispenses_table(state_db):
    logger.debug("Updating dispenses table")
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
    logger.debug(f"Dispenses table updated in {time.time() - start_time} seconds")


def finish_building_state_db(state_db):
    build_events_count_table(state_db)
    build_all_expirations_table(state_db)
    build_address_events_table(state_db)
    build_assets_info_table(state_db)
    update_issuances(state_db)
    update_fairminters_table(state_db)
    update_dispenses_table(state_db)


def build_state_db(use_memory_db=False):
    logger.debug("Building state db")
    start_time = time.time()

    state_db = initialize_state_db()
    if use_memory_db:
        state_db = initialize_memory_state_db()
    else:
        state_db = initialize_state_db()

    state_db.execute("""PRAGMA foreign_keys=OFF""")
    state_db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    for table in CONSOLIDATED_TABLES:
        copy_consolidated_table(state_db, table)
    for table in TABLES:
        copy_table(state_db, table)
    finish_building_state_db(state_db)

    state_db.execute("DETACH DATABASE ledger_db")
    state_db.execute("""PRAGMA foreign_keys=ON""")

    if use_memory_db:
        save_memory_db(state_db)

    logger.debug(f"State db built in {time.time() - start_time} seconds")
