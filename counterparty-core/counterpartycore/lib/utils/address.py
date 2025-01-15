import logging

import bitcoin
from bitcoin.bech32 import CBech32Data
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.parser import protocol
from counterpartycore.lib.utils import base58, multisig

logger = logging.getLogger(config.LOGGER_NAME)


def is_pubkeyhash(monosig_address):
    """Check if PubKeyHash is valid P2PKH address."""
    assert not multisig.is_multisig(monosig_address)
    try:
        base58.base58_check_decode(monosig_address, config.ADDRESSVERSION)
        return True
    except (exceptions.Base58Error, exceptions.VersionByteError):
        return False


def pubkeyhash_array(address):
    """Return PubKeyHashes from an address."""
    signatures_required, pubs, signatures_possible = multisig.extract_array(address)
    if not all([is_pubkeyhash(pub) for pub in pubs]):
        raise exceptions.MultiSigAddressError(
            "Invalid PubKeyHashes. Multi-signature address must use PubKeyHashes, not public keys."
        )
    pubkeyhashes = pubs
    return pubkeyhashes


def is_bech32(address):
    try:
        b32data = CBech32Data(address)  # noqa: F841
        return True
    except:  # noqa: E722
        return False


def validate(address, allow_p2sh=True):
    """Make sure the address is valid.

    May throw `AddressError`.
    """
    # Get array of pubkeyhashes to check.
    if multisig.is_multisig(address):
        pubkeyhashes = pubkeyhash_array(address)
    else:
        pubkeyhashes = [address]

    # Check validity by attempting to decode.
    for pubkeyhash in pubkeyhashes:
        try:
            if protocol.enabled("segwit_support"):
                if not is_bech32(pubkeyhash):
                    base58.base58_check_decode(pubkeyhash, config.ADDRESSVERSION)
            else:
                base58.base58_check_decode(pubkeyhash, config.ADDRESSVERSION)
        except exceptions.VersionByteError as e:
            if not allow_p2sh:
                raise e
            base58.base58_check_decode(pubkeyhash, config.P2SH_ADDRESSVERSION)
        except exceptions.Base58Error as e:
            if not protocol.enabled("segwit_support") or not is_bech32(pubkeyhash):
                raise e


def pack(address):
    """
    Converts a base58 bitcoin address into a 21 byte bytes object
    """
    from counterpartycore.lib.parser.protocol import (
        enabled,  # Here to account for test mock changes
    )

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
                validate(address)  # This will check if the address is valid
                short_address_bytes = bitcoin.base58.decode(address)[:-4]
                return short_address_bytes
            except Exception as e:  # noqa: F841
                raise exceptions.AddressError(  # noqa: B904
                    f"The address {address} is not a valid bitcoin address ({config.NETWORK_NAME})"
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
    from counterpartycore.lib.parser.protocol import (
        enabled,  # Here to account for test mock changes
    )

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
    else:
        check = bitcoin.core.Hash(short_address_bytes)[0:4]
        return bitcoin.base58.encode(short_address_bytes + check)
