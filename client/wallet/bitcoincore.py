import getpass
import binascii
import logging
logger = logging.getLogger(__name__)
import sys
import json
import time
import requests

from client import config
    
bitcoin_rpc_session = None

class BitcoindError(Exception):
    pass
class BitcoindRPCError(BitcoindError):
    pass

def rpc(method, params):
    url = config.WALLET_URL
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
            response = bitcoin_rpc_session.post(url, data=json.dumps(payload), headers=headers, verify=config.WALLET_SSL_VERIFY)
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
        raise BitcoindRPCError('Cannot communicate with Bitcoin Core')
    elif response.status_code not in (200, 500):
        raise BitcoindRPCError(str(response.status_code) + ' ' + response.reason)

    # Return result, with error handling.
    response_json = response.json()
    if 'error' not in response_json.keys() or response_json['error'] == None:
        return response_json['result']
    elif response_json['error']['code'] == -4:   # Unknown private key (locked wallet?)
        raise BitcoindError('Unknown private key. (Locked wallet?)')
    else:
        raise BitcoindError('{}'.format(response_json['error']))

def get_wallet_addresses():
    addresses = []
    for group in rpc('listaddressgroupings', []):
        for bunch in group:
            address, btc_balance = bunch[:2]
            addresses.append(address)
    return addresses

def get_wallet():
    for group in rpc('listaddressgroupings', []):
        for bunch in group:
            yield bunch[:2]

def sign_raw_transaction(tx_hex):
    return rpc('signrawtransaction', [tx_hex])['hex']

def is_valid(address):
    return rpc('validateaddress', [address])['isvalid']

def is_mine(address):
    return rpc('validateaddress', [address])['ismine']

def get_pubkey(address):
    address_infos = rpc('validateaddress', [address])
    if address_infos['isvalid'] and address_infos['ismine']:
        return address_infos['pubkey']
    return None

def get_btc_balance(address):
    for group in rpc('listaddressgroupings', []):
        for bunch in group:
            btc_address, btc_balance = bunch[:2]
            if btc_address == address:
                return btc_balance
    return 0

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4