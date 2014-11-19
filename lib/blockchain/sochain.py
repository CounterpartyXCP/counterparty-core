'''
chain.sp
'''
import logging

from lib import config, util

def get_host():
    if config.BLOCKCHAIN_SERVICE_CONNECT:
        return config.BLOCKCHAIN_SERVICE_CONNECT
    else:
        return 'https://chain.so'

def sochain_network():
	network = config.BTC
	if config.TESTNET:
		network += 'TEST'
	return network

def check():
    pass

def searchrawtransactions(address):
    unconfirmed = util.unconfirmed_transactions(address)

    confirmed = []
    txs = util.get_url(get_host() + '/api/v2/get_tx/{}/{}'.format(sochain_network(), address), abort_on_error=True)
    if 'status' in txs and txs['status'] == 'success':
        for tx in txs['data']['txs']:
            tx = util.rpc('getrawtransaction', [tx['txid'], 1])
            confirmed.append(tx)

    return unconfirmed + confirmed
    