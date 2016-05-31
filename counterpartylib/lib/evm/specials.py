# -*- coding: utf8 -*-

import bitcoin
import hashlib

from counterpartylib.lib.evm import ethutils as utils, opcodes
from .ethutils import safe_ord, decode_hex
from rlp.utils import ascii_chr

# @TODO
# try:
#     from c_secp256k1 import ecdsa_recover_raw
# except ImportError:
#     import warnings
#     warnings.warn('missing c_secp256k1 falling back to pybitcointools')
#
#     from bitcoin import ecdsa_raw_recover as ecdsa_recover_raw


ZERO_PRIVKEY_ADDR = decode_hex('3f17f1962b36e491b30a40b2405849e597ba5fb5')


def proc_ecrecover(ext, msg):
    # print('ecrecover proc', msg.gas)
    OP_GAS = opcodes.GECRECOVER
    gas_cost = OP_GAS
    if msg.gas < gas_cost:
        return 0, 0, []

    message_hash_bytes = [0] * 32
    msg.data.extract_copy(message_hash_bytes, 0, 0, 32)
    message_hash = b''.join(map(ascii_chr, message_hash_bytes))

    v = msg.data.extract32(32)
    r = msg.data.extract32(64)
    s = msg.data.extract32(96)

    sig = utils.zpad(utils.int_to_big_endian(v), 1) + utils.zpad(utils.int_to_big_endian(r), 32) + utils.zpad(utils.int_to_big_endian(s), 32)

    try:
        pubkey = bitcoin.core.key.CPubKey.recover_compact(message_hash, sig)
    except:
        # Recovery failed
        return 1, msg.gas - gas_cost, []

    o = [0] * 12 + [safe_ord(x) for x in utils.sha3(pubkey[1:])[-20:]]
    return 1, msg.gas - gas_cost, o


def proc_sha256(ext, msg):
    # print('sha256 proc', msg.gas)
    OP_GAS = opcodes.GSHA256BASE + \
        (utils.ceil32(msg.data.size) // 32) * opcodes.GSHA256WORD
    gas_cost = OP_GAS
    if msg.gas < gas_cost:
        return 0, 0, []
    d = msg.data.extract_all()

    o = [safe_ord(x) for x in hashlib.sha256(d).digest()]
    return 1, msg.gas - gas_cost, o


def proc_ripemd160(ext, msg):
    # print('ripemd160 proc', msg.gas)
    OP_GAS = opcodes.GRIPEMD160BASE + \
        (utils.ceil32(msg.data.size) // 32) * opcodes.GRIPEMD160WORD
    gas_cost = OP_GAS
    if msg.gas < gas_cost:
        return 0, 0, []
    d = msg.data.extract_all()
    o = [0] * 12 + [safe_ord(x) for x in hashlib.new('ripemd160', d).digest()]
    return 1, msg.gas - gas_cost, o


def proc_identity(ext, msg):
    #print('identity proc', msg.gas)
    OP_GAS = opcodes.GIDENTITYBASE + \
        opcodes.GIDENTITYWORD * (utils.ceil32(msg.data.size) // 32)
    gas_cost = OP_GAS
    if msg.gas < gas_cost:
        return 0, 0, []
    o = [0] * msg.data.size
    msg.data.extract_copy(o, 0, 0, len(o))
    return 1, msg.gas - gas_cost, o

specials = {
    decode_hex(k): v for k, v in
    {
        '0000000000000000000000000000000000000001': proc_ecrecover,
        '0000000000000000000000000000000000000002': proc_sha256,
        '0000000000000000000000000000000000000003': proc_ripemd160,
        '0000000000000000000000000000000000000004': proc_identity,
    }.items()
}

if __name__ == '__main__':
    class msg(object):
        data = 'testdata'
        gas = 500
    proc_ripemd160(None, msg)
