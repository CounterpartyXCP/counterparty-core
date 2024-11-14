import logging
import os
import shutil
import tempfile
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

EVENTS_ADDRESS_FIELDS = {
    "NEW_TRANSACTION": ["source", "destination"],
    "DEBIT": ["address"],
    "CREDIT": ["address"],
    "ENHANCED_SEND": ["source", "destination"],
    "MPMA_SEND": ["source", "destination"],
    "SEND": ["source", "destination"],
    "ASSET_TRANSFER": ["source", "issuer"],
    "SWEEP": ["source", "destination"],
    "ASSET_DIVIDEND": ["source"],
    "RESET_ISSUANCE": ["source", "issuer"],
    "ASSET_ISSUANCE": ["source", "issuer"],
    "ASSET_DESTRUCTION": ["source"],
    "OPEN_ORDER": ["source"],
    "ORDER_MATCH": ["tx0_address", "tx1_address"],
    "BTC_PAY": ["source", "destination"],
    "CANCEL_ORDER": ["source"],
    "ORDER_EXPIRATION": ["source"],
    "ORDER_MATCH_EXPIRATION": ["tx0_address", "tx1_address"],
    "OPEN_DISPENSER": ["source", "origin", "oracle_address"],
    "DISPENSER_UPDATE": ["source"],
    "REFILL_DISPENSER": ["source", "destination"],
    "DISPENSE": ["source", "destination"],
    "BROADCAST": ["source"],
    "BURN": ["source"],
    "NEW_FAIRMINT": ["source"],
    "NEW_FAIRMINTER": ["source"],
}


def apply_migration(db_path):
    logger.debug("Applying migrations...")
    # Apply migrations
    backend = get_backend(f"sqlite:///{db_path}")
    migrations = read_migrations(MIGRATIONS_DIR)
    try:
        with backend.lock():
            # Apply any outstanding migrations
            backend.apply_migrations(backend.to_apply(migrations), force=True)
    except LockTimeout:
        logger.debug("API Watcher - Migration lock timeout. Breaking lock and retrying...")
        backend.break_lock()
        backend.apply_migrations(backend.to_apply(migrations))
    backend.connection.close()


def initialize_state_db():
    state_db_path = config.API_DATABASE.replace("api.", "state.")
    if os.path.exists(state_db_path):
        os.unlink(state_db_path)
    if os.path.exists(state_db_path + "-wal"):
        os.unlink(state_db_path + "-wal")
    if os.path.exists(state_db_path + "-shm"):
        os.unlink(state_db_path + "-shm")

    start_time = time.time()
    logger.debug("Copying ledger database to state database")

    shutil.copyfile(config.DATABASE, state_db_path)
    state_db = database.get_db_connection(state_db_path, read_only=False)

    logger.debug(f"Ledger database copied in {time.time() - start_time} seconds")

    start_time = time.time()
    logger.debug("Cleaning state database")

    state_db.execute("""PRAGMA foreign_keys=OFF""")
    for table in CONSOLIDATED_TABLES.keys():
        state_db.execute(f"DELETE FROM {table}")  # noqa S608
    for table in list(EXPIRATION_TABLES.keys()) + TABLES:
        database.unlock_update(state_db, table)
    state_db.execute("DROP VIEW IF EXISTS all_expirations")
    state_db.execute("ALTER TABLE fairminters ADD COLUMN earned_quantity INTEGER")
    state_db.execute("ALTER TABLE fairminters ADD COLUMN paid_quantity INTEGER")
    state_db.execute("ALTER TABLE fairminters ADD COLUMN commission INTEGER")
    state_db.execute("ALTER TABLE issuances ADD COLUMN asset_events TEXT")
    state_db.execute("ALTER TABLE dispenses ADD COLUMN btc_amount TEXT")
    state_db.execute("""PRAGMA foreign_keys=ON""")
    state_db.close()

    logger.debug(f"Database cleaned in {time.time() - start_time} seconds")

    apply_migration(state_db_path)

    state_db = database.get_db_connection(state_db_path, read_only=False)

    return state_db


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

    queries = []
    for event, fields in EVENTS_ADDRESS_FIELDS.items():
        for field in fields:
            sql = f"""
                SELECT 
                    {gen_select_from_bindings(field, "address")},
                    message_index AS event_index
                FROM messages
                WHERE event = '{event}'
            """  # noqa S608
            queries.append(sql)

    sql = f"""
        INSERT INTO address_events (address, event_index)
        SELECT * FROM ({' UNION ALL'.join(queries)})
    """  # noqa S608

    state_db.execute(sql)

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
    # for table in TABLES:
    #    copy_table(state_db, table)
    finish_building_state_db(state_db)

    state_db.execute("DETACH DATABASE ledger_db")
    state_db.execute("""PRAGMA foreign_keys=ON""")

    if use_memory_db:
        save_memory_db(state_db)

    logger.debug(f"State db built in {time.time() - start_time} seconds")
