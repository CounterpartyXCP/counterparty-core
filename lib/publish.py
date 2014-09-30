#! /usr/bin/python3

"""Store arbitrary data in the blockchain."""

import struct
import binascii

from . import (util, config, exceptions, bitcoin, util)

ID = 100

def compose (db, source, code_hex):

    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += binascii.unhexlify(code_hex)

    return (source, [], data)


def parse (db, tx, message):
    cursor = db.cursor()

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'code': message,
        'storage': b'',
    }
    sql='insert into contracts values(:tx_index, :tx_hash, :block_index, :source, :code, :storage)'
    cursor.execute(sql, bindings)

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
