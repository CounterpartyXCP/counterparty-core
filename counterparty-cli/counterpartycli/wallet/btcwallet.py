import binascii
import logging
logger = logging.getLogger(__name__)
import sys
import json
import time
import requests

from counterpartylib.lib import config
from counterpartycli.util import wallet_api as rpc

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

def list_unspent():
    return rpc('listunspent', [0, 99999])

def sign_raw_transaction(tx_hex):
    return rpc('signrawtransaction', [tx_hex])['hex']

def is_valid(address):
    address_info = rpc('validateaddress', [address])
    # btcwallet return valid for pubkey
    if address_info['isvalid'] and address_info['address'] == address:
        return True
    return False

def is_mine(address):
    address_info = rpc('validateaddress', [address])
    if 'ismine' not in address_info:
        return False
    return address_info['ismine']

def get_pubkey(address):
    address_infos = rpc('validateaddress', [address])
    if address_infos['isvalid'] and address_infos['ismine']:
        return address_infos['pubkey']
    return None

def get_btc_balance(address):
    balance = 0
    for output in rpc('listunspent', [0, 99999]):
        if output['address'] == address:
            balance += output['amount']
    return balance

def is_locked():
    return rpc('walletislocked', [])

def unlock(passphrase):
    return rpc('walletpassphrase', [passphrase, 60])

def send_raw_transaction(tx_hex):
    return rpc('sendrawtransaction', [tx_hex])

def wallet_last_block():
    getinfo = rpc('getinfo', [])
    return getinfo['blocks']

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
