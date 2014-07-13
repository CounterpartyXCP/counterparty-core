#! /usr/bin/python3

"""Store arbitrary data in the block chain."""

import struct
import binascii

from . import (util, config, exceptions, bitcoin, util)

ID = 100

def compose (db, source, data_hex):

    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += binascii.unhexlify(data_hex)

    return (source, [], data)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
