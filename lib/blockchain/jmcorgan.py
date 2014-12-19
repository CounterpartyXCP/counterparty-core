'''
http://insight.bitpay.com/
'''
import logging
import requests
import time

from lib import config, exceptions, util, backend

bitcoin_rpc_session = None

def check():
    return True

def searchrawtransactions(address):
    unconfirmed = util.unconfirmed_transactions(address)
    try:
        rawtransactions = backend.old_rpc('searchrawtransactions', [address, 1, 0, 9999999])
    except backend.BitcoindRPCError as e:
        if str(e) == '404 Not Found':
            raise backend.BitcoindRPCError('Unknown RPC command: `searchrawtransactions`. Either, switch to jmcorgan (recommended), use Insight, or use sochain or blockr.')
        else:
            raise backend.BitcoindRPCError(str(e))
    confirmed = [tx for tx in rawtransactions if tx['confirmations'] > 0]
    return unconfirmed + confirmed
