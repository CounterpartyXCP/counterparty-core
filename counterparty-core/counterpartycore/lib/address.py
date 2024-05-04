import logging
import struct  # noqa: F401

import bitcoin

from counterpartycore.lib import config, exceptions, ledger, script  # noqa: F401

logger = logging.getLogger(config.LOGGER_NAME)


def address_scriptpubkey(address):
    try:
        bech32 = bitcoin.bech32.CBech32Data(address)
        return b"".join([b"\x00\x14", bech32.to_bytes()])
    except Exception as e:  # noqa: F841
        bs58 = bitcoin.base58.decode(address)[1:-4]
        return b"".join([b"\x76\xa9\x14", bs58, b"\x88\xac"])


def pack(address):
    """
    Converts a base58 bitcoin address into a 21 byte bytes object
    """
    from .ledger import enabled  # Here to account for test mock changes

    if enabled("segwit_support"):
        try:
            bech32 = bitcoin.bech32.CBech32Data(address)
            witver = (0x80 + bech32.witver).to_bytes(
                1, byteorder="big"
            )  # mark the first byte for segwit
            witprog = bech32.to_bytes()
            if len(witprog) > 20:
                raise Exception("p2wsh still not supported for sending")
            return b"".join([witver, witprog])
        except Exception as ne:  # noqa: F841
            try:
                script.validate(address)  # This will check if the address is valid
                short_address_bytes = bitcoin.base58.decode(address)[:-4]
                return short_address_bytes
            except bitcoin.base58.InvalidBase58Error as e:
                raise e
            except Exception as e:  # noqa: F841
                raise Exception(  # noqa: B904
                    f"The address {address} is not a valid bitcoin address ({'testnet' if config.TESTNET or config.REGTEST else 'mainnet'})"
                )
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
    from .ledger import enabled  # Here to account for test mock changes

    if short_address_bytes == b"":
        raise exceptions.UnpackError

    if (
        enabled("segwit_support")
        and short_address_bytes[0] >= 0x80
        and short_address_bytes[0] <= 0x8F
    ):
        # we have a segwit address here
        witver = short_address_bytes[0] - 0x80
        witprog = short_address_bytes[1:]
        return str(bitcoin.bech32.CBech32Data.from_bytes(witver, witprog))

    check = bitcoin.core.Hash(short_address_bytes)[0:4]
    return bitcoin.base58.encode(short_address_bytes + check)
