import logging
logger = logging.getLogger(__name__)
import sys
import json

from counterparty.lib import script
from counterparty.lib import config

import requests
import time
import json

from functools import lru_cache

bitcoin_rpc_session = None

class BitcoindError(Exception):
    pass
class BitcoindRPCError(BitcoindError):
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
            response = bitcoin_rpc_session.post(url, data=json.dumps(payload), headers=headers, verify=config.BACKEND_SSL_VERIFY)
            if i > 0:
                logger.debug('Successfully connected.', file=sys.stderr)
            break
        except requests.exceptions.SSLError as e:
            raise e
        except requests.exceptions.ConnectionError:
            logger.debug('Could not connect to Bitcoind. (Try {}/{})'.format(i+1, TRIES))
            time.sleep(5)

    if response == None:
        if config.TESTNET:
            network = 'testnet'
        else:
            network = 'mainnet'
        raise BitcoindRPCError('Cannot communicate with {} Core. ({} is set to run on {}, is {} Core?)'.format(config.BTC_NAME, config.XCP_CLIENT, network, config.BTC_NAME))
    elif response.status_code not in (200, 500):
        raise BitcoindRPCError(str(response.status_code) + ' ' + response.reason)

    # Return result, with error handling.
    response_json = response.json()
    if 'error' not in response_json.keys() or response_json['error'] == None:
        return response_json['result']
    elif response_json['error']['code'] == -5:   # RPC_INVALID_ADDRESS_OR_KEY
        raise BitcoindError('{} Is txindex enabled in {} Core?'.format(response_json['error'], config.BTC_NAME))
    elif response_json['error']['code'] == -4:   # Unknown private key (locked wallet?)
        raise BitcoindError('Unknown private key. (Locked wallet?)')
    else:
        raise BitcoindError('{}'.format(response_json['error']))

def check():
    return True

# TODO: use scriptpubkey_to_address()
@lru_cache(maxsize=4096)
def extract_addresses(tx_hash):
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
    unconfirmed_tx = []

    for tx_hash in getrawmempool():
        addresses, tx = extract_addresses(tx_hash)
        if address in addresses:
            unconfirmed_tx.append(tx)

    return unconfirmed_tx

def searchrawtransactions(address):
    unconfirmed = unconfirmed_transactions(address)
    try:
        rawtransactions = rpc('searchrawtransactions', [address, 1, 0, 9999999])
    except backend.BitcoindRPCError as e:
        if str(e) == '404 Not Found':
            raise BitcoindRPCError('Unknown RPC command: `searchrawtransactions`. Either, switch to jmcorgan (recommended), use Insight, or use sochain or blockr.')
        else:
            raise BitcoindRPCError(str(e))
    confirmed = [tx for tx in rawtransactions if tx['confirmations'] > 0]
    return unconfirmed + confirmed

def getblockcount():
    return rpc('getblockcount', [])

def getblockhash(blockcount):
    return rpc('getblockhash', [blockcount])

@lru_cache(maxsize=4096)
def getblock(block_hash):
    return rpc('getblock', [block_hash, False])

@lru_cache(maxsize=4096)
def getrawtransaction(tx_hash, verbose=False):
    return rpc('getrawtransaction', [tx_hash, 1 if verbose else 0])

def getrawmempool():
    return rpc('getrawmempool', [])

def sendrawtransaction(tx_hex):
    return rpc('sendrawtransaction', [tx_hex])



# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
