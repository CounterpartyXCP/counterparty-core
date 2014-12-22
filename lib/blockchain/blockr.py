'''
blockr.io
'''
import logging
logger = logging.getLogger(__name__)

from lib import config, util, backend

def get_host():
    if config.BLOCKCHAIN_SERVICE_CONNECT:
        return config.BLOCKCHAIN_SERVICE_CONNECT
    else:
        return 'http://tbtc.blockr.io' if config.TESTNET else 'http://btc.blockr.io'

def check():
    pass

def searchrawtransactions(address):
    unconfirmed = backend.unconfirmed_transactions(address)

    confirmed = []
    txs = util.get_url(get_host() + '/api/v1/address/txs/{}'.format(address), abort_on_error=True)
    if 'status' in txs and txs['status'] == 'success':
        for tx in txs['data']['txs']:
            tx = backend.old_rpc('getrawtransaction', [tx['tx'], 1])
            confirmed.append(tx)

    return unconfirmed + confirmed
