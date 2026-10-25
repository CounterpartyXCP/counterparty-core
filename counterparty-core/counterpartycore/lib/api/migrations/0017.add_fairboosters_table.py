#
# file: counterpartycore/lib/api/migrations/0017.add_fairboosters_table.py
#
# Fairboosters are updated in place (parameters, boosters sold), so the State DB
# keeps the latest version of each one, like `fairminters`. The other
# fairbooster tables are append-only and served from the Ledger DB.
#
import logging
import time

from counterpartycore.lib import config
from counterpartycore.lib.api.statetables import (
    LEDGER_FAIRBOOSTER_KEYS as FAIRBOOSTER_TABLES,
)
from counterpartycore.lib.api.statetables import (
    consolidated_projection,
)
from counterpartycore.lib.utils.database import text_affinitize_index_columns
from yoyo import step  # pylint: disable=wrong-import-order

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0016.add_rollback_block_index_indexes"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return dict(zip(fields, row, strict=True))


def build_table(state_db, table_name, group_by):
    """Copy the latest version of each row of a ledger table into the State DB."""
    # table_name comes from the hardcoded FAIRBOOSTER_TABLES dict, not user input
    rows = state_db.execute(f"""
        SELECT sql, type FROM ledger_db.sqlite_master
        WHERE tbl_name='{table_name}'
        AND type != 'trigger'
    """).fetchall()  # noqa: S608  # nosec B608
    indexes = [row["sql"] for row in rows if row["type"] == "index" and row["sql"]]
    for row in rows:
        if row["type"] != "index":
            # the State DB stores asset names and addresses, not their indexes
            state_db.execute(text_affinitize_index_columns(row["sql"]))

    names, expressions = consolidated_projection(state_db, table_name)
    state_db.execute(f"""
        INSERT INTO {table_name} ({", ".join(names)})
        SELECT {", ".join(expressions)}
        FROM ledger_db.{table_name} b
        WHERE b.rowid IN (
            SELECT MAX(rowid) FROM ledger_db.{table_name} GROUP BY {group_by}
        )
    """)  # noqa: S608  # nosec B608
    for index_sql in indexes:
        state_db.execute(index_sql)


def apply(db):
    if hasattr(db, "row_factory"):
        db.row_factory = dict_factory

    logger.debug("Adding fairboosters table to State DB...")
    start_time = time.time()

    attached = (
        db.execute(
            "SELECT COUNT(*) AS count FROM pragma_database_list WHERE name = ?", ("ledger_db",)
        ).fetchone()["count"]
        > 0
    )
    if not attached:
        db.execute(
            "ATTACH DATABASE ? AS ledger_db",
            (config.DATABASE,),  # pylint: disable=no-member
        )

    ledger_tables = {
        row["name"]
        for row in db.execute(
            "SELECT name FROM ledger_db.sqlite_master WHERE type='table'"
        ).fetchall()
    }
    for table_name, group_by in FAIRBOOSTER_TABLES.items():
        if table_name not in ledger_tables:
            logger.debug("Ledger table `%s` does not exist yet, skipping.", table_name)
            continue
        build_table(db, table_name, group_by)

    logger.debug("Fairboosters table added in %.2f seconds", time.time() - start_time)


def rollback(db):
    for table_name in FAIRBOOSTER_TABLES:
        db.execute(f"DROP TABLE IF EXISTS {table_name}")  # noqa: S608  # nosec B608


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
