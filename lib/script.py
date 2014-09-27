from lib import util_rlp

import time
import binascii



# schema: [opcode, ins, outs, memuses, gas]
# memuses are written as an array of (start, len) pairs; values less than
# zero are taken as stackarg indices and values zero or greater are taken
# as literals
opcodes = {
    0x00: ['STOP', 0, 0, [], 0],
    0x01: ['ADD', 2, 1, [], 1],
    0x02: ['MUL', 2, 1, [], 1],
    0x03: ['SUB', 2, 1, [], 1],
    0x04: ['DIV', 2, 1, [], 1],
    0x05: ['SDIV', 2, 1, [], 1],
    0x06: ['MOD', 2, 1, [], 1],
    0x07: ['SMOD', 2, 1, [], 1],
    0x08: ['EXP', 2, 1, [], 1],
    0x09: ['NEG', 2, 1, [], 1],
    0x0a: ['LT', 2, 1, [], 1],
    0x0b: ['GT', 2, 1, [], 1],
    0x0c: ['SLT', 2, 1, [], 1],
    0x0d: ['SGT', 2, 1, [], 1],
    0x0e: ['EQ', 2, 1, [], 1],
    0x0f: ['NOT', 1, 1, [], 1],
    0x10: ['AND', 2, 1, [], 1],
    0x11: ['OR', 2, 1, [], 1],
    0x12: ['XOR', 2, 1, [], 1],
    0x13: ['BYTE', 2, 1, [], 1],
    0x14: ['ADDMOD', 3, 1, [], 1],
    0x15: ['MULMOD', 3, 1, [], 1],
    0x20: ['SHA3', 2, 1, [[-1, -2]], 20],
    0x30: ['ADDRESS', 0, 1, [], 1],
    0x31: ['BALANCE', 1, 1, [], 20],
    0x32: ['ORIGIN', 0, 1, [], 1],
    0x33: ['CALLER', 0, 1, [], 1],
    0x34: ['CALLVALUE', 0, 1, [], 1],
    0x35: ['CALLDATALOAD', 1, 1, [], 1],
    0x36: ['CALLDATASIZE', 0, 1, [], 1],
    0x37: ['CALLDATACOPY', 3, 0, [[-1, -3]], 1],
    0x38: ['CODESIZE', 0, 1, [], 1],
    0x39: ['CODECOPY', 3, 0, [[-1, -3]], 1],
    0x3a: ['GASPRICE', 0, 1, [], 1],
    0x40: ['PREVHASH', 0, 1, [], 1],
    0x41: ['COINBASE', 0, 1, [], 1],
    0x42: ['TIMESTAMP', 0, 1, [], 1],
    0x43: ['NUMBER', 0, 1, [], 1],
    0x44: ['DIFFICULTY', 0, 1, [], 1],
    0x45: ['GASLIMIT', 0, 1, [], 1],
    0x50: ['POP', 1, 0, [], 1],
    0x53: ['MLOAD', 1, 1, [[-1, 32]], 1],
    0x54: ['MSTORE', 2, 0, [[-1, 32]], 1],
    0x55: ['MSTORE8', 2, 0, [[-1, 1]], 1],
    0x56: ['SLOAD', 1, 1, [], 20],
    0x57: ['SSTORE', 2, 0, [], 0],
    0x58: ['JUMP', 1, 0, [], 1],
    0x59: ['JUMPI', 2, 0, [], 1],
    0x5a: ['PC', 0, 1, [], 1],
    0x5b: ['MSIZE', 0, 1, [], 1],
    0x5c: ['GAS', 0, 1, [], 1],
    0xf0: ['CREATE', 3, 1, [[-2, -3]], 100],
    0xf1: ['CALL', 7, 1, [[-4, -5], [-6, -7]], 20],
    0xf2: ['RETURN', 2, 1, [[-1, -2]], 1],
    0xf3: ['POST', 5, 1, [[-4, -5]], 20],
    0xf4: ['CALL_STATELESS', 7, 1, [[-4, -5], [-6, -7]], 20],
    0xff: ['SUICIDE', 1, 1, [], 0],
}
for i in range(1, 33):
    opcodes[0x5f + i] = ['PUSH' + str(i), 0, 1, [], 1]
for i in range(1, 17):
    opcodes[0x7f + i] = ['DUP' + str(i), i, i+1, [], 1]
    opcodes[0x8f + i] = ['SWAP' + str(i), i+1, i+1, [], 1]
reverse_opcodes = {}
for o in opcodes:
    reverse_opcodes[opcodes[o][0]] = o



def sha3(seed):
    return sha3_256(seed).digest()
def encode_int(v):
    '''encodes an integer into serialization'''
    if not isinstance(v, int) or v < 0 or v >= 2 ** 256:
        raise Exception("Integer invalid or out of range")
    return util_rlp.int_to_big_endian(v)
def bytearray_to_int(arr):
    o = 0
    for a in arr:
        o = o * 256 + a
    return o
def coerce_addr_to_hex(x):
    if isinstance(x, int):
        return binascii.hexlify(zpad(util_rlp.int_to_big_endian(x), 20))
    elif len(x) == 40 or len(x) == 0:
        return x
    else:
        return binascii.hexlify(zpad(x, 20)[-20:])
def coerce_to_int(x):
    if isinstance(x, int):
        return x
    elif len(x) == 40:
        return util_rlp.big_endian_to_int(binascii.unhexlify(x))
    else:
        return util_rlp.big_endian_to_int(x)

def hexprint(data):
    line = binascii.hexlify(bytes(data))
    line = ' '.join([line[i:i+2].decode('ascii') for i in range(0, len(line), 2)])
    return line


class PBLogger(object):
    def __init__(self):
        return None
    def log(self, name, **kargs):
        print(name, kargs)
pblogger = PBLogger()

code_cache = {}

GDEFAULT = 1
GMEMORY = 1
GSTORAGE = 100
GTXDATA = 5
GTXCOST = 500
TT255 = 2**255
TT256 = 2**256

OUT_OF_GAS = -1


# contract creating transactions send to an empty address
CREATE_CONTRACT_ADDRESS = ''


class VerificationFailed(Exception):
    pass
class InvalidTransaction(Exception):
    pass
class UnsignedTransaction(InvalidTransaction):
    pass
class InvalidNonce(InvalidTransaction):
    pass
class InsufficientBalance(InvalidTransaction):
    pass
class InsufficientStartGas(InvalidTransaction):
    pass
class BlockGasLimitReached(InvalidTransaction):
    pass
class GasPriceTooLow(InvalidTransaction):
    pass


def verify(block, parent):
    def must_equal(what, a, b):
        if not a == b: raise VerificationFailed(what, a, '==', b)

    if not block.timestamp >= parent.timestamp:
        raise VerificationFailed('timestamp', block.timestamp, '>=', parent.timestamp)
    if not block.timestamp <= time.time() + 900:
        raise VerificationFailed('timestamps', block.timestamp, '<=', time.time() + 900)

    block2 = blocks.Block.init_from_parent(parent,
                                           block.coinbase,
                                           extra_data=block.extra_data,
                                           timestamp=block.timestamp,
                                           uncles=block.uncles)
    must_equal('difficulty', block2.difficulty, block.difficulty)
    must_equal('gas limit', block2.gas_limit, block.gas_limit)
    for i in range(block.transaction_count):
        tx, s, g = util_rlp.decode(
            block.transactions.get(util_rlp.encode(utils.encode_int(i))))
        tx = transactions.Transaction.create(tx)
        if not tx.startgas + block2.gas_used <= block.gas_limit:
            raise VerificationFailed('gas_limit', tx.startgas + block2.gas_used, '<=', block.gas_limit)
        apply_transaction(block2, tx)
        must_equal('tx state root', s, block2.state.root_hash)
        must_equal('tx gas used', g, utils.encode_int(block2.gas_used))
    block2.finalize()
    must_equal('block state root', block2.state.root_hash, block.state.root_hash)
    must_equal('block gas used', block2.gas_used, block.gas_used)
    return True


class Message(object):

    def __init__(self, sender, to, value, gas, data):
        self.sender = sender
        self.to = to
        self.value = value
        self.gas = gas
        self.data = data

    def __repr__(self):
        return '<Message(to:%s...)>' % self.to[:8]



def apply_transaction(block, tx):

    def rp(actual, target):
        return '%r, actual:%r target:%r' % (tx, actual, target)

    # TODO
    # (2) the transaction nonce is valid (equivalent to the
    #     sender account's current nonce);
    # acctnonce = block.get_nonce(tx.sender)
    # if acctnonce != tx.nonce:
    #     raise InvalidNonce(rp(tx.nonce, acctnonce))

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

    # check offered gas price is enough
    if tx.gasprice < block.min_gas_price:
        raise GasPriceTooLow(rp(tx.gasprice, block.min_gas_price))

    # check block gas limit
    if block.gas_used + tx.startgas > block.gas_limit:
        raise BlockGasLimitReached(rp(block.gas_used + tx.startgas, block.gas_limit))


    pblogger.log('TX NEW', tx='deadbeef', tx_dict=tx.as_dict())

    # start transacting #################
    block.increment_nonce(tx.sender)

    # TODO: destroy tx.sender's (tx.gasprice * tx.startgas)

    message_gas = tx.startgas - intrinsic_gas_used
    message = Message(tx.sender, tx.to, tx.value, message_gas, tx.data)

    block.postqueue = [ message ]
    primary_result = None
    while len(block.postqueue):
        message = block.postqueue.pop(0)
        # MESSAGE
        if tx.to and tx.to != CREATE_CONTRACT_ADDRESS:
            # TODO: code = get_contract(msg.to)
            import binascii
            code_hex = '6103e8335761007580610013600039610088586001602036040e0f610022596000356000546000535660205460206020f261007558336040546040535660605460003560805460203560a05460a0536060530c0f0f61006b5960a053606053036040535760a053608053560160805357600160c054602060c0f261007558600060e054602060e0f26000f2'
            code = binascii.unhexlify(code_hex)
            result, gas_remained, data = apply_msg(block, tx, message, code)
        else:  # CREATE
            result, gas_remained, data = create_contract(block, tx, message)
            if result > 0:
                result = coerce_addr_to_hex(result)
        if not primary_result:
            primary_result = result, gas_remained, data

    result, gas_remained, data = primary_result

    assert gas_remained >= 0

    pblogger.log("TX APPLIED", result=result, gas_remained=gas_remained,
                                data=hexprint(data))
    # NOTE: pblogger.log('BLOCK', block=block.to_dict(with_state=True, full_transactions=True))


    if not result:  # 0 = OOG failure in both cases
        pblogger.log('TX FAILED', reason='out of gas', startgas=tx.startgas, gas_remained=gas_remained)
        block.gas_used += tx.startgas
        output = OUT_OF_GAS
    else:
        pblogger.log('TX SUCCESS')
        gas_used = tx.startgas - gas_remained

        # TODO: return remaining gas to tx.sender

        block.gas_used += gas_used
        if tx.to:
            output = ''.join(map(chr, data))
        else:
            output = result

    # TODO: Commit state.
    # block.commit_state()

    # NOTE
    """
    suicides = block.suicides
    block.suicides = []
    for s in suicides:
        block.del_account(s)
    block.add_transaction_to_list(tx)
    """

    success = output is not OUT_OF_GAS
    return success, output if success else ''


class Compustate():

    def __init__(self, **kwargs):
        self.memory = []
        self.stack = []
        self.pc = 0
        self.gas = 0
        for kw in kwargs:
            setattr(self, kw, kwargs[kw])


def decode_datalist(arr):
    if isinstance(arr, list):
        arr = ''.join(map(chr, arr))
    o = []
    for i in range(0, len(arr), 32):
        o.append(util_rlp.big_endian_to_int(arr[i:i + 32]))
    return o


def apply_msg(block, tx, msg, code):
    pblogger.log("MSG APPLY", tx=tx.hex_hash(), sender=msg.sender, to=msg.to,
                                  gas=msg.gas, value=msg.value, data=binascii.hexlify(msg.data))
    # NOTE: pblogger.log('MSG PRE STATE', account=msg.to, state=block.account_to_dict(msg.to))

    # NOTE
    # Transfer value, instaquit if not enough
    # o = block.transfer_value(msg.sender, msg.to, msg.value)
    # if not o:
    #     return 1, msg.gas, []
    # TODO: debit value from msg.sender
    # TODO: credit value to msg.to

    # TODO: Snapshot

    # NOTE
    # snapshot = block.snapshot()
    print('CODE', hexprint(code))
    compustate = Compustate(gas=msg.gas)
    t, ops = time.time(), 0
    if code in code_cache:
        processed_code = code_cache[code]
    else:
        processed_code = [opcodes.get(c, ['INVALID', 0, 0, [], 0]) +
                          [c] for c in code]
        code_cache[code] = processed_code
    # print('PROCESSED_CODE', processed_code)
    # Main loop
    while 1:
        o = apply_op(block, tx, msg, processed_code, compustate)
        ops += 1
        if o is not None:
            pblogger.log('MSG APPLIED', result=hexprint(o), gas_remained=compustate.gas,
                        sender=msg.sender, to=msg.to, ops=ops,
                        time_per_op=(time.time() - t) / ops)
            # NOTE: pblogger.log('MSG POST STATE', account=msg.to,
            #              state=block.account_to_dict(msg.to))

            if o == OUT_OF_GAS:
                block.revert(snapshot)
                return 0, compustate.gas, []
            else:
                return 1, compustate.gas, o


def create_contract(block, tx, msg):
    sender = binascii.unhexlify(msg.sender) if len(msg.sender) == 40 else msg.sender
    if tx.sender != msg.sender:
        block.increment_nonce(msg.sender)
    nonce = encode_int(block.get_nonce(msg.sender) - 1)
    msg.to = binascii.hexlify(sha3(util_rlp.encode([sender, nonce]))[12:])
    assert not block.get_code(msg.to)
    res, gas, dat = apply_msg(block, tx, msg, msg.data)
    if res:
        block.set_code(msg.to, ''.join(map(chr, dat)))
        return coerce_to_int(msg.to), gas, dat
    else:
        if tx.sender != msg.sender:
            block.decrement_nonce(msg.sender)
        block.del_account(msg.to)
        return res, gas, dat


def get_opcode(code, index):
    return ord(code[index]) if index < len(code) else 0


def get_op_data(code, index):
    opcode = ord(code[index]) if index < len(code) else 0
    return opcodes.get(opcode, ['INVALID', 0, 0, [], 0])


def ceil32(x):
    return x if x % 32 == 0 else x + 32 - (x % 32)


def out_of_gas_exception(expense, fee, compustate, op):
    pblogger.log('OUT OF GAS', expense=expense, needed=fee, available=compustate.gas,
                 op=op, stack=list(reversed(compustate.stack)))
    return OUT_OF_GAS


def mem_extend(mem, compustate, op, newsize):
    if len(mem) < ceil32(newsize):
        m_extend = ceil32(newsize) - len(mem)
        mem.extend([0] * m_extend)
        memfee = GMEMORY * (m_extend / 32)
        compustate.gas -= memfee
        if compustate.gas < 0:
            out_of_gas_exception('mem_extend', memfee, compustate, op)
            return False
    return True


def to_signed(i):
    return i if i < TT255 else i - TT256

# Does not include paying opfee
def apply_op(block, tx, msg, processed_code, compustate):
    if compustate.pc >= len(processed_code):
        return []
    op, in_args, out_args, mem_grabs, fee, opcode = processed_code[compustate.pc]
    print()
    # print('APPLYING OP', op)
    # print('INARGS', in_args)
    # print('COMPUSTATE.STACK', compustate.stack)
    # empty stack error
    if in_args > len(compustate.stack):
        pblogger.log('INSUFFICIENT STACK ERROR', op=op, needed=in_args,
                     available=len(compustate.stack))
        return []

    # out of gas error
    if fee > compustate.gas:
        return out_of_gas_exception('base_gas', fee, compustate, op)

    pblogger.log('STK', stk=list(reversed(compustate.stack)))

    for i in range(0, len(compustate.memory), 16):
        memblk = compustate.memory[i:i+16]
        pblogger.log('MEM', mem=hexprint(memblk))

    # NOTE: pblogger.log('STORAGE', storage=block.account_to_dict(msg.to))

    log_args = dict(pc=compustate.pc,
                    op=op,
                    stackargs=compustate.stack[-1:-in_args-1:-1],
                    gas=compustate.gas)
    if op[:4] == 'PUSH':
        ind = compustate.pc + 1
        log_args['value'] = \
            bytearray_to_int([x[-1] for x in processed_code[ind: ind + int(op[4:])]])
    elif op == 'CALLDATACOPY':
        log_args['data'] = binascii.hexlify(msg.data)
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
        stk.append(0 if s1 == 0 else s0 / s1)
    elif op == 'MOD':
        s0, s1 = stk.pop(), stk.pop()
        stk.append(0 if s1 == 0 else s0 % s1)
    elif op == 'SDIV':
        s0, s1 = to_signed(stk.pop()), to_signed(stk.pop())
        stk.append(0 if s1 == 0 else (s0 / s1) % TT256)
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
            stk.append((s1 / 256 ** (31 - s0)) % 256)
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
        data = ''.join(map(chr, mem[s0: s0 + s1]))
        stk.append(util_rlp.big_endian_to_int(sha3(data)))
    elif op == 'ADDRESS':
        stk.append(coerce_to_int(msg.to))
    elif op == 'BALANCE':
        stk.append(block.get_balance(coerce_addr_to_hex(stk.pop())))
    elif op == 'ORIGIN':
        stk.append(coerce_to_int(tx.sender))
    elif op == 'CALLER':
        stk.append(coerce_to_int(msg.sender))
    elif op == 'CALLVALUE':
        stk.append(msg.value)
    elif op == 'CALLDATALOAD':
        s0 = stk.pop()
        if s0 >= len(msg.data):
            stk.append(0)
        else:
            dat = msg.data[s0: s0 + 32]
            stk.append(util_rlp.big_endian_to_int(dat + '\x00' * (32 - len(dat))))
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
        stk.append(util_rlp.big_endian_to_int(block.prevhash))
    elif op == 'COINBASE':
        stk.append(util_rlp.big_endian_to_int(binascii.unhexlify(block.coinbase)))
    elif op == 'TIMESTAMP':
        stk.append(block.timestamp)
    elif op == 'NUMBER':
        stk.append(block.number)
    elif op == 'DIFFICULTY':
        stk.append(block.difficulty)
    elif op == 'GASLIMIT':
        stk.append(block.gas_limit)
    elif op == 'POP':
        stk.pop()
    elif op == 'MLOAD':
        s0 = stk.pop()
        if not mem_extend(mem, compustate, op, s0 + 32):
            return OUT_OF_GAS
        data = ''.join(map(chr, mem[s0: s0 + 32]))
        stk.append(util_rlp.big_endian_to_int(data))
    elif op == 'MSTORE':
        s0, s1 = stk.pop(), stk.pop()
        if not mem_extend(mem, compustate, op, s0 + 32):
            return OUT_OF_GAS
        v = s1
        for i in range(31, -1, -1):
            mem[s0 + i] = v % 256
            v /= 256
    elif op == 'MSTORE8':
        s0, s1 = stk.pop(), stk.pop()
        if not mem_extend(mem, compustate, op, s0 + 1):
            return OUT_OF_GAS
        mem[s0] = s1 % 256
    elif op == 'SLOAD':
        stk.append(block.get_storage_data(msg.to, stk.pop()))
    elif op == 'SSTORE':
        # NOTE
        """
        s0, s1 = stk.pop(), stk.pop()
        pre_occupied = GSTORAGE if block.get_storage_data(msg.to, s0) else 0
        post_occupied = GSTORAGE if s1 else 0
        gascost = GSTORAGE + post_occupied - pre_occupied
        if compustate.gas < gascost:
            out_of_gas_exception('sstore trie expansion', gascost, compustate, op)
        compustate.gas -= gascost
        block.set_storage_data(msg.to, s0, s1)
        """
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
        stk.append(bytearray_to_int(dat))
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
            print(' '.join(map(repr, stackargs)))
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
        data = ''.join(map(chr, mem[mstart: mstart + msz]))
        pblogger.log('SUB CONTRACT NEW', sender=msg.to, value=value, data=binascii.hexlify(data))
        create_msg = Message(msg.to, '', value, compustate.gas, data)
        addr, gas, code = create_contract(block, tx, create_msg)
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
        to = encode_int(to)
        to = binascii.hexlify((('\x00' * (32 - len(to))) + to)[12:])
        data = ''.join(map(chr, mem[meminstart: meminstart + meminsz]))
        pblogger.log('SUB CALL NEW', sender=msg.to, to=to, value=value, gas=gas, data=binascii.hexlify(data))
        call_msg = Message(msg.to, to, value, gas, data)
        result, gas, data = apply_msg_send(block, tx, call_msg)
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
        to = encode_int(to)
        to = binascii.hexlify((('\x00' * (32 - len(to))) + to)[12:])
        data = ''.join(map(chr, mem[meminstart: meminstart + meminsz]))
        pblogger.log('POST NEW', sender=msg.to, to=to, value=value, gas=gas, data=binascii.hexlify(data))
        post_msg = Message(msg.to, to, value, gas, data)
        block.postqueue.append(post_msg)
    elif op == 'CALL_STATELESS':
        gas, to, value, meminstart, meminsz, memoutstart, memoutsz = \
            stk.pop(), stk.pop(), stk.pop(), stk.pop(), stk.pop(), stk.pop(), stk.pop()
        new_memsize = max(meminstart + meminsz, memoutstart + memoutsz)
        if not mem_extend(mem, compustate, op, new_memsize):
            return OUT_OF_GAS
        if compustate.gas < gas:
            return out_of_gas_exception('subcall gas', gas, compustate, op)
        compustate.gas -= gas
        to = encode_int(to)
        to = binascii.hexlify((('\x00' * (32 - len(to))) + to)[12:])
        data = ''.join(map(chr, mem[meminstart: meminstart + meminsz]))
        pblogger.log('SUB CALL NEW', sender=msg.to, to=to, value=value, gas=gas, data=binascii.hexlify(data))
        call_msg = Message(msg.to, msg.to, value, gas, data)
        result, gas, data = apply_msg(block, tx, call_msg, block.get_code(to))
        pblogger.log('SUB CALL OUT', result=result, data=data, length=len(data), expected=memoutsz)
        if result == 0:
            stk.append(0)
        else:
            stk.append(1)
            compustate.gas += gas
            for i in range(min(len(data), memoutsz)):
                mem[memoutstart + i] = data[i]
    elif op == 'SUICIDE':
        to = encode_int(stk.pop())
        to = binascii.hexlify((('\x00' * (32 - len(to))) + to)[12:])
        block.transfer_value(msg.to, to, block.get_balance(msg.to))
        block.suicides.append(msg.to)
        return []
    for a in stk:
        assert isinstance(a, int)
