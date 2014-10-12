#! /usr/bin/python3

# TODO: Ethereum (and Serpent?) licence

"""Execute arbitrary data as a smart contract."""

import struct
import binascii
import time
import logging
import string
import json
import pickle

from lib import (util, config, exceptions, bitcoin, util)
from lib.scriptlib import (rlp, utils, opcodes, blocks)

FORMAT = '>32sQQQ'
LENGTH = 56
ID = 101

class PBLogger(object):
    def log(self, name, **kargs):
        if name == 'TX NEW':
            order = dict(nonce=-10, sender=-9, startgas=-8, value=-7, to=-6, data=-5, gasprice=-4)
        elif name in ('OP', 'STK'):
            order = dict(pc=-2, op=-1, gas=0, value=.5, stackargs=1, data=2, code=3)
        elif name == 'SUB CALL NEW':
            order = dict(to=-2, gas=-1, sender=0, value=1, data=2)
        elif name == 'MSG APPLY':
            order = dict(sender=-2, tx=-1, gas=0, value=1, to=2, data=3)
        elif name == 'MSG PRE STATE':
            order = dict(nonce=-2, balance=-1, storage=0, code=1, to=2, data=3)
        else:
            order = dict()
        items = sorted(kargs.items(), key=lambda x: order.get(x[0], 0))
        msg = ", ".join("%s=%s" % (k,v) for k,v in items)
        logging.info("%s: %s", name.ljust(15), msg)

pblogger = PBLogger()

def log (name, obj):
    assert type(obj) == dict

    # Convert binary.
    for key in obj.keys():
        if type(obj[key]) == bytes:
            obj[key] = utils.hexprint(obj[key])

    # Truncate long lines.
    for key in obj.keys():
        if type(obj[key]) == str and len(obj[key]) > 120:
            obj[key] = obj[key][:60] + '…' + obj[key][-60:]

    # Sort
    if name == 'OP':
        keyorder = ['pc', 'gas', 'op', 'stackargs', 'value', 'stack']
        obj = sorted(obj.items(), key=lambda i:keyorder.index(i[0]))
    else:
        obj = sorted(obj.items())
    lines = ['{}: {}'.format(pair[0], pair[1]) for pair in obj]

    if 'op' == name.lower():
        string = str(lines).replace("'", "")[1:-1]
        logging.debug('\tOP ' + string)
    else:
        if name:
            logging.debug(name)
        for line in lines:
            logging.debug('\t' + str(line))

GDEFAULT = 1
GMEMORY = 1
GSTORAGE = 100
GTXDATA = 5
GTXCOST = 500
TT255 = 2**255
TT256 = 2**256

OUT_OF_GAS = -1

CREATE_CONTRACT_ADDRESS = ''

# TODO: Make fees proportional to money supply.



def compose (db, source, contract_id, gasprice, startgas, value, payload_hex):
    code = blocks.block.get_code(db, contract_id)
    payload = binascii.unhexlify(payload_hex)
    # TODO: Check start_gas, gasprice here?

    # Pack.
    data = struct.pack(config.TXTYPE_FORMAT, ID)
    curr_format = FORMAT + '{}s'.format(len(payload))
    data += struct.pack(curr_format, binascii.unhexlify(contract_id), gasprice, startgas, value, payload)

    return (source, [], data)

class Transaction(object):
    def __init__(self, tx, to, gasprice, startgas, value, data):
        assert type(data) == bytes
        self.block_index = tx['block_index']
        self.tx_hash = tx['tx_hash']
        self.sender = tx['source']
        self.data = data 
        self.to = to
        self.gasprice = gasprice
        self.startgas = startgas
        self.value = value
        self.timestamp = tx['timestamp']
    def hex_hash(self):
        return '<None>'
    def to_dict(self):
        dict_ = {
                 'sender': self.sender,
                 'data': utils.hexprint(self.data),
                 'to': self.to,
                 'gasprice': self.gasprice,
                 'startgas': self.startgas,
                 'value': self.value
                }
        return dict_

class ContractError(Exception): pass
def parse (db, tx, message):
    output = None
    status = 'valid'


    # TODO: unit tests!

    try:
        # Unpack message.
        curr_format = FORMAT + '{}s'.format(len(message) - LENGTH)
        try:
            contract_id, gasprice, startgas, value, payload = struct.unpack(curr_format, message)
        except (struct.error) as e:
            raise exceptions.UnpackError()

        contract_id = util.hexlify(contract_id)
        # TODO: gasprice is an int

        # ‘Apply transaction’!
        tx_obj = Transaction(tx, contract_id, gasprice, startgas, value, payload)
        block_obj = blocks.Block(db)
        apply_transaction(db, block_obj, tx_obj)

    except exceptions.UnpackError as e:
        contract_id, gasprice, startgas, value, payload = None, None, None, None, None
        status = 'invalid: could not unpack'
        output = None
    except util.ContractError as e:
        status = 'invalid: no such contract'
        contract_id = None
        output = None
    except InsufficientStartGas as e:
        have, need = e.args
        logging.debug('Insufficient start gas: have {} and need {}'.format(have, need))
        status = 'invalid: insufficient start gas'
        output = None
    except InsufficientBalance as e:
        have, need = e.args
        logging.debug('Insufficient balance: have {} and need {}'.format(have, need))
        status = 'invalid: insufficient balance'
        print(contract_id)
        output = None
    except OutOfGas as e:
        logging.debug('TX OUT_OF_GAS (startgas: {}, gas_remaining: {})'.format(startgas, gas_remaining))
        status = 'out of gas'
        output = None
    finally:

        # TODO: eh…
        if status == 'valid':
            logging.debug('TX FINISHED (gas_remaining: {})'.format(gas_remaining))

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
            'gas_remaining': gas_remaining,
            'value': value,
            'payload': payload,
            'output': output,
            'status': status
        }
        sql='insert into executions values(:tx_index, :tx_hash, :block_index, :source, :contract_id, :gasprice, :startgas, :gas_cost, :gas_remaining, :value, :data, :output, :status)'
        cursor = db.cursor()
        cursor.execute(sql, bindings)


class Message(object):
    def __init__(self, sender, to, value, gas, data):
        assert type(sender) == str
        assert type(to) == str
        self.sender = sender
        self.to = to
        self.value = value
        self.gas = gas
        self.data = data
        # TODO: self.decoded_data = utils.decode_datalist(data) # TODO: This can confuse endianness.

class HaltExecution(Exception): pass
class InsufficientBalance(HaltExecution): pass
class InsufficientStartGas(HaltExecution): pass
class OutOfGas(HaltExecution): pass
def apply_transaction(db, block, tx):
    def rp(actual, target):
        return '%r, actual:%r target:%r' % (tx, actual, target)

    # (3) the gas limit is no smaller than the intrinsic gas,
    # g0, used by the transaction;
    intrinsic_gas_used = GTXDATA * len(tx.data) + GTXCOST
    if tx.startgas < intrinsic_gas_used:
        raise InsufficientStartGas(rp(tx.startgas, intrinsic_gas_used))

    # (4) the sender account balance contains at least the
    # cost, v0, required in up-front payment.
    total_cost = tx.value + tx.gasprice * tx.startgas
    if block.get_balance(tx.sender) < total_cost:
        raise InsufficientBalance(
            rp(block.get_balance(tx.sender), total_cost))

    pblogger.log('TX NEW', tx=tx.hex_hash(), tx_dict=tx.to_dict())
    # log('TX NEW', tx_dict)
    # start transacting #################
    block.increment_nonce(tx.sender)

    # buy startgas
    success = block.transfer_value(tx, tx.sender, None,
                                   tx.gasprice * tx.startgas)
    assert success

    message_gas = tx.startgas - intrinsic_gas_used
    message = Message(tx.sender, tx.to, tx.value, message_gas, tx.data)


    ### Rather different ###
    primary_result = None

    # Postqueue
    block.postqueue_delete()
    block.postqueue_insert(message)
    while block.postqueue_get():
        message = block.postqueue_pop()
        # MESSAGE
        if tx.to and tx.to != CREATE_CONTRACT_ADDRESS:
            result, gas_remained, data = apply_msg_send(db, block, tx, message)
        else:  # CREATE
            result, gas_remained, data = create_contract(db, block, tx, message)
        if not primary_result:
            primary_result = result, gas_remained, data
    ### Rather different ###

    result, gas_remained, data = primary_result

    assert gas_remained >= 0

    pblogger.log("TX APPLIED", result=result, gas_remained=gas_remained,
                 data=util.hexlify(bytes(data)))
    # if pblogger.log_block:
    #     pblogger.log('BLOCK', block=block.to_dict(with_state=True, full_transactions=True))


    if not result:  # 0 = OOG failure in both cases
        # pblogger.log('TX FAILED', reason='out of gas', startgas=tx.startgas, gas_remained=gas_remained)
        output = OUT_OF_GAS
    else:
        pblogger.log('TX SUCCESS')
        gas_remained = int(gas_remained)  # TODO: BAD
        # sell remaining gas
        block.transfer_value(
            tx, None, tx.sender, tx.gasprice * gas_remained)
        if tx.to:
            # output = ''.join(map(chr, data))
            output = bytes(data)
        else:
            output = result
    # TODO: block.commit_state()

    # Kill suicidal contract.
    for s in block.suicides_get():
        block.del_account(s)
    block.suicides_delete()
    success = output is not OUT_OF_GAS
    return success, output if success else ''


def get_msg_state(block, msg, code):
    msg_state = {}
    # msg_state['contract'] = msg.to
    msg_state['balance'] = block.get_balance(msg.to)
    storages = ['{}: {}'.format(utils.hexprint(storage['key']), utils.hexprint(storage['value'])) for storage in block.get_storage_data(msg.to)]
    msg_state['storage'] = storages
    msg_state['code'] = code
    return msg_state

class Compustate():
    def __init__(self, **kwargs):
        self.memory = []
        self.stack = []
        self.pc = 0
        self.gas = 0
        for kw in kwargs:
            setattr(self, kw, kwargs[kw])

def apply_msg(db, block, tx, msg, code):
    """
    logging.debug('\n')
    new_dict = vars(msg).copy()
    new_dict.update(get_msg_state(block, msg, code))
    logging.debug('\nBEGIN MESSAGE') # TODO
    log('', new_dict)
    """

    pblogger.log("MSG APPLY", tx=tx.hex_hash(), sender=msg.sender, to=msg.to,
                                  gas=msg.gas, value=msg.value, data=utils.hexprint(msg.data))
    pblogger.log('MSG PRE STATE', account=msg.to, state=block.account_to_dict(msg.to))
    # Transfer value, instaquit if not enough
    o = block.transfer_value(tx, msg.sender, msg.to, msg.value)
    if not o:
        return 1, msg.gas, []

    processed_code = [opcodes.opcodes.get(c, ['INVALID', 0, 0, [], 0]) + [c] for c in code]
    # logging.debug('PROCESSED_CODE {}'.format(processed_code))

    try:
        # Snapshot.
        with db:

            # Initialise compustate.
            compustate = Compustate(gas=msg.gas)
            t, ops = time.time(), 0

            # Main loop
            # logging.debug('')
            while True:
                o = apply_op(db, block, tx, msg, processed_code, compustate)
                ops += 1

                if o is not None:
                    """"
                    # TODO: ugly
                    if data == OUT_OF_GAS:
                        data_printable = -1
                    else:
                        data_printable = bytes(data)

                    msg_applied = {'data (result)': data_printable,
                                   'sender': msg.sender,
                                   'to': msg.to,
                                   'gas': gas_remaining}
                    new_dict = msg_applied.copy()
                    new_dict.update(get_msg_state(msg, code))
                    logging.debug('')
                    log('', new_dict)
                    logging.debug('END MESSAGE\n')
                    """

                    pblogger.log('MSG APPLIED', result=o, gas_remained=compustate.gas,
                                sender=msg.sender, to=msg.to, ops=ops,
                                time_per_op=(time.time() - t) / ops)
                    pblogger.log('MSG POST STATE', account=msg.to,
                                state=block.account_to_dict(msg.to))

                    if o == OUT_OF_GAS:
                        raise OutOfGas
                        block.revert(snapshot)
                    else:
                        return 1, compustate.gas, o

    # When out of gas, break out of the `with` and then `return`.
    except OutOfGas as e:
        result = 0
        data = []
        gas_remained = compustate.gas
        return result, gas_remained, data

def apply_msg_send(db, block, tx, msg):
    return apply_msg(db, block, tx, msg, block.get_code(msg.to))

def create_contract(db, block, tx, msg):
    sender = binascii.unhexlify(msg.sender) if len(msg.sender) == 40 else msg.sender
    if tx.sender != msg.sender:
        block.increment_nonce(msg.sender)
    nonce = utils.encode_int(block.get_nonce(msg.sender) - 1)
    # msg.to = utils.sha3(rlp.encode([sender, nonce]))[12:].encode('hex')
    msg.to = utils.contract_sha3(rlp.encode([sender, nonce]))
    assert not block.get_code(msg.to)

    res, gas, dat = apply_msg(db, block, tx, msg, msg.data)
    if res:
        # block.set_code(msg.to, ''.join(map(chr, dat)))
        cursor = db.cursor()
        bindings = {'contract_id': msg.to, 'tx_index': None, 'tx_hash': None, 'block_index': 0, 'source': None, 'code': bytes(dat), 'nonce': 0}
        sql='insert into contracts values(:contract_id, :tx_index, :tx_hash, :block_index, :source, :code, :nonce)'
        cursor.execute(sql, bindings)
        return msg.to, gas, dat
    else:
        if tx.sender != msg.sender:
            block.decrement_nonce(msg.sender)   # TODO
        block.del_account(msg.to)   # TODO
        return res, gas, dat


def get_opcode(code, index):
    return ord(code[index]) if index < len(code) else 0
def get_op_data(code, index):
    opcode = ord(code[index]) if index < len(code) else 0
    return opcodes.get(opcode, ['INVALID', 0, 0, [], 0])
def ceil32(x):
    return x if x % 32 == 0 else x + 32 - (x % 32)
def out_of_gas_exception(expense, fee, compustate, op):
    logging.debug('OUT OF GAS (expense: {}, needed: {}, available: {}, op: {}, stack: {})'.format(expense, fee, compustate.gas, op, list(reversed(compustate.stack))))
    return OUT_OF_GAS
def mem_extend(mem, compustate, op, newsize):
    if len(mem) < ceil32(newsize):
        m_extend = ceil32(newsize) - len(mem)
        mem.extend([0] * m_extend)
        memfee = GMEMORY * (m_extend // 32)
        compustate.gas -= memfee
        if compustate.gas < 0:
            out_of_gas_exception('mem_extend', memfee, compustate, op)
            return False
    return True
def to_signed(i):
    return i if i < TT255 else i - TT256

def apply_op(db, block, tx, msg, processed_code, compustate):
    # Does not include paying opfee.

    if compustate.pc >= len(processed_code):
        return []
    op, in_args, out_args, mem_grabs, fee, opcode = processed_code[compustate.pc]

    # print('APPLYING OP', op)
    # print('INARGS', in_args)
    # print('COMPUSTATE.STACK', compustate.stack)

    # empty stack error
    if in_args > len(compustate.stack):
        logging.debug('INSUFFICIENT STACK ERROR (op: {}, needed: {}, available: {})'.format(op, in_args,
                     len(compustate.stack)))
        return []

    # out of gas error
    if fee > compustate.gas:
        return out_of_gas_exception('base_gas', fee, compustate, op)

    pblogger.log('STK', stk=list(reversed(compustate.stack)))

    for i in range(0, len(compustate.memory), 16):
        memblk = compustate.memory[i:i+16]
        # logging.debug('MEM {}'.format(memprint(memblk)))

    # logging.debug('\tSTORAGE\n\t\t' + '\n\t\t'.join(['{}: {}'.format(utils.hexprint(storage['key']), utils.hexprint(storage['value'])) for storage in block.get_storage_data(msg.to)]))

    # Log operation
    log_args = dict(pc=str(compustate.pc).zfill(3),
                    op=op,
                    stackargs=compustate.stack[-1:-in_args-1:-1],
    # TODO                stack=list(reversed(compustate.stack)),
                    gas=compustate.gas)
    if op[:4] == 'PUSH':
        ind = compustate.pc + 1
        log_args['value'] = \
            utils.bytearray_to_int([x[-1] for x in processed_code[ind: ind + int(op[4:])]])
    elif op == 'CALLDATACOPY':
        log_args['data'] = binascii.hexlify(msg.data)
    # log('OP', log_args)
    pblogger.log('OP', **log_args)

    # Apply operation
    compustate.gas -= fee
    compustate.pc += 1
    stk = compustate.stack
    mem = compustate.memory
    if op == 'STOP' or op == 'INVALID':
        return []
    elif op == 'ADD':
        stk.append((stk.pop() + stk.pop()) % TT256)
    elif op == 'SUB':
        stk.append((stk.pop() - stk.pop()) % TT256)
    elif op == 'MUL':
        stk.append((stk.pop() * stk.pop()) % TT256)
    elif op == 'DIV':
        s0, s1 = stk.pop(), stk.pop()
        stk.append(0 if s1 == 0 else s0 // s1)
    elif op == 'MOD':
        s0, s1 = stk.pop(), stk.pop()
        stk.append(0 if s1 == 0 else s0 % s1)
    elif op == 'SDIV':
        s0, s1 = to_signed(stk.pop()), to_signed(stk.pop())
        stk.append(0 if s1 == 0 else (s0 // s1) % TT256)
    elif op == 'SMOD':
        s0, s1 = to_signed(stk.pop()), to_signed(stk.pop())
        stk.append(0 if s1 == 0 else (s0 % s1) % TT256)
    elif op == 'EXP':
        stk.append(pow(stk.pop(), stk.pop(), TT256))
    elif op == 'NEG':
        stk.append(-stk.pop() % TT256)
    elif op == 'LT':
        stk.append(1 if stk.pop() < stk.pop() else 0)
    elif op == 'GT':
        stk.append(1 if stk.pop() > stk.pop() else 0)
    elif op == 'SLT':
        s0, s1 = to_signed(stk.pop()), to_signed(stk.pop())
        stk.append(1 if s0 < s1 else 0)
    elif op == 'SGT':
        s0, s1 = to_signed(stk.pop()), to_signed(stk.pop())
        stk.append(1 if s0 > s1 else 0)
    elif op == 'EQ':
        stk.append(1 if stk.pop() == stk.pop() else 0)
    elif op == 'NOT':
        stk.append(0 if stk.pop() else 1)
    elif op == 'AND':
        stk.append(stk.pop() & stk.pop())
    elif op == 'OR':
        stk.append(stk.pop() | stk.pop())
    elif op == 'XOR':
        stk.append(stk.pop() ^ stk.pop())
    elif op == 'BYTE':
        s0, s1 = stk.pop(), stk.pop()
        if s0 >= 32:
            stk.append(0)
        else:
            stk.append((s1 // 256 ** (31 - s0)) % 256)
    elif op == 'ADDMOD':
        s0, s1, s2 = stk.pop(), stk.pop(), stk.pop()
        stk.append((s0 + s1) % s2 if s2 else 0)
    elif op == 'MULMOD':
        s0, s1, s2 = stk.pop(), stk.pop(), stk.pop()
        stk.append((s0 * s1) % s2 if s2 else 0)
    elif op == 'SHA3':
        s0, s1 = stk.pop(), stk.pop()
        if not mem_extend(mem, compustate, op, s0 + s1):
            return OUT_OF_GAS
        data = bytes(mem[s0: s0 + s1])
        stk.append(rlp.big_endian_to_int(utils.sha3(data)))
    elif op == 'ADDRESS':
        stk.append(utils.coerce_to_int(msg.to))
    elif op == 'BALANCE':
        addr = stk.pop()
        addr = util.hexlify(addr.to_bytes(32, byteorder='big'))
        stk.append(block.get_balance(addr))
    elif op == 'ORIGIN':
        stk.append(utils.coerce_to_int(tx.sender))
    elif op == 'CALLER':
        stk.append(utils.coerce_to_int(msg.sender))
    elif op == 'CALLVALUE':
        stk.append(msg.value)
    elif op == 'CALLDATALOAD':
        s0 = stk.pop()
        if s0 >= len(msg.data):
            stk.append(0)
        else:
            dat = msg.data[s0: s0 + 32]
            stk.append(rlp.big_endian_to_int(dat + b'\x00' * (32 - len(dat))))
    elif op == 'CALLDATASIZE':
        stk.append(len(msg.data))
    elif op == 'CALLDATACOPY':
        s0, s1, s2 = stk.pop(), stk.pop(), stk.pop()
        if not mem_extend(mem, compustate, op, s0 + s2):
            return OUT_OF_GAS
        for i in range(s2):
            if s1 + i < len(msg.data):
                mem[s0 + i] = ord(msg.data[s1 + i])
            else:
                mem[s0 + i] = 0
    elif op == 'GASPRICE':
        stk.append(tx.gasprice)
    elif op == 'CODECOPY':
        s0, s1, s2 = stk.pop(), stk.pop(), stk.pop()
        if not mem_extend(mem, compustate, op, s0 + s2):
            return OUT_OF_GAS
        for i in range(s2):
            if s1 + i < len(processed_code):
                mem[s0 + i] = processed_code[s1 + i][-1]
            else:
                mem[s0 + i] = 0
    elif op == 'EXTCODESIZE':
        stk.append(len(block.get_code(stk.pop()) or ''))
    elif op == 'EXTCODECOPY':
        addr, s1, s2, s3 = stk.pop(), stk.pop(), stk.pop(), stk.pop()
        extcode = block.get_code(addr) or ''
        if not mem_extend(mem, compustate, op, s1 + s3):
            return OUT_OF_GAS
        for i in range(s3):
            if s2 + i < len(extcode):
                mem[s1 + i] = ord(extcode[s2 + i])
            else:
                mem[s1 + i] = 0
    elif op == 'PREVHASH':
        # TODO
        stk.append(rlp.big_endian_to_int(block.prevhash))
    elif op == 'COINBASE':
        # TODO
        stk.append(rlp.big_endian_to_int(binascii.unhexlify(block.coinbase)))
    elif op == 'TIMESTAMP':
        stk.append(tx.timestamp)
    elif op == 'NUMBER':
        # TODO
        stk.append(block.number)
    elif op == 'DIFFICULTY':
        # TODO
        stk.append(block.difficulty)
    elif op == 'GASLIMIT':
        # TODO
        stk.append(block.gas_limit)
    elif op == 'POP':
        stk.pop()
    elif op == 'MLOAD':
        s0 = stk.pop()
        if not mem_extend(mem, compustate, op, s0 + 32):
            return OUT_OF_GAS
        data = bytes(mem[s0: s0 + 32])
        stk.append(rlp.big_endian_to_int(data))
    elif op == 'MSTORE':
        s0, s1 = stk.pop(), stk.pop()
        if not mem_extend(mem, compustate, op, s0 + 32):
            return OUT_OF_GAS
        v = s1
        for i in range(31, -1, -1):
            mem[s0 + i] = v % 256
            v //= 256
    elif op == 'MSTORE8':
        s0, s1 = stk.pop(), stk.pop()
        if not mem_extend(mem, compustate, op, s0 + 1):
            return OUT_OF_GAS
        mem[s0] = s1 % 256
    elif op == 'SLOAD':
        stk.append(block.get_storage_data(msg.to, stk.pop()))
    elif op == 'SSTORE':
        s0, s1 = stk.pop(), stk.pop()
        pre_occupied = GSTORAGE if block.get_storage_data(msg.to, s0) else 0
        post_occupied = GSTORAGE if s1 else 0
        gascost = GSTORAGE + post_occupied - pre_occupied
        if compustate.gas < gascost:
            out_of_gas_exception('sstore trie expansion', gascost, compustate, op)
        compustate.gas -= gascost
        block.set_storage_data(msg.to, s0, s1)
    elif op == 'JUMP':
        compustate.pc = stk.pop()
    elif op == 'JUMPI':
        s0, s1 = stk.pop(), stk.pop()
        if s1:
            compustate.pc = s0
    elif op == 'PC':
        stk.append(compustate.pc)
    elif op == 'MSIZE':
        stk.append(len(mem))
    elif op == 'GAS':
        stk.append(compustate.gas)  # AFTER subtracting cost 1
    elif op[:4] == 'PUSH':
        pushnum = int(op[4:])
        dat = [x[-1] for x in processed_code[compustate.pc: compustate.pc + pushnum]]
        compustate.pc += pushnum
        stk.append(utils.bytearray_to_int(dat))
    elif op[:3] == 'DUP':
        depth = int(op[3:])
        # DUP POP POP Debug hint
        is_debug = 1
        for i in range(depth):
            if compustate.pc + i < len(processed_code) and \
                    processed_code[compustate.pc + i][0] != 'POP':
                is_debug = 0
                break
        if is_debug:
            stackargs = [stk.pop() for i in range(depth)]
            stk.extend(reversed(stackargs))
            stk.append(stackargs[-1])
        else:
            stk.append(stk[-depth])
    elif op[:4] == 'SWAP':
        depth = int(op[4:])
        temp = stk[-depth-1]
        stk[-depth-1] = stk[-1]
        stk[-1] = temp
    elif op == 'CREATE':
        value, mstart, msz = stk.pop(), stk.pop(), stk.pop()
        if not mem_extend(mem, compustate, op, mstart + msz):
            return OUT_OF_GAS
        data = bytes(mem[mstart: mstart + msz])
        # TODO: log('SUB CONTRACT NEW', {'sender': msg.to, 'value': value, 'data': util.hexlify(data)})
        pblogger.log('SUB CONTRACT NEW', sender=msg.to, value=value, data=util.hexlify(data))
        create_msg = Message(msg.to, '', value, compustate.gas, data)
        address, gas, code = create_contract(db, block, tx, create_msg)
        # TODO: log('SUB CONTRACT OUT', {'address': address, 'code': block.get_code(address)})
        addr = utils.coerce_to_int(address)
        pblogger.log('SUB CONTRACT OUT', address=addr, code=code)
        if addr:
            stk.append(addr)
            compustate.gas = gas
        else:
            stk.append(0)
            compustate.gas = 0
    elif op == 'CALL':
        gas, to, value, meminstart, meminsz, memoutstart, memoutsz = \
            stk.pop(), stk.pop(), stk.pop(), stk.pop(), stk.pop(), stk.pop(), stk.pop()
        new_memsize = max(meminstart + meminsz, memoutstart + memoutsz)
        if not mem_extend(mem, compustate, op, new_memsize):
            return OUT_OF_GAS
        if compustate.gas < gas:
            return out_of_gas_exception('subcall gas', gas, compustate, op)
        compustate.gas -= gas
        to = utils.encode_int(to)
        to = util.hexlify(((b'\x00' * (32 - len(to))) + to)[12:])
        data = bytes(mem[meminstart: meminstart + meminsz])
        # TODO: log('SUB CALL NEW', {'sender': msg.to, 'to': to, 'value': value, 'gas': gas, 'data': util.hexlify(data)})
        pblogger.log('SUB CALL NEW', sender=msg.to, to=to, value=value, gas=gas, data=util.hexlify(data))
        call_msg = Message(msg.to, to, value, gas, data)
        result, gas, data = apply_msg_send(db, block, tx, call_msg)
        # TODO: log('SUB CALL OUT', {'result': result, 'data': data, 'length': data, 'expected': memoutsz})
        pblogger.log('SUB CALL OUT', result=result, data=data, length=len(data), expected=memoutsz)
        if result == 0:
            stk.append(0)
        else:
            stk.append(1)
            compustate.gas += gas
            for i in range(min(len(data), memoutsz)):
                mem[memoutstart + i] = data[i]
    elif op == 'RETURN':
        s0, s1 = stk.pop(), stk.pop()
        if not mem_extend(mem, compustate, op, s0 + s1):
            return OUT_OF_GAS
        return mem[s0: s0 + s1]
    elif op == 'POST':
        gas, to, value, meminstart, meminsz = \
            stk.pop(), stk.pop(), stk.pop(), stk.pop(), stk.pop()
        if not mem_extend(mem, compustate, op, meminstart + meminsz):
            return OUT_OF_GAS
        if compustate.gas < gas:
            return out_of_gas_exception('subcall gas', gas, compustate, op)
        compustate.gas -= gas
        to = utils.encode_int(to)
        to = util.hexlify(((b'\x00' * (32 - len(to))) + to)[12:])
        data = bytes(mem[meminstart: meminstart + meminsz])
        post_dict = {'sender': msg.to, 'to': to, 'value': value, 'gas': gas, 'data': util.hexlify(data)}
        log('POST NEW', post_dict)
        post_msg = Message(msg.to, to, value, gas, data)
        block.postqueue_append(post_msg)
    elif op == 'CALL_STATELESS':
        gas, to, value, meminstart, meminsz, memoutstart, memoutsz = \
            stk.pop(), stk.pop(), stk.pop(), stk.pop(), stk.pop(), stk.pop(), stk.pop()
        new_memsize = max(meminstart + meminsz, memoutstart + memoutsz)
        if not mem_extend(mem, compustate, op, new_memsize):
            return OUT_OF_GAS
        if compustate.gas < gas:
            return out_of_gas_exception('subcall gas', gas, compustate, op)
        compustate.gas -= gas
        to = utils.encode_int(to)
        to = util.hexlify(((b'\x00' * (32 - len(to))) + to)[12:])
        data = bytes(mem[meminstart: meminstart + meminsz])
        # TODO: logging.debug('SUB CALL NEW (sender: {}, to: {}, value: {}, gas: {}, data: {})'.format(msg.to, to, value, gas, util.hexlify(data)))
        pblogger.log('SUB CALL NEW', sender=msg.to, to=to, value=value, gas=gas, data=util.hexlify(data))
        call_msg = Message(msg.to, to, value, gas, data)
        result, gas, data = apply_msg_send(db, block, tx, call_msg)
        # TODO: logging.debug('SUB CALL OUT (result: {}, data: {}, length: {}, expected: {}'.format(result, data, len(data), memoutsz))
        pblogger.log('SUB CALL OUT', result=result, data=data, length=len(data), expected=memoutsz)
        if result == 0:
            stk.append(0)
        else:
            stk.append(1)
            compustate.gas += gas
            for i in range(min(len(data), memoutsz)):
                mem[memoutstart + i] = data[i]
    elif op == 'SUICIDE':
        to = utils.encode_int(stk.pop())
        to = binascii.hexlify(((b'\x00' * (32 - len(to))) + to)[12:])
        block.transfer_value(tx, msg.to, to, block.get_balance(msg.to))
        block.suicides_append(msg.to)
        return []
    for a in stk:
        assert isinstance(a, int)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
