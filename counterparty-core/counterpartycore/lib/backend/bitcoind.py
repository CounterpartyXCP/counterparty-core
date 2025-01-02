import binascii
import functools
import json
import logging
import time
from collections import OrderedDict
from multiprocessing import current_process
from threading import current_thread

import requests
from requests.exceptions import ChunkedEncodingError, ConnectionError, ReadTimeout, Timeout

from counterpartycore.lib import config, deserialize, exceptions, script, util
from counterpartycore.lib.util import ib2h

logger = logging.getLogger(config.LOGGER_NAME)

BLOCKS_CACHE = OrderedDict()
BLOCKS_CACHE_MAX_SIZE = 1000
TRANSACTIONS_CACHE = OrderedDict()
TRANSACTIONS_CACHE_MAX_SIZE = 10000


def rpc_call(payload, retry=0):
    """Calls to bitcoin core and returns the response"""
    url = config.BACKEND_URL
    response = None
    start_time = time.time()

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
            if response.status_code == 503:
                raise ConnectionError("Received 503 error from backend")
            if response.status_code not in (200, 500):
                raise exceptions.BitcoindRPCError(str(response.status_code) + " " + response.reason)
            break
        except KeyboardInterrupt:
            raise
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
        result = response_json
    elif "error" not in response_json.keys() or response_json["error"] is None:  # noqa: E711
        result = response_json["result"]
    elif response_json["error"]["code"] == -5:  # RPC_INVALID_ADDRESS_OR_KEY
        raise exceptions.BitcoindRPCError(
            f"{response_json['error']} Is `txindex` enabled in {config.BTC_NAME} Core?"
        )
    elif response_json["error"]["code"] in [-28, -8, -2]:
        # "Verifying blocks..." or "Block height out of range" or "The network does not appear to fully agree!""
        logger.debug(f"Backend not ready. Sleeping for ten seconds. ({response_json['error']})")
        logger.debug(f"Payload: {payload}")
        if retry >= 10:
            raise exceptions.BitcoindRPCError(
                f"Backend not ready after {retry} retries. ({response_json['error']})"
            )
        # If Bitcoin Core takes more than `sys.getrecursionlimit() * 10 = 9970`
        # seconds to start, this'll hit the maximum recursion depth limit.
        time.sleep(10)
        return rpc_call(payload, retry=retry + 1)
    else:
        raise exceptions.BitcoindRPCError(response_json["error"]["message"])

    if hasattr(logger, "trace"):
        if isinstance(payload, dict):
            method = payload["method"]
        elif isinstance(payload, list):
            method = payload[0]["method"]
        else:
            method = "unknown"
        elapsed = time.time() - start_time
        logger.trace(f"Bitcoin Core RPC call {method} took {elapsed:.3f}s")

    return result


def is_api_request():
    if current_process().name != "API":
        return False
    thread_name = current_thread().name
    # waitress, werkzeug or Gunicorn thead
    for name in ["waitress", "process_request_thread", "ThreadPoolExecutor"]:
        if name in thread_name:
            return True
    return False


def rpc(method, params):
    if is_api_request():
        return safe_rpc(method, params)

    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    return rpc_call(payload)


# no retry for requests from the API
def safe_rpc(method, params):
    start_time = time.time()
    try:
        payload = {
            "method": method,
            "params": params,
            "jsonrpc": "2.0",
            "id": 0,
        }
        response = requests.post(
            config.BACKEND_URL,
            data=json.dumps(payload),
            headers={"content-type": "application/json"},
            verify=(not config.BACKEND_SSL_NO_VERIFY),
            timeout=config.REQUESTS_TIMEOUT,
        ).json()
        return response["result"]
    except (requests.exceptions.RequestException, json.decoder.JSONDecodeError, KeyError) as e:
        raise exceptions.BitcoindRPCError(f"Error calling {method}: {str(e)}") from e
    finally:
        elapsed = time.time() - start_time
        logger.trace(f"Bitcoin Core RPC call {method} took {elapsed:.3f}s")


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


def getrawtransaction_batch(tx_hashes, verbose=False, return_dict=False):
    if len(tx_hashes) == 0:
        return {}
    if len(tx_hashes) > config.MAX_RPC_BATCH_SIZE:
        raise exceptions.BitcoindRPCError("Too many transactions requested")

    payload = [
        {
            "method": "getrawtransaction",
            "params": [tx_hash, 1 if verbose else 0],
            "jsonrpc": "2.0",
            "id": i,
        }
        for i, tx_hash in enumerate(tx_hashes)
    ]
    results = rpc_call(payload)

    if return_dict:
        raw_transactions = {}
        for result in results:
            if "result" in result and result["result"] is not None:
                raw_transactions[tx_hashes[result["id"]]] = result["result"]
    else:
        raw_transactions = []
        for result in results:
            if "result" in result and result["result"] is not None:
                raw_transactions.append(result["result"])

    return raw_transactions


def createrawtransaction(inputs, outputs):
    return rpc("createrawtransaction", [inputs, outputs])


def getrawmempool(verbose=False):
    return rpc("getrawmempool", [True if verbose else False])


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


def get_utxo_value(tx_hash, vout):
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


def decoderawtransaction(rawtx: str):
    """
    Proxy to `decoderawtransaction` RPC call.
    :param rawtx: The raw transaction hex. (e.g. 0200000000010199c94580cbea44aead18f429be20552e640804dc3b4808e39115197f1312954d000000001600147c6b1112ed7bc76fd03af8b91d02fd6942c5a8d0ffffffff0280f0fa02000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac70da0a27010000001600147c6b1112ed7bc76fd03af8b91d02fd6942c5a8d002000000000000)
    """
    return rpc("decoderawtransaction", [rawtx])


def search_pubkey_in_transactions(pubkeyhash, tx_hashes):
    for tx_hash in tx_hashes:
        tx = getrawtransaction(tx_hash, True)
        for vin in tx["vin"]:
            if "txinwitness" in vin:
                if len(vin["txinwitness"]) >= 2:
                    # catch unhexlify errs for when txinwitness[1] isn't a witness program (eg; for P2W)
                    try:
                        pubkey = vin["txinwitness"][1]
                        if pubkeyhash == script.pubkey_to_p2whash2(pubkey):
                            return pubkey
                    except binascii.Error:
                        pass
            elif "coinbase" not in vin:
                scriptsig = vin["scriptSig"]
                asm = scriptsig["asm"].split(" ")
                if len(asm) == 4:  # p2pkh
                    # catch unhexlify errs for when asm[1] isn't a pubkey (eg; for P2SH)
                    try:
                        pubkey = asm[3]
                        if pubkeyhash == script.pubkey_to_pubkeyhash(util.unhexlify(pubkey)):
                            return pubkey
                    except binascii.Error:
                        pass
        for vout in tx["vout"]:
            asm = vout["scriptPubKey"]["asm"].split(" ")
            if len(asm) == 3:  # p2pk
                try:
                    pubkey = asm[1]
                    if pubkeyhash == script.pubkey_to_pubkeyhash(util.unhexlify(pubkey)):
                        return pubkey
                except binascii.Error:
                    pass
    return None


def list_unspent(source, allow_unconfirmed_inputs):
    min_conf = 0 if allow_unconfirmed_inputs else 1
    bitcoind_unspent_list = []
    try:
        bitcoind_unspent_list = safe_rpc("listunspent", [min_conf, 9999999, [source]]) or []
    except exceptions.BitcoindRPCError:
        pass

    if len(bitcoind_unspent_list) > 0:
        unspent_list = []
        for unspent in bitcoind_unspent_list:
            unspent_list.append(
                {
                    "txid": unspent["txid"],
                    "vout": unspent["vout"],
                    "value": int(unspent["amount"] * config.UNIT),
                    "amount": unspent["amount"],
                    "script_pub_key": unspent["scriptPubKey"],
                }
            )
        return unspent_list

    return []
