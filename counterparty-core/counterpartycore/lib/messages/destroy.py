"""Destroy a quantity of an asset."""

import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.parser import messagetype
from counterpartycore.lib.utils import address

logger = logging.getLogger(config.LOGGER_NAME)

FORMAT = ">QQ"
LENGTH = 8 + 8
MAX_TAG_LENGTH = 34
ID = 110


def pack(db, asset, quantity, tag):
    data = messagetype.pack(ID)
    if isinstance(tag, str):
        tag = bytes(tag.encode("utf8"))[0:MAX_TAG_LENGTH]
    elif isinstance(tag, bytes):
        tag = tag[0:MAX_TAG_LENGTH]
    else:
        tag = b""

    data += struct.pack(
        FORMAT,
        ledger.issuances.get_asset_id(db, asset),
        quantity,
    )
    data += tag
    return data


def unpack(db, message, return_dict=False):
    try:
        asset_id, quantity = struct.unpack(FORMAT, message[0:16])
        tag = message[16:]
        asset = ledger.issuances.get_asset_name(db, asset_id)

    except struct.error as e:
        raise exceptions.UnpackError("could not unpack") from e

    except exceptions.AssetIDError as e:
        raise exceptions.UnpackError("asset id invalid") from e

    if return_dict:
        return {"asset": asset, "quantity": quantity, "tag": tag}
    return asset, quantity, tag


def validate(db, source, destination, asset, quantity):
    try:
        ledger.issuances.get_asset_id(db, asset)
    except exceptions.AssetError as e:
        raise exceptions.ValidateError("asset invalid") from e

    try:
        address.validate(source)
    except exceptions.AddressError as e:
        raise exceptions.ValidateError("source address invalid") from e

    if destination:
        raise exceptions.ValidateError("destination exists")

    if asset == config.BTC:
        raise exceptions.ValidateError(f"cannot destroy {config.BTC}")

    if isinstance(quantity, int):
        raise exceptions.ValidateError("quantity not integer")

    if quantity > config.MAX_INT:
        raise exceptions.ValidateError("integer overflow, quantity too large")

    if quantity < 0:
        raise exceptions.ValidateError("quantity negative")

    if ledger.balances.get_balance(db, source, asset) < quantity:
        raise exceptions.BalanceError("balance insufficient")


def compose(db, source: str, asset: str, quantity: int, tag: str, skip_validation: bool = False):
    # resolve subassets
    asset = ledger.issuances.resolve_subasset_longname(db, asset)

    if not skip_validation:
        validate(db, source, None, asset, quantity)
    data = pack(db, asset, quantity, tag)

    return (source, [], data)


def parse(db, tx, message):
    status = "valid"

    asset, quantity, tag = None, None, None

    try:
        asset, quantity, tag = unpack(db, message)
        validate(db, tx["source"], tx["destination"], asset, quantity)
        ledger.events.debit(
            db, tx["source"], asset, quantity, tx["tx_index"], "destroy", tx["tx_hash"]
        )

    except exceptions.UnpackError as e:  # noqa: F405
        status = "invalid: " + "".join(e.args)

    except (exceptions.ValidateError, exceptions.BalanceError) as e:  # noqa: F405
        status = "invalid: " + "".join(e.args)

    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "asset": asset,
        "quantity": quantity,
        "tag": tag,
        "status": status,
    }
    if "integer overflow" not in status:
        ledger.events.insert_record(db, "destructions", bindings, "ASSET_DESTRUCTION")

    logger.info(
        "Destroy of %(quantity)s %(asset)s by %(source)s (%(tx_hash)s) [%(status)s]", bindings
    )


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
