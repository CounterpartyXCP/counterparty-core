'''
Proxy API to make queries to popular blockchains explorer
'''
import sys
import logging

from lib import config
from lib.blockchain import blockr, insight, sochain, jmcorgan

# http://test.insight.is/api/sync
def check():
    logging.info('Status: Connecting to block explorer.')
    return sys.modules['lib.blockchain.{}'.format(config.BLOCKCHAIN_SERVICE_NAME)].check()

def searchrawtransactions(address):
    return sys.modules['lib.blockchain.{}'.format(config.BLOCKCHAIN_SERVICE_NAME)].searchrawtransactions(address)
