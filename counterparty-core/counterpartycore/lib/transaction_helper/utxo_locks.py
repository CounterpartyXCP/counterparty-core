import binascii
import hashlib
import threading

import bitcoin as bitcoinlib
import cachetools

from counterpartycore.lib import backend, config, util


class BaseThreadSafeCache:
    def __init__(self, *args, **kwargs):
        # Note: reading is thread safe out of the box
        self.lock = threading.Lock()
        self.__cache = self.create_cache(*args, **kwargs)

    def create_cache(self, *args, **kwargs):
        raise NotImplementedError

    def get(self, key, default=None):
        return self.__cache.get(key, default)

    def pop(self, key, default=None):
        with self.lock:
            return self.__cache.pop(key, default)

    def delete(self, key):
        with self.lock:
            try:
                del self.__cache[key]
            except KeyError:
                pass

    def _get_cache(self):
        return self.__cache

    def set(self, key, value):
        with self.lock:
            try:
                self.__cache[key] = value
            except KeyError:
                pass

    def keys(self):
        return self.__cache.keys()

    def __len__(self):
        return len(self.__cache)

    def __iter__(self):
        return iter(self.__cache)

    def __contains__(self, key):
        return key in self.__cache


class ThreadSafeTTLCache(BaseThreadSafeCache):
    def create_cache(self, *args, **kwargs):
        return cachetools.TTLCache(*args, **kwargs)


def make_outkey_vin(txhex, vout):
    txbin = binascii.unhexlify(txhex) if isinstance(txhex, str) else txhex
    assert isinstance(vout, int)

    tx = bitcoinlib.core.CTransaction.deserialize(txbin)
    outkey = [(vin.prevout.hash, vin.prevout.n) for vin in tx.vin]
    outkey = hashlib.sha256((f"{outkey}{vout}").encode("ascii")).digest()

    return outkey


def make_outkey(output):
    return f"{output['txid']}{output['vout']}"


class UTXOLocks(metaclass=util.SingletonMeta):
    # set higher than the max number of UTXOs we should expect to
    # manage in an aging cache for any one source address, at any one period
    # UTXO_P2SH_ENCODING_LOCKS is TTLCache for UTXOs that are used for chaining p2sh encoding
    #  instead of a simple (txid, vout) key we use [(vin.prevout.hash, vin.prevout.n) for vin tx1.vin]
    # we cache the make_outkey_vin to avoid having to fetch raw txs too often

    def __init__(self, utxo_locks_max_addresses=None):
        self.init(utxo_locks_max_addresses)

    def init(self, utxo_locks_max_addresses=None):
        # config
        self.utxo_p2sh_encoding_locks = ThreadSafeTTLCache(10000, 180)
        self.utxo_p2sh_encoding_locks_cache = ThreadSafeTTLCache(1000, 600)
        self.utxo_locks_max_age = config.UTXO_LOCKS_MAX_AGE
        self.utxo_locks_max_addresses = utxo_locks_max_addresses or config.UTXO_LOCKS_MAX_ADDRESSES
        self.utxo_locks_per_address_maxsize = 5000

        self.utxo_locks = None
        if self.utxo_locks_max_addresses > 0:
            self.utxo_locks = util.DictCache(self.utxo_locks_max_addresses)
        print("UTXOLocks initialized")
        print(self.utxo_locks, self.utxo_locks_max_addresses)

    def make_outkey_vin_txid(self, txid, vout):
        if (txid, vout) not in self.utxo_p2sh_encoding_locks_cache:
            txhex = backend.bitcoind.getrawtransaction(txid, verbose=False)
            self.utxo_p2sh_encoding_locks_cache.set((txid, vout), make_outkey_vin(txhex, vout))

        return self.utxo_p2sh_encoding_locks_cache.get((txid, vout))

    def filter_unspents(self, source, unspent, exclude_utxos):
        filter_unspents_utxo_locks = []
        if self.utxo_locks is not None and source in self.utxo_locks:
            filter_unspents_utxo_locks = self.utxo_locks[source].keys()
        filter_unspents_p2sh_locks = self.utxo_p2sh_encoding_locks.keys()  # filter out any locked UTXOs to prevent creating transactions that spend the same UTXO when they're created at the same time
        filtered_unspent = []
        for output in unspent:
            if (
                make_outkey(output) not in filter_unspents_utxo_locks
                and self.make_outkey_vin_txid(output["txid"], output["vout"])
                not in filter_unspents_p2sh_locks
                and (
                    not exclude_utxos
                    or not isinstance(exclude_utxos, str)
                    or f"{output['txid']}:{output['vout']}" not in exclude_utxos.split(",")
                )
            ):
                filtered_unspent.append(output)
        return filtered_unspent

    def lock_utxos(self, source, inputs):
        # Lock the source's inputs (UTXOs) chosen for this transaction
        if self.utxo_locks is not None:
            if source not in self.utxo_locks:
                self.utxo_locks[source] = ThreadSafeTTLCache(
                    self.utxo_locks_per_address_maxsize, self.utxo_locks_max_age
                )
            for input in inputs:
                self.utxo_locks[source].set(make_outkey(input), input)

    def lock_p2sh_utxos(self, unsigned_pretx):
        self.utxo_p2sh_encoding_locks.set(make_outkey_vin(unsigned_pretx, 0), True)

    def unlock_utxos(self, source, inputs):
        if self.utxo_locks is not None and inputs:
            for input in inputs:
                self.utxo_locks[source].pop(make_outkey(input), None)


def sort_unspent_txouts(unspent, dust_size=config.DEFAULT_REGULAR_DUST_SIZE):
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
