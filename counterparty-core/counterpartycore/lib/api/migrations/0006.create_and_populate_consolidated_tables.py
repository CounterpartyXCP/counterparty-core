#
# file: counterpartycore/lib/api/migrations/0006.create_and_populate_consolidated_tables.py
#
import logging
import time

from counterpartycore.lib import config, database
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0005.create_and_populate_events_count"}

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

ADDITONAL_COLUMNS = {
    "fairminters": [
        "earned_quantity INTEGER",
        "paid_quantity INTEGER",
        "commission INTEGER",
    ]
}

POST_QUERIES = {
    "fairminters": [
        """
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
    ]
}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def get_table_schema(state_db, table_name):
    table = ""
    indexes = []
    for sql in state_db.execute(f"""
        SELECT sql, type FROM ledger_db.sqlite_master 
        WHERE tbl_name='{table_name}'
        AND type != 'trigger'
    """).fetchall():  # noqa S608
        if sql["type"] == "index":
            indexes.append(sql["sql"])
        else:
            table = sql["sql"]
    return table, indexes


def build_consolidated_table(state_db, table_name):
    logger.debug(f"Copying the consolidated table `{table_name}` to State DB...")
    start_time = time.time()

    # recreate table
    create_table, create_indexes = get_table_schema(state_db, table_name)
    state_db.execute(create_table)

    columns = [column["name"] for column in state_db.execute(f"PRAGMA table_info({table_name})")]
    select_fields = ", ".join(columns)

    sql = f"""
        INSERT INTO {table_name} 
            SELECT {select_fields} FROM (
                SELECT *, MAX(rowid) as rowid FROM ledger_db.{table_name}
                GROUP BY {CONSOLIDATED_TABLES[table_name]}
            )
    """  # noqa S608
    state_db.execute(sql)

    # add additional columns
    if table_name in ADDITONAL_COLUMNS:
        for column in ADDITONAL_COLUMNS[table_name]:
            state_db.execute(f"""
                ALTER TABLE {table_name} ADD COLUMN {column}
            """)

    if table_name in POST_QUERIES:
        for post_query in POST_QUERIES[table_name]:
            state_db.execute(post_query)

    for sql_index in create_indexes:
        state_db.execute(sql_index)

    logger.debug(
        f"Copied consolidated table `{table_name}` in {time.time() - start_time:.2f} seconds"
    )


def rebuild_consolidated_table(state_db, table_name, block_index):
    logger.debug(f"Rebuilding State DB table `{table_name}` from block {block_index}...")
    start_time = time.time()

    columns = [column["name"] for column in state_db.execute(f"PRAGMA table_info({table_name})")]
    if table_name in ADDITONAL_COLUMNS:
        for field in ADDITONAL_COLUMNS[table_name]:
            field_name = field.split(" ")[0]
            columns = [
                f"NULL AS {field_name}" if column == field_name else column for column in columns
            ]
    select_fields = ", ".join(columns)

    sql = f"""
        INSERT INTO {table_name} 
            SELECT {select_fields} FROM (
                SELECT *, MAX(rowid) as rowid FROM ledger_db.{table_name}
                GROUP BY {CONSOLIDATED_TABLES[table_name]}
            ) WHERE block_index >= {block_index}
    """  # noqa S608
    state_db.execute(sql)

    if table_name in POST_QUERIES:
        for post_query in POST_QUERIES[table_name]:
            state_db.execute(post_query)

    logger.debug(f"Rebuilt State DB table `{table_name}` in {time.time() - start_time:.2f} seconds")


def apply(db, block_index=None):
    if hasattr(db, "row_factory"):
        db.row_factory = dict_factory

    logger.debug("Copying consolidated tables from ledger db...")

    db.execute("""PRAGMA foreign_keys=OFF""")

    database.attach_ledger_db(db)

    for table in CONSOLIDATED_TABLES.keys():
        if block_index:
            rebuild_consolidated_table(db, table, block_index)
        else:
            build_consolidated_table(db, table)

    db.execute("""PRAGMA foreign_keys=ON""")


def rollback(db, block_index=None):
    for table_name in CONSOLIDATED_TABLES.keys():
        if block_index:
            db.execute(f"DELETE FROM {table_name} WHERE block_index >= ?", (block_index,))  # noqa S608
        else:
            db.execute(f"DROP TABLE {table_name}")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
