#! /usr/bin/python3

"""Store arbitrary data in the blockchain."""

import struct
import binascii
from bitcoin.core import VarIntSerializer

from counterpartylib.lib import (config, exceptions, util)
from . import execute

FORMAT = '>QQQ'
LENGTH = 8 + 8 + 8
ID = 103


def compose (db, source, gasprice, startgas, endowment, code_hex):
    if not util.enabled('evmparty'):
        return

    code = binascii.unhexlify(code_hex)

    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, gasprice, startgas, endowment)
    data += VarIntSerializer.serialize(len(code))
    data += code

    return (source, [], data)


def parse (db, tx, message):
    if not util.enabled('evmparty'):
        return

    try:
        gasprice, startgas, endowment = struct.unpack(FORMAT, message[:LENGTH])
        code = message[LENGTH:]

        codelen = VarIntSerializer.deserialize(code)
        codelenlen = len(VarIntSerializer.serialize(codelen))
        code = code[codelenlen:(codelenlen + codelen)]

    except (struct.error, exceptions.UnpackError) as e:
        gasprice, startgas, endowment = 0, 0, 0  # @TODO: this is a mess

    source, destination, data = execute.compose(db, tx['source'], '', gasprice, startgas, endowment, binascii.hexlify(code))
    message = data[4:]

    # Execute transaction upon publication, for actual creation of contract.
    execute.parse(db, tx, message)


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
