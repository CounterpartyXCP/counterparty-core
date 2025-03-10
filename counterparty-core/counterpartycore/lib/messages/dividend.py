"""Pay out dividends."""

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

D = decimal.Decimal

logger = logging.getLogger(config.LOGGER_NAME)

FORMAT_1 = ">QQ"
LENGTH_1 = 8 + 8
FORMAT_2 = ">QQQ"
LENGTH_2 = 8 + 8 + 8
ID = 50


def validate(db, source, quantity_per_unit, asset, dividend_asset, block_index):
    cursor = db.cursor()
    problems = []

    if asset == config.BTC:
        problems.append(f"cannot pay dividends to holders of {config.BTC}")
    if asset == config.XCP:
        if not protocol.enabled("no_zero_expiration") or protocol.enabled(
            "no_xcp_dividends"
        ):  # Protocol change.
            problems.append(f"cannot pay dividends to holders of {config.XCP}")

    if quantity_per_unit <= 0:
        problems.append("non‐positive quantity per unit")

    # For SQLite3
    if quantity_per_unit > config.MAX_INT:
        problems.append("integer overflow")

    # Examine asset.
    try:
        divisible = ledger.issuances.is_divisible(db, asset)
    except exceptions.AssetError:
        problems.append(f"no such asset, {asset}.")
        return None, None, problems, 0

    # Only issuer can pay dividends.
    if protocol.enabled("no_xcp_dividends"):  # Protocol change.
        issuer = ledger.issuances.get_asset_issuer(db, asset)

        if issuer != source:
            problems.append("only issuer can pay dividends")

    # Examine dividend asset.
    try:
        dividend_divisible = ledger.issuances.is_divisible(db, dividend_asset)
    except exceptions.AssetError:
        problems.append(f"no such dividend asset, {dividend_asset}.")
        return None, None, problems, 0

    # Calculate dividend quantities.
    exclude_empty = False
    if protocol.enabled("zero_quantity_value_adjustment_1"):
        exclude_empty = True
    asset_holders = ledger.supplies.holders(db, asset, exclude_empty)

    outputs = []
    addresses = []
    dividend_total = 0
    for holder in asset_holders:
        if (
            not protocol.enabled("price_as_fraction") and not protocol.is_test_network()
        ):  # Protocol change.
            if holder["escrow"]:
                continue

        address = holder["address"]
        address_quantity = holder["address_quantity"]

        dividend_quantity = address_quantity * quantity_per_unit

        if divisible:
            dividend_quantity /= config.UNIT
        if not protocol.enabled("nondivisible_dividend_fix") and not dividend_divisible:
            dividend_quantity /= config.UNIT  # Pre-fix behaviour

        if dividend_asset == config.BTC and dividend_quantity < config.DEFAULT_MULTISIG_DUST_SIZE:
            continue  # A bit hackish.
        dividend_quantity = int(dividend_quantity)

        outputs.append(
            {
                "address": address,
                "address_quantity": address_quantity,
                "dividend_quantity": dividend_quantity,
            }
        )
        addresses.append(address)
        dividend_total += dividend_quantity

    if not dividend_total:
        problems.append("zero dividend")

    if dividend_asset != config.BTC:
        dividend_balances = ledger.balances.get_balance(db, source, dividend_asset)
        if dividend_balances < dividend_total:
            problems.append(f"insufficient funds ({dividend_asset})")

    fee = 0
    if not problems and dividend_asset != config.BTC:
        holder_count = len(set(addresses))
        if protocol.enabled("dividend_fees"):  # Protocol change.
            fee = int(0.0002 * config.UNIT * holder_count)
        if fee:
            balance = ledger.balances.get_balance(db, source, config.XCP)
            if balance < fee:
                problems.append(f"insufficient funds ({config.XCP})")

    if not problems and dividend_asset == config.XCP:
        total_cost = dividend_total + fee
        if dividend_balances < total_cost:
            problems.append(f"insufficient funds ({dividend_asset})")

    # For SQLite3
    if fee > config.MAX_INT or dividend_total > config.MAX_INT:
        problems.append("integer overflow")

    cursor.close()

    if len(problems) > 0:
        return None, None, problems, 0

    # preserve order with old queries
    if not protocol.is_test_network() and block_index in [313590, 313594]:
        outputs.append(outputs.pop(-3))

    return dividend_total, outputs, problems, fee


def get_estimate_xcp_fee(db, asset):
    all_holders = ledger.supplies.holders(db, asset, True)
    addresses = [holder["address"] for holder in all_holders]
    holder_count = len(set(addresses))
    return int(0.0002 * config.UNIT * holder_count)


def compose(
    db,
    source: str,
    quantity_per_unit: int,
    asset: str,
    dividend_asset: str,
    skip_validation: bool = False,
):
    # resolve subassets
    asset = ledger.issuances.resolve_subasset_longname(db, asset)
    dividend_asset = ledger.issuances.resolve_subasset_longname(db, dividend_asset)

    dividend_total, outputs, problems, _fee = validate(
        db, source, quantity_per_unit, asset, dividend_asset, CurrentState().current_block_index()
    )
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)
    logger.info(
        "Total quantity to be distributed in dividends: %s %s",
        ledger.issuances.value_out(db, dividend_total, dividend_asset),
        dividend_asset,
    )

    if dividend_asset == config.BTC:
        return (
            source,
            [(output["address"], output["dividend_quantity"]) for output in outputs],
            None,
        )

    asset_id = ledger.issuances.get_asset_id(db, asset)
    dividend_asset_id = ledger.issuances.get_asset_id(db, dividend_asset)
    data = messagetype.pack(ID)
    data += struct.pack(FORMAT_2, quantity_per_unit, asset_id, dividend_asset_id)
    return (source, [], data)


def unpack(db, message, block_index, return_dict=False):
    try:
        if protocol.enabled("new_dividend_format") and len(message) == LENGTH_2:
            quantity_per_unit, asset_id, dividend_asset_id = struct.unpack(FORMAT_2, message)
            asset = ledger.issuances.get_asset_name(db, asset_id)
            dividend_asset = ledger.issuances.get_asset_name(db, dividend_asset_id)
            status = "valid"
        elif len(message) == LENGTH_1:
            quantity_per_unit, asset_id = struct.unpack(FORMAT_1, message)
            asset = ledger.issuances.get_asset_name(db, asset_id)
            dividend_asset = config.XCP
            status = "valid"
        else:
            raise exceptions.UnpackError
    except (exceptions.UnpackError, exceptions.AssetNameError, struct.error):
        dividend_asset, quantity_per_unit, asset = None, None, None
        status = "invalid: could not unpack"

    if return_dict:
        return {
            "asset": asset,
            "quantity_per_unit": quantity_per_unit,
            "dividend_asset": dividend_asset,
            "status": status,
        }
    return asset, quantity_per_unit, dividend_asset, status


def parse(db, tx, message):
    dividend_parse_cursor = db.cursor()

    fee = 0

    # Unpack message.
    asset, quantity_per_unit, dividend_asset, status = unpack(db, message, tx["block_index"])

    if dividend_asset == config.BTC:
        status = f"invalid: cannot pay {config.BTC} dividends within protocol"

    if status == "valid":
        # For SQLite3
        quantity_per_unit = min(quantity_per_unit, config.MAX_INT)

        dividend_total, outputs, problems, fee = validate(
            db,
            tx["source"],
            quantity_per_unit,
            asset,
            dividend_asset,
            block_index=tx["block_index"],
        )
        if problems:
            status = "invalid: " + "; ".join(problems)

    if status == "valid":
        # Debit.
        ledger.events.debit(
            db,
            tx["source"],
            dividend_asset,
            dividend_total,
            tx["tx_index"],
            action="dividend",
            event=tx["tx_hash"],
        )
        if protocol.enabled("dividend_fees"):  # Protocol change.
            ledger.events.debit(
                db,
                tx["source"],
                config.XCP,
                fee,
                tx["tx_index"],
                action="dividend fee",
                event=tx["tx_hash"],
            )

        # Credit.
        for output in outputs:
            if not protocol.enabled("dont_credit_zero_dividend") or output["dividend_quantity"] > 0:
                ledger.events.credit(
                    db,
                    output["address"],
                    dividend_asset,
                    output["dividend_quantity"],
                    tx["tx_index"],
                    action="dividend",
                    event=tx["tx_hash"],
                )

    # Add parsed transaction to message-type–specific table.
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "asset": asset,
        "dividend_asset": dividend_asset,
        "quantity_per_unit": quantity_per_unit,
        "fee_paid": fee,
        "status": status,
    }

    if "integer overflow" not in status:
        ledger.events.insert_record(db, "dividends", bindings, "ASSET_DIVIDEND")

    logger.info(
        "Dividend of %(quantity_per_unit)s %(dividend_asset)s per unit of %(asset)s (%(tx_hash)s) [%(status)s]",
        bindings,
    )

    dividend_parse_cursor.close()
