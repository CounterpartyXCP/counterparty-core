import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import gas
from counterpartycore.lib.parser import utxosinfo
from counterpartycore.lib.utils import address

logger = logging.getLogger(config.LOGGER_NAME)

ID = 101


def validate_asset_and_quantity(asset, quantity):
    problems = []

    if asset == config.BTC:
        problems.append("cannot send bitcoins")  # Only for parsing.

    if not isinstance(quantity, int):
        problems.append("quantity must be in satoshis")
        return problems

    if quantity <= 0:
        problems.append("quantity must be greater than zero")

    # For SQLite3
    if quantity > config.MAX_INT:
        problems.append("integer overflow")

    return problems


def validate_balance(db, source, asset, quantity, fee=0):
    problems = []
    # check if source has enough funds
    asset_balance = ledger.balances.get_balance(db, source, asset)
    if asset == config.XCP:
        # fee is always paid in XCP
        if asset_balance < quantity + fee:
            problems.append("insufficient funds for transfer and fee")
    else:
        if asset_balance < quantity:
            problems.append("insufficient funds for transfer")
        if fee > 0:
            xcp_balance = ledger.balances.get_balance(db, source, config.XCP)
            if xcp_balance < fee:
                problems.append("insufficient funds for fee")
    return problems


def validate(db, source, asset, quantity, destination_vout=None, block_index=None):
    problems = []

    # check if source is an address
    try:
        address.validate(source)
    except exceptions.AddressError:
        problems.append("invalid source address")

    # validate asset and quantity
    problems += validate_asset_and_quantity(asset, quantity)
    if len(problems) > 0:
        # if asset or quantity are invalid, let's avoid some potential
        # errors in the next checks by returning here
        return problems

    # attach needs fee
    fee = gas.get_transaction_fee(db, ID, block_index or CurrentState().current_block_index())

    # check balances
    problems += validate_balance(db, source, asset, quantity, fee)

    # check if destination_vout is valid
    if destination_vout is not None:
        if not isinstance(destination_vout, int):
            problems.append("if provided destination must be an integer")
        elif destination_vout < 0:
            problems.append("destination vout must be greater than or equal to zero")

    return problems


def compose(
    db, source, asset, quantity, utxo_value=None, destination_vout=None, skip_validation=False
):
    problems = validate(db, source, asset, quantity, destination_vout)
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    # create message
    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
    # to optimize the data size (avoiding fixed sizes per parameter) we use a simple
    # string of characters separated by `|`.
    data_content = "|".join(
        [
            str(value)
            for value in [
                asset,
                quantity,
                destination_vout or "",
            ]
        ]
    ).encode("utf-8")
    data += struct.pack(f">{len(data_content)}s", data_content)

    # if destination_vout is provided it's the responsability of the caller to
    # build a transaction with the destination UTXO
    destinations = []
    if destination_vout is None:
        value = config.DEFAULT_UTXO_VALUE
        if utxo_value is not None:
            try:
                value = int(utxo_value)
            except ValueError as e:
                raise exceptions.ComposeError(["utxo_value must be an integer"]) from e
        # else we use the source address as the destination
        destinations.append((source, value))

    return (source, destinations, data)


def unpack(message, return_dict=False):
    try:
        data_content = struct.unpack(f">{len(message)}s", message)[0].decode("utf-8").split("|")

        (asset, quantity, destination_vout) = data_content
        destination_vout = int(destination_vout) if destination_vout else None

        if return_dict:
            return {
                "asset": asset,
                "quantity": int(quantity),
                "destination_vout": destination_vout,
            }

        return (asset, int(quantity), destination_vout)
    except Exception:
        return "", 0, None


def pay_fee(db, tx, source, fee):
    # debit fee from the fee payer
    ledger.events.debit(
        db,
        source,
        config.XCP,
        fee,
        tx["tx_index"],
        action="attach to utxo fee",
        event=tx["tx_hash"],
    )
    # destroy fee
    destroy_bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "asset": config.XCP,
        "quantity": fee,
        "tag": "attach to utxo fee",
        "status": "valid",
    }
    ledger.events.insert_record(db, "destructions", destroy_bindings, "ASSET_DESTRUCTION")


def parse(db, tx, message):
    (asset, quantity, destination_vout) = unpack(message)
    source = tx["source"]

    problems = validate(db, source, asset, quantity, destination_vout, tx["block_index"])

    # determine destination
    if destination_vout is None:
        # if no destination_vout is provided, we use the first non-OPT_RETURN output
        destination = utxosinfo.get_destination_from_utxos_info(tx["utxos_info"])
        if not destination:
            problems.append("no UTXO to attach to")
    else:
        # check if destination_vout is valid
        outputs_count = utxosinfo.get_outputs_count_from_utxos_info(tx["utxos_info"])
        if outputs_count and destination_vout > outputs_count - 1:
            problems.append("destination vout is greater than the number of outputs")

        # check if destination_vout is an OP_RETURN output
        op_return_output = utxosinfo.get_op_return_output_from_utxos_info(tx["utxos_info"])
        if op_return_output and destination_vout == op_return_output:
            problems.append("destination vout is an OP_RETURN output")

        destination = f"{tx['tx_hash']}:{destination_vout}"

    status = "valid"
    if problems:
        status = "invalid: " + "; ".join(problems)
        # store the invalid transaction without potentially invalid parameters
        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "msg_index": ledger.ledger.get_send_msg_index(db, tx["tx_hash"]),
            "block_index": tx["block_index"],
            "status": status,
            "send_type": "attach",
        }
        ledger.events.insert_record(db, "sends", bindings, "ATTACH_TO_UTXO")
        # return here to avoid further processing
        return

    # calculate and pay fee
    fee = gas.get_transaction_fee(db, ID, tx["block_index"])
    if fee > 0:
        pay_fee(db, tx, source, fee)
    # increment gas counter
    gas.increment_counter(db, ID, tx["block_index"])

    # debit asset from source and credit to recipient
    action = "attach to utxo"
    ledger.events.debit(
        db, source, asset, quantity, tx["tx_index"], action=action, event=tx["tx_hash"]
    )
    destination_address = ledger.events.credit(
        db,
        destination,
        asset,
        quantity,
        tx["tx_index"],
        action=action,
        event=tx["tx_hash"],
    )
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "msg_index": ledger.ledger.get_send_msg_index(db, tx["tx_hash"]),
        "block_index": tx["block_index"],
        "status": "valid",
        "source": source,
        "destination": destination,
        "destination_address": destination_address,
        "asset": asset,
        "quantity": quantity,
        "fee_paid": fee,
        "send_type": "attach",
    }
    ledger.events.insert_record(db, "sends", bindings, "ATTACH_TO_UTXO")

    logger.info(
        "Attach %(asset)s from %(source)s to utxo: %(destination)s (%(tx_hash)s) [%(status)s]",
        bindings,
    )
