#
# file: counterpartycore/lib/api/migrations/0014.add_pool_consolidated_tables.py
#
import logging
import time

from counterpartycore.lib import config
from counterpartycore.lib.utils.database import (
    ADDRESS_INDEX_COLUMN_NAMES,
    ASSET_INDEX_COLUMN_NAMES,
    text_affinitize_index_columns,
)
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0013.add_performance_indexes"}

# group_by fields determine which columns identify a unique record
# (used to get the latest version via MAX(rowid)).
POOL_TABLES = {
    "pools": "asset_a, asset_b",
    "pool_deposits": "tx_hash",
    "pool_withdrawals": "tx_hash",
    "pool_matches": "rowid",
}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return dict(zip(fields, row, strict=True))


def build_table(state_db, table_name, group_by):
    """Copy latest state of a ledger table into state DB (consolidated)."""
    logger.debug("Copying consolidated table `%s` to State DB...", table_name)
    start_time = time.time()

    # Recreate schema from ledger DB
    sqls = []
    indexes = []
    # table_name comes from the hardcoded POOL_TABLES dict, not user input
    for row in state_db.execute(f"""
        SELECT sql, type FROM ledger_db.sqlite_master
        WHERE tbl_name='{table_name}'
        AND type != 'trigger'
    """).fetchall():  # noqa: S608  # nosec B608
        if row["type"] == "index":
            indexes.append(row["sql"])
        else:
            sqls.append(row["sql"])

    for sql in sqls:
        # The State DB stores the decoded asset name / address string in the
        # asset/address columns, so retype them from the ledger's compact
        # ``INTEGER`` to ``TEXT`` (matching ``assets_info.asset``) -- otherwise
        # the affinity mismatch defeats the index on joins/subqueries against
        # ``assets_info`` and degrades into full scans.
        state_db.execute(text_affinitize_index_columns(sql))

    # Get latest row per group
    # table_name and group_by come from the hardcoded POOL_TABLES dict, not user input
    state_db.execute(f"""
        CREATE TEMP TABLE latest_ids AS
        SELECT {group_by}, MAX(rowid) as max_id
        FROM ledger_db.{table_name}
        GROUP BY {group_by}
    """)  # noqa: S608  # nosec B608
    state_db.execute("CREATE INDEX temp.latest_ids_idx ON latest_ids(max_id)")

    # The State DB stores asset *names*; decode the compact ``asset_index`` back
    # to names while ``ledger_db`` is attached (the INSERT ... SELECT bypasses
    # the rowtracer). ``lp_asset`` is not normalized, so it is copied verbatim.
    columns = []
    for col in state_db.execute(f"PRAGMA table_info({table_name})"):
        name = col["name"]
        if name in ASSET_INDEX_COLUMN_NAMES:
            columns.append(
                f"(SELECT asset_name FROM ledger_db.assets WHERE asset_index = b.{name}) AS {name}"  # noqa: S608  # nosec B608
            )
        elif name in ADDRESS_INDEX_COLUMN_NAMES:
            # decode the compact ``address_id`` back to the address string
            columns.append(
                f"(SELECT address FROM ledger_db.address_list WHERE address_id = b.{name}) AS {name}"  # noqa: S608  # nosec B608
            )
        else:
            columns.append(f"b.{name}")
    select_fields = ", ".join(columns)

    # table_name comes from POOL_TABLES dict; select_fields is built from PRAGMA table_info results
    state_db.execute(f"""
        INSERT INTO {table_name}
        SELECT {select_fields}
        FROM ledger_db.{table_name} b
        JOIN latest_ids l ON b.rowid = l.max_id
    """)  # noqa: S608  # nosec B608
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

    # Rebuild asset_holders view to include pool reserves
    if "pools" in ledger_tables:
        db.execute("DROP VIEW IF EXISTS xcp_holders")
        db.execute("DROP VIEW IF EXISTS asset_holders")
        unspendable = config.UNSPENDABLE
        # ``tx_hash`` is stored as BLOB(32) after the compact-hash storage
        # migration; convert to lowercase hex via the ``hex_lower`` UDF when
        # projecting the legacy ``escrow`` column.
        asset_holders_sql = """
            CREATE VIEW IF NOT EXISTS asset_holders AS
                SELECT asset, address, quantity, NULL AS escrow,
                    ('balances_' || CAST(rowid AS VARCHAR)) AS cursor_id, 'balances' AS holding_type, NULL AS status
                FROM balances
             UNION ALL
                SELECT give_asset AS asset, source AS address, give_remaining AS quantity, hex_lower(tx_hash) AS escrow,
                    ('open_order_' || CAST(rowid AS VARCHAR)) AS cursor_id,
                    'open_order' AS holding_type, status
                FROM orders WHERE status = 'open'
             UNION ALL
                SELECT forward_asset AS asset, tx0_address AS address, forward_quantity AS quantity,
                    hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash) AS escrow, ('order_match_' || CAST(rowid AS VARCHAR)) AS cursor_id,
                    'pending_order_match' AS holding_type, status
                FROM order_matches WHERE status = 'pending'
             UNION ALL
                SELECT backward_asset AS asset, tx1_address AS address, backward_quantity AS quantity,
                    hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash) AS escrow, ('order_match_' || CAST(rowid AS VARCHAR)) AS cursor_id,
                    'pending_order_match' AS holding_type, status
                FROM order_matches WHERE status = 'pending'
             UNION ALL
                SELECT asset, source AS address, give_remaining AS quantity,
                hex_lower(tx_hash) AS escrow, ('open_dispenser_' || CAST(rowid AS VARCHAR)) AS cursor_id,
                'open_dispenser' AS holding_type, status
                FROM dispensers WHERE status = 0
             UNION ALL
                SELECT asset_a AS asset, '"""
        asset_holders_sql += unspendable
        asset_holders_sql += """' AS address, reserve_a AS quantity,
                hex_lower(tx_hash) AS escrow, ('pool_reserve_a_' || CAST(rowid AS VARCHAR)) AS cursor_id,
                'pool_reserve' AS holding_type, NULL AS status
                FROM pools WHERE reserve_a > 0
             UNION ALL
                SELECT asset_b AS asset, '"""
        asset_holders_sql += unspendable
        asset_holders_sql += """' AS address, reserve_b AS quantity,
                hex_lower(tx_hash) AS escrow, ('pool_reserve_b_' || CAST(rowid AS VARCHAR)) AS cursor_id,
                'pool_reserve' AS holding_type, NULL AS status
                FROM pools WHERE reserve_b > 0;
        """
        db.execute(asset_holders_sql)
        db.execute("""
            CREATE VIEW IF NOT EXISTS xcp_holders AS
                SELECT * FROM asset_holders
             UNION ALL
                SELECT 'XCP' AS asset, source AS address, wager_remaining AS quantity,
                hex_lower(tx_hash) AS escrow, ('open_bet_' || CAST(rowid AS VARCHAR)) AS cursor_id,
                'open_bet' AS holding_type, status
                FROM bets WHERE status = 'open'
             UNION ALL
                SELECT 'XCP' AS asset, tx0_address AS address, forward_quantity AS quantity,
                hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash) AS escrow, ('bet_match_' || CAST(rowid AS VARCHAR)) AS cursor_id,
                'pending_bet_match' AS holding_type, status
                FROM bet_matches WHERE status = 'pending'
             UNION ALL
                SELECT 'XCP' AS asset, tx1_address AS address, backward_quantity AS quantity,
                hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash) AS escrow, ('bet_match_' || CAST(rowid AS VARCHAR)) AS cursor_id,
                'pending_bet_match' AS holding_type, status
                FROM bet_matches WHERE status = 'pending'
             UNION ALL
                SELECT 'XCP' AS asset, source AS address, wager AS quantity,
                hex_lower(tx_hash) AS escrow, ('open_rps_' || CAST(rowid AS VARCHAR)) AS cursor_id,
                'open_rps' AS holding_type, status
                FROM rps WHERE status = 'open'
             UNION ALL
                SELECT 'XCP' AS asset, tx0_address AS address, wager AS quantity,
                hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash) AS escrow, ('rps_match_' || CAST(rowid AS VARCHAR)) AS cursor_id,
                'pending_rps_match' AS holding_type, status
                FROM rps_matches WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
             UNION ALL
                SELECT 'XCP' AS asset, tx1_address AS address, wager AS quantity,
                hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash) AS escrow, ('rps_match_' || CAST(rowid AS VARCHAR)) AS cursor_id,
                'pending_rps_match' AS holding_type, status
                FROM rps_matches WHERE status IN ('pending', 'pending and resolved', 'resolved and pending');
        """)

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
