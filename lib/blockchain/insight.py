'''
http://insight.bitpay.com/
'''
import logging

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
        logging.warning("WARNING: Insight is not fully synced to the blockchain: %s%% complete" % result['syncPercentage'])

def getinfo():
    return util.get_url(get_host() + '/api/status?q=getInfo', abort_on_error=True)

def listunspent(address):
    return util.get_url(get_host() + '/api/addr/' + address + '/utxo/', abort_on_error=True)

def getaddressinfo(address):
    return util.get_url(get_host() + '/api/addr/' + address + '/', abort_on_error=True)

def gettransaction(tx_hash):
    return util.get_url(get_host() + '/api/tx/' + tx_hash + '/', abort_on_error=False)