# Filled orders may not be re‐opened, so only orders not involving BTC (and so
# which cannot have expired order matches) may be filled.
import decimal
import logging
import struct

from counterpartycore.lib import (
    config,
    exceptions,
    ledger,
)
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser import messagetype, protocol
from counterpartycore.lib.utils import helpers

logger = logging.getLogger(config.LOGGER_NAME)
D = decimal.Decimal

FORMAT = ">QQQQHQ"
LENGTH = 8 + 8 + 8 + 8 + 2 + 8
ID = 10


def exact_penalty(db, address, block_index, order_match_id, tx_index):
    # Penalize addresses that don’t make BTC payments. If an address lets an
    # order match expire, expire sell BTC orders from that address.
    cursor = db.cursor()

    # Orders.
    bad_orders = ledger.ledger.get_open_btc_orders(db, address)
    for bad_order in bad_orders:
        cancel_order(db, bad_order, "expired", block_index, tx_index)

    if not protocol.after_block_or_test_network(block_index, 314250):  # Protocol change.
        # Order matches.
        bad_order_matches = ledger.ledger.get_pending_btc_order_matches(db, address)
        for bad_order_match in bad_order_matches:
            cancel_order_match(db, bad_order_match, "expired", block_index, tx_index)

    cursor.close()
    return


def cancel_order(db, order, status, block_index, tx_index):
    cursor = db.cursor()

    # Update status of order.
    set_data = {
        "status": status,
    }
    ledger.ledger.update_order(db, order["tx_hash"], set_data)

    if order["give_asset"] != config.BTC:  # Can’t credit BTC.
        ledger.events.credit(
            db,
            order["source"],
            order["give_asset"],
            order["give_remaining"],
            tx_index,
            action="cancel order",
            event=order["tx_hash"],
        )

    if status == "expired":
        # Record offer expiration.
        bindings = {
            "order_hash": order["tx_hash"],
            "source": order["source"],
            "block_index": block_index,
        }
        ledger.events.insert_record(db, "order_expirations", bindings, "ORDER_EXPIRATION")

    logger.info(
        "Order cancelled %(give_asset)s / %(get_asset)s (%(order_hash)s) [%(status)s]",
        {
            "give_asset": order["give_asset"],
            "get_asset": order["get_asset"],
            "order_hash": order["tx_hash"],
            "status": status,
        },
    )

    cursor.close()


def cancel_order_match(db, order_match, status, block_index, tx_index):
    """The only cancelling is an expiration."""
    # Skip order matches just expired as a penalty. (Not very efficient.)
    if not protocol.after_block_or_test_network(block_index, 314250):  # Protocol change.
        order_matches = ledger.ledger.get_order_match(db, id=order_match["id"])
        if order_matches and order_matches[0]["status"] == "expired":
            return

    # Update status of order match.
    ledger.ledger.update_order_match_status(db, order_match["id"], status)

    # If tx0 is dead, credit address directly; if not, replenish give remaining, get remaining, and fee required remaining.
    orders = ledger.ledger.get_order(db, order_hash=order_match["tx0_hash"])
    assert len(orders) == 1
    tx0_order = orders[0]
    if tx0_order["status"] in ("expired", "cancelled"):
        tx0_order_status = tx0_order["status"]
        if order_match["forward_asset"] != config.BTC:
            ledger.events.credit(
                db,
                order_match["tx0_address"],
                order_match["forward_asset"],
                order_match["forward_quantity"],
                tx_index,
                action=f"order {tx0_order_status}",
                event=order_match["id"],
            )
    else:
        tx0_give_remaining = tx0_order["give_remaining"] + order_match["forward_quantity"]
        tx0_get_remaining = tx0_order["get_remaining"] + order_match["backward_quantity"]
        if tx0_order["get_asset"] == config.BTC and protocol.after_block_or_test_network(
            block_index, 297000
        ):  # Protocol change.
            tx0_fee_required_remaining = (
                tx0_order["fee_required_remaining"] + order_match["fee_paid"]
            )
        else:
            tx0_fee_required_remaining = tx0_order["fee_required_remaining"]
        tx0_order_status = tx0_order["status"]

        if (
            tx0_order_status == "filled"
            and protocol.enabled("reopen_order_when_btcpay_expires_fix", block_index)
        ):  # This case could happen if a BTCpay expires and before the expiration, the order was filled by a correct BTCpay
            tx0_order_status = "open"  # So, we have to open the order again

        set_data = {
            "give_remaining": tx0_give_remaining,
            "get_remaining": tx0_get_remaining,
            "status": tx0_order_status,
            "fee_required_remaining": tx0_fee_required_remaining,
        }
        ledger.ledger.update_order(db, order_match["tx0_hash"], set_data)

    # If tx1 is dead, credit address directly; if not, replenish give remaining, get remaining, and fee required remaining.
    orders = ledger.ledger.get_order(db, order_hash=order_match["tx1_hash"])
    assert len(orders) == 1
    tx1_order = orders[0]
    if tx1_order["status"] in ("expired", "cancelled"):
        tx1_order_status = tx1_order["status"]
        if order_match["backward_asset"] != config.BTC:
            ledger.events.credit(
                db,
                order_match["tx1_address"],
                order_match["backward_asset"],
                order_match["backward_quantity"],
                tx_index,
                action=f"order {tx1_order_status}",
                event=order_match["id"],
            )
    else:
        tx1_give_remaining = tx1_order["give_remaining"] + order_match["backward_quantity"]
        tx1_get_remaining = tx1_order["get_remaining"] + order_match["forward_quantity"]
        if tx1_order["get_asset"] == config.BTC and protocol.after_block_or_test_network(
            block_index, 297000
        ):  # Protocol change.
            tx1_fee_required_remaining = (
                tx1_order["fee_required_remaining"] + order_match["fee_paid"]
            )
        else:
            tx1_fee_required_remaining = tx1_order["fee_required_remaining"]
        tx1_order_status = tx1_order["status"]
        if (
            tx1_order_status == "filled"
            and protocol.enabled("reopen_order_when_btcpay_expires_fix", block_index)
        ):  # This case could happen if a BTCpay expires and before the expiration, the order was filled by a correct BTCpay
            tx1_order_status = "open"  # So, we have to open the order again

        set_data = {
            "give_remaining": tx1_give_remaining,
            "get_remaining": tx1_get_remaining,
            "status": tx1_order_status,
            "fee_required_remaining": tx1_fee_required_remaining,
        }
        ledger.ledger.update_order(db, order_match["tx1_hash"], set_data)

    if block_index < 286500:  # Protocol change.
        # Sanity check: one of the two must have expired.
        tx0_order_time_left = tx0_order["expire_index"] - block_index
        tx1_order_time_left = tx1_order["expire_index"] - block_index
        assert tx0_order_time_left or tx1_order_time_left

    # Penalize tardiness.
    if protocol.after_block_or_test_network(block_index, 313900):  # Protocol change.
        if tx0_order["status"] == "expired" and order_match["forward_asset"] == config.BTC:
            exact_penalty(db, order_match["tx0_address"], block_index, order_match["id"], tx_index)
        if tx1_order["status"] == "expired" and order_match["backward_asset"] == config.BTC:
            exact_penalty(db, order_match["tx1_address"], block_index, order_match["id"], tx_index)

    # Re‐match.
    if protocol.after_block_or_test_network(block_index, 310000):  # Protocol change.
        if not protocol.after_block_or_test_network(block_index, 315000):  # Protocol change.
            match(
                db, ledger.blocks.get_transactions(db, tx_hash=tx0_order["tx_hash"])[0], block_index
            )
            match(
                db, ledger.blocks.get_transactions(db, tx_hash=tx1_order["tx_hash"])[0], block_index
            )

    if status == "expired":
        # Record order match expiration.
        cursor = db.cursor()  # noqa: F841
        bindings = {
            "order_match_id": order_match["id"],
            "tx0_address": order_match["tx0_address"],
            "tx1_address": order_match["tx1_address"],
            "block_index": block_index,
        }
        ledger.events.insert_record(
            db, "order_match_expirations", bindings, "ORDER_MATCH_EXPIRATION"
        )

    logger.info(
        "Order match cancelled %(forward_asset)s / %(backward_asset)s (%(order_match_id)s) [%(status)s]",
        {
            "forward_asset": order_match["forward_asset"],
            "backward_asset": order_match["backward_asset"],
            "order_match_id": order_match["id"],
            "status": status,
        },
    )


def validate(
    db,
    source,
    give_asset,
    give_quantity,
    get_asset,
    get_quantity,
    expiration,
    fee_required,
    block_index,
):
    problems = []
    cursor = db.cursor()

    # For SQLite3
    if (
        give_quantity > config.MAX_INT
        or get_quantity > config.MAX_INT
        or fee_required > config.MAX_INT
        or block_index + expiration > config.MAX_INT
    ):
        problems.append("integer overflow")

    if give_asset == config.BTC and get_asset == config.BTC:
        problems.append(f"cannot trade {config.BTC} for itself")

    if not isinstance(give_quantity, int):
        problems.append("give_quantity must be in satoshis")
        return problems
    if not isinstance(get_quantity, int):
        problems.append("get_quantity must be in satoshis")
        return problems
    if not isinstance(fee_required, int):
        problems.append("fee_required must be in satoshis")
        return problems
    if not isinstance(expiration, int):
        problems.append("expiration must be expressed as an integer block delta")
        return problems

    if give_quantity <= 0:
        problems.append("non‐positive give quantity")
    if get_quantity <= 0:
        problems.append("non‐positive get quantity")
    if fee_required < 0:
        problems.append("negative fee_required")
    if expiration < 0:
        problems.append("negative expiration")
    if expiration == 0 and not protocol.after_block_or_test_network(
        block_index, 317500
    ):  # Protocol change.
        problems.append("zero expiration")

    if not give_quantity or not get_quantity:
        problems.append("zero give or zero get")
    if give_asset not in (config.BTC, config.XCP) and not ledger.ledger.get_issuances(
        db, status="valid", asset=give_asset, current_block_index=block_index
    ):
        problems.append(f"no such asset to give ({give_asset})")
    if get_asset not in (config.BTC, config.XCP) and not ledger.ledger.get_issuances(
        db, status="valid", asset=get_asset, current_block_index=block_index
    ):
        problems.append(f"no such asset to get ({get_asset})")
    if expiration > config.MAX_EXPIRATION:
        problems.append("expiration overflow")

    cursor.close()
    return problems


def compose(
    db,
    source: str,
    give_asset: str,
    give_quantity: int,
    get_asset: str,
    get_quantity: int,
    expiration: int,
    fee_required: int,
    skip_validation: bool = False,
):
    cursor = db.cursor()

    # resolve subassets
    give_asset = ledger.ledger.resolve_subasset_longname(db, give_asset)
    get_asset = ledger.ledger.resolve_subasset_longname(db, get_asset)

    # Check balance.
    if give_asset != config.BTC:
        balance = ledger.balances.get_balance(db, source, give_asset)
        if balance < give_quantity:
            raise exceptions.ComposeError("insufficient funds")

    problems = validate(
        db,
        source,
        give_asset,
        give_quantity,
        get_asset,
        get_quantity,
        expiration,
        fee_required,
        CurrentState().current_block_index(),
    )
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    give_id = ledger.ledger.get_asset_id(db, give_asset, CurrentState().current_block_index())
    get_id = ledger.ledger.get_asset_id(db, get_asset, CurrentState().current_block_index())
    data = messagetype.pack(ID)
    data += struct.pack(
        FORMAT, give_id, give_quantity, get_id, get_quantity, expiration, fee_required
    )
    cursor.close()
    return (source, [], data)


def unpack(db, message, block_index, return_dict=False):
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        give_id, give_quantity, get_id, get_quantity, expiration, fee_required = struct.unpack(
            FORMAT, message
        )
        give_asset = ledger.ledger.get_asset_name(db, give_id, block_index)
        get_asset = ledger.ledger.get_asset_name(db, get_id, block_index)
        status = "open"
    except (exceptions.UnpackError, exceptions.AssetNameError, struct.error) as e:  # noqa: F841
        give_asset, give_quantity, get_asset, get_quantity, expiration, fee_required = (
            0,
            0,
            0,
            0,
            0,
            0,
        )
        status = "invalid: could not unpack"

    if return_dict:
        return {
            "give_asset": give_asset,
            "give_quantity": give_quantity,
            "get_asset": get_asset,
            "get_quantity": get_quantity,
            "expiration": expiration,
            "fee_required": fee_required,
            "status": status,
        }
    return give_asset, give_quantity, get_asset, get_quantity, expiration, fee_required, status


def parse(db, tx, message):
    order_parse_cursor = db.cursor()

    # Unpack message.
    (give_asset, give_quantity, get_asset, get_quantity, expiration, fee_required, status) = unpack(
        db, message, tx["block_index"]
    )

    price = 0
    if status == "open":
        try:
            price = ledger.ledger.price(get_quantity, give_quantity)
        except ZeroDivisionError:
            price = 0

        # Overorder
        balance = ledger.balances.get_balance(db, tx["source"], give_asset)
        if give_asset != config.BTC:
            if balance == 0:
                give_quantity = 0
            else:
                if balance < give_quantity:
                    give_quantity = balance
                    get_quantity = int(price * give_quantity)

        problems = validate(
            db,
            tx["source"],
            give_asset,
            give_quantity,
            get_asset,
            get_quantity,
            expiration,
            fee_required,
            tx["block_index"],
        )
        if problems:
            status = "invalid: " + "; ".join(problems)

        if protocol.enabled("btc_order_minimum"):
            min_btc_quantity = 0.001 * config.UNIT  # 0.001 BTC
            if protocol.enabled("btc_order_minimum_adjustment_1"):
                min_btc_quantity = 0.00001 * config.UNIT  # 0.00001 BTC
            if protocol.enabled("fix_min_btc_quantity", tx["block_index"]):
                min_btc_quantity = int(D("0.00001") * D(1e8))

            if (give_asset == config.BTC and give_quantity < min_btc_quantity) or (
                get_asset == config.BTC and get_quantity < min_btc_quantity
            ):
                if problems:
                    status += "; btc order below minimum"
                else:
                    status = "invalid: btc order below minimum"

    # Debit give quantity. (Escrow.)
    if status == "open":
        if give_asset != config.BTC:  # No need (or way) to debit BTC.
            ledger.events.debit(
                db,
                tx["source"],
                give_asset,
                give_quantity,
                tx["tx_index"],
                action="open order",
                event=tx["tx_hash"],
            )

    # Add parsed transaction to message-type–specific table.
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "give_asset": give_asset,
        "give_quantity": give_quantity,
        "give_remaining": give_quantity,
        "get_asset": get_asset,
        "get_quantity": get_quantity,
        "get_remaining": get_quantity,
        "expiration": expiration,
        "expire_index": tx["block_index"] + expiration,
        "fee_required": fee_required,
        "fee_required_remaining": fee_required,
        "fee_provided": tx["fee"],
        "fee_provided_remaining": tx["fee"],
        "status": status,
    }
    if "integer overflow" not in status:
        ledger.ledger.insert_order(db, bindings)

    logger.info(
        "Order opened for %(give_quantity)s %(give_asset)s at %(source)s (%(tx_hash)s) [%(status)s]",
        bindings,
    )

    # Match.
    if status == "open" and tx["block_index"] != config.MEMPOOL_BLOCK_INDEX:
        match(db, tx)

    order_parse_cursor.close()


def match(db, tx, block_index=None):
    cursor = db.cursor()

    # Get order in question.
    orders = ledger.ledger.get_order(db, order_hash=tx["tx_hash"])
    if not orders:
        cursor.close()
        return
    else:
        assert len(orders) == 1
        if orders[0]["status"] != "open":
            cursor.close()
            return

    tx1 = orders[0]

    tx1_give_remaining = tx1["give_remaining"]
    tx1_get_remaining = tx1["get_remaining"]

    order_matches = ledger.ledger.get_matching_orders(
        db, tx1["tx_hash"], give_asset=tx1["give_asset"], get_asset=tx1["get_asset"]
    )

    if protocol.after_block_or_test_network(tx["block_index"], 284501):  # Protocol change.
        order_matches = sorted(
            order_matches, key=lambda x: x["tx_index"]
        )  # Sort by tx index second.
        order_matches = sorted(
            order_matches, key=lambda x: ledger.ledger.price(x["get_quantity"], x["give_quantity"])
        )  # Sort by price first.

    # Get fee remaining.
    tx1_fee_required_remaining = tx1["fee_required_remaining"]
    tx1_fee_provided_remaining = tx1["fee_provided_remaining"]

    tx1_status = tx1["status"]
    for tx0 in order_matches:
        # Sanity check. Should never happen.
        if tx0["status"] != "open":
            raise Exception(f"Order match is not open: {tx0}.")
        order_match_id = helpers.make_id(tx0["tx_hash"], tx1["tx_hash"])
        if not block_index:
            block_index = max(
                ledger.ledger.get_order_first_block_index(cursor, tx0["tx_hash"]),
                ledger.ledger.get_order_first_block_index(cursor, tx1["tx_hash"]),
            )
        if tx1_status != "open":
            break

        logger.trace("Considering: " + tx0["tx_hash"])
        tx0_give_remaining = tx0["give_remaining"]
        tx0_get_remaining = tx0["get_remaining"]

        # Ignore previous matches. (Both directions, just to be sure.)
        if ledger.ledger.get_order_match(db, id=helpers.make_id(tx0["tx_hash"], tx1["tx_hash"])):
            logger.trace("Skipping: previous match")
            continue
        if ledger.ledger.get_order_match(db, id=helpers.make_id(tx1["tx_hash"], tx0["tx_hash"])):
            logger.trace("Skipping: previous match")
            continue

        # Get fee provided remaining.
        tx0_fee_required_remaining = tx0["fee_required_remaining"]
        tx0_fee_provided_remaining = tx0["fee_provided_remaining"]

        # Make sure that that both orders still have funds remaining (if order involves BTC, and so cannot be ‘filled’).
        if tx0["give_asset"] == config.BTC or tx0["get_asset"] == config.BTC:  # Gratuitous
            if tx0_give_remaining <= 0 or tx1_give_remaining <= 0:
                logger.trace("Skipping: negative give quantity remaining")
                continue
            if (
                block_index >= 292000 and block_index <= 310500 and not protocol.is_test_network()
            ):  # Protocol changes
                if tx0_get_remaining <= 0 or tx1_get_remaining <= 0:
                    logger.trace("Skipping: negative get quantity remaining")
                    continue

            if protocol.after_block_or_test_network(block_index, 294000):  # Protocol change.
                if tx0["fee_required_remaining"] < 0:
                    logger.trace("Skipping: negative tx0 fee required remaining")
                    continue
                if tx0["fee_provided_remaining"] < 0:
                    logger.trace("Skipping: negative tx0 fee provided remaining")
                    continue
                if tx1_fee_provided_remaining < 0:
                    logger.trace("Skipping: negative tx1 fee provided remaining")
                    continue
                if tx1_fee_required_remaining < 0:
                    logger.trace("Skipping: negative tx1 fee required remaining")
                    continue

        # If the prices agree, make the trade. The found order sets the price,
        # and they trade as much as they can.
        tx0_price = ledger.ledger.price(tx0["get_quantity"], tx0["give_quantity"])
        tx1_price = ledger.ledger.price(tx1["get_quantity"], tx1["give_quantity"])
        tx1_inverse_price = ledger.ledger.price(tx1["give_quantity"], tx1["get_quantity"])

        # Protocol change.
        if tx["block_index"] < 286000:
            tx1_inverse_price = ledger.ledger.price(1, tx1_price)

        logger.trace(
            f"Tx0 Price: {float(tx0_price)}; Tx1 Inverse Price: {float(tx1_inverse_price)}"
        )
        if tx0_price > tx1_inverse_price:
            logger.trace("Skipping: price mismatch.")
        else:
            logger.trace(
                f"Potential forward quantities: {tx0_give_remaining}, {int(ledger.ledger.price(tx1_give_remaining, tx0_price))}"
            )
            forward_quantity = int(
                min(tx0_give_remaining, int(ledger.ledger.price(tx1_give_remaining, tx0_price)))
            )
            logger.trace(f"Forward Quantity: {forward_quantity}")
            backward_quantity = round(forward_quantity * tx0_price)
            logger.trace(f"Backward Quantity: {backward_quantity}")

            if not forward_quantity:
                logger.trace("Skipping: zero forward quantity.")
                continue
            if protocol.after_block_or_test_network(block_index, 286500):  # Protocol change.
                if not backward_quantity:
                    logger.trace("Skipping: zero backward quantity.")
                    continue

            forward_asset, backward_asset = tx1["get_asset"], tx1["give_asset"]

            if protocol.after_block_or_test_network(block_index, 313900):  # Protocol change.
                min_btc_quantity = 0.001 * config.UNIT  # 0.001 BTC
                if protocol.enabled("fix_min_btc_quantity", block_index):
                    # we subtract 1 because the <= instead of < like when checking orders
                    min_btc_quantity = int(D("0.00001") * D(1e8)) - 1
                if (forward_asset == config.BTC and forward_quantity <= min_btc_quantity) or (
                    backward_asset == config.BTC and backward_quantity <= min_btc_quantity
                ):
                    logger.trace(f"Skipping: below minimum {config.BTC} quantity")
                    continue

            # Check and update fee remainings.
            fee = 0
            if protocol.after_block_or_test_network(
                block_index, 286500
            ):  # Protocol change. Deduct fee_required from provided_remaining, etc., if possible (else don’t match).
                if tx1["get_asset"] == config.BTC:
                    if protocol.after_block_or_test_network(
                        block_index, 310500
                    ):  # Protocol change.
                        fee = int(
                            tx1["fee_required"]
                            * ledger.ledger.price(backward_quantity, tx1["give_quantity"])
                        )
                    else:
                        fee = int(
                            tx1["fee_required_remaining"]
                            * ledger.ledger.price(forward_quantity, tx1_get_remaining)
                        )

                    logger.trace(
                        f"Tx0 fee provided remaining: {tx0_fee_provided_remaining / config.UNIT}; required fee: {fee / config.UNIT}"
                    )
                    if tx0_fee_provided_remaining < fee:
                        logger.trace("Skipping: tx0 fee provided remaining is too low.")
                        continue
                    else:
                        tx0_fee_provided_remaining -= fee
                        if protocol.after_block_or_test_network(
                            block_index, 287800
                        ):  # Protocol change.
                            tx1_fee_required_remaining -= fee

                elif tx1["give_asset"] == config.BTC:
                    if protocol.after_block_or_test_network(
                        block_index, 310500
                    ):  # Protocol change.
                        fee = int(
                            tx0["fee_required"]
                            * ledger.ledger.price(backward_quantity, tx0["give_quantity"])
                        )
                    else:
                        fee = int(
                            tx0["fee_required_remaining"]
                            * ledger.ledger.price(backward_quantity, tx0_get_remaining)
                        )

                    logger.trace(
                        f"Tx1 fee provided remaining: {tx1_fee_provided_remaining / config.UNIT}; required fee: {fee / config.UNIT}"
                    )
                    if tx1_fee_provided_remaining < fee:
                        logger.trace("Skipping: tx1 fee provided remaining is too low.")
                        continue
                    else:
                        tx1_fee_provided_remaining -= fee
                        if protocol.after_block_or_test_network(
                            block_index, 287800
                        ):  # Protocol change.
                            tx0_fee_required_remaining -= fee

            else:  # Don’t deduct.
                if tx1["get_asset"] == config.BTC:
                    if tx0_fee_provided_remaining < tx1["fee_required"]:
                        continue
                elif tx1["give_asset"] == config.BTC:
                    if tx1_fee_provided_remaining < tx0["fee_required"]:
                        continue

            if config.BTC in (tx1["give_asset"], tx1["get_asset"]):
                status = "pending"
            else:
                status = "completed"
                # Credit.
                ledger.events.credit(
                    db,
                    tx1["source"],
                    tx1["get_asset"],
                    forward_quantity,
                    tx["block_index"],
                    action="order match",
                    event=order_match_id,
                )
                ledger.events.credit(
                    db,
                    tx0["source"],
                    tx0["get_asset"],
                    backward_quantity,
                    tx["block_index"],
                    action="order match",
                    event=order_match_id,
                )

            # Debit the order, even if it involves giving bitcoins, and so one
            # can't debit the sending account.
            # Get remainings may be negative.
            tx0_give_remaining -= forward_quantity
            tx0_get_remaining -= backward_quantity
            tx1_give_remaining -= backward_quantity
            tx1_get_remaining -= forward_quantity

            # Update give_remaining, get_remaining.
            # tx0
            tx0_status = "open"
            if tx0_give_remaining <= 0 or (
                tx0_get_remaining <= 0 and protocol.after_block_or_test_network(block_index, 292000)
            ):  # Protocol change
                if tx0["give_asset"] != config.BTC and tx0["get_asset"] != config.BTC:
                    # Fill order, and recredit give_remaining.
                    tx0_status = "filled"
                    ledger.events.credit(
                        db,
                        tx0["source"],
                        tx0["give_asset"],
                        tx0_give_remaining,
                        tx["block_index"],
                        event=tx1["tx_hash"],
                        action="filled",
                    )
            set_data = {
                "give_remaining": tx0_give_remaining,
                "get_remaining": tx0_get_remaining,
                "fee_required_remaining": tx0_fee_required_remaining,
                "fee_provided_remaining": tx0_fee_provided_remaining,
                "status": tx0_status,
            }
            ledger.ledger.update_order(db, tx0["tx_hash"], set_data)

            # tx1
            if tx1_give_remaining <= 0 or (
                tx1_get_remaining <= 0 and protocol.after_block_or_test_network(block_index, 292000)
            ):  # Protocol change
                if tx1["give_asset"] != config.BTC and tx1["get_asset"] != config.BTC:
                    # Fill order, and recredit give_remaining.
                    tx1_status = "filled"
                    ledger.events.credit(
                        db,
                        tx1["source"],
                        tx1["give_asset"],
                        tx1_give_remaining,
                        tx["block_index"],
                        event=tx0["tx_hash"],
                        action="filled",
                    )
            set_data = {
                "give_remaining": tx1_give_remaining,
                "get_remaining": tx1_get_remaining,
                "fee_required_remaining": tx1_fee_required_remaining,
                "fee_provided_remaining": tx1_fee_provided_remaining,
                "status": tx1_status,
            }
            ledger.ledger.update_order(db, tx1["tx_hash"], set_data)

            # Calculate when the match will expire.
            if protocol.after_block_or_test_network(block_index, 308000):  # Protocol change.
                match_expire_index = block_index + 20
            elif protocol.after_block_or_test_network(block_index, 286500):  # Protocol change.
                match_expire_index = block_index + 10
            else:
                match_expire_index = min(tx0["expire_index"], tx1["expire_index"])

            # Record order match.
            bindings = {
                "id": helpers.make_id(tx0["tx_hash"], tx["tx_hash"]),
                "tx0_index": tx0["tx_index"],
                "tx0_hash": tx0["tx_hash"],
                "tx0_address": tx0["source"],
                "tx1_index": tx1["tx_index"],
                "tx1_hash": tx1["tx_hash"],
                "tx1_address": tx1["source"],
                "forward_asset": forward_asset,
                "forward_quantity": forward_quantity,
                "backward_asset": backward_asset,
                "backward_quantity": backward_quantity,
                "tx0_block_index": tx0["block_index"],
                "tx1_block_index": tx1["block_index"],
                "block_index": block_index,
                "tx0_expiration": tx0["expiration"],
                "tx1_expiration": tx1["expiration"],
                "match_expire_index": match_expire_index,
                "fee_paid": fee,
                "status": status,
            }
            ledger.events.insert_record(db, "order_matches", bindings, "ORDER_MATCH")

            logger.info(
                "Order match for %(forward_quantity)s %(forward_asset)s against %(backward_quantity)s %(backward_asset)s (%(id)s) [%(status)s]",
                bindings,
            )

            if tx1_status == "filled":
                break

    cursor.close()
    return


def expire_orders(db, block_index):
    # Expire orders and give refunds for the quantity give_remaining (if non-zero; if not BTC).
    orders = ledger.ledger.get_orders_to_expire(db, block_index)
    # Edge case: filled orders, and therefore not expired in the previous block,
    # re-ropened by order_match expiration in the previous block.
    # TODO: protocol change: expire order matches then orders.
    orders += ledger.ledger.get_orders_to_expire(db, block_index - 1)
    for order in orders:
        cancel_order(db, order, "expired", block_index, 0)  # tx_index=0 for block action


def expire_order_matches(db, block_index):
    # Expire order_matches for BTC with no BTC.
    order_matches = ledger.ledger.get_order_matches_to_expire(db, block_index)
    for order_match in order_matches:
        cancel_order_match(
            db, order_match, "expired", block_index, 0
        )  # tx_index=0 for block action

        # Expire btc sell order if match expires
        if protocol.enabled("btc_sell_expire_on_match_expire"):
            # Check for other pending order matches involving either tx0_hash or tx1_hash
            order_matches_pending = ledger.ledger.get_pending_order_matches(
                db, tx0_hash=order_match["tx0_hash"], tx1_hash=order_match["tx1_hash"]
            )
            # Set BTC sell order status as expired only if there are no pending order matches
            if len(order_matches_pending) == 0:
                if order_match["backward_asset"] == "BTC" and order_match["status"] == "expired":
                    cancel_order(
                        db,
                        ledger.ledger.get_order(db, order_hash=order_match["tx1_hash"])[0],
                        "expired",
                        block_index,
                    )
                if order_match["forward_asset"] == "BTC" and order_match["status"] == "expired":
                    cancel_order(
                        db,
                        ledger.ledger.get_order(db, order_hash=order_match["tx0_hash"])[0],
                        "expired",
                        block_index,
                    )

    if protocol.after_block_or_test_network(block_index, 315000):  # Protocol change.
        # Re‐match.
        for order_match in order_matches:
            match(
                db, ledger.ledger.get_order(db, order_hash=order_match["tx0_hash"])[0], block_index
            )
            match(
                db, ledger.ledger.get_order(db, order_hash=order_match["tx1_hash"])[0], block_index
            )


def expire(db, block_index):
    if protocol.enabled("expire_order_matches_then_orders"):
        expire_order_matches(db, block_index)
        expire_orders(db, block_index)
    else:
        expire_orders(db, block_index)
        expire_order_matches(db, block_index)
