import sys

import binascii
from rlp.utils import decode_hex, encode_hex, ascii_chr, str_to_bytes

from .slogging import get_logger
from counterpartylib.lib.evm import opcodes, ethutils, specials, vm
from counterpartylib.lib.evm.vm import VmExtBase
from counterpartylib.lib.evm.exceptions import *
from counterpartylib.lib.evm.blocks import Log
import logging
logger = logging.getLogger(__name__)

from counterpartylib.lib import util
from counterpartylib.lib import config
from counterpartylib.lib import script
from counterpartylib.lib.evm.address import Address, mk_contract_address


sys.setrecursionlimit(100000)


class Rollback(Exception):
    pass


class PBLogger(object):
    def __init__(self, prefix):
        self.logger = get_logger(prefix)

    def is_active(self, *args):
        return self.logger.is_active(*args)

    def trace(self, *args, **kwargs):
        return self.debug(*args, **kwargs)

    def warn(self, *args, **kwargs):
        return self.debug(*args, type='warn', **kwargs)

    def debug(self, name, type='debug', **kargs):
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
        getattr(self.logger, type)("%s: %s" % (name, msg))

logger = logging.getLogger(__name__)
log_tx = PBLogger('tx')
log_msg = PBLogger('msg')
log_state = PBLogger('msg.state')

TT255 = 2 ** 255
TT256 = 2 ** 256
TT256M1 = 2 ** 256 - 1

OUT_OF_GAS = -1

# contract creating transactions send to an empty address
CREATE_CONTRACT_ADDRESS = b''


def validate_transaction(block, tx):
    def rp(what, actual, target):
        return '%r: %r actual:%r target:%r' % (tx.tx_hash, what, actual, target)

    # (1) The transaction signature is valid;
    if not tx.sender:  # sender is set and validated on Transaction initialization
        raise UnsignedTransaction(tx)

    # (2) the transaction nonce is valid (equivalent to the
    #     sender account's current nonce);
    blocknonce = block.get_nonce(tx.sender)

    if blocknonce != tx.nonce:
        raise InvalidNonce(rp('nonce', tx.nonce, blocknonce))

    # (3) the gas limit is no smaller than the intrinsic gas,
    # g0, used by the transaction;
    if tx.startgas < tx.intrinsic_gas_used:
        raise InsufficientStartGas(rp('startgas', tx.startgas, tx.intrinsic_gas_used))

    # (4) the sender account balance contains at least the
    # cost, v0, required in up-front payment.
    total_cost = tx.value + tx.gasprice * tx.startgas
    if block.get_balance(tx.sender) < total_cost:
        raise InsufficientBalance(rp('balance %s' % tx.sender, block.get_balance(tx.sender), total_cost))

    # check block gas limit
    # @TODO
    # if block.gas_used + tx.startgas > block.gas_limit:
    #     raise BlockGasLimitReached(rp('gaslimit', block.gas_used + tx.startgas, block.gas_limit))

    return True


def apply_transaction(db, block, tx):
    validate_transaction(block, tx)

    # print block.get_nonce(tx.sender), '@@@'

    def rp(what, actual, target):
        return '%r: %r actual:%r target:%r' % (tx, what, actual, target)

    intrinsic_gas = tx.intrinsic_gas_used

    # @TODO
    # assert tx.s * 2 < transactions.secpk1n

    if not tx.to or tx.to == CREATE_CONTRACT_ADDRESS:
        intrinsic_gas += opcodes.CREATE[3]
        if tx.startgas < intrinsic_gas:
            raise InsufficientStartGas(rp('startgas', tx.startgas, intrinsic_gas))

    log_tx.debug('TX NEW', tx_dict=tx.log_dict())
    # start transacting #################
    block.increment_nonce(tx.sender)
                
    # buy startgas
    assert block.get_balance(tx.sender) >= tx.startgas * tx.gasprice
    block.delta_balance(tx.sender, -tx.startgas * tx.gasprice, config.XCP, tx, action='startgas')
    message_gas = tx.startgas - intrinsic_gas
    message_data = vm.CallData([ethutils.safe_ord(x) for x in tx.data], 0, len(tx.data))

    message = vm.Message(Address.normalize(tx.sender), Address.normalize(tx.to),
                         tx.value, message_gas, message_data, code_address=Address.normalize(tx.to))

    # MESSAGE
    ext = VMExt(db, block, tx)
    if tx.to and tx.to != CREATE_CONTRACT_ADDRESS:
        result, gas_remained, data = apply_msg(db, tx, ext, message)
        log_tx.debug('_res_', result=result, gas_remained=gas_remained, data=data)
    else:  # CREATE
        result, gas_remained, data = create_contract(db, tx, ext, message)
        assert ethutils.is_numeric(gas_remained)
        log_tx.debug('_create_', result=result, gas_remained=gas_remained, data=data)

    assert gas_remained >= 0

    log_tx.debug("TX APPLIED", result=result, gas_remained=gas_remained, data=data)

    if not result:  # 0 = OOG failure in both cases
        log_tx.debug('TX FAILED', reason='out of gas',
                     startgas=tx.startgas, gas_remained=gas_remained)
        block.gas_used += tx.startgas
        output = b''
        success = 0
    else:
        log_tx.debug('TX SUCCESS', data=data)
        gas_used = tx.startgas - gas_remained
        block.refunds += len(set(block.suicides)) * opcodes.GSUICIDEREFUND
        if block.refunds > 0:
            log_tx.debug('Refunding', gas_refunded=min(block.refunds, gas_used // 2))
            gas_remained += min(block.refunds, gas_used // 2)
            gas_used -= min(block.refunds, gas_used // 2)
            block.refunds = 0
        # sell remaining gas
        block.delta_balance(tx.sender, tx.gasprice * gas_remained, config.XCP, tx, action='startgas')
        block.gas_used += gas_used
        if tx.to:
            output = b''.join(map(ascii_chr, data))
        else:
            output = data
        success = 1

    suicides = block.suicides
    block.suicides = []
    for s in suicides:
        block.del_account(s)
    block.logs = []
    return success, output, gas_remained


# External calls that can be made from inside the VM. To use the EVM with a
# different blockchain system, database, set parameters for testing, just
# swap out the functions here
class VMExt(VmExtBase):
    def __init__(self, db, block, tx):
        super().__init__()

        self.db = db # debug only

        self._block = block
        self._tx = tx

        def block_hash(x):
            logger.warn('block_hash %s %s %s %s' % (x, x > 0, x > block.number - 256, x <= block.number))
            if x > 0 and x > block.number - 256 and x <= block.number:
                return binascii.unhexlify(block.get_block_hash(x))
            else:
                return b''

        self.block_hash = block_hash

        self.block_prevhash = 0  # @TODO
        self.block_coinbase = 0  # @TODO
        self.block_timestamp = block.timestamp
        self.block_number = block.number
        self.block_difficulty = 0  # @TODO
        self.block_gas_limit = 0  # @TODO

        self.get_code = block.get_code
        self.get_balance = block.get_balance

        def set_balance(address, balance):
            raise NotImplemented
        self.set_balance = set_balance
        self.delta_balance = lambda address, balance, action='delta balance': block.delta_balance(address, balance, tx=tx, action=action)
        self.set_storage_data = block.set_storage_data
        self.get_storage_data = block.get_storage_data
        self.add_suicide = lambda x: block.suicides.append(x)
        self.add_refund = lambda x: setattr(block, 'refunds', block.refunds + x)
        self.tx_origin = tx.sender
        self.tx_gasprice = tx.gasprice
        self.log_storage = lambda address: 0
        self.log = lambda addr, topics, data: block.add_log(Log(addr, topics, data))
        self.create = lambda msg: create_contract(db, tx, self, msg)
        self.msg = lambda msg: _apply_msg(db, tx, self, msg, self.get_code(msg.code_address))
        self.account_exists = block.account_exists
        self.post_homestead_hardfork = lambda: True


def apply_msg(db, tx, ext, msg):
    return _apply_msg(db, tx, ext, msg, ext.get_code(msg.code_address) if msg.code_address is not None else None)


def _apply_msg(db, tx, ext, msg, code):
    trace_msg = log_msg.is_active('trace')
    if trace_msg:
        log_msg.warn("MSG APPLY", sender=msg.sender.base58(), to=msg.to.base58(),
                      gas=msg.gas, value=msg.value,
                      data=encode_hex(msg.data.extract_all()))
        if log_state.is_active('trace'):
            log_state.trace('MSG PRE STATE SENDER', account=msg.sender.base58(),
                            bal=ext.get_balance(msg.sender),
                            state=ext.log_storage(msg.sender))
            log_state.trace('MSG PRE STATE RECIPIENT', account=msg.to.base58(),
                            bal=ext.get_balance(msg.to),
                            state=ext.log_storage(msg.to))
        # log_state.trace('CODE', code=code)

    res = 0
    gas = 0
    dat = []

    # get snapshot, uses SAVEPOINT in sqlite, needs to be reverted or released!
    snapshot = ext._block.snapshot()

    if msg.transfers_value:
        # Transfer value, instaquit if not enough
        log_msg.debug('TRANSFER %s -> %s: %d' % (msg.sender, msg.to, msg.value))
        if not ext._block.transfer_value(msg.sender, msg.to, msg.value, tx=tx, action='transfer value'):
            log_msg.debug('MSG TRANSFER FAILED', have=ext.get_balance(msg.to), want=msg.value)
            return 1, msg.gas, []

    # Main loop
    if msg.code_address and msg.code_address.data in specials.specials:
        res, gas, dat = specials.specials[msg.code_address.data](ext, msg)
    else:
        res, gas, dat = vm.vm_execute(ext, msg, code)
    # gas = int(gas)
    # assert ethutils.is_numeric(gas)
    if trace_msg:
        log_msg.warn('MSG APPLIED', gas_remained=gas,
                      sender=msg.sender, to=msg.to, data=dat, res=res)
        if log_state.is_active('trace'):
            log_state.trace('MSG POST STATE SENDER', account=msg.sender.base58(),
                            bal=ext.get_balance(msg.sender),
                            state=ext.log_storage(msg.sender))
            log_state.trace('MSG POST STATE RECIPIENT', account=msg.to.base58(),
                            bal=ext.get_balance(msg.to),
                            state=ext.log_storage(msg.to))

    if res == 0:
        log_msg.debug('REVERTING')
        ext._block.revert(snapshot)
    else:
        ext._block.release(snapshot)

    return res, gas, dat


def create_contract(db, tx, ext, msg):
    log_msg.debug('CONTRACT CREATION %s' % msg.sender)

    # @TODO: tx_origin?!
    if ext.tx_origin != msg.sender:
        ext._block.increment_nonce(msg.sender)

    nonce = ethutils.encode_int(ext._block.get_nonce(msg.sender) - 1)
    msg.to = mk_contract_address(msg.sender, nonce, version=config.CONTRACT_ADDRESSVERSION)
    b = ext.get_balance(msg.to)

    if b > 0:
        ext.set_balance(msg.to, b)
        ext._block.set_nonce(msg.to, 0)
        ext._block.set_code(tx, msg.to, b'')
        ext._block.reset_storage(msg.to)
    else:
        # need to create `contracts` entry to satisfy FK constraints
        #  for when contract creation sets data
        log_msg.debug('create_contract::init_code %s' % msg.to)
        ext._block.set_code(tx, msg.to, b'')

    msg.is_create = True
    # assert not ext.get_code(msg.to)
    code = msg.data.extract_all()
    msg.data = vm.CallData([], 0, 0)

    try:
        if True: # with db:
            res, gas, dat = _apply_msg(db, tx, ext, msg, code)
            log_msg.debug('create_contract::_apply_msg %s %s %d' % (res, gas, len(dat)))
            assert ethutils.is_numeric(gas)

            if res:
                if not len(dat):
                    return 1, gas, msg.to
                gcost = len(dat) * opcodes.GCONTRACTBYTE

                log_msg.debug('create_contract::gcst %s %s %s' % (gas, gcost, gas >= gcost))
                if gas >= gcost:
                    gas -= gcost
                else:
                    dat = []
                    log_msg.debug('CONTRACT CREATION OOG', have=gas, want=gcost, block_number=ext._block.number)
                    if ext.post_homestead_hardfork():
                        raise Rollback

                log_msg.debug('create_contract::set_code %s' % msg.to)
                ext._block.set_code(tx, msg.to, b''.join(map(ascii_chr, dat)))
                return 1, gas, msg.to
            else:
                return 0, gas, b''
    except Rollback:
        return 0, 0, b''

