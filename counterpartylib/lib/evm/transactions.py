# -*- coding: utf8 -*-
import rlp
from rlp.sedes import big_endian_int, binary
from rlp.utils import decode_hex, encode_hex, str_to_bytes, ascii_chr

from .exceptions import InvalidTransaction
from counterpartylib.lib.evm import opcodes
from counterpartylib.lib.evm import ethutils as utils
from counterpartylib.lib.evm.address import Address
from counterpartylib.lib.evm.slogging import get_logger
from counterpartylib.lib.evm.ethutils import TT256
from counterpartylib.lib.evm import exceptions as ethexceptions
from counterpartylib.lib import exceptions

log = get_logger('eth.chain.tx')

# in the yellow paper it is specified that s should be smaller than secpk1n (eq.205)
secpk1n = 115792089237316195423570985008687907852837564279074904382605163141518161494337


class Transaction(object):
    def __init__(self, tx, nonce, to, gasprice, startgas, value, data):
        assert type(data) == bytes
        assert to is None or isinstance(to, Address)
        self.block_index = tx['block_index']
        self.tx_hash = tx['tx_hash']
        self.tx_index = tx['tx_index']
        self.sender = Address.normalize(tx['source'])
        self.data = data
        self.to = to
        self.gasprice = gasprice
        self.startgas = startgas
        self.value = value
        self.nonce = nonce
        self.timestamp = tx['block_time']

        if self.gasprice >= TT256 or self.startgas >= TT256 or self.value >= TT256 or self.nonce >= TT256:
            raise ethexceptions.InvalidTransaction("Values way too high!")
        if self.startgas < self.intrinsic_gas_used:
            raise ethexceptions.InsufficientStartGas("Startgas too low")


    def to_dict(self):
        dict_ = {
                 'sender': self.sender,
                 'data': utils.hexprint(self.data),
                 'to': self.to,
                 'gasprice': self.gasprice,
                 'startgas': self.startgas,
                 'value': self.value,
                 'nonce': self.nonce
                }
        return dict_

    def log_dict(self):
        d = self.to_dict()
        d['sender'] = d['sender'].base58()
        d['to'] = d['to'].base58() if d['to'] else ''
        return d

    @property
    def intrinsic_gas_used(self):
        return Transaction.intrinsic_gas_used_for_data(self.data)

    @classmethod
    def intrinsic_gas_used_for_data(cls, data):
        num_zero_bytes = str_to_bytes(data).count(ascii_chr(0))
        num_non_zero_bytes = len(data) - num_zero_bytes
        return (opcodes.GTXCOST
                + opcodes.GTXDATAZERO * num_zero_bytes
                + opcodes.GTXDATANONZERO * num_non_zero_bytes)


    @property
    def creates(self):
        raise NotImplemented
        "returns the address of a contract created by this tx"
        if self.to in (b'', '\0'*20):
            return mk_contract_address(self.sender, self.nonce)

    def hex_hash(self):
        return '<None>'


def contract(tx, nonce, gasprice, startgas, endowment, code, v=0, r=0, s=0):
    """A contract is a special transaction without the `to` argument."""
    tx = Transaction(tx, nonce, '', gasprice, startgas, endowment, code)
    return tx
