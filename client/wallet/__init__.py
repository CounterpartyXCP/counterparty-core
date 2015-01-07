import getpass
import binascii
import logging
logger = logging.getLogger(__name__)
import sys
import json
import time

from client.wallet import bitcoincore
from client import config

def WALLET():
    return sys.modules['client.wallet.{}'.format(config.WALLET_NAME)] 

def get_wallet_addresses():
    return WALLET().get_wallet_addresses()

def get_wallet():
    for address, btc_balance in WALLET().get_wallet():
    	yield [address, btc_balance]

def sign_raw_transaction(tx_hex):
    return WALLET().sign_raw_transaction(tx_hex)

def get_pubkey(address):
    return WALLET().get_pubkey(address)

def is_valid(address):
    return WALLET().is_valid(address)

def is_mine(address):
    return WALLET().is_mine(address)

def get_btc_balance(address):
    return WALLET().get_btc_balance(address)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4