#! /usr/bin/python3

import logging
import struct

import cbor2

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages.versions import send1
from counterpartycore.lib.parser import messagetype, protocol
from counterpartycore.lib.utils import address, helpers

logger = logging.getLogger(config.LOGGER_NAME)

FORMAT = ">QQ21s"
LENGTH = 8 + 8 + 21
MAX_MEMO_LENGTH = 34
ID = 2  # 0x02


def new_unpack(message):
    try:
        (asset_id, quantity, short_address_bytes, memo_bytes) = cbor2.loads(message)
        asset = ledger.issuances.generate_asset_name(asset_id)
        if asset == config.BTC:
            raise exceptions.AssetNameError(f"{config.BTC} not allowed")

        full_address = address.unpack(short_address_bytes)

        return {
            "asset": asset,
            "quantity": quantity,
            "address": full_address,
            "memo": None if memo_bytes == b"" else memo_bytes,
        }
    except Exception as e:  # pylint: disable=broad-exception-caught
        logger.error("enhanced send unpack error: %s", e)
        raise exceptions.UnpackError(f"could not unpack: {e}") from e


def unpack(message):
    if protocol.enabled("taproot_support"):
        try:
            return new_unpack(message)
        except exceptions.UnpackError:
            pass  # fallback to legacy unpacking

    try:
        # account for memo bytes
        memo_bytes_length = len(message) - LENGTH
        if memo_bytes_length < 0:
            raise exceptions.UnpackError("invalid message length")
        if memo_bytes_length > MAX_MEMO_LENGTH:
            raise exceptions.UnpackError("memo too long")

        struct_format = FORMAT + f"{memo_bytes_length}s"
        asset_id, quantity, short_address_bytes, memo_bytes = struct.unpack(struct_format, message)
        if len(memo_bytes) == 0:
            memo_bytes = None

        # unpack address
        full_address = address.unpack(short_address_bytes)

        # asset id to name
        asset = ledger.issuances.generate_asset_name(asset_id)
        if asset == config.BTC:
            raise exceptions.AssetNameError(f"{config.BTC} not allowed")

    except (struct.error, TypeError) as e:
        logger.trace(f"enhanced send unpack error: {e}")
        raise exceptions.UnpackError(f"could not unpack: {e}")  # noqa: B904

    except (exceptions.AssetNameError, exceptions.AssetIDError) as e:
        logger.trace(f"enhanced send invalid asset id: {e}")
        raise exceptions.UnpackError("asset id invalid")  # noqa: B904

    unpacked = {
        "asset": asset,
        "quantity": quantity,
        "address": full_address,
        "memo": memo_bytes,
    }
    return unpacked


def validate(db, destination, asset, quantity, memo_bytes):
    problems = []

    if asset == config.BTC:
        problems.append(f"cannot send {config.BTC}")

    if not isinstance(quantity, int):
        problems.append("quantity must be in satoshis")
        return problems

    if quantity < 0:
        problems.append("negative quantity")

    if quantity == 0:
        problems.append("zero quantity")

    # For SQLite3
    if quantity > config.MAX_INT:
        problems.append("integer overflow")

    # destination is always required
    if not destination:
        problems.append("destination is required")

    # check memo
    if memo_bytes is not None and len(memo_bytes) > MAX_MEMO_LENGTH:
        problems.append("memo is too long")

    if protocol.enabled("options_require_memo"):
        cursor = db.cursor()
        try:
            results = ledger.other.get_addresses(db, address=destination)
            if results:
                result = results[0]
                if result and helpers.active_options(
                    result["options"], config.ADDRESS_OPTION_REQUIRE_MEMO
                ):
                    if memo_bytes is None or (len(memo_bytes) == 0):
                        problems.append("destination requires memo")
        finally:
            cursor.close()

    return problems


def compose(
    db,
    source: str,
    destination: str,
    asset: str,
    quantity: int,
    memo: str,
    memo_is_hex: bool,
    skip_validation: bool = False,
    no_dispense: bool = False,
):
    cursor = db.cursor()

    # Just send BTC?
    if asset == config.BTC:
        # try to compose a dispense instead
        return send1.compose_send_btc(db, source, destination, quantity, no_dispense)

    # resolve subassets
    asset = ledger.issuances.resolve_subasset_longname(db, asset)

    # quantity must be in int satoshi (not float, string, etc)
    if not isinstance(quantity, int):
        raise exceptions.ComposeError("quantity must be an int (in satoshi)")

    # Only for outgoing (incoming will overburn).
    balance = ledger.balances.get_balance(db, source, asset)
    if balance < quantity and not skip_validation:
        raise exceptions.ComposeError("insufficient funds")

    # convert memo to memo_bytes based on memo_is_hex setting
    if memo is None:
        memo_bytes = b""
    elif memo_is_hex:
        memo_bytes = bytes.fromhex(memo)
    else:
        memo_bytes = memo.encode("utf-8")
        memo_bytes = struct.pack(f">{len(memo_bytes)}s", memo_bytes)

    problems = validate(db, destination, asset, quantity, memo_bytes)
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    if not skip_validation:
        asset_id = ledger.issuances.get_asset_id(db, asset)
    else:
        asset_id = ledger.issuances.generate_asset_id(asset)

    short_address_bytes = address.pack(destination)

    if protocol.enabled("taproot_support"):
        data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
        data += cbor2.dumps(
            [
                asset_id,
                quantity,
                short_address_bytes,
                memo_bytes,
            ]
        )
    else:
        data = messagetype.pack(ID)
        data += struct.pack(FORMAT, asset_id, quantity, short_address_bytes)
        data += memo_bytes

    cursor.close()
    # return an empty array as the second argument because we don't need to send BTC dust to the recipient
    return (source, [], data)


def parse(db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        unpacked = unpack(message)
        asset, quantity, destination, memo_bytes = (
            unpacked["asset"],
            unpacked["quantity"],
            unpacked["address"],
            unpacked["memo"],
        )

        status = "valid"

    except (exceptions.UnpackError, exceptions.AssetNameError, struct.error) as e:
        asset, quantity, destination, memo_bytes = None, None, None, None
        status = f"invalid: could not unpack ({e})"
    except:  # noqa: E722 # pylint: disable=bare-except
        asset, quantity, destination, memo_bytes = None, None, None, None
        status = "invalid: could not unpack"

    if status == "valid":
        # don't allow sends over MAX_INT at all
        if quantity and quantity > config.MAX_INT:
            status = "invalid: quantity is too large"
            quantity = None

    if status == "valid":
        problems = validate(db, destination, asset, quantity, memo_bytes)
        if problems:
            status = "invalid: " + "; ".join(problems)

    if status == "valid":
        # verify balance is present
        balance = ledger.balances.get_balance(db, tx["source"], asset)
        if balance == 0 or balance < quantity:
            status = "invalid: insufficient funds"

    if status == "valid":
        ledger.events.debit(
            db, tx["source"], asset, quantity, tx["tx_index"], action="send", event=tx["tx_hash"]
        )
        ledger.events.credit(
            db, destination, asset, quantity, tx["tx_index"], action="send", event=tx["tx_hash"]
        )

    # Add parsed transaction to message-type–specific table.
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "destination": destination,
        "asset": asset,
        "quantity": quantity,
        "status": status,
        "memo": memo_bytes,
        "msg_index": ledger.other.get_send_msg_index(db, tx["tx_hash"]),
        "send_type": "send",
    }
    if "integer overflow" not in status and "quantity must be in satoshis" not in status:
        ledger.events.insert_record(db, "sends", bindings, "ENHANCED_SEND")

    logger.info(
        "Send (Enhanced) %(asset)s from %(source)s to %(destination)s (%(tx_hash)s) [%(status)s]",
        bindings,
    )

    cursor.close()


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
