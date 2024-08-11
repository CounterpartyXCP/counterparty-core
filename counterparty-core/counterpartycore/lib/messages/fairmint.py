import decimal
import logging

from counterpartycore.lib import config, database, ledger

logger = logging.getLogger(config.LOGGER_NAME)
D = decimal.Decimal

ID = 91


def initialise(db):
    cursor = db.cursor()

    create_table_sql = """
        CREATE TABLE IF NOT EXISTS fairmints (
            tx_hash TEXT PRIMARY KEY,
            tx_index INTEGER,
            block_index INTEGER,
            source TEXT,
            fairminter_tx_hash TEXT,
            asset TEXT,
            earn_quantity INTEGER,
            paid_quantity INTEGER,
            status TEXT,
        )
    """

    cursor.execute(create_table_sql)

    database.create_indexes(
        cursor,
        "fairmints",
        [
            ["tx_hash"],
            ["block_index"],
            ["fair_minter_tx_hash"],
            ["asset"],
            ["source"],
            ["status"],
        ],
    )


def validate(
    db,
    source,
    asset,
    quantity=0,
):
    problems = []

    if not isinstance(quantity, int):
        problems.append("quantity must be an integer")

    fairminter = ledger.get_fairminter_by_asset(db, asset)
    if not fairminter:
        problems.append("Fairminter not found for asset: {}".format(asset))
        return problems

    if fairminter["status"] != "open":
        problems.append("Fairminter is not open for asset: {}".format(asset))

    if fairminter["price"] > 0:
        if fairminter["hard_cap"] > 0:
            fairmint_quantity = ledger.get_fairmint_quantity(db, fairminter["tx_hash"])
            if fairmint_quantity + quantity > fairminter["hard_cap"]:
                problems.append("Fairmint quantity exceeds hard cap")

        xcp_total_price = quantity * fairminter["price"]
        balance = ledger.get_balance(db, source, "XCP")
        if balance < xcp_total_price:
            problems.append("Insufficient XCP balance")

    return problems
