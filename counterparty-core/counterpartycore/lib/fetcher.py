import logging
from collections import OrderedDict

from counterpartycore.lib import backend, config, deserialize, util

logger = logging.getLogger(config.LOGGER_NAME)


BLOCKS_CACHE = {}
BLOCKS_CACHE_MAX_SIZE = 100
TRANSACTIONS_CACHE = OrderedDict()
TRANSACTIONS_CACHE_MAX_SIZE = 10000


def add_transaction_in_cache(tx_hash, tx):
    TRANSACTIONS_CACHE[tx_hash] = tx
    if len(TRANSACTIONS_CACHE) > TRANSACTIONS_CACHE_MAX_SIZE:
        TRANSACTIONS_CACHE.popitem(last=False)


def add_block_in_cache(block_index, block):
    BLOCKS_CACHE[block_index] = block
    for transaction in block["transactions"]:
        add_transaction_in_cache(transaction["tx_hash"], transaction)


def get_decoded_block(block_index):
    if block_index in BLOCKS_CACHE:
        # remove from cache when used
        return BLOCKS_CACHE.pop(block_index)

    block_hash = backend.bitcoind.getblockhash(block_index)
    raw_block = backend.bitcoind.getblock(block_hash)
    use_txid = util.enabled("correct_segwit_txids", block_index=block_index)
    block = deserialize.deserialize_block(raw_block, use_txid=use_txid)

    add_block_in_cache(block_index, block)

    return block


def get_decoded_transaction(tx_hash, block_index=None):
    if tx_hash in TRANSACTIONS_CACHE:
        return TRANSACTIONS_CACHE[tx_hash]

    raw_tx = backend.bitcoind.getrawtransaction(tx_hash)
    use_txid = util.enabled("correct_segwit_txids", block_index=block_index)
    tx = deserialize.deserialize_tx(raw_tx, use_txid=use_txid)

    add_transaction_in_cache(tx_hash, tx)

    return tx


class BlockFetcher:
    def __init__(self, first_block) -> None:
        self.current_block = first_block

    def get_next_block(self):
        block = get_decoded_block(self.current_block)
        self.current_block += 1
        return block
