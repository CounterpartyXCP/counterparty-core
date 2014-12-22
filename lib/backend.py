import getpass
import binascii
import logging
logger = logging.getLogger(__name__)
import sys
import json
from decimal import Decimal as D
from functools import lru_cache

import bitcoin as bitcoinlib
import bitcoin.rpc as bitcoinlib_rpc

from lib import util
from lib import script
from lib import config

def get_proxy():
    if config.TESTNET:
        bitcoinlib.SelectParams('testnet')
    proxy = bitcoinlib_rpc.Proxy(service_url=config.BACKEND_RPC,
                                 timeout=config.BACKEND_HTTP_TIMEOUT)
    return proxy

def get_wallet():
    proxy = get_proxy()
    for group in proxy.listaddressgroupings():
        for bunch in group:
            yield bunch

def dumpprivkey(address):
    return old_rpc('dumpprivkey', [address])

def wallet_unlock():
    proxy = get_proxy()
    getinfo = proxy.getinfo() # TODO: broken with btcd
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

@lru_cache(maxsize=4096)
def get_cached_raw_transaction(tx_hash, verbose=False):
    # NOTE: python-bitcoinlib won’t return JSON.
    if verbose:
        return old_rpc('getrawtransaction', [tx_hash, 1])
    else:
        return old_rpc('getrawtransaction', [tx_hash])

def is_valid(address):
    proxy = get_proxy()
    return proxy.validateaddress(address)['isvalid']
def is_mine(address):
    proxy = get_proxy()
    return proxy.validateaddress(address)['ismine']

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
        vin_tx = get_cached_raw_transaction(vin['txid'], verbose=True)
        vout = vin_tx['vout'][vin['vout']]
        if 'addresses' in vout['scriptPubKey']:
            addresses += vout['scriptPubKey']['addresses']

    return addresses

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, D):
            return format(obj, '.8f')
        # Let the base class default method raise the TypeError
        return json.JSONEncoder.default(self, obj)

def unconfirmed_transactions(address):
    unconfirmed_tx = []

    call_id = 0
    call_list = []
    for tx_hash in old_rpc('getrawmempool', []):
        call_list.append({
            "method": 'getrawtransaction',
            "params": [tx_hash, 1],
            "jsonrpc": "2.0",
            "id": call_id
        })
        call_id += 1

    batch_responses = get_proxy()._batch(call_list)
    for response in batch_responses:
        if 'error' not in response or response['error'] is None:
            if 'result' in response and response['result'] is not None:
                tx = response['result']
                addresses = extract_addresses(json.dumps(tx, cls=DecimalEncoder))
                if address in addresses:
                    unconfirmed_tx.append(tx)

    return unconfirmed_tx


def input_value_weight(amount):
    # Prefer outputs less than dust size, then bigger is better.
    if amount * config.UNIT <= config.DEFAULT_REGULAR_DUST_SIZE:
        return 0
    else:
        return 1 / amount

def sort_unspent_txouts(unspent, allow_unconfirmed_inputs):
    # Get deterministic results (for multiAPIConsensus type requirements), sort by timestamp and vout index.
    # (Oldest to newest so the nodes don’t have to be exactly caught up to each other for consensus to be achieved.)
    # searchrawtransactions doesn’t support unconfirmed transactions
    try:
        unspent = sorted(unspent, key=util.sortkeypicker(['ts', 'vout']))
    except KeyError: # If timestamp isn’t given.
        pass

    # Sort by amount.
    unspent = sorted(unspent, key=lambda x: input_value_weight(x['amount']))

    # Remove unconfirmed txouts, if desired.
    if allow_unconfirmed_inputs:
        # Hackish: Allow only inputs which are either already confirmed or were seen only recently. (Skip outputs from slow‐to‐confirm transanctions.)
        try:
            unspent = [coin for coin in unspent if coin['confirmations'] > 0 or (time.time() - coin['ts']) < 6 * 3600] # Cutoff: six hours
        except (KeyError, TypeError):
            pass
    else:
        unspent = [coin for coin in unspent if coin['confirmations'] > 0]

    return unspent



def get_btc_supply(normalize=False):
    """returns the total supply of {} (based on what Bitcoin Core says the current block height is)""".format(config.BTC)
    proxy = get_proxy()
    block_count = proxy.getblockcount()
    blocks_remaining = block_count
    total_supply = 0
    reward = 50.0
    while blocks_remaining > 0:
        if blocks_remaining >= 210000:
            blocks_remaining -= 210000
            total_supply += 210000 * reward
            reward /= 2
        else:
            total_supply += (blocks_remaining * reward)
            blocks_remaining = 0
    return total_supply if normalize else int(total_supply * config.UNIT)

def get_unspent_txouts(source, return_confirmed=False):
    """returns a list of unspent outputs for a specific address
    @return: A list of dicts, with each entry in the dict having the following keys:
    """
    from lib import blockchain  # TODO
    # Get all coins.
    outputs = {}
    if script.is_multisig(source):
        pubkeyhashes = script.pubkeyhash_array(source)
        raw_transactions = blockchain.searchrawtransactions(pubkeyhashes[1])
    else:
        pubkeyhashes = [source]
        raw_transactions = blockchain.searchrawtransactions(source)

    canonical_source = script.make_canonical(source)

    for tx in raw_transactions:
        for vout in tx['vout']:
            scriptpubkey = vout['scriptPubKey']
            if script.scriptpubkey_to_address(bitcoinlib.core.CScript(bitcoinlib.core.x(scriptpubkey['hex']))) == canonical_source:
                txid = tx['txid']
                confirmations = tx['confirmations'] if 'confirmations' in tx else 0
                outkey = '{}{}'.format(txid, vout['n'])
                if outkey not in outputs or outputs[outkey]['confirmations'] < confirmations:
                    coin = {'amount': float(vout['value']),
                            'confirmations': confirmations,
                            'scriptPubKey': scriptpubkey['hex'],
                            'txid': txid,
                            'vout': vout['n']
                           }
                    outputs[outkey] = coin
    outputs = outputs.values()

    # Prune away spent coins.
    unspent = []
    confirmed_unspent = []
    for output in outputs:
        spent = False
        confirmed_spent = False
        for tx in raw_transactions:
            for vin in tx['vin']:
                if 'coinbase' in vin:
                    continue
                if (vin['txid'], vin['vout']) == (output['txid'], output['vout']):
                    spent = True
                    if 'confirmations' in tx and tx['confirmations'] > 0:
                        confirmed_spent = True
        if not spent:
            unspent.append(output)
        if not confirmed_spent and output['confirmations'] > 0:
            confirmed_unspent.append(output)

    unspent = sorted(unspent, key=lambda x: x['txid'])
    confirmed_unspent = sorted(confirmed_unspent, key=lambda x: x['txid'])

    if return_confirmed:
        return unspent, confirmed_unspent
    else:
        return unspent

def get_btc_balance(address, confirmed=True):
    all_unspent, confirmed_unspent = get_unspent_txouts(address, return_confirmed=True)
    unspent = confirmed_unspent if confirmed else all_unspent
    return sum(out['amount'] for out in unspent)





import requests
import time
import json

from lib import config

bitcoin_rpc_session = None

class BitcoindError(Exception):
    pass
class BitcoindRPCError(BitcoindError):
    pass

def old_rpc(method, params):
    """
    Used only for `getrawtransaction`, `searchrawtransaction`, `dumpprivkey` and
    `walletpassphrase` methods (unsupported by python-bitcoinlib).
    """

    url = config.BACKEND_RPC
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
            response = bitcoin_rpc_session.post(url, data=json.dumps(payload), headers=headers, verify=config.BACKEND_RPC_SSL_VERIFY)
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
        # If address in wallet, attempt to unlock.
        address = params[0]
        if is_valid(address):
            if is_mine(address):
                raise BitcoindError('Wallet is locked.')
            else:   # When will this happen?
                raise BitcoindError('Source address not in wallet.')
        else:
            raise script.AddressError('Invalid address. (Multi‐signature?)')
    # elif response_json['error']['code'] == -1 and response_json['error']['message'] == 'Block number out of range.':
    #     time.sleep(10)
    #     return bitcoinlib.core.b2lx(proxy.getblockhash(block_index))
    else:
        raise BitcoindError('{}'.format(response_json['error']))

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
