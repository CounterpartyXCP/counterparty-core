import decimal
import logging
import struct

from counterpartycore.lib import config, database, exceptions, ledger

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
        if quantity <= 0:
            problems.append("Quantity must be greater than 0")
            return problems

        if fairminter["hard_cap"] > 0:
            fairmint_quantity = ledger.get_fairmint_quantity(db, fairminter["tx_hash"])
            if fairmint_quantity + quantity > fairminter["hard_cap"]:
                problems.append("Fairmint quantity exceeds hard cap")

        xcp_total_price = quantity * fairminter["price"]
        balance = ledger.get_balance(db, source, "XCP")
        if balance < xcp_total_price:
            problems.append("Insufficient XCP balance")

    return problems


def compose(
    db,
    source,
    asset,
    quantity=0,
):
    problems = validate(db, source, asset, quantity)
    if len(problems) > 0:
        raise exceptions.ComposeError(problems)

    # create message
    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
    data_content = "|".join(
        [
            str(value)
            for value in [
                asset,
                quantity,
            ]
        ]
    ).encode("utf-8")
    data += struct.pack(f">{len(data_content)}s", data_content)
    return (source, [], data)


def unpack(message, return_dict=False):
    try:
        data_content = struct.unpack(f">{len(message)}s", message)[0].decode("utf-8").split("|")
        (asset, quantity) = data_content
        if return_dict:
            return {"asset": asset, "quantity": quantity}
        else:
            return (asset, quantity)
    except Exception as e:
        raise exceptions.UnpackError(f"Cannot unpack fair mint message: {e}") from e


def parse(db, tx, message):
    (asset, quantity) = unpack(message)
    problems = validate(db, tx["source"], asset, quantity)

    # if problems, insert into fairmints table with status invalid and return
    status = "valid"
    if problems:
        status = "invalid: " + "; ".join(problems)
        bindings = {
            "tx_hash": tx["tx_hash"],
            "tx_index": tx["tx_index"],
            "block_index": tx["block_index"],
            "source": tx["source"],
            "status": status,
        }
        ledger.insert_record(db, "fairmints", bindings, "NEW_FAIRMINT")
        return

    fairminter = ledger.get_fairminter_by_asset(db, asset)

    soft_cap_not_reached = (
        fairminter["soft_cap"] > 0 and fairminter["soft_cap_deadline_block"] > tx["block_index"]
    )

    xcp_action = "fairmint"
    asset_action = "fairmint"
    xcp_destination = fairminter["source"]
    asset_destination = tx["source"]

    if fairminter["burn_payment"]:
        xcp_action = "burn payment"
        xcp_destination = config.UNSPENDABLE

    if soft_cap_not_reached:
        xcp_action = "escrowed fairmint"
        xcp_destination = config.UNSPENDABLE
        asset_action = "escrowed fairmint"
        asset_destination = config.UNSPENDABLE

    if fairminter["price"] > 0:
        paid_quantity = quantity * fairminter["price"]
        earn_quantity = quantity
    else:
        paid_quantity = 0
        earn_quantity = fairminter["max_mint_per_tx"]

    if paid_quantity > 0:
        ledger.debit(db, tx["source"], "XCP", paid_quantity, xcp_action, tx["tx_hash"])
        ledger.credit(db, xcp_destination, "XCP", paid_quantity, xcp_action, tx["tx_hash"])

    ledger.credit(db, asset_destination, asset, earn_quantity, asset_action, tx["tx_hash"])

    last_issuance = ledger.get_asset(db, asset)
    fair_minting = True
    if fairminter["hard_cap"] > 0:
        fairmint_quantity = ledger.get_fairmint_quantity(db, fairminter["tx_hash"])
        if fairmint_quantity + quantity == fairminter["hard_cap"]:
            fair_minting = False

    bindings = last_issuance | {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "quantity": earn_quantity,
        "source": tx["source"],
        "status": "valid",
        "fair_minting": fair_minting,
    }
    ledger.insert_record(db, "issuances", bindings, "ASSET_ISSUANCE")

    if not fair_minting:
        ledger.update_fairminter(db, fairminter["tx_hash"], {"status": "closed"})
