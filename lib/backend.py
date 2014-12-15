import getpass
import binascii
from functools import lru_cache

import bitcoin as bitcoinlib

def dumpprivkey(address):
   return old_rpc('dumpprivkey', [address])

def wallet_unlock ():
    getinfo = rpc.getinfo() # TODO: broken with btcd
    if 'unlocked_until' in getinfo:
        if getinfo['unlocked_until'] >= 60:
            return True # Wallet is unlocked for at least the next 60 seconds.
        else:
            passphrase = getpass.getpass('Enter your Bitcoind[‐Qt] wallet passhrase: ')
            print('Unlocking wallet for 60 (more) seconds.')
            old_rpc('walletpassphrase', [passphrase, 60])
    else:
        return True    # Wallet is unencrypted.

def deserialize(tx_hex):
    return bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(tx_hex))
def serialize(ctx):
    return bitcoinlib.core.CTransaction.serialize(ctx)

def get_prevhash(c_hash):
    c_block = rpc.getblock(c_hash)
    return bitcoinlib.core.b2lx(c_block.hashPrevBlock)

@lru_cache(maxsize=4096)
def get_cached_raw_transaction (tx_hash, verbose=False):
    # NOTE: python-bitcoinlib won’t return JSON.
    if verbose:
        return old_rpc('getrawtransaction', [tx_hash, 1])
    else:
        return old_rpc('getrawtransaction', [tx_hash])

def is_valid (address):
    return rpc.validateaddress(address)['isvalid']
def is_mine (address):
    return rpc.validateaddress(address)['ismine']

def get_txhash_list(block):
    return [bitcoinlib.core.b2lx(ctx.GetHash()) for ctx in block.vtx]

# TODO: use scriptpubkey_to_address()
@lru_cache(maxsize=4096)
def extract_addresses(tx):
    tx = json.loads(tx) # for lru_cache
    addresses = []

    for vout in tx['vout']:
        if 'addresses' in vout['scriptPubKey']:
            addresses += vout['scriptPubKey']['addresses']

    for vin in tx['vin']:
        vin_tx = backend.get_cached_raw_transaction(vin['txid'], verbose=True)
        vout = vin_tx['vout'][vin['vout']]
        if 'addresses' in vout['scriptPubKey']:
            addresses += vout['scriptPubKey']['addresses']

    return addresses

def unconfirmed_transactions(address):
    unconfirmed_tx = []
    for tx_hash in bitcoin.get_mempool():
        tx = get_cached_raw_transaction(tx_hash)
        addresses = extract_addresses(json.dumps(tx))
        if address in addresses:
             unconfirmed_tx.append(tx)
    return unconfirmed_tx


import requests
import time
import json

from lib import config

bitcoin_rpc_session = None
class BitcoindError (Exception): pass
class BitcoindRPCError (BitcoindError): pass
def old_rpc (method, params):
    """
    Used only for `getrawtransaction`, `searchrawtransaction`, `dumpprivkey` and
    `walletpassphrase` methods (unsupported by python-bitcoinlib).
    """

    starttime = time.time()
    url = config.BACKEND_RPC
    headers = {'content-type': 'application/json'}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }

    global bitcoin_rpc_session
    if not bitcoin_rpc_session: bitcoin_rpc_session = requests.Session()
    response = None
    TRIES = 12
    for i in range(TRIES):
        try:
            response = bitcoin_rpc_session.post(url, data=json.dumps(payload), headers=headers, verify=config.BACKEND_RPC_SSL_VERIFY)
            if i > 0: logging.debug('Status: Successfully connected.', file=sys.stderr)
            break
        except requests.exceptions.SSLError as e:
            raise e
        except requests.exceptions.ConnectionError:
            logging.debug('Could not connect to Bitcoind. (Try {}/{})'.format(i+1, TRIES))
            time.sleep(5)

    if response == None:
        if config.TESTNET: network = 'testnet'
        else: network = 'mainnet'
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
        # If address in wallet, attempt to unlock.
        address = params[0]
        if is_valid(address):
            if is_mine(address):
                raise BitcoindError('Wallet is locked.')
            else:   # When will this happen?
                raise BitcoindError('Source address not in wallet.')
        else:
            raise exceptions.AddressError('Invalid address. (Multi‐signature?)')
    elif response_json['error']['code'] == -1 and response_json['error']['message'] == 'Block number out of range.':
        time.sleep(10)
        return bitcoinlib.core.b2lx(rpc.getblockhash(block_index))
    else:
        raise BitcoindError('{}'.format(response_json['error']))

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
