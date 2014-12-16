import hashlib
import bitcoin as bitcoinlib
import binascii

from lib import (util, config, address)
from .exceptions import DecodeError

def hash160(x):
    x = hashlib.sha256(x).digest()
    m = hashlib.new('ripemd160')
    m.update(x)
    return m.digest()

def pubkey_to_pubkeyhash(pubkey):
    pubkeyhash = hash160(pubkey)
    pubkey = address.base58_check_encode(binascii.hexlify(pubkeyhash).decode('utf-8'), config.ADDRESSVERSION)
    return pubkey

def get_asm(scriptpubkey):
    try:
        asm = []
        for op in scriptpubkey:
            if type(op) == bitcoinlib.core.script.CScriptOp:
                asm.append(str(op))
            else:
                asm.append(op)
    except bitcoinlib.core.script.CScriptTruncatedPushDataError:
        raise DecodeError('invalid pushdata due to truncation')
    if not asm:
        raise DecodeError('empty output')
    return asm

def get_checksig(asm):
    if len(asm) == 5 and asm[0] == 'OP_DUP' and asm[1] == 'OP_HASH160' and asm[3] == 'OP_EQUALVERIFY' and asm[4] == 'OP_CHECKSIG':
        pubkeyhash = asm[2]
        if type(pubkeyhash) == bytes:
            return pubkeyhash
    raise DecodeError('invalid OP_CHECKSIG')

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
    raise DecodeError('invalid OP_CHECKMULTISIG')

def scriptpubkey_to_address(scriptpubkey):
    asm = get_asm(scriptpubkey)
    if asm[-1] == 'OP_CHECKSIG':
        return address.base58_check_encode(binascii.hexlify(get_checksig(asm)).decode('utf-8'), config.ADDRESSVERSION)
    elif asm[-1] == 'OP_CHECKMULTISIG':
        pubkeys, signatures_required = get_checkmultisig(asm)
        pubkeyhashes = [pubkey_to_pubkeyhash(pubkey) for pubkey in pubkeys]
        return address.construct_array(signatures_required, pubkeyhashes, len(pubkeyhashes))
    return None




from pycoin.encoding import wif_to_tuple_of_secret_exponent_compressed, public_pair_to_sec, EncodingError
from pycoin.ecdsa import generator_secp256k1, public_pair_for_secret_exponent

class AltcoinSupportError (Exception): pass
def private_key_to_public_key (private_key_wif):
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

def pubkeyhash_to_pubkey(pubkeyhash):
    raw_transactions = blockchain.searchrawtransactions(pubkeyhash)
    for tx in raw_transactions:
        for vin in tx['vin']:
            scriptsig = vin['scriptSig']
            asm = scriptsig['asm'].split(' ')
            pubkey = asm[1]
            if pubkeyhash == script.pubkey_to_pubkeyhash(binascii.unhexlify(bytes(pubkey, 'utf-8'))):
                return pubkey
    raise exceptions.AddressError('Public key for address ‘{}’ not published in blockchain.'.format(pubkeyhash))
def multisig_pubkeyhashes_to_pubkeys(address):
    signatures_required, pubkeyhashes, signatures_possible = address.extract_array(address)
    pubkeys = [pubkeyhash_to_pubkey(pubkeyhash) for pubkeyhash in pubkeyhashes]
    return address.construct_array(signatures_required, pubkeys, signatures_possible)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
