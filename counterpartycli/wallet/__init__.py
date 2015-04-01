import os
import getpass
import binascii
import logging
logger = logging.getLogger(__name__)
import sys
import json
import time
from decimal import Decimal as D

from counterpartycli.wallet import bitcoincore, btcwallet
from counterpartylib.lib import config, util, exceptions, script
from counterpartycli.util import api, value_out

from pycoin.tx import Tx, SIGHASH_ALL
from pycoin.encoding import wif_to_tuple_of_secret_exponent_compressed, public_pair_to_hash160_sec
from pycoin.ecdsa import generator_secp256k1, public_pair_for_secret_exponent

class WalletError(Exception):
    pass

class LockedWalletError(WalletError):
    pass

def WALLET():
    return sys.modules['counterpartycli.wallet.{}'.format(config.WALLET_NAME)] 

def get_wallet_addresses():
    return WALLET().get_wallet_addresses()

def get_btc_balances():
    for address, btc_balance in WALLET().get_btc_balances():
    	yield [address, btc_balance]

def pycoin_sign_raw_transaction(tx_hex, private_key_wif):
    for char in private_key_wif:
        if char not in script.b58_digits:
            raise exceptions.TransactionError('invalid private key')

    if config.TESTNET:
        allowable_wif_prefixes = [config.PRIVATEKEY_VERSION_TESTNET]
    else:
        allowable_wif_prefixes = [config.PRIVATEKEY_VERSION_MAINNET]

    secret_exponent, compressed = wif_to_tuple_of_secret_exponent_compressed(
                    private_key_wif, allowable_wif_prefixes=allowable_wif_prefixes)
    public_pair = public_pair_for_secret_exponent(generator_secp256k1, secret_exponent)
    hash160 = public_pair_to_hash160_sec(public_pair, compressed)
    hash160_lookup = {hash160: (secret_exponent, public_pair, compressed)}

    tx = Tx.tx_from_hex(tx_hex)
    for idx, tx_in in enumerate(tx.txs_in):
        tx.sign_tx_in(hash160_lookup, idx, tx_in.script, hash_type=SIGHASH_ALL)

    return tx.as_hex()

def sign_raw_transaction(tx_hex, private_key_wif=None):
    if private_key_wif is None:
        if WALLET().is_locked():
            raise LockedWalletError('Wallet is locked.')
        return WALLET().sign_raw_transaction(tx_hex)
    else:
        return pycoin_sign_raw_transaction(tx_hex, private_key_wif)

def get_pubkey(address):
    return WALLET().get_pubkey(address)

def is_valid(address):
    return WALLET().is_valid(address)

def is_mine(address):
    return WALLET().is_mine(address)

def get_btc_balance(address):
    return WALLET().get_btc_balance(address)

def list_unspent():
    return WALLET().list_unspent()

def send_raw_transaction(tx_hex):
	return WALLET().send_raw_transaction(tx_hex)

def is_locked():
    return WALLET().is_locked()

def unlock(passphrase):
    return WALLET().unlock(passphrase)

def wallet_last_block():
    return WALLET().wallet_last_block()

def wallet():
    wallet = {
        'addresses': {},
        'assets': {}
    }

    def add_total(address, asset, quantity):
        if quantity:
            if address not in wallet['addresses']:
                wallet['addresses'][address] = {}
            if asset not in wallet['assets']:
                wallet['assets'][asset]  = 0
            if asset not in wallet['addresses'][address]:
                wallet['addresses'][address][asset] = 0
            wallet['addresses'][address][asset] += quantity
            wallet['assets'][asset]  += quantity

    for bunch in get_btc_balances():
        address, btc_balance = bunch
        add_total(address, 'BTC', btc_balance)
        balances = api('get_balances', {'filters': [('address', '==', address),]})
        for balance in balances:
            asset = balance['asset']
            balance = D(value_out(balance['quantity'], asset))
            add_total(address, asset, balance)

    return wallet

def asset(asset_name):
    supply = api('get_supply', {'asset': asset_name})
    asset_id = api('get_assets', {'filters': [('asset_name', '==', asset_name),]})[0]['asset_id']
    asset_info = {
        'asset': asset_name,
        'supply': D(value_out(supply, asset_name)),
        'asset_id': asset_id
    }
    if asset_name in ['XCP', 'BTC']:
        asset_info.update({
            'owner': None,
            'divisible': True,
            'locked': False,
            'description': '',
            'issuer': None
        })
    else:
        issuances = api('get_issuances', {
            'filters': [('asset', '==', asset_name),], 
            'status': 'valid', 
            'order_by': 'tx_index', 
            'order_dir': 'DESC', 
        })
        if not issuances:
            raise WalletError('Asset not found')
        locked = False
        for issuance in issuances:
            if issuance['locked']:
                locked = True
        issuance = issuances[0]
        asset_info.update({
            'owner': issuance['issuer'],
            'divisible': bool(issuance['divisible']),
            'locked': locked,
            'description': issuance['description'],
            'issuer': issuance['issuer']
        })

    asset_info['balance'] = 0
    asset_info['addresses'] = {}

    for bunch in get_btc_balances():
        address, btc_balance = bunch
        if asset_name == 'BTC':
            balance = btc_balance
        else:
            balances = api('get_balances', {'filters': [('address', '==', address), ('asset', '==', asset_name)]})
            if balances:
                balance = balances[0]
                balance = D(value_out(balance['quantity'], asset_name))
            else:
                balance = 0
        if balance:
            asset_info['balance'] += balance
            asset_info['addresses'][address] = balance

    addresses = list(asset_info['addresses'].keys())

    if asset_name != 'BTC':
        all_sends = api('get_sends',  {'filters': [('source', 'IN', addresses), ('destination', 'IN', addresses)], 'filterop': 'OR', 'status': 'valid'})
        sends = []
        for send in all_sends:
            if send['asset'] == asset_name:
                if send['source'] in addresses and send['destination'] in addresses:
                    tx_type = 'in-wallet'
                elif send['source'] in addresses:
                    tx_type = 'send'
                elif send['destination'] in addresses:
                    tx_type = 'receive'
                send['type'] = tx_type
                send['quantity'] = D(value_out(send['quantity'], asset_name))
                sends.append(send)
        asset_info['sends'] = sends

    return asset_info

def balances(address):
    result = {
        'BTC': get_btc_balance(address)
    }
    balances = api('get_balances', {'filters': [('address', '==', address),]})
    for balance in balances:
        asset = balance['asset']
        balance = D(value_out(balance['quantity'], asset))
        result[asset] =  balance
    return result

def pending():
    addresses = []
    for bunch in get_btc_balances():
        addresses.append(bunch[0])
    filters = [
        ('tx0_address', 'IN', addresses),
        ('tx1_address', 'IN', addresses)
    ]
    awaiting_btcs = api('get_order_matches', {'filters': filters, 'filterop': 'OR', 'status': 'pending'})
    return awaiting_btcs

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
