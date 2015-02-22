import logging
logger = logging.getLogger(__name__)
import sys
import json

from counterpartylib.lib import script
from counterpartylib.lib import config

import requests
import time
import json

from functools import lru_cache

bitcoin_rpc_session = None

class BackendRPCError(Exception):
    pass

def rpc(method, params):
    url = config.BACKEND_URL
    headers = {'content-type': 'application/json'}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }

    global bitcoin_rpc_session
    if not bitcoin_rpc_session:
        bitcoin_rpc_session = requests.Session()
    response = None
    TRIES = 12
    for i in range(TRIES):
        try:
            response = bitcoin_rpc_session.post(url, data=json.dumps(payload), headers=headers, verify=(not config.BACKEND_SSL_NO_VERIFY))
            if i > 0:
                logger.debug('Successfully connected.')
            break
        except requests.exceptions.SSLError as e:
            raise e
        except requests.exceptions.ConnectionError:
            logger.debug('Could not connect to backend at `{}`. (Try {}/{})'.format(url, i+1, TRIES))
            time.sleep(5)

    if response == None:
        if config.TESTNET:
            network = 'testnet'
        else:
            network = 'mainnet'
        raise BackendRPCError('Cannot communicate with backend at `{}`. (server is set to run on {}, is backend?)'.format(url, network))
    elif response.status_code not in (200, 500):
        raise BackendRPCError(str(response.status_code) + ' ' + response.reason)

    # Return result, with error handling.
    response_json = response.json()
    if 'error' not in response_json.keys() or response_json['error'] == None:
        return response_json['result']
    elif response_json['error']['code'] == -5:   # RPC_INVALID_ADDRESS_OR_KEY
        raise BackendRPCError('{} Is `txindex` enabled in {} Core?'.format(response_json['error'], config.BTC_NAME))
    elif response_json['error']['code'] == -28:   # “Verifying blocks...”
        logger.debug('Backend not ready. Sleeping for ten seconds.')
        # If Bitcoin Core takes more than `sys.getrecursionlimit() * 10 = 9970`
        # seconds to start, this’ll hit the maximum recursion depth limit.
        time.sleep(10)
        return rpc(method, params)
    else:
        raise BackendRPCError('{}'.format(response_json['error']))

# TODO: use scriptpubkey_to_address()
@lru_cache(maxsize=4096)
def extract_addresses(tx_hash):
    # TODO: Use `rpc._batch` here.
    tx = getrawtransaction(tx_hash, verbose=True)
    addresses = []

    for vout in tx['vout']:
        if 'addresses' in vout['scriptPubKey']:
            addresses += vout['scriptPubKey']['addresses']

    for vin in tx['vin']:
        vin_tx = getrawtransaction(vin['txid'], verbose=True)
        vout = vin_tx['vout'][vin['vout']]
        if 'addresses' in vout['scriptPubKey']:
            addresses += vout['scriptPubKey']['addresses']

    return addresses, tx

def unconfirmed_transactions(address):
    # NOTE: This operation can be very slow.
    logger.debug('Checking mempool for UTXOs.')

    unconfirmed_tx = []
    mempool = getrawmempool()
    for index, tx_hash in enumerate(mempool):
        logger.debug('Possible mempool UTXO: {} ({}/{})'.format(tx_hash, index, len(mempool)))
        addresses, tx = extract_addresses(tx_hash)
        if address in addresses:
            unconfirmed_tx.append(tx)
    return unconfirmed_tx

def searchrawtransactions(address, unconfirmed=False):

    # Get unconfirmed transactions.
    if unconfirmed:
        logger.debug('Getting unconfirmed transactions.')
        unconfirmed = unconfirmed_transactions(address)
    else:
        unconfirmed = []

    # Get confirmed transactions.
    try:
        logger.debug('Searching raw transactions.')
        rawtransactions = rpc('searchrawtransactions', [address, 1, 0, 9999999])
    except BackendRPCError as e:
        if str(e) == '404 Not Found':
            raise BackendRPCError('Unknown RPC command: `searchrawtransactions`. Please use a version of {} Core which supports an address index.'.format(config.BTC_NAME))
        else:
            raise BackendRPCError(str(e))
    confirmed = [tx for tx in rawtransactions if tx['confirmations'] > 0]

    return unconfirmed + confirmed

def getblockcount():
    return rpc('getblockcount', [])

def getblockhash(blockcount):
    return rpc('getblockhash', [blockcount])

def getblock(block_hash):
    return rpc('getblock', [block_hash, False])

def getrawtransaction(tx_hash, verbose=False):
    return rpc('getrawtransaction', [tx_hash, 1 if verbose else 0])

def getrawmempool():
    return rpc('getrawmempool', [])

def sendrawtransaction(tx_hex):
    return rpc('sendrawtransaction', [tx_hex])

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
