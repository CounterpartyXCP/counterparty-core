#
# file: counterpartycore/lib/api/migrations/0014.add_pool_consolidated_tables.py
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0013.add_performance_indexes"}

# group_by fields determine which columns identify a unique record
# (used to get the latest version via MAX(rowid)).
POOL_TABLES = {
    "pools": "asset_a, asset_b",
    "pool_deposits": "tx_hash",
    "pool_withdrawals": "tx_hash",
    "pool_matches": "tx_hash, order_tx_hash",
}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return dict(zip(fields, row))


def build_table(state_db, table_name, group_by):
    """Copy latest state of a ledger table into state DB (consolidated)."""
    logger.debug("Copying consolidated table `%s` to State DB...", table_name)
    start_time = time.time()

    # Recreate schema from ledger DB
    sqls = []
    indexes = []
    for row in state_db.execute(f"""
        SELECT sql, type FROM ledger_db.sqlite_master
        WHERE tbl_name='{table_name}'
        AND type != 'trigger'
    """).fetchall():
        if row["type"] == "index":
            indexes.append(row["sql"])
        else:
            sqls.append(row["sql"])

    for sql in sqls:
        state_db.execute(sql)

    # Get latest row per group
    state_db.execute(f"""
        CREATE TEMP TABLE latest_ids AS
        SELECT {group_by}, MAX(rowid) as max_id
        FROM ledger_db.{table_name}
        GROUP BY {group_by}
    """)
    state_db.execute("CREATE INDEX temp.latest_ids_idx ON latest_ids(max_id)")

    columns = [f"b.{col['name']}" for col in state_db.execute(f"PRAGMA table_info({table_name})")]
    select_fields = ", ".join(columns)

    state_db.execute(f"""
        INSERT INTO {table_name}
        SELECT {select_fields}
        FROM ledger_db.{table_name} b
        JOIN latest_ids l ON b.rowid = l.max_id
    """)
    state_db.execute("DROP TABLE latest_ids")

    for idx_sql in indexes:
        if idx_sql:
            state_db.execute(idx_sql)

    logger.debug(
        "Copied consolidated table `%s` in %.2f seconds",
        table_name,
        time.time() - start_time,
    )


def apply(db):
    if hasattr(db, "row_factory"):
        db.row_factory = dict_factory

    logger.debug("Adding AMM pool consolidated tables to State DB...")
    start_time = time.time()

    db.execute("""PRAGMA foreign_keys=OFF""")

    attached = (
        db.execute(
            "SELECT COUNT(*) AS count FROM pragma_database_list WHERE name = ?", ("ledger_db",)
        ).fetchone()["count"]
        > 0
    )
    if not attached:
        db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    # Check which pool tables exist in ledger DB (they won't pre-activation)
    ledger_tables = {
        row["name"]
        for row in db.execute(
            "SELECT name FROM ledger_db.sqlite_master WHERE type='table'"
        ).fetchall()
    }

    for table_name, group_by in POOL_TABLES.items():
        if table_name not in ledger_tables:
            logger.debug("Ledger table `%s` does not exist yet, skipping.", table_name)
            continue
        build_table(db, table_name, group_by)

    db.execute("""PRAGMA foreign_keys=ON""")

    logger.debug(
        "AMM pool consolidated tables added in %.2f seconds",
        time.time() - start_time,
    )


def rollback(db):
    for table_name in POOL_TABLES:
        db.execute(f"DROP TABLE IF EXISTS {table_name}")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
