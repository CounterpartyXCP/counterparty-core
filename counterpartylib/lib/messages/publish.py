import struct
import binascii
import logging
from bitcoin.core import VarIntSerializer
logger = logging.getLogger(__name__)

from counterpartylib.lib import (util, config, exceptions)
from counterpartylib.lib.messages import (execute)
from counterpartylib.lib.evm import exceptions as evmexceptions, transactions, blocks, processblock
from counterpartylib.lib.evm.address import Address

FORMAT = '>QQQ'
LENGTH = 8 + 8 + 8
ID = 103


def unpack(db, message):
    # Unpack message.
    curr_format = FORMAT + '{}s'.format(len(message) - LENGTH)
    try:
        gasprice, startgas, endowment, code = struct.unpack(curr_format, message)
        if gasprice > config.MAX_INT or startgas > config.MAX_INT:  # TODO: define max for gasprice and startgas
            raise exceptions.UnpackError()

        codelen = VarIntSerializer.deserialize(code)
        codelenlen = len(VarIntSerializer.serialize(codelen))
        code = code[codelenlen:(codelenlen + codelen)]

    except (struct.error) as e:
        raise exceptions.UnpackError()

    return None, gasprice, startgas, endowment, code


def compose(db, source, gasprice, startgas, endowment, code_hex):
    if not util.enabled('evmparty'):
        logger.warn("EVM hasn't been activated yet!")
        return

    code = binascii.unhexlify(code_hex)

    if startgas < 0:
        raise evmexceptions.ContractError('negative startgas')
    if gasprice < 0:
        raise evmexceptions.ContractError('negative gasprice')

    # Pack.
    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, gasprice, startgas, endowment)
    data += VarIntSerializer.serialize(len(code))
    data += code

    return (source, [], data)


def parse(db, tx, message):
    if not util.enabled('evmparty'):
        logger.warn("EVM hasn't been activated yet!")
        return

    return execute.parse_helper(db, tx, message, unpack)


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
