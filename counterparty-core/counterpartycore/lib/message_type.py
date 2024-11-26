import logging
import struct

from counterpartycore.lib import (
    config,
    messages,
    util,
)

logger = logging.getLogger(config.LOGGER_NAME)


def pack(message_type_id, block_index=None):
    # pack message ID into 1 byte if not zero
    if (
        util.enabled("short_tx_type_id", block_index)
        and message_type_id > 0
        and message_type_id < 256
    ):
        return struct.pack(config.SHORT_TXTYPE_FORMAT, message_type_id)

    # pack into 4 bytes
    return struct.pack(config.TXTYPE_FORMAT, message_type_id)


# retuns both the message type id and the remainder of the message data
def unpack(packed_data, block_index=None):
    message_type_id = None
    message_remainder = None

    if len(packed_data) > 1:
        # try to read 1 byte first
        if util.enabled("short_tx_type_id", block_index):
            message_type_id = struct.unpack(config.SHORT_TXTYPE_FORMAT, packed_data[:1])[0]
            if message_type_id > 0:
                message_remainder = packed_data[1:]
                return (message_type_id, message_remainder)

    # First message byte was 0.  We will read 4 bytes
    if len(packed_data) > 4:
        message_type_id = struct.unpack(config.TXTYPE_FORMAT, packed_data[:4])[0]
        message_remainder = packed_data[4:]

    return (message_type_id, message_remainder)


def get_transaction_type(data: bytes, block_index: int):
    TRANSACTION_TYPE_BY_ID = {
        messages.bet.ID: "bet",
        messages.broadcast.ID: "broadcast",
        messages.btcpay.ID: "btcpay",
        messages.cancel.ID: "cancel",
        messages.destroy.ID: "destroy",
        messages.dispenser.ID: "dispenser",
        messages.dispenser.DISPENSE_ID: "dispense",
        messages.dividend.ID: "dividend",
        messages.issuance.ID: "issuance",
        messages.issuance.LR_ISSUANCE_ID: "issuance",
        messages.issuance.SUBASSET_ID: "issuance",
        messages.issuance.LR_SUBASSET_ID: "issuance",
        messages.order.ID: "order",
        messages.send.ID: "send",
        messages.versions.enhanced_send.ID: "enhanced_send",
        messages.versions.mpma.ID: "mpma",
        messages.rps.ID: "rps",
        messages.rpsresolve.ID: "rpsresolve",
        messages.sweep.ID: "sweep",
        messages.fairminter.ID: "fairminter",
        messages.fairmint.ID: "fairmint",
        messages.utxo.ID: "utxo",
        messages.attach.ID: "attach",
        messages.detach.ID: "detach",
    }

    if not data and block_index >= 866000:
        return "utxomove"
    elif not data:
        return "unknown"

    try:
        if data[: len(config.PREFIX)] == config.PREFIX:
            data = data[len(config.PREFIX) :]
        message_type_id, message = unpack(data)
    except Exception:
        return "unknown"

    if message_type_id == messages.utxo.ID:
        message_data = messages.utxo.unpack(message, return_dict=True)
        if util.is_utxo_format(message_data["source"]):
            return "detach"
        return "attach"
    return TRANSACTION_TYPE_BY_ID.get(message_type_id, "unknown")
