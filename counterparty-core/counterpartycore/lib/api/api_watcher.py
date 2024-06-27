import json
import logging
import os
import time
from threading import Thread

from counterpartycore.lib import config, database, exceptions
from counterpartycore.lib.api import queries, util
from counterpartycore.lib.util import format_duration
from yoyo import get_backend, read_migrations

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))
MIGRATIONS_DIR = os.path.join(CURRENT_DIR, "migrations")

UPDATE_EVENTS_ID_FIELDS = {
    "BLOCK_PARSED": ["block_index"],
    "TRANSACTION_PARSED": ["tx_index"],
    "BET_MATCH_UPDATE": ["id"],
    "BET_UPDATE": ["tx_hash"],
    "DISPENSER_UPDATE": ["tx_hash"],
    "ORDER_FILLED": ["tx_hash"],
    "ORDER_MATCH_UPDATE": ["id"],
    "ORDER_UPDATE": ["tx_hash"],
    "RPS_MATCH_UPDATE": ["id"],
    "RPS_UPDATE": ["tx_hash"],
    "ADDRESS_OPTIONS_UPDATE": ["address"],
}

EXPIRATION_EVENTS_OBJECT_ID = {
    "ORDER_EXPIRATION": "order_hash",
    "ORDER_MATCH_EXPIRATION": "order_match_id",
    "RPS_EXPIRATION": "rps_hash",
    "RPS_MATCH_EXPIRATION": "rps_match_id",
    "BET_EXPIRATION": "bet_hash",
    "BET_MATCH_EXPIRATION": "bet_match_id",
}

ASSET_EVENTS = [
    "ASSET_CREATION",
    "ASSET_ISSUANCE",
    "ASSET_DESTRUCTION",
    "RESET_ISSUANCE",
    "ASSET_TRANSFER",
]


def fetch_all(db, query, bindings=None):
    cursor = db.cursor()
    cursor.execute(query, bindings)
    return cursor.fetchall()


def fetch_one(db, query, bindings=None):
    cursor = db.cursor()
    cursor.execute(query, bindings)
    return cursor.fetchone()


def delete_all(db, query, bindings=None):
    cursor = db.cursor()
    cursor.execute(query, bindings)
    changes = fetch_one(db, "SELECT changes() AS deleted")
    return changes["deleted"]


def get_last_parsed_message_index(api_db):
    sql = "SELECT * FROM messages ORDER BY message_index DESC LIMIT 1"
    last_event = fetch_one(api_db, sql)
    last_message_index = -1
    if last_event:
        last_message_index = last_event["message_index"]
    return last_message_index


def get_next_event_to_parse(api_db, ledger_db):
    last_parsed_message_index = get_last_parsed_message_index(api_db)
    sql = "SELECT * FROM messages WHERE message_index > ? ORDER BY message_index ASC LIMIT 1"
    # logger.warning(f"last_parsed_message_index: {last_parsed_message_index}")
    next_event = fetch_one(ledger_db, sql, (last_parsed_message_index,))
    # logger.warning(api_db.cursor().execute("SELECT * FROM messages ORDER BY message_index DESC LIMIT 1").fetchone())
    # logger.warning(ledger_db.cursor().execute("SELECT * FROM messages ORDER BY message_index DESC LIMIT 1").fetchone())
    return next_event


def get_event_to_parse_count(api_db, ledger_db):
    last_parsed_message_index = get_last_parsed_message_index(api_db)
    sql = "SELECT message_index FROM messages ORDER BY message_index DESC LIMIT 1"
    last_event = fetch_one(ledger_db, sql)
    return last_event["message_index"] - last_parsed_message_index


def get_event_bindings(event):
    event_bindings = json.loads(event["bindings"])
    if "order_match_id" in event_bindings:
        del event_bindings["order_match_id"]
    return event_bindings


def insert_event_to_sql(event):
    event_bindings = get_event_bindings(event)
    sql_bindings = []
    sql = f"INSERT INTO {event['category']} "
    names = []
    for key, value in event_bindings.items():
        names.append(key)
        sql_bindings.append(value)
    sql += f"({', '.join(names)}) VALUES ({', '.join(['?' for _ in names])})"
    return sql, sql_bindings


def update_event_to_sql(event):
    event_bindings = get_event_bindings(event)
    sql_bindings = []

    id_field_names = UPDATE_EVENTS_ID_FIELDS[event["event"]]

    sets = []
    for key, value in event_bindings.items():
        if key in id_field_names:
            continue
        sets.append(f"{key} = ?")
        sql_bindings.append(value)
    sets_clause = ", ".join(sets)

    where = []
    for id_field_name in id_field_names:
        where.append(f"{id_field_name} = ?")
        sql_bindings.append(event_bindings[id_field_name])
    where_clause = " AND ".join(where)

    sql = f"UPDATE {event['category']} SET {sets_clause} WHERE {where_clause}"  # noqa: S608

    return sql, sql_bindings


def event_to_sql(event):
    if event["command"] == "insert":
        return insert_event_to_sql(event)
    if event["command"] in ["update", "parse"]:
        return update_event_to_sql(event)
    return None, []


def get_event_previous_state(api_db, event):
    previous_state = None
    if event["command"] in ["update", "parse"]:
        id_field_names = UPDATE_EVENTS_ID_FIELDS[event["event"]]

        where = []
        for id_field_name in id_field_names:
            where.append(f"{id_field_name} = :{id_field_name}")
        where_clause = " AND ".join(where)

        sql = f"SELECT * FROM {event['category']} WHERE {where_clause}"  # noqa: S608
        event_bindings = json.loads(event["bindings"])
        previous_state = fetch_one(api_db, sql, event_bindings)
    return previous_state


def delete_event(api_db, event):
    sql = f"DELETE FROM {event['category']} WHERE rowid = ?"  # noqa: S608
    deleted = delete_all(api_db, sql, (event["insert_rowid"],))
    if deleted == 0:
        raise exceptions.APIWatcherError(f"Event not found: {event}")


def insert_event(api_db, event):
    previous_state = get_event_previous_state(api_db, event)
    if previous_state is not None:
        event["previous_state"] = util.to_json(previous_state)
    else:
        event["previous_state"] = None
    sql = """
        INSERT INTO messages 
            (message_index, block_index, event, category, command, bindings, tx_hash, previous_state, insert_rowid)
        VALUES (:message_index, :block_index, :event, :category, :command, :bindings, :tx_hash, :previous_state, :insert_rowid)
    """
    cursor = api_db.cursor()
    cursor.execute(sql, event)


def rollback_event(api_db, event):
    logger.debug(f"Rolling back event: {event}")
    if event["previous_state"] is None or event["previous_state"] == "null":
        delete_event(api_db, event)
        return
    previous_state = json.loads(event["previous_state"])

    id_field_names = UPDATE_EVENTS_ID_FIELDS[event["event"]]

    sets = []
    for key in previous_state.keys():
        if key in id_field_names:
            continue
        sets.append(f"{key} = :{key}")
    set_clause = ", ".join(sets)

    where = []
    for id_field_name in id_field_names:
        where.append(f"{id_field_name} = :{id_field_name}")
    where_clause = " AND ".join(where)

    sql = f"UPDATE {event['category']} SET {set_clause} WHERE {where_clause}"  # noqa: S608
    cursor = api_db.cursor()
    cursor.execute(sql, previous_state)

    if event["event"] in ["CREDIT", "DEBIT"]:
        revert_event = event.copy()
        revert_event["event"] = "DEBIT" if event["event"] == "CREDIT" else "CREDIT"
        update_balances(api_db, revert_event)

    sql = "DELETE FROM messages WHERE message_index = ?"
    cursor.execute(sql, (event["message_index"],))


def rollback_events(api_db, block_index):
    logger.info(f"Rolling back events to block {block_index}...")
    with api_db:
        cursor = api_db.cursor()
        sql = "SELECT * FROM messages WHERE block_index >= ? ORDER BY message_index DESC"
        cursor.execute(sql, (block_index,))
        for event in cursor:
            rollback_event(api_db, event)
        cursor.execute("DELETE FROM messages WHERE block_index >= ?", (block_index,))


def update_balances(api_db, event):
    if event["event"] not in ["DEBIT", "CREDIT"]:
        return

    cursor = api_db.cursor()

    event_bindings = get_event_bindings(event)
    quantity = event_bindings["quantity"]
    if event["event"] == "DEBIT":
        quantity = -quantity

    sql = "SELECT * FROM balances WHERE address = :address AND asset = :asset"
    existing_balance = fetch_one(api_db, sql, event_bindings)

    if existing_balance is not None:
        sql = """
            UPDATE balances
            SET quantity = quantity + :quantity
            WHERE address = :address AND asset = :asset
            """
    else:
        sql = """
            INSERT INTO balances (address, asset, quantity)
            VALUES (:address, :asset, :quantity)
            """
    insert_bindings = {
        "address": event_bindings["address"],
        "asset": event_bindings["asset"],
        "quantity": quantity,
    }
    cursor.execute(sql, insert_bindings)


def update_expiration(api_db, event):
    if event["event"] not in EXPIRATION_EVENTS_OBJECT_ID:
        return
    event_bindings = json.loads(event["bindings"])

    cursor = api_db.cursor()
    sql = """
        INSERT INTO all_expirations (object_id, block_index, type) 
        VALUES (:object_id, :block_index, :type)
        """
    bindings = {
        "object_id": event_bindings[EXPIRATION_EVENTS_OBJECT_ID[event["event"]]],
        "block_index": event_bindings["block_index"],
        "type": event["event"].replace("_EXPIRATION", "").lower(),
    }
    cursor.execute(sql, bindings)


def update_assets_info(api_db, event):
    if event["event"] not in ASSET_EVENTS:
        return
    event_bindings = json.loads(event["bindings"])

    if event["event"] == "ASSET_CREATION":
        sql = """
            INSERT INTO assets_info 
                (asset, asset_id, asset_longname, first_issuance_block_index) 
            VALUES 
                (:asset_name, :asset_id, :asset_longname, :block_index)
            """
        cursor = api_db.cursor()
        cursor.execute(sql, event_bindings)
        return

    if event["event"] in ["ASSET_ISSUANCE", "RESET_ISSUANCE"]:
        if event_bindings["status"] != "valid":
            return
        existing_asset = fetch_one(
            api_db,
            "SELECT * FROM assets_info WHERE asset = :asset",
            {"asset": event_bindings["asset"]},
        )
        set_data = []
        set_data.append("divisible = :divisible")
        set_data.append("description = :description")
        set_data.append("owner = :issuer")
        set_data.append("supply = supply + :quantity")
        set_data.append("last_issuance_block_index = :block_index")
        set_data.append("asset_longname = :asset_longname")
        if event_bindings["locked"]:
            set_data.append("locked = :locked")
        if not existing_asset["issuer"]:  # first issuance
            set_data.append("issuer = :issuer")
        set_data = ", ".join(set_data)

        sql = f"UPDATE assets_info SET {set_data} WHERE asset = :asset"  # noqa: S608
        cursor = api_db.cursor()
        cursor.execute(sql, event_bindings)
        return

    if event["event"] == "ASSET_DESTRUCTION":
        if event_bindings["status"] != "valid":
            return
        sql = """
            UPDATE assets_info 
            SET supply = supply - :quantity
            WHERE asset = :asset
            """
        cursor = api_db.cursor()
        cursor.execute(sql, event_bindings)
        return

    if event["event"] == "ASSET_TRANSFER":
        if event_bindings["status"] != "valid":
            return
        sql = """
            UPDATE assets_info 
            SET owner = :issuer
            WHERE asset = :asset
            """
        cursor = api_db.cursor()
        cursor.execute(sql, event_bindings)
        return


def execute_event(api_db, event):
    sql, sql_bindings = event_to_sql(event)
    if sql is not None:
        cursor = api_db.cursor()
        cursor.execute(sql, sql_bindings)
        if event["command"] == "insert":
            cursor.execute("SELECT last_insert_rowid() AS rowid")
            return cursor.fetchone()["rowid"]
    return None


def parse_event(api_db, event):
    with api_db:
        event["insert_rowid"] = execute_event(api_db, event)
        update_balances(api_db, event)
        update_expiration(api_db, event)
        update_assets_info(api_db, event)
        insert_event(api_db, event)
        logger.trace(f"API Watcher - Event parsed: {event['message_index']} {event['event']}")


def catch_up(api_db, ledger_db):
    event_to_parse_count = get_event_to_parse_count(api_db, ledger_db)
    if event_to_parse_count > 0:
        logger.info(f"API Watcher - {event_to_parse_count} events to catch up...")
        start_time = time.time()
        event_parsed = 0
        next_event = get_next_event_to_parse(api_db, ledger_db)
        while next_event:
            logger.trace(f"API Watcher - Parsing event: {next_event}")
            parse_event(api_db, next_event)
            event_parsed += 1
            if event_parsed % 10000 == 0:
                duration = time.time() - start_time
                expected_duration = duration / event_parsed * event_to_parse_count
                logger.info(
                    f"API Watcher - {event_parsed}/{event_to_parse_count} events parsed in {format_duration(duration)} (expected {format_duration(expected_duration)})"
                )
            next_event = get_next_event_to_parse(api_db, ledger_db)
        duration = time.time() - start_time
        logger.debug(f"API Watcher - {event_parsed} events parsed in {format_duration(duration)}")
    logger.info("API Watcher - Catch up completed.")


def apply_migration():
    logger.debug("API Watcher - Applying migrations...")
    # Apply migrations
    backend = get_backend(f"sqlite:///{config.API_DATABASE}")
    migrations = read_migrations(MIGRATIONS_DIR)
    with backend.lock():
        # Apply any outstanding migrations
        backend.apply_migrations(backend.to_apply(migrations))
    backend.connection.close()


def initialize_api_db(api_db, ledger_db):
    logger.info("API Watcher - Initializing API Database...")

    cursor = api_db.cursor()

    # Create XCP and BTC assets if they don't exist
    cursor.execute("""SELECT * FROM assets WHERE asset_name = ?""", ("BTC",))
    if not list(cursor):
        cursor.execute("""INSERT INTO assets VALUES (?,?,?,?)""", ("0", "BTC", None, None))
        cursor.execute("""INSERT INTO assets VALUES (?,?,?,?)""", ("1", "XCP", None, None))
    cursor.close()

    # check if rollback is needed
    last_ledger_block = queries.get_last_block(ledger_db)
    if last_ledger_block is not None:
        last_ledger_block = last_ledger_block.result
    last_api_block = queries.get_last_block(api_db)
    if last_api_block is not None:
        last_api_block = last_api_block.result

    if last_ledger_block is None and last_api_block is not None:
        rollback_events(api_db, 0)
    elif (
        last_api_block
        and last_ledger_block
        and last_api_block["block_index"] > last_ledger_block["block_index"]
    ):
        rollback_events(api_db, last_ledger_block["block_index"])


class APIWatcher(Thread):
    def __init__(self):
        Thread.__init__(self)
        logger.debug("Initializing API Watcher...")
        apply_migration()
        self.stopping = False
        self.stopped = False
        self.api_db = database.get_db_connection(
            config.API_DATABASE, read_only=False, check_wal=False
        )
        self.ledger_db = database.get_db_connection(
            config.DATABASE, read_only=True, check_wal=False
        )
        try:
            initialize_api_db(self.api_db, self.ledger_db)
        except KeyboardInterrupt:
            logger.debug("API Watcher - Keyboard interrupt")
            self.stopped = True
            self.api_db.close()
            self.ledger_db.close()

    def run(self):
        logger.info("Starting API Watcher...")
        catch_up(self.api_db, self.ledger_db)
        try:
            while True and not self.stopping and not self.stopped:
                next_event = get_next_event_to_parse(self.api_db, self.ledger_db)
                if next_event:
                    last_block = queries.get_last_block(self.api_db).result
                    if last_block and last_block["block_index"] > next_event["block_index"]:
                        logger.warning(
                            "API Watcher - Reorg detected, rolling back events to block %s...",
                            next_event["block_index"],
                        )
                        rollback_events(self.api_db, next_event["block_index"])
                    logger.debug(f"API Watcher - Parsing event: {next_event['event']}")
                    parse_event(self.api_db, next_event)
                else:
                    logger.trace("API Watcher - No new events to parse")
                    time.sleep(1)
        except KeyboardInterrupt:
            logger.debug("API Watcher - Keyboard interrupt")
            pass
        self.stopped = True
        return

    def stop(self):
        logger.info("Stopping API Watcher...")
        self.stopping = True
        while not self.stopped:
            time.sleep(0.1)
        self.api_db.close()
        self.ledger_db.close()
        logger.trace("API Watcher stopped")
