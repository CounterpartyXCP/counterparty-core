import binascii

from counterparty_rs import b58
from counterpartycore.lib import exceptions


def base58_check_encode(original, version):
    return b58.b58_encode(version + binascii.unhexlify(original))


def base58_check_decode(s, version):
    try:
        decoded = bytes(b58.b58_decode(s))
    except ValueError:
        raise exceptions.Base58Error("invalid base58 string")  # noqa: B904

    if decoded[0] != ord(version):
        raise exceptions.VersionByteError("incorrect version byte")

    return decoded[1:]
