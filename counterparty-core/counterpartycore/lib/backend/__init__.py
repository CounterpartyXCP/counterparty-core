import binascii
import logging

from counterpartycore.lib import config, script, util
from counterpartycore.lib.backend import addrindexrs  # noqa: F401

logger = logging.getLogger(config.LOGGER_NAME)

MEMPOOL_CACHE_INITIALIZED = False
INITIALIZED = False

BLOCKCHAIN_CACHE = {}
PRETX_CACHE = {}


def backend(initialize=True):
    global INITIALIZED  # noqa: PLW0603
    if not INITIALIZED and initialize:
        addrindexrs.init()
        INITIALIZED = True
    return addrindexrs


def stop():
    logger.info("Stopping backend...")
    backend(initialize=False).stop()


def getrawtransaction_batch(txhash_list, verbose=False, skip_missing=False):
    return backend().getrawtransaction_batch(
        txhash_list, verbose=verbose, skip_missing=skip_missing
    )


def extract_addresses(txhash_list):
    return backend().extract_addresses(txhash_list)


def ensure_script_pub_key_for_inputs(coins):
    txhash_set = set()
    for coin in coins:
        if "scriptPubKey" not in coin:
            txhash_set.add(coin["txid"])

    if len(txhash_set) > 0:
        txs = backend().getrawtransaction_batch(list(txhash_set), verbose=True, skip_missing=False)
        for coin in coins:
            if "scriptPubKey" not in coin:
                # get the scriptPubKey
                txid = coin["txid"]
                for vout in txs[txid]["vout"]:
                    if vout["n"] == coin["vout"]:
                        coin["scriptPubKey"] = vout["scriptPubKey"]["hex"]

    return coins


def sort_unspent_txouts(unspent, unconfirmed=False, dust_size=config.DEFAULT_REGULAR_DUST_SIZE):
    # Filter out all dust amounts to avoid bloating the resultant transaction
    unspent = list(filter(lambda x: x["value"] > dust_size, unspent))
    # Sort by amount, using the largest UTXOs available
    if config.REGTEST:
        # REGTEST has a lot of coinbase inputs that can't be spent due to maturity
        # this doesn't usually happens on mainnet or testnet because most fednodes aren't mining
        unspent = sorted(unspent, key=lambda x: (x["confirmations"], x["value"]), reverse=True)
    else:
        unspent = sorted(unspent, key=lambda x: x["value"], reverse=True)

    return unspent


def get_unspent_txouts(address: str, unconfirmed: bool = False, unspent_tx_hash: str = None):
    """
    Returns a list of unspent outputs for a specific address
    :param address: The address to search for (e.g. 14TjwxgnuqgB4HcDcSZk2m7WKwcGVYxRjS)
    :param unconfirmed: Include unconfirmed transactions
    :param unspent_tx_hash: Filter by unspent_tx_hash
    """

    unspent = backend().get_unspent_txouts(address)

    # filter by unspent_tx_hash
    if unspent_tx_hash is not None:
        unspent = list(filter(lambda x: x["txId"] == unspent_tx_hash, unspent))

    # filter unconfirmed
    if not unconfirmed:
        unspent = [utxo for utxo in unspent if utxo["confirmations"] > 0]

    # format
    for utxo in unspent:
        utxo["amount"] = float(utxo["value"] / config.UNIT)
        utxo["txid"] = utxo["txId"]
        del utxo["txId"]
        # do not add scriptPubKey

    return unspent


def search_raw_transactions(address: str, unconfirmed: bool = True, only_tx_hashes: bool = False):
    return backend().search_raw_transactions(address, unconfirmed, only_tx_hashes)


def get_transactions_by_address(
    address: str, unconfirmed: bool = True, only_tx_hashes: bool = False
):
    """
    Returns all transactions involving a given address
    :param address: The address to search for (e.g. 14TjwxgnuqgB4HcDcSZk2m7WKwcGVYxRjS)
    :param unconfirmed: Include unconfirmed transactions (e.g. True)
    :param only_tx_hashes: Return only the tx hashes (e.g. True)
    """
    return search_raw_transactions(address, unconfirmed, only_tx_hashes)


def get_oldest_tx(address: str, block_index: int):
    return backend().get_oldest_tx(address, block_index=block_index)


class UnknownPubKeyError(Exception):
    pass


def pubkeyhash_to_pubkey(pubkeyhash, provided_pubkeys=None):
    # Search provided pubkeys.
    if provided_pubkeys:
        if type(provided_pubkeys) != list:  # noqa: E721
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
        for vin in tx["vin"]:
            if "txinwitness" in vin:
                if len(vin["txinwitness"]) >= 2:
                    # catch unhexlify errs for when txinwitness[1] isn't a witness program (eg; for P2W)
                    try:
                        pubkey = vin["txinwitness"][1]
                        if pubkeyhash == script.pubkey_to_p2whash(util.unhexlify(pubkey)):
                            return pubkey
                    except binascii.Error:
                        pass
            elif "coinbase" not in vin:
                scriptsig = vin["scriptSig"]
                asm = scriptsig["asm"].split(" ")
                if len(asm) >= 2:
                    # catch unhexlify errs for when asm[1] isn't a pubkey (eg; for P2SH)
                    try:
                        pubkey = asm[1]
                        if pubkeyhash == script.pubkey_to_pubkeyhash(util.unhexlify(pubkey)):
                            return pubkey
                    except binascii.Error:
                        pass

    raise UnknownPubKeyError("Public key was neither provided nor published in blockchain.")


def multisig_pubkeyhashes_to_pubkeys(address, provided_pubkeys=None):
    signatures_required, pubkeyhashes, signatures_possible = script.extract_array(address)
    pubkeys = [pubkeyhash_to_pubkey(pubkeyhash, provided_pubkeys) for pubkeyhash in pubkeyhashes]
    return script.construct_array(signatures_required, pubkeys, signatures_possible)
