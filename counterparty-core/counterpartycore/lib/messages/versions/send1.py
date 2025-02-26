"""Create and parse 'send'-type messages."""

import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages import dispense
from counterpartycore.lib.parser import messagetype, protocol
from counterpartycore.lib.utils import helpers

logger = logging.getLogger(config.LOGGER_NAME)

FORMAT = ">QQ"
LENGTH = 8 + 8
ID = 0


def unpack(db, message):
    # Only used for `unpack` API call at the moment.
    try:
        asset_id, quantity = struct.unpack(FORMAT, message)
        asset = ledger.issuances.get_asset_name(db, asset_id)

    except struct.error as e:
        raise exceptions.UnpackError("could not unpack") from e

    except exceptions.AssetNameError as e:
        raise exceptions.UnpackError("asset id invalid") from e

    unpacked = {"asset": asset, "quantity": quantity}
    return unpacked


def validate(db, destination, asset, quantity):
    problems = []

    if asset == config.BTC:
        problems.append("cannot send bitcoins")  # Only for parsing.

    if not isinstance(quantity, int):
        problems.append("quantity must be in satoshis")
        return problems

    if quantity < 0:
        problems.append("negative quantity")

    # For SQLite3
    if quantity > config.MAX_INT:
        problems.append("integer overflow")

    if protocol.enabled("send_destination_required"):  # Protocol change.
        if not destination:
            problems.append("destination is required")

    if protocol.enabled("options_require_memo"):
        # Check destination address options

        cursor = db.cursor()
        results = ledger.other.get_addresses(db, address=destination)
        if results:
            result = results[0]
            if result and helpers.active_options(
                result["options"], config.ADDRESS_OPTION_REQUIRE_MEMO
            ):
                problems.append("destination requires memo")
        cursor.close()

    return problems


def compose_send_btc(db, source: str, destination: str, quantity: int, no_dispense: bool):
    if not protocol.enabled("enable_dispense_tx") or no_dispense:
        return (source, [(destination, quantity)], None)
    # try to compose a dispense instead
    try:
        return dispense.compose(db, source, destination, quantity)
    except (exceptions.NoDispenserError, exceptions.ComposeError):
        # simple BTC send
        return (source, [(destination, quantity)], None)


def compose(
    db,
    source: str,
    destination: str,
    asset: str,
    quantity: int,
    skip_validation: bool = False,
    no_dispense: bool = False,
):
    cursor = db.cursor()

    # Just send BTC?
    if asset == config.BTC:
        return compose_send_btc(db, source, destination, quantity, no_dispense)

    # resolve subassets
    asset = ledger.issuances.resolve_subasset_longname(db, asset)

    # quantity must be in int satoshi (not float, string, etc)
    if not isinstance(quantity, int):
        raise exceptions.ComposeError("quantity must be an int (in satoshi)")

    # Only for outgoing (incoming will overburn).
    balance = ledger.balances.get_balance(db, source, asset)
    if balance < quantity and not skip_validation:
        raise exceptions.ComposeError("insufficient funds")

    problems = validate(db, destination, asset, quantity)
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    asset_id = ledger.issuances.get_asset_id(db, asset)
    data = messagetype.pack(ID)
    data += struct.pack(FORMAT, asset_id, quantity)

    cursor.close()
    return (source, [(destination, None)], data)


def parse(db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        asset_id, quantity = struct.unpack(FORMAT, message)
        asset = ledger.issuances.get_asset_name(db, asset_id)
        status = "valid"
    except (exceptions.UnpackError, exceptions.AssetNameError, struct.error):
        asset, quantity = None, None
        status = "invalid: could not unpack"

    if status == "valid":
        # Oversend
        # doesn't make sense (0 and no balance should be the same) but let's not break the protocol
        try:
            balance = ledger.balances.get_balance(
                db, tx["source"], asset, raise_error_if_no_balance=True
            )
            if balance < quantity:
                quantity = min(balance, quantity)
        except exceptions.BalanceError:
            status = "invalid: insufficient funds"

    # For SQLite3
    if quantity:
        quantity = min(quantity, config.MAX_INT)

    if status == "valid":
        problems = validate(db, tx["destination"], asset, quantity)
        if problems:
            status = "invalid: " + "; ".join(problems)

    if status == "valid":
        ledger.events.debit(
            db, tx["source"], asset, quantity, tx["tx_index"], action="send", event=tx["tx_hash"]
        )
        ledger.events.credit(
            db,
            tx["destination"],
            asset,
            quantity,
            tx["tx_index"],
            action="send",
            event=tx["tx_hash"],
        )

    # Add parsed transaction to message-type–specific table.
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "destination": tx["destination"],
        "asset": asset,
        "quantity": quantity,
        "status": status,
        "msg_index": ledger.other.get_send_msg_index(db, tx["tx_hash"]),
        "send_type": "send",
    }
    if "integer overflow" not in status and "quantity must be in satoshis" not in status:
        ledger.events.insert_record(db, "sends", bindings, "SEND")

    logger.info(
        "Send %(asset)s from %(source)s to %(destination)s (%(tx_hash)s) [%(status)s]", bindings
    )

    cursor.close()
