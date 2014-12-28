'''
http://insight.bitpay.com/
'''
import logging
logger = logging.getLogger(__name__)

from lib import config, util

def get_host():
    if config.BLOCKCHAIN_SERVICE_CONNECT:
        return config.BLOCKCHAIN_SERVICE_CONNECT
    else:
        return 'http://localhost:3001' if config.TESTNET else 'http://localhost:3000'

def check():
    result = util.get_url(get_host() + '/api/sync/', abort_on_error=True)
    if not result:
        raise Exception('Insight reports error: %s' % result['error'])
    if result['status'] == 'error':
        raise Exception('Insight reports error: %s' % result['error'])
    if result['status'] == 'syncing':
        logger.warning("Insight is not fully synced to the blockchain: %s%% complete" % result['syncPercentage'])

def searchrawtransactions(proxy, address):
    result = util.get_url(get_host() + '/api/txs/?address=' + address, abort_on_error=False)
    if 'txs' in result:
        return result['txs']
    else:
        return []
