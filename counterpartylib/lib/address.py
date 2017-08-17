import logging
logger = logging.getLogger(__name__)
import struct

import bitcoin

def pack(address):
    """
    Converts a base58 bitcoin address into a 21 byte bytes object
    """

    short_address_bytes = bitcoin.base58.decode(address)[:-4]
    return short_address_bytes

# retuns both the message type id and the remainder of the message data
def unpack(short_address_bytes):
    """
    Converts a 21 byte prefix and public key hash into a full base58 bitcoin address
    """

    check = bitcoin.core.Hash(short_address_bytes)[0:4]
    return bitcoin.base58.encode(short_address_bytes + check)
