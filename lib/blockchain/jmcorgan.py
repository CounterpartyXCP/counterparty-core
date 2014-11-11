'''
http://insight.bitpay.com/
'''
import logging
import requests
import time

from lib import config, exceptions, util

bitcoin_rpc_session = None

def check():
    return True

def searchrawtransactions(address):
    unconfirmed = search_mempool_transactions(address)
    confirmed = util.rpc('searchrawtransactions', [address, 1, 0, 9999999])
    return unconfirmed + confirmed

def extract_addresses(tx):
    addresses = []

    for vout in tx['vout']:
        if 'addresses' in vout['scriptPubKey']:
            addresses += vout['scriptPubKey']['addresses']

    for vin in tx['vin']:
        vin_tx = util.rpc('getrawtransaction', [vin['txid'], 1])
        vout = vin_tx['vout'][vin['vout']]
        if 'addresses' in vout['scriptPubKey']:
            addresses += vout['scriptPubKey']['addresses']

    return addresses

def search_mempool_transactions(address):
    transactions = []

    for tx_hash in util.rpc('getrawmempool', []):
        tx = util.rpc('getrawtransaction', [tx_hash, 1])
        if address in extract_addresses(tx):
            transactions.append(tx)

    return transactions
