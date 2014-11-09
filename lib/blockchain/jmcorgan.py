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
    return util.rpc('searchrawtransactions', [address, 1, 0, 9999999])
