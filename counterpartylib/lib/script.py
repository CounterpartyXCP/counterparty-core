"""
None of the functions/objects in this module need be passed `db`.

Naming convention: a `pub` is either a pubkey or a pubkeyhash
"""

import hashlib
import bitcoin as bitcoinlib
import binascii

from bitcoin.core.key import CPubKey

from counterpartylib.lib import util
from counterpartylib.lib import config
from counterpartylib.lib import exceptions

b58_digits = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

class InputError (Exception):
    pass
class AddressError(Exception):
    pass
class MultiSigAddressError(AddressError):
    pass
class VersionByteError (AddressError):
    pass
class Base58Error (AddressError):
    pass
class Base58ChecksumError (Base58Error):
    pass

def validate(address):
    """Make sure the address is valid.
    
    May throw `AddressError`.
    """
    # Get array of pubkeyhashes to check.
    if is_multisig(address):
        pubkeyhashes = pubkeyhash_array(address)
    else:
        pubkeyhashes = [address]

    # Check validity by attempting to decode.
    for pubkeyhash in pubkeyhashes:
        base58_check_decode(pubkeyhash, config.ADDRESSVERSION)

def base58_encode(binary):
    """Encode the address in base58."""
    # Convert big‐endian bytes to integer
    n = int('0x0' + util.hexlify(binary), 16)

    # Divide that integer into base58
    res = []
    while n > 0:
        n, r = divmod(n, 58)
        res.append(b58_digits[r])
    res = ''.join(res[::-1])

    return res

def base58_check_encode(original, version):
    """Check if base58 encoding is valid."""
    b = binascii.unhexlify(bytes(original, 'utf-8'))
    d = version + b

    binary = d + util.dhash(d)[:4]
    res = base58_encode(binary)

    # Encode leading zeros as base58 zeros
    czero = 0
    pad = 0
    for c in d:
        if c == czero:
            pad += 1
        else:
            break

    address = b58_digits[0] * pad + res

    if original != util.hexlify(base58_check_decode(address, version)):
        raise AddressError('encoded address does not decode properly')

    return address

def base58_check_decode(s, version):
    """Decode from base58."""
    # Convert the string to an integer
    n = 0
    for c in s:
        n *= 58
        if c not in b58_digits:
            raise Base58Error('Not a valid Base58 character: ‘{}’'.format(c))
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
        if c == b58_digits[0]:
            pad += 1
        else:
            break
    k = version * pad + res

    addrbyte, data, chk0 = k[0:1], k[1:-4], k[-4:]
    if addrbyte != version:
        raise VersionByteError('incorrect version byte')
    chk1 = util.dhash(addrbyte + data)[:4]
    if chk0 != chk1:
        raise Base58ChecksumError('Checksum mismatch: 0x{} ≠ 0x{}'.format(util.hexlify(chk0), util.hexlify(chk1)))
    return data


def is_multisig(address):
    """Check if the address is multi‐signature."""
    array = address.split('_')
    return len(array) > 1

def is_fully_valid(pubkey_bin):
    """Check if the public key is valid."""
    cpubkey = CPubKey(pubkey_bin)
    return cpubkey.is_fullyvalid

def make_canonical(address):
    """Return canonical version of the address."""
    if is_multisig(address):
        signatures_required, pubkeyhashes, signatures_possible = extract_array(address)
        try:
            [base58_check_decode(pubkeyhash, config.ADDRESSVERSION) for pubkeyhash in pubkeyhashes]
        except Base58Error:
            raise MultiSigAddressError('Multi‐signature address must use PubKeyHashes, not public keys.')
        return construct_array(signatures_required, pubkeyhashes, signatures_possible)
    else:
        return address

def test_array(signatures_required, pubs, signatures_possible):
    """Check if multi‐signature data is valid."""
    try:
        signatures_required, signatures_possible = int(signatures_required), int(signatures_possible)
    except (ValueError, TypeError):
        raise MultiSigAddressError('Signature values not integers.')
    if signatures_required < 1 or signatures_required > 3:
        raise MultiSigAddressError('Invalid signatures_required.')
    if signatures_possible < 2 or signatures_possible > 3:
        raise MultiSigAddressError('Invalid signatures_possible.')
    for pubkey in pubs:
        if '_' in pubkey:
            raise MultiSigAddressError('Invalid characters in pubkeys/pubkeyhashes.')
    if signatures_possible != len(pubs):
        raise InputError('Incorrect number of pubkeys/pubkeyhashes in multi‐signature address.')

def construct_array(signatures_required, pubs, signatures_possible):
    """Create a multi‐signature address."""
    test_array(signatures_required, pubs, signatures_possible)
    address = '_'.join([str(signatures_required)] + sorted(pubs) + [str(signatures_possible)])
    return address

def extract_array(address):
    """Extract data from multi‐signature address."""
    assert is_multisig(address)
    array = address.split('_')
    signatures_required, pubs, signatures_possible = array[0], sorted(array[1:-1]), array[-1]
    test_array(signatures_required, pubs, signatures_possible)
    return int(signatures_required), pubs, int(signatures_possible)

def pubkeyhash_array(address):
    """Return PubKeyHashes from an address."""
    signatures_required, pubs, signatures_possible = extract_array(address)
    if not all([is_pubkeyhash(pub) for pub in pubs]):
        raise MultiSigAddressError('Invalid PubKeyHashes. Multi‐signature address must use PubKeyHashes, not public keys.')
    pubkeyhashes = pubs
    return pubkeyhashes

def hash160(x):
    x = hashlib.sha256(x).digest()
    m = hashlib.new('ripemd160')
    m.update(x)
    return m.digest()

def pubkey_to_pubkeyhash(pubkey):
    """Convert public key to PubKeyHash."""
    pubkeyhash = hash160(pubkey)
    pubkey = base58_check_encode(binascii.hexlify(pubkeyhash).decode('utf-8'), config.ADDRESSVERSION)
    return pubkey

def get_asm(scriptpubkey):
    # TODO: When is an exception thrown here? Can this `try` block be tighter? Can it be replaced by a conditional?
    try:
        asm = []
        # TODO: This should be `for element in scriptpubkey`.
        for op in scriptpubkey:
            if type(op) == bitcoinlib.core.script.CScriptOp:
                # TODO: `op = element`
                asm.append(str(op))
            else:
                # TODO: `data = element` (?)
                asm.append(op)
    except bitcoinlib.core.script.CScriptTruncatedPushDataError:
        raise exceptions.DecodeError('invalid pushdata due to truncation')
    if not asm:
        raise exceptions.DecodeError('empty output')
    return asm

def get_checksig(asm):
    if len(asm) == 5 and asm[0] == 'OP_DUP' and asm[1] == 'OP_HASH160' and asm[3] == 'OP_EQUALVERIFY' and asm[4] == 'OP_CHECKSIG':
        pubkeyhash = asm[2]
        if type(pubkeyhash) == bytes:
            return pubkeyhash
    raise exceptions.DecodeError('invalid OP_CHECKSIG')

def get_checkmultisig(asm):
    # N‐of‐2
    if len(asm) == 5 and asm[3] == 2 and asm[4] == 'OP_CHECKMULTISIG':
        pubkeys, signatures_required = asm[1:3], asm[0]
        if all([type(pubkey) == bytes for pubkey in pubkeys]):
            return pubkeys, signatures_required
    # N‐of‐3
    if len(asm) == 6 and asm[4] == 3 and asm[5] == 'OP_CHECKMULTISIG':
        pubkeys, signatures_required = asm[1:4], asm[0]
        if all([type(pubkey) == bytes for pubkey in pubkeys]):
            return pubkeys, signatures_required
    raise exceptions.DecodeError('invalid OP_CHECKMULTISIG')

def scriptpubkey_to_address(scriptpubkey):
    asm = get_asm(scriptpubkey)
    if asm[-1] == 'OP_CHECKSIG':
        try:
            checksig = get_checksig(asm)
        except exceptions.DecodeError: # coinbase
            return None
        return base58_check_encode(binascii.hexlify(checksig).decode('utf-8'), config.ADDRESSVERSION)
    elif asm[-1] == 'OP_CHECKMULTISIG':
        pubkeys, signatures_required = get_checkmultisig(asm)
        pubkeyhashes = [pubkey_to_pubkeyhash(pubkey) for pubkey in pubkeys]
        return construct_array(signatures_required, pubkeyhashes, len(pubkeyhashes))
    return None




# TODO: Use `python-bitcointools` instead. (Get rid of `pycoin` dependency.)
from pycoin.encoding import wif_to_tuple_of_secret_exponent_compressed, public_pair_to_sec, EncodingError
from pycoin.ecdsa import generator_secp256k1, public_pair_for_secret_exponent

class AltcoinSupportError (Exception): pass
def private_key_to_public_key(private_key_wif):
    """Convert private key to public key."""
    if config.TESTNET:
        allowable_wif_prefixes = [config.PRIVATEKEY_VERSION_TESTNET]
    else:
        allowable_wif_prefixes = [config.PRIVATEKEY_VERSION_MAINNET]
    try:
        secret_exponent, compressed = wif_to_tuple_of_secret_exponent_compressed(
                private_key_wif, allowable_wif_prefixes=allowable_wif_prefixes)
    except EncodingError:
        raise AltcoinSupportError('pycoin: unsupported WIF prefix')
    public_pair = public_pair_for_secret_exponent(generator_secp256k1, secret_exponent)
    public_key = public_pair_to_sec(public_pair, compressed=compressed)
    public_key_hex = binascii.hexlify(public_key).decode('utf-8')
    return public_key_hex

def is_pubkeyhash(monosig_address):
    """Check if PubKeyHash is valid. """
    assert not is_multisig(monosig_address)
    try:
        base58_check_decode(monosig_address, config.ADDRESSVERSION)
        return True
    except (Base58Error, VersionByteError):
        return False

def make_pubkeyhash(address):
    """Create a new PubKeyHash."""
    if is_multisig(address):
        signatures_required, pubs, signatures_possible = extract_array(address)
        pubkeyhashes = []
        for pub in pubs:
            if is_pubkeyhash(pub):
                pubkeyhash = pub
            else:
                pubkeyhash = pubkey_to_pubkeyhash(binascii.unhexlify(bytes(pub, 'utf-8')))
            pubkeyhashes.append(pubkeyhash)
        pubkeyhash_address = construct_array(signatures_required, pubkeyhashes, signatures_possible)
    else:
        if is_pubkeyhash(address):
            pubkeyhash_address = address
        else:
            pubkeyhash_address = pubkey_to_pubkeyhash(binascii.unhexlify(bytes(address, 'utf-8')))
    return pubkeyhash_address

def extract_pubkeys(pub):
    """Assume pubkey if not pubkeyhash. (Check validity later.)"""
    pubkeys = []
    if is_multisig(pub):
        _, pubs, _ = extract_array(pub)
        for pub in pubs:
            if not is_pubkeyhash(pub):
                pubkeys.append(pub)
    else:
        if not is_pubkeyhash(pub):
            pubkeys.append(pub)
    return pubkeys

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
