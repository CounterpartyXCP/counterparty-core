#! /usr/bin/python3

"""Store arbitrary data in the blockchain."""

import struct
import binascii

from . import (util, config, exceptions, bitcoin, util, execute)
from lib.scriptlib import(blocks)

ID = 100



def do_create_contract(db, tx, message, endowment=0):
    code = message
    gasprice = 1                # TODO
    startgas = 100000           # TODO
    tx_obj = execute.Transaction(tx, '', gasprice, startgas, endowment, code)

    success, contract_id = execute.apply_transaction(db, tx_obj)


def compose (db, source, code_hex):

    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += binascii.unhexlify(code_hex)

    return (source, [], data)


def parse (db, tx, message):

    endowment = 0   # TODO
    do_create_contract(db, tx, message, endowment=endowment)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
