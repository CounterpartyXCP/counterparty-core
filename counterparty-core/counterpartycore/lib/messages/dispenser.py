#! /usr/bin/python3
#
# What is a dispenser?
#
# A dispenser is a type of order where the holder address gives out a given amount
# of units of an asset for a given amount of BTC satoshis received.
# It's a very simple but powerful semantic to allow swaps to operate on-chain.
#

import logging
import struct
from math import floor

from counterpartycore.lib import (
    address,
    backend,
    config,
    database,
    exceptions,
    ledger,
    message_type,
    util,
)

logger = logging.getLogger(config.LOGGER_NAME)

FORMAT = ">QQQQB"
LENGTH = 33
ID = 12
DISPENSE_ID = 13

STATUS_OPEN = 0
STATUS_OPEN_EMPTY_ADDRESS = 1
# STATUS_OPEN_ORACLE_PRICE = 20
# STATUS_OPEN_ORACLE_PRICE_EMPTY_ADDRESS = 21
STATUS_CLOSED = 10
STATUS_CLOSING = 11


def initialise(db):
    cursor = db.cursor()

    # Dispensers
    create_dispensers_query = """CREATE TABLE IF NOT EXISTS dispensers(
                                tx_index INTEGER,
                                tx_hash TEXT,
                                block_index INTEGER,
                                source TEXT,
                                asset TEXT,
                                give_quantity INTEGER,
                                escrow_quantity INTEGER,
                                satoshirate INTEGER,
                                status INTEGER,
                                give_remaining INTEGER,
                                oracle_address TEXT,
                                last_status_tx_hash TEXT,
                                origin TEXT,
                                dispense_count INTEGER DEFAULT 0)
                                """
    # create tables
    cursor.execute(create_dispensers_query)

    # add new columns if not exist
    columns = [column["name"] for column in cursor.execute("""PRAGMA table_info(dispensers)""")]
    if "oracle_address" not in columns:
        cursor.execute("ALTER TABLE dispensers ADD COLUMN oracle_address TEXT")
    if "last_status_tx_hash" not in columns:
        # this column will be used to know when a dispenser was marked to close
        cursor.execute("ALTER TABLE dispensers ADD COLUMN last_status_tx_hash TEXT")
    if "origin" not in columns:
        cursor.execute("ALTER TABLE dispensers ADD COLUMN origin TEXT")
        cursor.execute(
            "UPDATE dispensers AS d SET origin = (SELECT t.source FROM transactions t WHERE d.tx_hash = t.tx_hash)"
        )
    if "dispense_count" not in columns:
        cursor.execute("ALTER TABLE dispensers ADD COLUMN dispense_count INTEGER DEFAULT 0")

    # migrate old table
    if database.field_is_pk(cursor, "dispensers", "tx_index"):
        database.copy_old_table(cursor, "dispensers", create_dispensers_query)

    # create indexes
    database.create_indexes(
        cursor,
        "dispensers",
        [
            ["block_index"],
            ["source"],
            ["asset"],
            ["tx_index"],
            ["tx_hash"],
            ["status"],
            ["give_remaining"],
            ["status", "block_index"],
            ["source", "origin"],
            ["source", "asset", "origin"],
            ["last_status_tx_hash"],
        ],
    )

    # Dispenses
    create_dispensers_query = """CREATE TABLE IF NOT EXISTS dispenses (
                                tx_index INTEGER,
                                dispense_index INTEGER,
                                tx_hash TEXT,
                                block_index INTEGER,
                                source TEXT,
                                destination TEXT,
                                asset TEXT,
                                dispense_quantity INTEGER,
                                dispenser_tx_hash TEXT,
                                PRIMARY KEY (tx_index, dispense_index, source, destination),
                                FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                                """
    # create tables
    cursor.execute(create_dispensers_query)

    # add new columns if not exist
    columns = [column["name"] for column in cursor.execute("""PRAGMA table_info(dispenses)""")]
    if "dispenser_tx_hash" not in columns:
        cursor.execute("ALTER TABLE dispenses ADD COLUMN dispenser_tx_hash TEXT")

    # create indexes
    database.create_indexes(
        cursor, "dispenses", [["tx_hash"], ["block_index"], ["dispenser_tx_hash"]]
    )

    # Dispenser refills
    create_dispenser_refills_query = """CREATE TABLE IF NOT EXISTS dispenser_refills(
                                        tx_index INTEGER,
                                        tx_hash TEXT,
                                        block_index INTEGER,
                                        source TEXT,
                                        destination TEXT,
                                        asset TEXT,
                                        dispense_quantity INTEGER,
                                        dispenser_tx_hash TEXT,
                                        PRIMARY KEY (tx_index, tx_hash, source, destination),
                                        FOREIGN KEY (tx_index, tx_hash, block_index)
                                            REFERENCES transactions(tx_index, tx_hash, block_index))
                                        """
    # create tables
    cursor.execute(create_dispenser_refills_query)
    # create indexes
    database.create_indexes(
        cursor,
        "dispenser_refills",
        [
            ["tx_hash"],
            ["block_index"],
        ],
    )
    # fill dispenser_refills table
    dispenser_refills_is_empty = (
        cursor.execute("SELECT * FROM dispenser_refills LIMIT 1").fetchone() is None
    )
    if dispenser_refills_is_empty:
        cursor.execute("""INSERT INTO dispenser_refills
                          SELECT t.tx_index, deb.event, deb.block_index, deb.address,
                                 dis.source, deb.asset, deb.quantity, dis.tx_hash
                          FROM debits deb
                          LEFT JOIN transactions t ON t.tx_hash = deb.event
                          LEFT JOIN dispensers dis ON
                              dis.source = deb.address
                              AND dis.asset = deb.asset
                              AND dis.tx_index = (
                                  SELECT max(dis2.tx_index)
                                  FROM dispensers dis2
                                  WHERE dis2.source = deb.address
                                  AND dis2.asset = deb.asset
                                  AND dis2.block_index <= deb.block_index
                              )
                          WHERE deb.action = 'refill dispenser' AND dis.source IS NOT NULL""")


def validate(
    db,
    source,
    asset,
    give_quantity,
    escrow_quantity,
    mainchainrate,
    status,
    open_address,
    block_index,
    oracle_address,
):
    problems = []
    order_match = None  # noqa: F841
    asset_id = None

    if asset == config.BTC:
        problems.append(f"cannot dispense {config.BTC}")
        return None, problems

    # resolve subassets
    asset = ledger.resolve_subasset_longname(db, asset)

    if status == STATUS_OPEN or status == STATUS_OPEN_EMPTY_ADDRESS:
        if give_quantity <= 0:
            problems.append("give_quantity must be positive")
        if mainchainrate <= 0:
            problems.append("mainchainrate must be positive")
        if escrow_quantity < give_quantity:
            problems.append("escrow_quantity must be greater or equal than give_quantity")
    elif not (status == STATUS_CLOSED):
        problems.append(f"invalid status {status}")

    cursor = db.cursor()
    available = ledger.get_balance(db, source, asset, return_list=True)

    if len(available) == 0:
        problems.append(f"address doesn't has the asset {asset}")
    elif len(available) >= 1 and available[0]["quantity"] < escrow_quantity:
        problems.append(
            f"address doesn't has enough balance of {asset} ({available[0]['quantity']} < {escrow_quantity})"
        )
    else:
        if status == STATUS_OPEN_EMPTY_ADDRESS and not (open_address):
            open_address = source
            status = STATUS_OPEN

        open_dispensers = []
        if (
            ledger.enabled("dispenser_origin_permission_extended", block_index)
            and status == STATUS_CLOSED
            and open_address
            and open_address != source
        ):
            open_dispensers = ledger.get_dispensers(
                db, status_in=[0, 11], address=open_address, asset=asset, origin=source
            )
        else:
            query_address = open_address if status == STATUS_OPEN_EMPTY_ADDRESS else source
            open_dispensers = ledger.get_dispensers(
                db, status_in=[0, 11], address=query_address, asset=asset
            )

        if len(open_dispensers) == 0 or open_dispensers[0]["status"] != STATUS_CLOSING:
            if status == STATUS_OPEN or status == STATUS_OPEN_EMPTY_ADDRESS:
                if len(open_dispensers) > 0:
                    max_refills = ledger.get_value_by_block_index("max_refills", block_index)
                    refilling_count = 0
                    if max_refills > 0:
                        refilling_count = ledger.get_refilling_count(
                            db, dispenser_tx_hash=open_dispensers[0]["tx_hash"]
                        )

                    # It's a valid refill
                    if (
                        open_dispensers[0]["satoshirate"] == mainchainrate
                        and open_dispensers[0]["give_quantity"] == give_quantity
                    ):
                        if (max_refills > 0) and (refilling_count >= max_refills):
                            problems.append("the dispenser reached its maximum refilling")
                    else:
                        if open_dispensers[0]["satoshirate"] != mainchainrate:
                            problems.append(
                                f"address has a dispenser already opened for asset {asset} with a different mainchainrate"
                            )
                        if open_dispensers[0]["give_quantity"] != give_quantity:
                            problems.append(
                                f"address has a dispenser already opened for asset {asset} with a different give_quantity"
                            )
            elif status == STATUS_CLOSED:
                if len(open_dispensers) == 0:
                    problems.append(f"address doesnt has an open dispenser for asset {asset}")

            if status == STATUS_OPEN_EMPTY_ADDRESS:
                # If an address is trying to refill a dispenser in a different address and it's the creator
                if not (
                    ledger.enabled("dispenser_origin_permission_extended", block_index)
                    and (len(open_dispensers) > 0)
                    and (open_dispensers[0]["origin"] == source)
                ):
                    dispensers_from_same_origin_count = ledger.get_dispensers_count(
                        db, source=query_address, status=STATUS_CLOSED, origin=source
                    )

                    if not (
                        ledger.enabled("dispenser_origin_permission_extended", block_index)
                        and dispensers_from_same_origin_count > 0
                    ):
                        # It means that the same origin has not opened other dispensers in this address
                        existing_balances = ledger.get_balances_count(db, query_address)

                        if existing_balances[0]["cnt"] > 0:
                            problems.append(
                                "cannot open on another address if it has any balance history"
                            )

                        if ledger.enabled("dispenser_origin_permission_extended", block_index):
                            address_oldest_transaction = backend.get_oldest_tx(query_address)
                            if (
                                ("block_index" in address_oldest_transaction)
                                and (address_oldest_transaction["block_index"] > 0)
                                and (block_index > address_oldest_transaction["block_index"])
                            ):
                                problems.append(
                                    "cannot open on another address if it has any confirmed bitcoin txs"
                                )

            if len(problems) == 0:
                asset_id = ledger.generate_asset_id(asset, block_index)
                if asset_id == 0:
                    problems.append(
                        f"cannot dispense {asset}"
                    )  # How can we test this on a test vector?
        else:
            problems.append(
                "address has already a dispenser about to close, no action can be taken until it closes"
            )

    cursor.close()

    if oracle_address is not None and ledger.enabled("oracle_dispensers", block_index):
        last_price, last_fee, last_label, last_updated = ledger.get_oracle_last_price(
            db, oracle_address, block_index
        )

        if last_price is None:
            problems.append(
                f"The oracle address {oracle_address} has not broadcasted any price yet"
            )

    if (
        give_quantity > config.MAX_INT
        or escrow_quantity > config.MAX_INT
        or mainchainrate > config.MAX_INT
    ):
        problems.append("integer overflow")

    if len(problems) > 0:
        return None, problems
    else:
        return asset_id, None


def compose(
    db,
    source,
    asset,
    give_quantity,
    escrow_quantity,
    mainchainrate,
    status,
    open_address=None,
    oracle_address=None,
):
    assetid, problems = validate(
        db,
        source,
        asset,
        give_quantity,
        escrow_quantity,
        mainchainrate,
        status,
        open_address,
        ledger.CURRENT_BLOCK_INDEX,
        oracle_address,
    )
    if problems:
        raise exceptions.ComposeError(problems)

    destination = []
    data = message_type.pack(ID)
    data += struct.pack(FORMAT, assetid, give_quantity, escrow_quantity, mainchainrate, status)
    if (status == STATUS_OPEN_EMPTY_ADDRESS and open_address) or (
        ledger.enabled("dispenser_origin_permission_extended")
        and status == STATUS_CLOSED
        and open_address
        and open_address != source
    ):
        data += address.pack(open_address)
    if oracle_address is not None and ledger.enabled("oracle_dispensers"):
        oracle_fee = calculate_oracle_fee(
            db,
            escrow_quantity,
            give_quantity,
            mainchainrate,
            oracle_address,
            ledger.CURRENT_BLOCK_INDEX,
        )

        if oracle_fee >= config.DEFAULT_REGULAR_DUST_SIZE:
            destination.append((oracle_address, oracle_fee))
        data += address.pack(oracle_address)

    return (source, destination, data)


def calculate_oracle_fee(
    db, escrow_quantity, give_quantity, mainchainrate, oracle_address, block_index
):
    last_price, last_fee, last_fiat_label, last_updated = ledger.get_oracle_last_price(
        db, oracle_address, block_index
    )
    last_fee_multiplier = last_fee / config.UNIT

    # Format mainchainrate to ######.##
    oracle_mainchainrate = util.satoshirate_to_fiat(mainchainrate)
    oracle_mainchainrate_btc = oracle_mainchainrate / last_price

    # Calculate the total amount earned for dispenser and the fee
    remaining = int(floor(escrow_quantity / give_quantity))
    total_quantity_btc = oracle_mainchainrate_btc * remaining
    oracle_fee_btc = int(total_quantity_btc * last_fee_multiplier * config.UNIT)

    return oracle_fee_btc


def unpack(message, return_dict=False):
    try:
        action_address = None
        oracle_address = None
        assetid, give_quantity, escrow_quantity, mainchainrate, dispenser_status = struct.unpack(
            FORMAT, message[0:LENGTH]
        )
        read = LENGTH
        if dispenser_status == STATUS_OPEN_EMPTY_ADDRESS or (
            ledger.enabled("dispenser_origin_permission_extended")
            and dispenser_status == STATUS_CLOSED
            and len(message) > read
        ):
            action_address = address.unpack(message[LENGTH : LENGTH + 21])
            read = LENGTH + 21
        if len(message) > read:
            oracle_address = address.unpack(message[read : read + 21])
        asset = ledger.generate_asset_name(assetid, ledger.CURRENT_BLOCK_INDEX)
        status = "valid"
    except (exceptions.UnpackError, struct.error) as e:  # noqa: F841
        (
            give_quantity,
            escrow_quantity,
            mainchainrate,
            dispenser_status,
            action_address,
            oracle_address,
            asset,
        ) = None, None, None, None, None, None, None
        status = "invalid: could not unpack"

    if return_dict:
        return {
            "asset": asset,
            "give_quantity": give_quantity,
            "escrow_quantity": escrow_quantity,
            "mainchainrate": mainchainrate,
            "dispenser_status": dispenser_status,
            "action_address": action_address,
            "oracle_address": oracle_address,
            "status": status,
        }
    return (
        asset,
        give_quantity,
        escrow_quantity,
        mainchainrate,
        dispenser_status,
        action_address,
        oracle_address,
        status,
    )


def parse(db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    (
        asset,
        give_quantity,
        escrow_quantity,
        mainchainrate,
        dispenser_status,
        action_address,
        oracle_address,
        status,
    ) = unpack(message)
    if action_address is None:
        action_address = tx["source"]

    if status == "valid":
        if ledger.enabled("dispenser_parsing_validation", ledger.CURRENT_BLOCK_INDEX):
            asset_id, problems = validate(
                db,
                tx["source"],
                asset,
                give_quantity,
                escrow_quantity,
                mainchainrate,
                dispenser_status,
                action_address
                if dispenser_status in [STATUS_OPEN_EMPTY_ADDRESS, STATUS_CLOSED]
                else None,
                tx["block_index"],
                oracle_address,
            )
        else:
            problems = None

        if problems:
            status = "invalid: " + "; ".join(problems)
        else:
            if dispenser_status == STATUS_OPEN or dispenser_status == STATUS_OPEN_EMPTY_ADDRESS:
                existing = ledger.get_dispensers(
                    db, address=action_address, asset=asset, status=STATUS_OPEN
                )

                if len(existing) == 0:
                    if (oracle_address != None) and ledger.enabled(  # noqa: E711
                        "oracle_dispensers", tx["block_index"]
                    ):
                        oracle_fee = calculate_oracle_fee(
                            db,
                            escrow_quantity,
                            give_quantity,
                            mainchainrate,
                            oracle_address,
                            tx["block_index"],
                        )

                        if oracle_fee >= config.DEFAULT_REGULAR_DUST_SIZE:
                            if tx["destination"] != oracle_address or tx["btc_amount"] < oracle_fee:
                                status = "invalid: insufficient or non-existent oracle fee"

                    if status == "valid":
                        # Create the new dispenser
                        try:
                            if dispenser_status == STATUS_OPEN_EMPTY_ADDRESS:
                                is_empty_address = True
                                address_assets = ledger.get_address_assets(db, action_address)
                                if len(address_assets) > 0:
                                    for asset_name in address_assets:
                                        asset_balance = ledger.get_balance(
                                            db, action_address, asset_name["asset"]
                                        )
                                        if asset_balance > 0:
                                            is_empty_address = False
                                            break

                                if is_empty_address:
                                    ledger.debit(
                                        db,
                                        tx["source"],
                                        asset,
                                        escrow_quantity,
                                        tx["tx_index"],
                                        action="open dispenser empty addr",
                                        event=tx["tx_hash"],
                                    )
                                    ledger.credit(
                                        db,
                                        action_address,
                                        asset,
                                        escrow_quantity,
                                        tx["tx_index"],
                                        action="open dispenser empty addr",
                                        event=tx["tx_hash"],
                                    )
                                    ledger.debit(
                                        db,
                                        action_address,
                                        asset,
                                        escrow_quantity,
                                        tx["tx_index"],
                                        action="open dispenser empty addr",
                                        event=tx["tx_hash"],
                                    )
                                else:
                                    status = "invalid: address not empty"
                            else:
                                ledger.debit(
                                    db,
                                    tx["source"],
                                    asset,
                                    escrow_quantity,
                                    tx["tx_index"],
                                    action="open dispenser",
                                    event=tx["tx_hash"],
                                )
                        except ledger.DebitError as e:  # noqa: F841
                            status = "invalid: insufficient funds"

                    if status == "valid":
                        bindings = {
                            "tx_index": tx["tx_index"],
                            "tx_hash": tx["tx_hash"],
                            "block_index": tx["block_index"],
                            "source": action_address,
                            "asset": asset,
                            "give_quantity": give_quantity,
                            "escrow_quantity": escrow_quantity,
                            "satoshirate": mainchainrate,
                            "status": STATUS_OPEN,
                            "give_remaining": escrow_quantity,
                            "oracle_address": oracle_address,
                            "origin": tx["source"],
                            "dispense_count": 0,
                        }

                        if ledger.enabled("dispenser_origin_permission_extended"):
                            bindings["origin"] = tx["source"]

                        ledger.insert_record(db, "dispensers", bindings, "OPEN_DISPENSER")
                elif (
                    len(existing) == 1
                    and existing[0]["satoshirate"] == mainchainrate
                    and existing[0]["give_quantity"] == give_quantity
                ):
                    if tx["source"] == action_address or (
                        ledger.enabled("dispenser_origin_permission_extended", tx["block_index"])
                        and tx["source"] == existing[0]["origin"]
                    ):
                        if (oracle_address != None) and ledger.enabled(  # noqa: E711
                            "oracle_dispensers", tx["block_index"]
                        ):
                            oracle_fee = calculate_oracle_fee(
                                db,
                                escrow_quantity,
                                give_quantity,
                                mainchainrate,
                                oracle_address,
                                tx["block_index"],
                            )

                            if oracle_fee >= config.DEFAULT_REGULAR_DUST_SIZE:
                                if (
                                    tx["destination"] != oracle_address
                                    or tx["btc_amount"] < oracle_fee
                                ):
                                    status = "invalid: insufficient or non-existent oracle fee"

                        if status == "valid":
                            # Refill the dispenser by the given amount
                            try:
                                ledger.debit(
                                    db,
                                    tx["source"],
                                    asset,
                                    escrow_quantity,
                                    tx["tx_index"],
                                    action="refill dispenser",
                                    event=tx["tx_hash"],
                                )

                                set_data = {
                                    "give_remaining": existing[0]["give_remaining"]
                                    + escrow_quantity,
                                    "dispense_count": 0,  # reset the dispense count on refill
                                }
                                ledger.update_dispenser(
                                    db,
                                    existing[0]["rowid"],
                                    set_data,
                                    {"source": tx["source"], "asset": asset, "status": STATUS_OPEN},
                                )

                                dispenser_tx_hash = ledger.get_dispensers(
                                    db, address=action_address, asset=asset, status=STATUS_OPEN
                                )[0]["tx_hash"]
                                bindings_refill = {
                                    "tx_index": tx["tx_index"],
                                    "tx_hash": tx["tx_hash"],
                                    "block_index": tx["block_index"],
                                    "source": tx["source"],
                                    "destination": action_address,
                                    "asset": asset,
                                    "dispense_quantity": escrow_quantity,
                                    "dispenser_tx_hash": dispenser_tx_hash,
                                }
                                ledger.insert_record(
                                    db, "dispenser_refills", bindings_refill, "REFILL_DISPENSER"
                                )
                            except ledger.DebitError:
                                status = "insufficient funds"
                    else:
                        status = "invalid: can only refill dispenser from source or origin"
                else:
                    status = "can only have one open dispenser per asset per address"

            elif dispenser_status == STATUS_CLOSED:
                close_delay = ledger.get_value_by_block_index(
                    "dispenser_close_delay", tx["block_index"]
                )
                close_from_another_address = (
                    ledger.enabled("dispenser_origin_permission_extended", tx["block_index"])
                    and action_address
                    and action_address != tx["source"]
                )
                existing = []
                if close_from_another_address:
                    existing = ledger.get_dispensers(
                        db,
                        address=action_address,
                        asset=asset,
                        status=STATUS_OPEN,
                        origin=tx["source"],
                    )
                else:
                    existing = ledger.get_dispensers(
                        db, address=tx["source"], asset=asset, status=STATUS_OPEN
                    )
                if len(existing) == 1:
                    if close_delay == 0:
                        ledger.credit(
                            db,
                            tx["source"],
                            asset,
                            existing[0]["give_remaining"],
                            tx["tx_index"],
                            action="close dispenser",
                            event=tx["tx_hash"],
                        )

                        set_data = {
                            "give_remaining": 0,
                            "status": STATUS_CLOSED,
                        }
                    else:
                        set_data = {"status": STATUS_CLOSING, "last_status_tx_hash": tx["tx_hash"]}
                    ledger.update_dispenser(
                        db, existing[0]["rowid"], set_data, {"source": tx["source"], "asset": asset}
                    )
                else:
                    status = "dispenser inexistent"
            else:
                status = "invalid: status must be one of OPEN or CLOSE"

    if status != "valid":
        logger.debug(f"Not storing [dispenser] tx [{tx['tx_hash']}]: {status}")

    cursor.close()


def is_dispensable(db, address, amount):
    if address is None:
        return False

    dispensers = ledger.get_dispensers(db, address=address, status_in=[0, 11])

    for next_dispenser in dispensers:
        if next_dispenser["oracle_address"] != None:  # noqa: E711
            last_price, last_fee, last_fiat_label, last_updated = ledger.get_oracle_last_price(
                db, next_dispenser["oracle_address"], ledger.CURRENT_BLOCK_INDEX
            )
            fiatrate = util.satoshirate_to_fiat(next_dispenser["satoshirate"])
            if fiatrate == 0 or last_price == 0:
                return False
            if amount >= fiatrate / last_price:
                return True
        else:
            if amount >= next_dispenser["satoshirate"]:
                return True

    return False


def dispense(db, tx):
    cursor = db.cursor()

    outs = []
    if ledger.enabled("multiple_dispenses"):
        outs = ledger.get_vouts(db, tx["tx_hash"])
    else:
        outs = [tx]

    # if len(outs) == 0:
    #    outs = [tx]
    # or
    # assert len(outs) > 0 ?

    dispense_index = 0

    for next_out in outs:
        dispensers = []
        if next_out["destination"] is not None:
            dispensers = ledger.get_dispensers(
                db, address=next_out["destination"], status_in=[0, 11], order_by="asset"
            )

        for dispenser in dispensers:
            satoshirate = dispenser["satoshirate"]
            give_quantity = dispenser["give_quantity"]

            if satoshirate > 0 and give_quantity > 0:
                if (dispenser["oracle_address"] != None) and ledger.enabled(  # noqa: E711
                    "oracle_dispensers", next_out["block_index"]
                ):
                    last_price, last_fee, last_fiat_label, last_updated = (
                        ledger.get_oracle_last_price(
                            db, dispenser["oracle_address"], next_out["block_index"]
                        )
                    )
                    fiatrate = util.satoshirate_to_fiat(satoshirate)
                    must_give = int(
                        floor(((next_out["btc_amount"] / config.UNIT) * last_price) / fiatrate)
                    )
                else:
                    must_give = int(floor(next_out["btc_amount"] / satoshirate))

                remaining = int(floor(dispenser["give_remaining"] / give_quantity))
                actually_given = min(must_give, remaining) * give_quantity
                give_remaining = dispenser["give_remaining"] - actually_given

                assert give_remaining >= 0

                # Skip dispense if quantity is 0
                if ledger.enabled("zero_quantity_value_adjustment_1") and actually_given == 0:
                    continue

                ledger.credit(
                    db,
                    next_out["source"],
                    dispenser["asset"],
                    actually_given,
                    tx["tx_index"],
                    action="dispense",
                    event=next_out["tx_hash"],
                )

                # Checking if the dispenser reach its max dispenses limit
                max_dispenses_limit = ledger.get_value_by_block_index(
                    "max_dispenses_limit", next_out["block_index"]
                )
                max_dispenser_limit_hit = False

                if (
                    max_dispenses_limit > 0
                    and dispenser["dispense_count"] + 1 >= max_dispenses_limit
                ):
                    max_dispenser_limit_hit = True

                dispenser["give_remaining"] = give_remaining
                if give_remaining < dispenser["give_quantity"] or max_dispenser_limit_hit:
                    # close the dispenser
                    dispenser["give_remaining"] = 0
                    if give_remaining > 0:
                        if max_dispenser_limit_hit:
                            credit_action = "Closed: Max dispenses reached"
                            dispenser["closing_reason"] = "max_dispenses_reached"
                        else:
                            credit_action = "dispenser close"
                            dispenser["closing_reason"] = "no_more_to_give"

                        # return the remaining to the owner
                        ledger.credit(
                            db,
                            dispenser["source"],
                            dispenser["asset"],
                            give_remaining,
                            tx["tx_index"],
                            action=credit_action,
                            event=next_out["tx_hash"],
                        )
                    else:
                        dispenser["closing_reason"] = "depleted"
                    dispenser["status"] = STATUS_CLOSED

                dispenser["block_index"] = next_out["block_index"]
                dispenser["prev_status"] = STATUS_OPEN

                set_data = {
                    "give_remaining": dispenser["give_remaining"],
                    "status": dispenser["status"],
                    "dispense_count": dispenser["dispense_count"] + 1,
                }
                ledger.update_dispenser(
                    db,
                    dispenser["rowid"],
                    set_data,
                    {"source": dispenser["source"], "asset": dispenser["asset"]},
                )

                bindings = {
                    "tx_index": next_out["tx_index"],
                    "tx_hash": next_out["tx_hash"],
                    "dispense_index": dispense_index,
                    "block_index": next_out["block_index"],
                    "source": next_out["destination"],
                    "destination": next_out["source"],
                    "asset": dispenser["asset"],
                    "dispense_quantity": actually_given,
                    "dispenser_tx_hash": dispenser["tx_hash"],
                }
                ledger.insert_record(db, "dispenses", bindings, "DISPENSE")
                dispense_index += 1

    cursor.close()


def close_pending(db, block_index):
    block_delay = ledger.get_value_by_block_index("dispenser_close_delay", block_index)

    if block_delay > 0:
        pending_dispensers = ledger.get_pending_dispensers(
            db, delay=block_delay, block_index=block_index
        )

        for dispenser in pending_dispensers:
            # use tx_index=0 for block actions
            ledger.credit(
                db,
                dispenser["tx_source"],
                dispenser["asset"],
                dispenser["give_remaining"],
                0,
                action="close dispenser",
                event=dispenser["last_status_tx_hash"],
            )

            set_data = {
                "give_remaining": 0,
                "status": STATUS_CLOSED,
            }
            ledger.update_dispenser(
                db,
                dispenser["rowid"],
                set_data,
                {"source": dispenser["source"], "asset": dispenser["asset"]},
            )  # use tx_index=0 for block actions
