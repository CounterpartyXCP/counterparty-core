import functools
import json
import logging
import time
from collections import OrderedDict

import requests
from requests.exceptions import ChunkedEncodingError, ConnectionError, ReadTimeout, Timeout

from counterpartycore.lib import config, deserialize, exceptions, util
from counterpartycore.lib.util import ib2h

logger = logging.getLogger(config.LOGGER_NAME)

BLOCKS_CACHE = OrderedDict()
BLOCKS_CACHE_MAX_SIZE = 1000
TRANSACTIONS_CACHE = OrderedDict()
TRANSACTIONS_CACHE_MAX_SIZE = 10000


def rpc_call(payload):
    """Calls to bitcoin core and returns the response"""
    url = config.BACKEND_URL
    response = None

    tries = 0
    broken_error = None
    while True:
        try:
            tries += 1
            response = requests.post(
                url,
                data=json.dumps(payload),
                headers={"content-type": "application/json"},
                verify=(not config.BACKEND_SSL_NO_VERIFY),
                timeout=config.REQUESTS_TIMEOUT,
            )

            if response is None:  # noqa: E711
                if config.TESTNET:
                    network = "testnet"
                elif config.REGTEST:
                    network = "regtest"
                else:
                    network = "mainnet"
                raise exceptions.BitcoindRPCError(
                    f"Cannot communicate with Bitcoin Core at `{util.clean_url_for_log(url)}`. (server is set to run on {network}, is backend?)"
                )
            if response.status_code in (401,):
                raise exceptions.BitcoindRPCError(
                    f"Authorization error connecting to {util.clean_url_for_log(url)}: {response.status_code} {response.reason}"
                )
            if response.status_code not in (200, 500):
                raise exceptions.BitcoindRPCError(str(response.status_code) + " " + response.reason)
            break
        except KeyboardInterrupt:
            logger.warning("Interrupted by user")
            exit(0)
        except (Timeout, ReadTimeout, ConnectionError, ChunkedEncodingError):
            logger.warning(
                f"Could not connect to backend at `{util.clean_url_for_log(url)}`. (Attempt: {tries})"
            )
            time.sleep(5)
        except Exception as e:
            broken_error = e
            break
    if broken_error:
        raise broken_error

    # Handle json decode errors
    try:
        response_json = response.json()
    except json.decoder.JSONDecodeError as e:  # noqa: F841
        raise exceptions.BitcoindRPCError(  # noqa: B904
            f"Received invalid JSON from backend with a response of {str(response.status_code) + ' ' + response.reason}"
        ) from e

    # Batch query returns a list
    if isinstance(response_json, list):
        return response_json
    if "error" not in response_json.keys() or response_json["error"] is None:  # noqa: E711
        return response_json["result"]
    if response_json["error"]["code"] == -5:  # RPC_INVALID_ADDRESS_OR_KEY
        raise exceptions.BitcoindRPCError(
            f"{response_json['error']} Is `txindex` enabled in {config.BTC_NAME} Core?"
        )
    if response_json["error"]["code"] in [-28, -8, -2]:
        # “Verifying blocks...” or “Block height out of range” or “The network does not appear to fully agree!“
        logger.debug(f"Backend not ready. Sleeping for ten seconds. ({response_json['error']})")
        # If Bitcoin Core takes more than `sys.getrecursionlimit() * 10 = 9970`
        # seconds to start, this’ll hit the maximum recursion depth limit.
        time.sleep(10)
        return rpc_call(payload)
    raise exceptions.BitcoindRPCError(response_json["error"]["message"])


def rpc(method, params):
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    return rpc_call(payload)


def getblockcount():
    return rpc("getblockcount", [])


def getblockhash(blockcount):
    return rpc("getblockhash", [blockcount])


def getblock(block_hash, verbosity=0):
    return rpc("getblock", [block_hash, verbosity])


def get_block_height(block_hash):
    block_info = rpc("getblock", [block_hash, 1])
    return block_info["height"]


def convert_to_psbt(rawtx):
    return rpc("converttopsbt", [rawtx, True])


@functools.lru_cache(maxsize=10000)
def getrawtransaction(tx_hash, verbose=False):
    return rpc("getrawtransaction", [tx_hash, 1 if verbose else 0])


def createrawtransaction(inputs, outputs):
    return rpc("createrawtransaction", [inputs, outputs])


@functools.lru_cache(maxsize=1000)
def get_utxo_address_and_value(utxo):
    tx_hash = utxo.split(":")[0]
    vout = int(utxo.split(":")[1])
    try:
        transaction = getrawtransaction(tx_hash, True)
    except exceptions.BitcoindRPCError as e:
        raise exceptions.InvalidUTXOError(f"Could not find UTXO {utxo}") from e
    if vout >= len(transaction["vout"]):
        raise exceptions.InvalidUTXOError("vout index out of range")
    if "address" not in transaction["vout"][vout]["scriptPubKey"]:
        raise exceptions.InvalidUTXOError("vout does not have an address")
    return transaction["vout"][vout]["scriptPubKey"]["address"], transaction["vout"][vout]["value"]


def safe_get_utxo_address(utxo):
    try:
        return get_utxo_address_and_value(utxo)[0]
    except exceptions.InvalidUTXOError:
        return "unknown"


def is_valid_utxo(utxo):
    if not util.is_utxo_format(utxo):
        return False
    try:
        get_utxo_address_and_value(utxo)
        return True
    except exceptions.InvalidUTXOError:
        return False


def fee_per_kb(
    conf_target: int = config.ESTIMATE_FEE_CONF_TARGET, mode: str = config.ESTIMATE_FEE_MODE
):
    """
    Get the fee per kilobyte for a transaction to be confirmed in `conf_target` blocks.
    :param conf_target: Confirmation target in blocks (1 - 1008) (e.g. 2)
    :param mode: The fee estimate mode. (e.g. CONSERVATIVE)
    """
    feeperkb = rpc("estimatesmartfee", [conf_target, mode])

    if "errors" in feeperkb and feeperkb["errors"][0] == "Insufficient data or no feerate found":
        return None

    return int(max(feeperkb["feerate"] * config.UNIT, config.DEFAULT_FEE_PER_KB_ESTIMATE_SMART))


def satoshis_per_vbyte(
    conf_target: int = config.ESTIMATE_FEE_CONF_TARGET, mode: str = config.ESTIMATE_FEE_MODE
):
    feeperkb = rpc("estimatesmartfee", [conf_target, mode])

    if "errors" in feeperkb and feeperkb["errors"][0] == "Insufficient data or no feerate found":
        return config.DEFAULT_FEE_PER_KB_ESTIMATE_SMART

    return (feeperkb["feerate"] * config.UNIT) / 1024


def get_btc_supply(normalize=False):
    f"""returns the total supply of {config.BTC} (based on what Bitcoin Core says the current block height is)"""  # noqa: B021
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
            total_supply += blocks_remaining * reward
            blocks_remaining = 0
    return total_supply if normalize else int(total_supply * config.UNIT)


def get_chain_tip():
    return rpc("getchaintips", [])[0]["height"]


def get_blocks_behind():
    block_count = getblockcount()
    chain_tip = get_chain_tip()
    return chain_tip - block_count


def get_zmq_notifications():
    return rpc("getzmqnotifications", [])


def get_mempool_info():
    """
    Get the current mempool info.
    """
    return rpc("getmempoolinfo", [])


def wait_for_block(block_index):
    block_count = getblockcount()
    while block_count < block_index:
        logger.debug(f"Waiting for bitcoind to catch up {block_index - block_count} blocks...")
        time.sleep(10)
        block_count = getblockcount()


def add_transaction_in_cache(tx_hash, tx):
    TRANSACTIONS_CACHE[tx_hash] = tx
    if len(TRANSACTIONS_CACHE) > TRANSACTIONS_CACHE_MAX_SIZE:
        TRANSACTIONS_CACHE.popitem(last=False)


def add_block_in_cache(block_index, block):
    BLOCKS_CACHE[block_index] = block
    if len(BLOCKS_CACHE) > BLOCKS_CACHE_MAX_SIZE:
        BLOCKS_CACHE.popitem(last=False)
    for transaction in block["transactions"]:
        add_transaction_in_cache(transaction["tx_hash"], transaction)


def get_decoded_block(block_index):
    if block_index in BLOCKS_CACHE:
        # remove from cache when used
        return BLOCKS_CACHE.pop(block_index)

    block_hash = getblockhash(block_index)
    raw_block = getblock(block_hash)
    use_txid = util.enabled("correct_segwit_txids", block_index=block_index)
    block = deserialize.deserialize_block(raw_block, use_txid=use_txid)

    add_block_in_cache(block_index, block)

    return block


def get_decoded_transaction(tx_hash, block_index=None):
    if isinstance(tx_hash, bytes):
        tx_hash = ib2h(tx_hash)
    if tx_hash in TRANSACTIONS_CACHE:
        return TRANSACTIONS_CACHE[tx_hash]

    raw_tx = getrawtransaction(tx_hash)
    use_txid = util.enabled("correct_segwit_txids", block_index=block_index)
    tx = deserialize.deserialize_tx(raw_tx, use_txid=use_txid)

    add_transaction_in_cache(tx_hash, tx)

    return tx


def get_tx_out_amount(tx_hash, vout):
    raw_tx = getrawtransaction(tx_hash, True)
    return raw_tx["vout"][vout]["value"]


def get_tx_out_value(tx_hash, vout):
    return get_tx_out_amount(tx_hash, vout)


class BlockFetcher:
    def __init__(self, first_block) -> None:
        self.current_block = first_block

    def get_block(self):
        block = get_decoded_block(self.current_block)
        self.current_block += 1
        return block


def sendrawtransaction(signedhex: str):
    """
    Proxy to `sendrawtransaction` RPC call.
    :param signedhex: The signed transaction hex.
    """
    return rpc("sendrawtransaction", [signedhex])
