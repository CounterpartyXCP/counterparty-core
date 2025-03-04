import logging

import bitcoin
from bitcoin.bech32 import CBech32Data
from bitcoinutils.keys import P2pkhAddress, P2shAddress, P2trAddress, P2wpkhAddress
from counterparty_rs import utils  # pylint: disable=no-name-in-module
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.parser import protocol
from counterpartycore.lib.parser.protocol import enabled
from counterpartycore.lib.utils import base58, helpers, multisig

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
    _signatures_required, pubs, _signatures_possible = multisig.extract_array(address)
    if not all(is_pubkeyhash(pub) for pub in pubs):
        raise exceptions.MultiSigAddressError(
            "Invalid PubKeyHashes. Multi-signature address must use PubKeyHashes, not public keys."
        )
    pubkeyhashes = pubs
    return pubkeyhashes


def is_bech32(address):
    try:
        CBech32Data(address)  # noqa: F841
        return True
    except:  # noqa: E722 # pylint: disable=bare-except
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
            if protocol.enabled("taproot_support"):
                if not is_valid_address(pubkeyhash):
                    raise exceptions.AddressError(
                        f"The address {pubkeyhash} is not a valid bitcoin address ({config.NETWORK_NAME})"
                    )
            elif protocol.enabled("segwit_support"):
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


def pack_legacy(address):
    if enabled("segwit_support"):
        try:
            bech32 = bitcoin.bech32.CBech32Data(address)
            witver = (0x80 + bech32.witver).to_bytes(
                1, byteorder="big"
            )  # mark the first byte for segwit
            witprog = bech32.to_bytes()
            if len(witprog) > 20:
                raise Exception("p2wsh still not supported for sending")  # pylint: disable=broad-exception-raised
            return b"".join([witver, witprog])
        except Exception:  # noqa: F841 # pylint: disable=broad-except
            try:
                validate(address)  # This will check if the address is valid
                short_address_bytes = bitcoin.base58.decode(address)[:-4]
                print("short_address_bytes", short_address_bytes)
                return short_address_bytes
            except Exception as e:  # pylint: disable=broad-except  # noqa: F841
                raise exceptions.AddressError(  # noqa: B904
                    f"The address {address} is not a valid bitcoin address ({config.NETWORK_NAME})"
                ) from e

    try:
        short_address_bytes = bitcoin.base58.decode(address)[:-4]
        return short_address_bytes
    except bitcoin.base58.InvalidBase58Error as e:
        raise e


def pack(address):
    """
    Converts a base58 bitcoin address into a 21 byte bytes object
    """
    if enabled("taproot_support"):
        try:
            return bytes(utils.pack_address(address, config.NETWORK_NAME))
        except Exception as e:  # pylint: disable=broad-except  # noqa: F841
            raise exceptions.AddressError(  # noqa: B904
                f"The address {address} is not a valid bitcoin address ({config.NETWORK_NAME})"
            ) from e

    return pack_legacy(address)


def unpack_legacy(short_address_bytes):
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


# retuns both the message type id and the remainder of the message data
def unpack(short_address_bytes):
    """
    Converts a 21 byte prefix and public key hash into a full base58 bitcoin address
    """
    if enabled("taproot_support"):
        try:
            return utils.unpack_address(short_address_bytes, config.NETWORK_NAME)
        except Exception as e:  # pylint: disable=broad-except  # noqa: F841
            raise exceptions.DecodeError(  # noqa: B904
                f"T{short_address_bytes} is not a valid packed bitcoin address ({config.NETWORK_NAME})"
            ) from e

    return unpack_legacy(short_address_bytes)


def is_valid_address(address, network=None):
    helpers.setup_bitcoinutils(network)
    if multisig.is_multisig(address):
        return True
    try:
        P2trAddress(address).to_script_pub_key()
        return True
    except (ValueError, TypeError):
        pass
    try:
        P2wpkhAddress(address).to_script_pub_key()
        return True
    except (ValueError, TypeError):
        pass
    try:
        P2pkhAddress(address).to_script_pub_key()
        return True
    except ValueError:
        pass
    try:
        P2shAddress(address).to_script_pub_key()
        return True
    except ValueError:
        pass
    return False
