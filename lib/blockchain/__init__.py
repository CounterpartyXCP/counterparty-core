'''
Proxy API to make queries to popular blockchains explorer
'''
import sys
import logging
logger = logging.getLogger(__name__)

from lib import config
from lib.blockchain import insight, jmcorgan, sochain, blockr

# http://test.insight.is/api/sync
def check():
    logger.info('Connecting to block explorer.')
    return sys.modules['lib.blockchain.{}'.format(config.BLOCKCHAIN_SERVICE_NAME)].check()

def searchrawtransactions(proxy, address):
    return sys.modules['lib.blockchain.{}'.format(config.BLOCKCHAIN_SERVICE_NAME)].searchrawtransactions(proxy, address)
