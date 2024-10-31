import logging
import struct

from counterpartycore.lib import backend, config, exceptions, gas, ledger, script, util
from counterpartycore.lib.messages import attach

logger = logging.getLogger(config.LOGGER_NAME)

ID = 100

# TODO: after "spend_utxo_to_detach" activation refactor like rps.py


def validate(db, source, destination, asset=None, quantity=None, block_index=None):
    problems = []

    problems += attach.validate_asset_and_quantity(asset, quantity)
    if "quantity must be in satoshis" in problems:
        return problems

    source_is_address = True
    destination_is_address = True
    # check if source is an address
    try:
        script.validate(source)
    except script.AddressError:
        source_is_address = False
    # check if destination is an address
    if destination:
        try:
            script.validate(destination)
        except script.AddressError:
            destination_is_address = False

    # check if source is a UTXO
    source_is_utxo = util.is_utxo_format(source)
    # check if destination is a UTXO
    if destination:
        destination_is_utxo = util.is_utxo_format(destination)
    else:
        destination_is_utxo = True

    # attach to utxo
    if source_is_address and not destination_is_utxo:
        problems.append("If source is an address, destination must be a UTXO")
    # or detach from utxo
    if source_is_utxo and not destination_is_address:
        problems.append("If source is a UTXO, destination must be an address")

    # fee only for attach to utxo
    if source_is_address:
        fee = gas.get_transaction_fee(db, ID, block_index or util.CURRENT_BLOCK_INDEX)
    else:
        fee = 0

    problems += attach.validate_balance(db, source, asset, quantity, fee)

    return problems


def unpack(message, return_dict=False):
    try:
        data_content = struct.unpack(f">{len(message)}s", message)[0].decode("utf-8").split("|")

        (source, destination, asset, quantity) = data_content

        if return_dict:
            return {
                "source": source,
                "destination": destination or None,
                "asset": asset,
                "quantity": int(quantity),
            }

        return (source, destination, asset, int(quantity))
    except Exception as e:
        raise exceptions.UnpackError(f"Cannot unpack utxo message: {e}") from e


def move_asset(db, tx, action, source, recipient, asset, quantity, event, fee_paid):
    # debit asset from source and credit to recipient
    ledger.debit(db, source, asset, quantity, tx["tx_index"], action=action, event=tx["tx_hash"])
    ledger.credit(
        db,
        recipient,
        asset,
        quantity,
        tx["tx_index"],
        action=action,
        event=tx["tx_hash"],
    )
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "msg_index": ledger.get_send_msg_index(db, tx["tx_hash"]),
        "block_index": tx["block_index"],
        "status": "valid",
        "source": source,
        "destination": recipient,
        "asset": asset,
        "quantity": quantity,
        "fee_paid": fee_paid,
    }
    ledger.insert_record(db, "sends", bindings, event)


def parse(db, tx, message):
    (source, destination, asset, quantity) = unpack(message)

    problems = validate(db, source, destination, asset, quantity, tx["block_index"])

    recipient = destination
    # if no destination, we assume the destination is the first non-OP_RETURN output
    # that's mean the last element of the UTXOs info in `transactions` table
    if not recipient:
        recipient = util.get_destination_from_utxos_info(tx["utxos_info"])

    # detach if source is a UTXO
    if util.is_utxo_format(source):
        source_address, _value = backend.bitcoind.get_utxo_address_and_value(source)
        if source_address != tx["source"]:
            problems.append("source does not match the UTXO source")
        action = "detach from utxo"
        event = "DETACH_FROM_UTXO"
    # attach if source is an address
    else:
        if source != tx["source"]:
            problems.append("source does not match the source address")
        action = "attach to utxo"
        event = "ATTACH_TO_UTXO"

    status = "valid"
    if problems:
        status = "invalid: " + "; ".join(problems)

    if status == "valid":
        if action == "attach to utxo":
            fee = gas.get_transaction_fee(db, ID, tx["block_index"])
        else:
            fee = 0
        if fee > 0:
            attach.pay_fee(db, tx, source, fee)

        # update counter
        if action == "attach to utxo":
            gas.increment_counter(db, ID, tx["block_index"])

        move_asset(db, tx, action, source, recipient, asset, quantity, event, fee)
    else:
        # store the invalid transaction without potentially invalid parameters
        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "msg_index": ledger.get_send_msg_index(db, tx["tx_hash"]),
            "block_index": tx["block_index"],
            "status": status,
        }
        ledger.insert_record(db, "sends", bindings, event)

    # log valid transactions
    if status == "valid":
        log_bindings = {
            "tx_hash": tx["tx_hash"],
            "source": source,
            "destination": recipient,
            "asset": asset,
            "status": status,
        }
        if util.is_utxo_format(source):
            logger.info(
                "Detach assets from %(source)s to address: %(destination)s (%(tx_hash)s) [%(status)s]",
                log_bindings,
            )
        else:
            logger.info(
                "Attach %(asset)s from %(source)s to utxo: %(destination)s (%(tx_hash)s) [%(status)s]",
                log_bindings,
            )
