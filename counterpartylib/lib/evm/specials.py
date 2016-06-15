# -*- coding: utf8 -*-
import logging
import bitcoin
import hashlib

from counterpartylib.lib.evm import ethutils, opcodes
from counterpartylib.lib import script, util, exceptions
from rlp.utils import ascii_chr

logger = logging.getLogger(__name__)


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

    sig = ethutils.zpad(ethutils.int_to_big_endian(v), 1) + ethutils.zpad(ethutils.int_to_big_endian(r), 32) + ethutils.zpad(ethutils.int_to_big_endian(s), 32)

    try:
        pubkey = bitcoin.core.key.CPubKey.recover_compact(message_hash, sig)
    except:
        # Recovery failed
        return 1, msg.gas - gas_cost, []

    from counterpartylib.lib.evm.address import Address
    addr = Address.normalize(script.pubkey_to_pubkeyhash(pubkey))
    o = [ethutils.safe_ord(x) for x in addr.bytes32()]

    return 1, msg.gas - gas_cost, o


def proc_sha256(ext, msg):
    # print('sha256 proc', msg.gas)
    OP_GAS = opcodes.GSHA256BASE + \
        (ethutils.ceil32(msg.data.size) // 32) * opcodes.GSHA256WORD
    gas_cost = OP_GAS
    if msg.gas < gas_cost:
        return 0, 0, []
    d = msg.data.extract_all()

    print('proc_sha256', d, hashlib.sha256(d).digest())
    o = [ethutils.safe_ord(x) for x in hashlib.sha256(d).digest()]
    return 1, msg.gas - gas_cost, o


def proc_ripemd160(ext, msg):
    # print('ripemd160 proc', msg.gas)
    OP_GAS = opcodes.GRIPEMD160BASE + \
        (ethutils.ceil32(msg.data.size) // 32) * opcodes.GRIPEMD160WORD
    gas_cost = OP_GAS
    if msg.gas < gas_cost:
        return 0, 0, []
    d = msg.data.extract_all()
    print('proc_sha256', d, hashlib.new('ripemd160', d).digest())
    o = [0] * 12 + [ethutils.safe_ord(x) for x in hashlib.new('ripemd160', d).digest()]
    return 1, msg.gas - gas_cost, o


def proc_identity(ext, msg):
    #print('identity proc', msg.gas)
    OP_GAS = opcodes.GIDENTITYBASE + \
        opcodes.GIDENTITYWORD * (ethutils.ceil32(msg.data.size) // 32)
    gas_cost = OP_GAS
    if msg.gas < gas_cost:
        return 0, 0, []
    o = [0] * msg.data.size
    msg.data.extract_copy(o, 0, 0, len(o))
    return 1, msg.gas - gas_cost, o


def proc_sendasset(ext, msg):
    from counterpartylib.lib.evm.address import Address

    gas_cost = opcodes.GRIPEMD160BASE

    address = msg.data.extract32(0)
    value = msg.data.extract32(32)
    asset = msg.data.extract32(64)

    address = Address.normalize(address)

    # decode asset from int to bytes to string
    asset = ethutils.int_to_big_endian(asset)
    asset = asset.decode('utf-8').replace('\x00', '').rstrip()
    
    logger.warn('proc_sendasset %s -> %s %s [%s]' % (msg.sender, address, value, repr(asset)))

    r = ext._block.transfer_value(msg.sender, address, value, asset=asset, tx=ext._tx, action='proc_sendasset')
    # try:
    #     r = ext._block.transfer_value(msg.sender, address, value, asset=asset, tx=ext._tx)
    # except util.DebitError as e:
    #     r = False

    logger.warn(r)

    o = ethutils.zpad(ethutils.encode_int(int(True)), 32)

    return 1, msg.gas - gas_cost, o


specials = {
    ethutils.decode_hex(k): v for k, v in
    {
        '0000000000000000000000000000000000000001': proc_ecrecover,
        '0000000000000000000000000000000000000002': proc_sha256,
        '0000000000000000000000000000000000000003': proc_ripemd160,
        '0000000000000000000000000000000000000004': proc_identity,
        '434e545250525459000000000000000000000001': proc_sendasset, # CNTRPRTY prefix
    }.items()
}

if __name__ == '__main__':
    class msg(object):
        data = 'testdata'
        gas = 500
    proc_ripemd160(None, msg)
