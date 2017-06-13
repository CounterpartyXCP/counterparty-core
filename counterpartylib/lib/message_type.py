import logging
logger = logging.getLogger(__name__)
import struct

from counterpartylib.lib import config
from counterpartylib.lib import util

def pack(message_type_id, block_index=None):
    # pack message ID into 1 byte if not zero
    if util.enabled('short_tx_type_id', block_index) and message_type_id > 0 and message_type_id < 256:
        return struct.pack(config.SHORT_TXTYPE_FORMAT, message_type_id)
        
    # pack into 4 bytes
    return struct.pack(config.TXTYPE_FORMAT, message_type_id)

# retuns both the message type id and the remainder of the message data
def unpack(packed_data, block_index=None):
    message_type_id = None

    # try to read 1 byte first
    if util.enabled('short_tx_type_id', block_index):
        message_type_id = struct.unpack(config.SHORT_TXTYPE_FORMAT, packed_data[:1])[0]
        if message_type_id > 0:
            message_remainder = packed_data[1:]
            return (message_type_id, message_remainder)

    # First message byte was 0.  We will read 4 bytes
    message_type_id = struct.unpack(config.TXTYPE_FORMAT, packed_data[:4])[0]
    message_remainder = packed_data[4:]

    return (message_type_id, message_remainder)
