import logging
logger = logging.getLogger(__name__)
import struct

import bitcoin

def pack(address):
    """
    Converts a base58 bitcoin address into a 21 byte bytes object
    """
    from .util import enabled # Here to account for test mock changes

    if enabled('segwit_support'):
        try:
            bech32 = bitcoin.bech32.CBech32Data(address)
            witver = (0x80 + bech32.witver).to_bytes(1, byteorder='big') # mark the first byte for segwit
            witprog = bech32.to_bytes()
            if not (0 <= bech32.witver <= 16):
                raise Exception('impossible witness version')
            if len(witprog) == 20:
                return b''.join([witver, witprog])
            elif len(witprog) == 32:
                raise Exception('p2wsh still not supported for sending')
            else:
                raise Exception('unexpected length for segwit')
        except Exception as ne:
            try:
                short_address_bytes = bitcoin.base58.decode(address)[:-4]
                return short_address_bytes
            except bitcoin.base58.InvalidBase58Error as e:
                raise e
    else:
        try:
            short_address_bytes = bitcoin.base58.decode(address)[:-4]
            return short_address_bytes
        except bitcoin.base58.InvalidBase58Error as e:
            raise e

# retuns both the message type id and the remainder of the message data
def unpack(short_address_bytes):
    """
    Converts a 21 byte prefix and public key hash into a full base58 bitcoin address
    """
    from .util import enabled # Here to account for test mock changes

    if enabled('segwit_support') and short_address_bytes[0] >= 0x80 and short_address_bytes[0] <= 0x8F:
        # we have a segwit address here
        witver = short_address_bytes[0] - 0x80
        witprog = short_address_bytes[1:]
        return str(bitcoin.bech32.CBech32Data.from_bytes(witver, witprog))
    else:
        check = bitcoin.core.Hash(short_address_bytes)[0:4]
        return bitcoin.base58.encode(short_address_bytes + check)
