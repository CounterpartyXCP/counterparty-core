"""
Naming convention: a `pub` is either a pubkey or a pubkeyhash
"""

import binascii

from lib import config, exceptions, util

b58_digits = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

class MultiSigAddressError (exceptions.AddressError):
    pass

def validate(address):

    # Get array of pubkeyhashes to check.
    if is_multisig(address):
        pubkeyhashes = pubkeyhash_array(address)
    else:
        pubkeyhashes = [address]

    # Check validity by attempting to decode.
    for pubkeyhashes in pubkeyhashes:
        base58_check_decode(pubkeyhashes, config.ADDRESSVERSION)

def base58_encode(binary):
    # Convert big‐endian bytes to integer
    n = int('0x0' + binascii.hexlify(binary).decode('utf8'), 16)

    # Divide that integer into base58
    res = []
    while n > 0:
        n, r = divmod (n, 58)
        res.append(b58_digits[r])
    res = ''.join(res[::-1])

    return res

def base58_check_encode(original, version):
    b = binascii.unhexlify(bytes(original, 'utf-8'))
    d = version + b

    binary = d + util.dhash(d)[:4]
    res = base58_encode(binary)

    # Encode leading zeros as base58 zeros
    czero = 0
    pad = 0
    for c in d:
        if c == czero: pad += 1
        else: break

    address = b58_digits[0] * pad + res

    if bytes(original, 'utf-8') != binascii.hexlify(base58_check_decode(address, version)):
        raise exceptions.AddressError('encoded address does not decode properly')

    return address

def base58_check_decode (s, version):
    # Convert the string to an integer
    n = 0
    for c in s:
        n *= 58
        if c not in b58_digits:
            raise exceptions.InvalidBase58Error('Not a valid base58 character:', c)
        digit = b58_digits.index(c)
        n += digit

    # Convert the integer to bytes
    h = '%x' % n
    if len(h) % 2:
        h = '0' + h
    res = binascii.unhexlify(h.encode('utf8'))

    # Add padding back.
    pad = 0
    for c in s[:-1]:
        if c == b58_digits[0]: pad += 1
        else: break
    k = version * pad + res

    addrbyte, data, chk0 = k[0:1], k[1:-4], k[-4:]
    if addrbyte != version:
        raise exceptions.VersionByteError('incorrect version byte')
    chk1 = util.dhash(addrbyte + data)[:4]
    if chk0 != chk1:
        raise exceptions.Base58ChecksumError('Checksum mismatch: %r ≠ %r' % (chk0, chk1))
    return data


def is_multisig(address):
    array = address.split('_')
    return (len(array) > 1)

def make_canonical(address):
    if is_multisig(address):
        signatures_required, pubkeyhashes, signatures_possible = extract_array(address)
        if not all([base58_check_decode(pubkeyhash, config.ADDRESSVERSION) for pubkeyhash in pubkeyhashes]):
            raise MultiSigAddressError('Multi‐signature address must use PubKeyHashes, not public keys.')
        return construct_array(signatures_required, pubkeyhashes, signatures_possible)
    else:
        return address

def test_array(signatures_required, pubs, signatures_possible):
    try:
        signatures_required, signatures_possible = int(signatures_required), int(signatures_possible)
    except ValueError:
        raise MultiSigAddressError('Signature values not integers.')
    if signatures_required < 1 or signatures_required > 3:
        raise MultiSigAddressError('Invalid signatures_required.')
    if signatures_possible < 2 or signatures_possible > 3:
        raise MultiSigAddressError('Invalid signatures_possible.')
    if signatures_possible != len(pubs):
        raise exceptions.InputError('Incorrect number of pubkeys/pubkeyhashes in multi‐signature address.')

def construct_array(signatures_required, pubs, signatures_possible):
    test_array(signatures_required, pubs, signatures_possible)
    address = '_'.join([str(signatures_required)] + sorted(pubs) + [str(signatures_possible)])
    return address

def extract_array(address):
    assert is_multisig(address)
    array = address.split('_')
    signatures_required, pubs, signatures_possible = array[0], sorted(array[1:-1]), array[-1]
    test_array(signatures_required, pubs, signatures_possible)
    return int(signatures_required), pubs, int(signatures_possible)

def pubkeyhash_array(address):
    signatures_required, pubkeyhashes, signatures_possible = extract_array(address)
    if not all([base58_check_decode(pubkeyhash, config.ADDRESSVERSION) for pubkeyhash in pubkeyhashes]):
        raise MultiSigAddressError('Multi‐signature address must use PubKeyHashes, not public keys.')
    return pubkeyhashes

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
