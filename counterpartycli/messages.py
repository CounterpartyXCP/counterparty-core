import logging
from decimal import Decimal as D
import binascii
from math import ceil
import time

from counterpartylib.lib import script, config, blocks, exceptions, api, transaction
from counterpartylib.lib.util import make_id, BET_TYPE_NAME, BET_TYPE_ID, dhash, generate_asset_name
from counterpartylib.lib.kickstart.utils import ib2h
from counterpartycli import util
from counterpartycli import wallet

import bitcoin as bitcoinlib

MESSAGE_PARAMS = {
    'send': ['source', 'destination', 'asset', 'quantity'],
    'order': ['source', 'give_asset', 'give_quantity', 'get_asset', 'get_quantity', 'expiration', 'fee_required', 'fee_provided'],
    'btcpay': ['source', 'order_match_id'],
    'issuance': ['source', 'asset', 'quantity', 'divisible', 'description', 'transfer_destination'],
    'broadcast': ['source', 'fee_fraction', 'text', 'timestamp', 'value'],
    'bet': ['source', 'feed_address', 'bet_type','deadline', 'wager_quantity', 'counterwager_quantity', 'expiration', 'target_value', 'leverage'],
    'dividend': ['source', 'quantity_per_unit', 'asset', 'dividend_asset'],
    'burn': ['source', 'quantity'],
    'cancel': ['source', 'offer_hash'],
    'rps': ['source', 'possible_moves', 'wager', 'move_random_hash', 'expiration'],
    'rpsresolve': ['source', 'random', 'move', 'rps_match_id'],
    'publish': ['source', 'gasprice', 'startgas', 'endowment','code_hex'],
    'execute': ['source', 'contract_id', 'gasprice', 'startgas', 'value', 'payload_hex'],
    'destroy': ['source', 'asset', 'quantity', 'tag']
}

class InputError(Exception):
    pass
class ArgumentError(Exception):
    pass

class MessageArgs:
    def __init__(self, dict_args):
        self.__dict__.update(dict_args)

def input_pubkey(address):
    input_message = 'Public keys (hexadecimal) or Private key (Wallet Import Format) for `{}`: '.format(address)
    return input(input_message)

def get_pubkey_monosig(pubkeyhash, pubkey_resolver=input_pubkey):
    if wallet.is_valid(pubkeyhash):

        # If in wallet, get from wallet.
        logging.debug('Looking for public key for `{}` in wallet.'.format(pubkeyhash))
        if wallet.is_mine(pubkeyhash):
            pubkey = wallet.get_pubkey(pubkeyhash)
            if pubkey:
                return pubkey
        logging.debug('Public key for `{}` not found in wallet.'.format(pubkeyhash))

        # If in blockchain (and not in wallet), get from blockchain.
        logging.debug('Looking for public key for `{}` in blockchain.'.format(pubkeyhash))
        try:
            pubkey = util.api('search_pubkey', {'pubkeyhash': pubkeyhash, 'provided_pubkeys': None})
        except util.RPCError as e:
            pubkey = None
        if pubkey:
            return pubkey
        logging.debug('Public key for `{}` not found in blockchain.'.format(pubkeyhash))

        # If not in wallet and not in blockchain, get from user.
        answer = pubkey_resolver(pubkeyhash)
        if not answer:
            return None

        # Public Key or Private Key?
        is_fully_valid_pubkey = True
        try:
            is_fully_valid_pubkey = script.is_fully_valid(binascii.unhexlify(answer))
        except binascii.Error:
            is_fully_valid_pubkey = False
        if is_fully_valid_pubkey:
            logging.debug('Answer was a fully valid public key.')
            pubkey = answer
        else:
            logging.debug('Answer was not a fully valid public key. Assuming answer was a private key.')
            private_key = answer
            try:
                pubkey = script.private_key_to_public_key(private_key)
            except script.AltcoinSupportError:
                raise InputError('invalid private key')
        if pubkeyhash != script.pubkey_to_pubkeyhash(binascii.unhexlify(bytes(pubkey, 'utf-8'))):
            raise InputError('provided public or private key does not match the source address')

        return pubkey

    return None

def get_pubkeys(address, pubkey_resolver=input_pubkey):
    pubkeys = []
    if script.is_multisig(address):
        _, pubs, _ = script.extract_array(address)
        for pub in pubs:
            pubkey = get_pubkey_monosig(pub, pubkey_resolver=pubkey_resolver)
            if pubkey:
                pubkeys.append(pubkey)
    else:
        pubkey = get_pubkey_monosig(address, pubkey_resolver=pubkey_resolver)
        if pubkey:
            pubkeys.append(pubkey)
    return pubkeys

def common_args(args):
    return {
        'fee': args.fee,
        'allow_unconfirmed_inputs': args.unconfirmed,
        'encoding': args.encoding,
        'fee_per_kb': args.fee_per_kb,
        'regular_dust_size': args.regular_dust_size,
        'multisig_dust_size': args.multisig_dust_size,
        'op_return_value': args.op_return_value
    }

def prepare_args(args, action):
    # Convert.
    args.fee_per_kb = int(args.fee_per_kb * config.UNIT)
    args.regular_dust_size = int(args.regular_dust_size * config.UNIT)
    args.multisig_dust_size = int(args.multisig_dust_size * config.UNIT)
    args.op_return_value = int(args.op_return_value * config.UNIT)
    
    # common
    if args.fee:
        args.fee = util.value_in(args.fee, config.BTC)

    # send
    if action == 'send':
        args.quantity = util.value_in(args.quantity, args.asset)

    # order
    if action == 'order':
        fee_required, fee_fraction_provided = D(args.fee_fraction_required), D(args.fee_fraction_provided)
        give_quantity, get_quantity = D(args.give_quantity), D(args.get_quantity)

        # Fee argument is either fee_required or fee_provided, as necessary.
        if args.give_asset == config.BTC:
            args.fee_required = 0
            fee_fraction_provided = util.value_in(fee_fraction_provided, 'fraction')
            args.fee_provided = round(D(fee_fraction_provided) * D(give_quantity) * D(config.UNIT))
            print('Fee provided: {} {}'.format(util.value_out(args.fee_provided, config.BTC), config.BTC))
        elif args.get_asset == config.BTC:
            args.fee_provided = 0
            fee_fraction_required = util.value_in(args.fee_fraction_required, 'fraction')
            args.fee_required = round(D(fee_fraction_required) * D(get_quantity) * D(config.UNIT))
            print('Fee required: {} {}'.format(util.value_out(args.fee_required, config.BTC), config.BTC))
        else:
            args.fee_required = 0
            args.fee_provided = 0

        args.give_quantity = util.value_in(give_quantity, args.give_asset)
        args.get_quantity = util.value_in(get_quantity, args.get_asset)

    # issuance
    if action == 'issuance':
        args.quantity = util.value_in(args.quantity, None, divisible=args.divisible)

    # broadcast
    if action == 'broadcast':
        args.value = util.value_in(args.value, 'value')
        args.fee_fraction = util.value_in(args.fee_fraction, 'fraction')
        args.timestamp = int(time.time())

    # bet
    if action == 'bet':
        args.deadline = calendar.timegm(dateutil.parser.parse(args.deadline).utctimetuple())
        args.wager = util.value_in(args.wager, config.XCP)
        args.counterwager = util.value_in(args.counterwager, config.XCP)
        args.target_value = util.value_in(args.target_value, 'value')
        args.leverage = util.value_in(args.leverage, 'leverage')
        args.bet_type = BET_TYPE_ID[args.bet_type]

    # dividend
    if action == 'dividend':
        args.quantity_per_unit = util.value_in(args.quantity_per_unit, config.XCP)

    # burn
    if action == 'burn':
        args.quantity = util.value_in(args.quantity, config.BTC)

    # execute
    if action == 'execute':
        args.value = util.value_in(args.value, 'XCP')
        args.startgas = util.value_in(args.startgas, 'XCP')

    # destroy
    if action == 'destroy':
        args.quantity = util.value_in(args.quantity, args.asset, 'input')

    # RPS
    if action == 'rps':
        def generate_move_random_hash(move):
            move = int(move).to_bytes(2, byteorder='big')
            random_bin = os.urandom(16)
            move_random_hash_bin = dhash(random_bin + move)
            return binascii.hexlify(random_bin).decode('utf8'), binascii.hexlify(move_random_hash_bin).decode('utf8')

        args.wager = util.value_in(args.wager, 'XCP')
        random, move_random_hash = generate_move_random_hash(args.move)
        setattr(args, 'move_random_hash', move_random_hash)
        print('random: {}'.format(random))
        print('move_random_hash: {}'.format(move_random_hash))

    return args

def extract_args(args, keys):
    params = {}
    dargs = vars(args)
    for key in keys:
        if key in dargs:
            params[key] = dargs[key]
    return params

def get_input_value(tx_hex):
    unspents = wallet.list_unspent()
    ctx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(tx_hex))
    
    inputs_value = 0
    for vin in ctx.vin:
        vin_tx_hash = ib2h(vin.prevout.hash)
        vout_n = vin.prevout.n
        found = False
        for output in unspents:
            if output['txid'] == vin_tx_hash and output['vout'] == vout_n:
                inputs_value += int(output['amount'] * config.UNIT)
                found = True
        if not found:
            raise exceptions.TransactionError('input not found in wallet list unspents')

    return inputs_value

def check_transaction(method, params, tx_hex):
    tx_info = transaction.check_outputs(method, params, tx_hex)
    input_value = get_input_value(tx_hex)
    fee = input_value - tx_info['total_value']
    fee_per_kb = params['fee_per_kb'] if 'fee_per_kb' in params else config.DEFAULT_FEE_PER_KB

    if 'fee' in params and params['fee']:
        necessary_fee = params['fee']
    else:
        necessary_fee = ceil(((len(tx_hex) / 2) / 1024)) * fee_per_kb # TODO

    if fee > necessary_fee:
        raise exceptions.TransactionError('Incorrect fee ({} > {})'.format(fee, necessary_fee))

def compose_transaction(args, message_name, param_names):
    args = prepare_args(args, message_name)
    common_params = common_args(args)
    params = extract_args(args, param_names)
    params.update(common_params)
    
    # Get provided pubkeys from params.
    pubkeys = []
    for address_name in ['source', 'destination']:
        if address_name in params:
            address = params[address_name]
            if script.is_multisig(address) or address_name != 'destination':    # We don’t need the pubkey for a mono‐sig destination.
                pubkeys += get_pubkeys(address)
    params['pubkey'] = pubkeys

    method = 'create_{}'.format(message_name)
    unsigned_tx_hex = util.api(method, params)
    
    # check_transaction(method, params, unsigned_tx_hex)

    return unsigned_tx_hex

def compose(message, args):
    if message in MESSAGE_PARAMS:
        param_names = MESSAGE_PARAMS[message]
        return compose_transaction(args, message, param_names)
    else:
        raise ArgumentError('Invalid message name')

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
