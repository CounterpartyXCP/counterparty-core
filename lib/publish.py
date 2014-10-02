#! /usr/bin/python3

"""Store arbitrary data in the blockchain."""

import struct
import binascii
import hashlib

from . import (util, config, exceptions, bitcoin, util)

ID = 100

def create_contract (db, contract_id, tx_index, tx_hash, block_index, source, code):
    cursor = db.cursor()

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'contract_id': contract_id,
        'tx_index': tx_index,
        'tx_hash': tx_hash,
        'block_index': block_index,
        'source': source,
        'code': code,
        'storage': b'',
        'alive': True,
    }
    sql='insert into contracts values(:contract_id, :tx_index, :tx_hash, :block_index, :source, :code, :storage, :alive)'
    cursor.execute(sql, bindings)

    cursor.close()

def compose (db, source, code_hex):

    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += binascii.unhexlify(code_hex)

    return (source, [], data)


def parse (db, tx, message):

    create_contract(db, hashlib.sha256(message).hexdigest(), tx['tx_index'], tx['tx_hash'], tx['block_index'], tx['source'], message)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
