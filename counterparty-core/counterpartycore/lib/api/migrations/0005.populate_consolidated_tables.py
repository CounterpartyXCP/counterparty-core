#
# file: counterpartycore/lib/api/migrations/0003.populate_address_events.py
#
import logging
import os
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

__depends__ = {"0001.api_db_to_state_db"}

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


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    db.row_factory = dict_factory

    logger.debug("Copy consolidated tables from ledger db...")

    db.execute("""PRAGMA foreign_keys=OFF""")
    logger.debug(f"Attach ledger db {config.DATABASE}...")
    db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    for table in CONSOLIDATED_TABLES.keys():
        build_consolidated_table(db, table)

    db.execute("""PRAGMA foreign_keys=ON""")


def rollback(db):
    pass


steps = [step(apply, rollback)]
