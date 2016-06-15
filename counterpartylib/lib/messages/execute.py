import struct
import binascii
import logging
from bitcoin.core import VarIntSerializer
logger = logging.getLogger(__name__)

from counterpartylib.lib import (util, config, exceptions)
from counterpartylib.lib.evm import exceptions as evmexceptions, transactions, blocks, processblock
from counterpartylib.lib.evm.address import Address

FORMAT = '>32sQQQ'
LENGTH = 56
ID = 104


def unpack(db, message):
    curr_format = FORMAT + '{}s'.format(len(message) - LENGTH)
    try:
        contract_id, gasprice, startgas, value, payload = struct.unpack(curr_format, message)
        if gasprice > config.MAX_INT or startgas > config.MAX_INT: # TODO: define max for gasprice and startgas
            raise exceptions.UnpackError()

        payloadlen = VarIntSerializer.deserialize(payload)
        payloadlenlen = len(VarIntSerializer.serialize(payloadlen))
        payload = payload[payloadlenlen:(payloadlenlen + payloadlen)]

    except (struct.error) as e:
        raise exceptions.UnpackError()

    if contract_id == b'\x00' * 32:
        contract_id = None
    else:
        contract_id = Address.normalize(contract_id)

    return contract_id, gasprice, startgas, value, payload


def compose(db, source, contract_id, gasprice, startgas, value, payload_hex):
    if not util.enabled('evmparty'):
        return

    contract_id = Address.normalize(contract_id)

    payload = binascii.unhexlify(payload_hex)

    if startgas < 0:
        raise evmexceptions.ContractError('negative startgas')
    if gasprice < 0:
        raise evmexceptions.ContractError('negative gasprice')

    # Pack.
    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, contract_id.bytes32() if contract_id else b'', gasprice, startgas, value)
    data += VarIntSerializer.serialize(len(payload))
    data += payload

    return (source, [], data)


def parse(db, tx, message):
    if not util.enabled('evmparty'):
        return

    return parse_helper(db, tx, message, unpack)


def parse_helper(db, tx, message, unpacker):
    """
    Because publish and execute messages are so similar this helper us used by both and only the unpacker differs
    """
    status = 'valid'
    contract_id, gasprice, startgas, value, payload, output, gas_cost, gas_remained = None, None, None, None, None, None, None, None

    try:
        # Unpack message.
        contract_id, gasprice, startgas, value, payload = unpacker(db, message)

        # Apply transaction!
        block_obj = blocks.Block(db, tx['block_hash'])
        tx_obj = transactions.Transaction(tx, nonce=block_obj.get_nonce(tx['source']), to=contract_id, gasprice=1, startgas=startgas, value=value, data=payload)
        success, output, gas_remained = processblock.apply_transaction(db, block_obj, tx_obj)

        if not success and output == '':
            status = 'out of gas'
        gas_cost = gasprice * (startgas - gas_remained)  # different definition from pyethereum’s

    except exceptions.UnpackError as e:
        contract_id, gasprice, startgas, value, payload = None, None, None, None, None
        status = 'invalid: could not unpack'
    except evmexceptions.InvalidTransaction as e:
        logger.debug('invalid transaction: %s' % e)
        status = 'invalid: invalid transaction'
    except evmexceptions.InsufficientStartGas as e:
        logger.debug('Insufficient start gas: %s' % e)
        status = 'invalid: insufficient start gas'
    except evmexceptions.InsufficientBalance as e:
        logger.debug('Insufficient balance: %s' % e)
        status = 'invalid: insufficient balance'

    if status == 'valid':
        logger.debug('TX FINISHED (gas_remained: {})'.format(gas_remained))

    if isinstance(output, Address):
        output = output.base58()
    if isinstance(contract_id, Address):
        contract_id = contract_id.base58()

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'contract_id': contract_id,
        'gasprice': gasprice,
        'startgas': startgas,
        'gas_cost': gas_cost,
        'gas_remained': gas_remained,
        'value': value,
        'payload': payload,
        'output': output,
        'status': status
    }
    sql = 'insert into executions values(:tx_index, :tx_hash, :block_index, :source, :contract_id, :gasprice, :startgas, :gas_cost, :gas_remained, :value, :payload, :output, :status)'

    cursor = db.cursor()
    cursor.execute(sql, bindings)
    cursor.close()


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
