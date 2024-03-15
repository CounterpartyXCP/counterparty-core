import binascii
import logging
import sys
import time
from decimal import Decimal as D

import bitcoin as bitcoinlib
import bitcoin.rpc as bitcoinlib_rpc
from bitcoin.core import CBlock

from counterpartylib.lib import util
from counterpartylib.lib import script
from counterpartylib.lib import config
from counterpartylib.lib import exceptions
from counterpartylib.lib import prefetcher
from counterpartylib.lib import ledger

from counterpartylib.lib.backend import addrindexrs

logger = logging.getLogger(config.LOGGER_NAME)

MEMPOOL_CACHE_INITIALIZED = False
INITIALIZED = False

PRETX_CACHE = {}

def sortkeypicker(keynames):
    """http://stackoverflow.com/a/1143719"""
    negate = set()
    for i, k in enumerate(keynames):
        if k[:1] == '-':
            keynames[i] = k[1:]
            negate.add(k[1:])
    def getit(adict):
        composite = [adict[k] for k in keynames]
        for i, (k, v) in enumerate(zip(keynames, composite)):
            if k in negate:
                composite[i] = -v
        return composite
    return getit

def backend():
    mdl = sys.modules[f'counterpartylib.lib.backend.{config.BACKEND_NAME}']
    global INITIALIZED
    if not INITIALIZED:
        mdl.init()
        INITIALIZED = True
    return mdl

def stop():
    backend().stop()

def getblockcount():
    return backend().getblockcount()

def getblockhash(blockcount):
    return backend().getblockhash(blockcount)

def getblock(block_hash):
    block_hex = backend().getblock(block_hash)
    return CBlock.deserialize(util.unhexlify(block_hex))

def cache_pretx(txid, rawtx):
    PRETX_CACHE[binascii.hexlify(txid).decode('utf8')] = binascii.hexlify(rawtx).decode('utf8')

def clear_pretx(txid):
    del PRETX_CACHE[binascii.hexlify(txid).decode('utf8')]

def getrawtransaction(tx_hash, verbose=False, skip_missing=False, block_index=None):
    if block_index and block_index in prefetcher.BLOCKCHAIN_CACHE:
        return prefetcher.BLOCKCHAIN_CACHE[block_index]['raw_transactions'][tx_hash]

    if tx_hash in PRETX_CACHE:
        return PRETX_CACHE[tx_hash]

    # There's a separate LRU cache on the backend here, fwiw.
    return backend().getrawtransaction(tx_hash, verbose=verbose, skip_missing=skip_missing)

def getrawtransaction_batch(txhash_list, verbose=False, skip_missing=False):
    return backend().getrawtransaction_batch(txhash_list, verbose=verbose, skip_missing=skip_missing)

def sendrawtransaction(tx_hex):
    return backend().sendrawtransaction(tx_hex)

def getrawmempool():
    return backend().getrawmempool()

def getindexblocksbehind():
    return backend().getindexblocksbehind()

def extract_addresses(txhash_list):
    return backend().extract_addresses(txhash_list)

def ensure_script_pub_key_for_inputs(coins):
    txhash_set = set()
    for coin in coins:
        if 'scriptPubKey' not in coin:
            txhash_set.add(coin['txid'])

    if len(txhash_set) > 0:
        txs = backend().getrawtransaction_batch(list(txhash_set), verbose=True, skip_missing=False)
        for coin in coins:
            if 'scriptPubKey' not in coin:
                # get the scriptPubKey
                txid = coin['txid']
                for vout in txs[txid]['vout']:
                    if vout['n'] == coin['vout']:
                        coin['scriptPubKey'] = vout['scriptPubKey']['hex']

    return coins


def fee_per_kb(conf_target, mode, nblocks=None):
    """
    :param conf_target:
    :param mode:
    :return: fee_per_kb in satoshis, or None when unable to determine
    """

    return backend().fee_per_kb(conf_target, mode, nblocks=nblocks)


def deserialize(tx_hex):
    return bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(tx_hex))

def serialize(ctx):
    return bitcoinlib.core.CTransaction.serialize(ctx)

def is_valid(address):
    try:
        script.validate(address)
        return True
    except script.AddressError:
        return False

def get_txhash_list(block):
    return [bitcoinlib.core.b2lx(ctx.GetHash()) for ctx in block.vtx]

def get_tx_list(block, block_index=None):
    raw_transactions = {}
    tx_hash_list = []

    for ctx in block.vtx:
        if ledger.enabled('correct_segwit_txids', block_index=block_index):
            hsh = ctx.GetTxid()
        else:
            hsh = ctx.GetHash()
        tx_hash = bitcoinlib.core.b2lx(hsh)
        raw = ctx.serialize()

        tx_hash_list.append(tx_hash)
        raw_transactions[tx_hash] = bitcoinlib.core.b2x(raw)

    return (tx_hash_list, raw_transactions)

def sort_unspent_txouts(unspent, unconfirmed=False, dust_size=config.DEFAULT_REGULAR_DUST_SIZE):
    # Filter out all dust amounts to avoid bloating the resultant transaction
    unspent = list(filter(lambda x: x['value'] > dust_size, unspent))
    # Sort by amount, using the largest UTXOs available
    if config.REGTEST:
        # REGTEST has a lot of coinbase inputs that can't be spent due to maturity
        # this doesn't usually happens on mainnet or testnet because most fednodes aren't mining
        unspent = sorted(unspent, key=lambda x: (x['confirmations'], x['value']), reverse=True)
    else:
        unspent = sorted(unspent, key=lambda x: x['value'], reverse=True)

    return unspent

def get_btc_supply(normalize=False):
    f"""returns the total supply of {config.BTC} (based on what Bitcoin Core says the current block height is)"""
    block_count = getblockcount()
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

class MempoolError(Exception):
    pass

def get_unspent_txouts(source, unconfirmed=False, unspent_tx_hash=None):
    """returns a list of unspent outputs for a specific address
    @return: A list of dicts, with each entry in the dict having the following keys:
    """

    unspent = backend().get_unspent_txouts(source)

    # filter by unspent_tx_hash
    if unspent_tx_hash is not None:
        unspent = list(filter(lambda x: x['txId'] == unspent_tx_hash, unspent))

    # filter unconfirmed
    if not unconfirmed:
        unspent = [utxo for utxo in unspent if utxo['confirmations'] > 0]

    # format
    for utxo in unspent:
        utxo['amount'] = float(utxo['value'] / config.UNIT)
        utxo['txid'] = utxo['txId']
        del utxo['txId']
        # do not add scriptPubKey

    return unspent

def search_raw_transactions(address, unconfirmed=True, only_tx_hashes=False):
    return backend().search_raw_transactions(address, unconfirmed, only_tx_hashes)

def get_oldest_tx(address, block_index=None):
    return backend().get_oldest_tx(address, block_index=block_index)

class UnknownPubKeyError(Exception):
    pass

def pubkeyhash_to_pubkey(pubkeyhash, provided_pubkeys=None):
    # Search provided pubkeys.
    if provided_pubkeys:
        if type(provided_pubkeys) != list:
            provided_pubkeys = [provided_pubkeys]
        for pubkey in provided_pubkeys:
            if pubkeyhash == script.pubkey_to_pubkeyhash(util.unhexlify(pubkey)):
                return pubkey
            elif pubkeyhash == script.pubkey_to_p2whash(util.unhexlify(pubkey)):
                return pubkey

    # Search blockchain.
    raw_transactions = search_raw_transactions(pubkeyhash, unconfirmed=True)
    for tx_id in raw_transactions:
        tx = raw_transactions[tx_id]
        for vin in tx['vin']:
            if 'txinwitness' in vin:
                if len(vin['txinwitness']) >= 2:
                    # catch unhexlify errs for when txinwitness[1] isn't a witness program (eg; for P2W)
                    try:
                        pubkey = vin['txinwitness'][1]
                        if pubkeyhash == script.pubkey_to_p2whash(util.unhexlify(pubkey)):
                            return pubkey
                    except binascii.Error:
                        pass
            elif 'coinbase' not in vin:
                scriptsig = vin['scriptSig']
                asm = scriptsig['asm'].split(' ')
                if len(asm) >= 2:
                    # catch unhexlify errs for when asm[1] isn't a pubkey (eg; for P2SH)
                    try:
                        pubkey = asm[1]
                        if pubkeyhash == script.pubkey_to_pubkeyhash(util.unhexlify(pubkey)):
                            return pubkey
                    except binascii.Error:
                        pass

    raise UnknownPubKeyError('Public key was neither provided nor published in blockchain.')


def multisig_pubkeyhashes_to_pubkeys(address, provided_pubkeys=None):
    signatures_required, pubkeyhashes, signatures_possible = script.extract_array(address)
    pubkeys = [pubkeyhash_to_pubkey(pubkeyhash, provided_pubkeys) for pubkeyhash in pubkeyhashes]
    return script.construct_array(signatures_required, pubkeys, signatures_possible)


def init_mempool_cache():
    """prime the mempool cache, so that functioning is faster...
    """
    global MEMPOOL_CACHE_INITIALIZED
    logger.debug('Initializing mempool cache...')
    start = time.time()

    mempool_txhash_list = getrawmempool()

    #with this function, don't try to load in more than BACKEND_RAW_TRANSACTIONS_CACHE_SIZE entries
    num_tx = min(len(mempool_txhash_list), config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE)
    mempool_tx = backend().getrawtransaction_batch(mempool_txhash_list[:num_tx], skip_missing=True, verbose=True)

    vin_txhash_list = []
    max_remaining_num_tx = config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE - num_tx
    if max_remaining_num_tx:
        for txid in mempool_tx:
            tx = mempool_tx[txid]
            if not(tx is None):
                vin_txhash_list += [vin['txid'] for vin in tx['vin']]
        backend().getrawtransaction_batch(vin_txhash_list[:max_remaining_num_tx], skip_missing=True, verbose=True)

    MEMPOOL_CACHE_INITIALIZED = True
    logger.info(f'Mempool cache initialized: {time.time() - start:.2f}s for {num_tx + min(max_remaining_num_tx, len(vin_txhash_list)):,} transactions')


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
