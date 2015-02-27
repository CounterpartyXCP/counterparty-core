import getpass
import binascii
import logging
logger = logging.getLogger(__name__)
import sys
import json
import time
import requests

from counterpartylib.lib import config
from counterpartycli import util

def rpc(method, params):
    return util.rpc(config.WALLET_URL, method, params=params, ssl_verify=config.WALLET_SSL_VERIFY)

def get_wallet_addresses():
    addresses = []
    for output in rpc('listunspent', [0, 99999]):
        if output['address'] not in addresses:
            addresses.append(output['address'])
    return addresses

def get_btc_balances():
    addresses = {}
    for output in rpc('listunspent', [0, 99999]):
        if output['address'] not in addresses:
            addresses[output['address']] = 0
        addresses[output['address']] += output['amount']

    for address in addresses:
        yield [address, addresses[address]]

def sign_raw_transaction(tx_hex):
    wallet_unlock()
    return rpc('signrawtransaction', [tx_hex])['hex']

def is_valid(address):
    return rpc('validateaddress', [address])['isvalid']

def is_mine(address):
    return rpc('validateaddress', [address])['ismine']

def get_pubkey(address):
    address_infos = rpc('validateaddress', [address])
    if address_infos['isvalid'] and address_infos['ismine']:
        return address_infos['pubkey']
    return None

def get_btc_balance(address):
    balance = 0
    for output in rpc('listunspent', [0, 99999]):
        if output['address'] == addresses:
            balance += output['amount']
    return balance

def wallet_unlock():
    if not rpc('walletislocked', []):
        return True # Wallet is unlocked for at least the next 60 seconds.
    else:
        passphrase = getpass.getpass('Enter your btcwallet passhrase: ')
        print('Unlocking wallet for 60 (more) seconds.')
        rpc('walletpassphrase', [passphrase, 60])

def send_raw_transaction(tx_hex):
    return rpc('sendrawtransaction', [tx_hex])

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
