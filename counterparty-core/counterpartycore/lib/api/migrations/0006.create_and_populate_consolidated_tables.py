#
# file: counterpartycore/lib/api/migrations/0006.create_and_populate_consolidated_tables.py
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0005.create_and_populate_events_count"}

CONSOLIDATED_TABLES = {
    "fairminters": "tx_hash",
    "balances": "address, utxo, asset",
    "addresses": "address",
    "dispensers": "source, asset, tx_hash",
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
    ],
    "balances": [
        "asset_longname TEXT",
    ],
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
        """,
    ],
    "balances": [
        """
        UPDATE balances SET
            asset_longname = (
                SELECT assets.asset_longname
                FROM assets
                WHERE assets.asset_name = balances.asset
            );
        """,
        """
        CREATE INDEX balances_asset_longname_idx ON balances (asset_longname)
        """,
    ],
}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return dict(zip(fields, row))


def build_consolidated_table(state_db, table_name):
    logger.debug("Copying the consolidated table `%s` to State DB...", table_name)
    start_time = time.time()

    # recreate table
    sqls = []
    indexes = []
    for sql in state_db.execute(f"""
        SELECT sql, type FROM ledger_db.sqlite_master 
        WHERE tbl_name='{table_name}'
        AND type != 'trigger'
    """).fetchall():  # noqa S608 # nosec B608
        if sql["type"] == "index":
            indexes.append(sql["sql"])
        else:
            sqls.append(sql["sql"])

    for sql in sqls:
        state_db.execute(sql)

    state_db.execute(f"""
        CREATE TEMP TABLE latest_ids AS
        SELECT {CONSOLIDATED_TABLES[table_name]}, MAX(rowid) as max_id
        FROM ledger_db.{table_name}
        GROUP BY {CONSOLIDATED_TABLES[table_name]}
    """)  # noqa S608 # nosec B608

    state_db.execute("""
        CREATE INDEX temp.latest_ids_idx ON latest_ids(max_id)
    """)

    columns = [
        f"b.{column['name']}" for column in state_db.execute(f"PRAGMA table_info({table_name})")
    ]
    select_fields = ", ".join(columns)

    state_db.execute(f"""
        INSERT INTO {table_name}
        SELECT {select_fields}
        FROM ledger_db.{table_name} b
        JOIN latest_ids l ON b.rowid = l.max_id
    """)  # noqa S608 # nosec B608
    state_db.execute("DROP TABLE latest_ids")

    # add additional columns
    if table_name in ADDITONAL_COLUMNS:
        for column in ADDITONAL_COLUMNS[table_name]:
            state_db.execute(f"""
                ALTER TABLE {table_name} ADD COLUMN {column}
            """)

    if table_name in POST_QUERIES:
        for post_query in POST_QUERIES[table_name]:
            state_db.execute(post_query)

    for sql_index in indexes:
        state_db.execute(sql_index)
    logger.debug(
        "Copied consolidated table `%s` in %.2f seconds", table_name, time.time() - start_time
    )


def apply(db):
    if hasattr(db, "row_factory"):
        db.row_factory = dict_factory

    logger.debug("Copying consolidated tables from ledger db...")

    db.execute("""PRAGMA foreign_keys=OFF""")

    attached = (
        db.execute(
            "SELECT COUNT(*) AS count FROM pragma_database_list WHERE name = ?", ("ledger_db",)
        ).fetchone()["count"]
        > 0
    )
    if not attached:
        db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    for table in CONSOLIDATED_TABLES:
        build_consolidated_table(db, table)

    db.execute("""PRAGMA foreign_keys=ON""")


def rollback(db):
    for table in CONSOLIDATED_TABLES:
        db.execute(f"DROP TABLE {table}")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
