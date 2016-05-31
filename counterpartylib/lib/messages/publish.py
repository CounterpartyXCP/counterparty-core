#! /usr/bin/python3

"""Store arbitrary data in the blockchain."""

import struct
import binascii

from counterpartylib.lib import (config, exceptions, util)
from . import execute

FORMAT = '>QQQ'
LENGTH = 8 + 8 + 8
ID = 103


def compose (db, source, gasprice, startgas, endowment, code_hex):
    if not util.enabled('evmparty'):
        return

    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, gasprice, startgas, endowment)
    data += binascii.unhexlify(code_hex)

    return (source, [], data)


def parse (db, tx, message):
    if not util.enabled('evmparty'):
        return

    try:
        gasprice, startgas, endowment = struct.unpack(FORMAT, message[:LENGTH])
    except struct.error:
        gasprice, startgas, endowment = 0, 0, 0 # TODO: Is this ideal 

    code = util.hexlify(message[LENGTH:])
    source, destination, data = execute.compose(db, tx['source'], '', gasprice, startgas, endowment, code)
    message = data[4:]

    # Execute transaction upon publication, for actual creation of contract.
    execute.parse(db, tx, message)


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
