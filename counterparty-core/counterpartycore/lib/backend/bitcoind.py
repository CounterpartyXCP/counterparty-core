import binascii
import functools
import json
import logging
import re
import time
from collections import OrderedDict
from multiprocessing import current_process
from threading import current_thread

import requests
from bitcoinutils.keys import PublicKey
from requests.exceptions import (  # pylint: disable=redefined-builtin
    ChunkedEncodingError,
    ConnectionError,
    ReadTimeout,
    Timeout,
)

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser import deserialize, utxosinfo

logger = logging.getLogger(config.LOGGER_NAME)

BLOCKS_CACHE = OrderedDict()
BLOCKS_CACHE_MAX_SIZE = 1000
TRANSACTIONS_CACHE = OrderedDict()
TRANSACTIONS_CACHE_MAX_SIZE = 10000


URL_USERNAMEPASS_REGEX = re.compile(".+://(.+)@")


def clean_url_for_log(url):
    m = URL_USERNAMEPASS_REGEX.match(url)
    if m and m.group(1):
        url = url.replace(m.group(1), "XXXXXXXX")

    return url


# for testing
def should_retry():
    if CurrentState().stopping():
        return False
    return True


def get_json_response(response, retry=0):
    try:
        json_response = response.json()
        if isinstance(json_response, str):
            raise json.decoder.JSONDecodeError("Invalid JSON", json_response, 0)
        return json_response
    except json.decoder.JSONDecodeError as e:  # noqa: F841
        if response.status_code == 200:
            logger.warning(
                "Received invalid JSON with status 200 from Bitcoin Core: %s. Retrying in 5 seconds...",
                response.text,
                stack_info=config.VERBOSE > 0,
            )
            time.sleep(5)
            if retry < 5:
                return get_json_response(response, retry=retry + 1)
        raise exceptions.BitcoindRPCError(  # noqa: B904
            f"Received invalid JSON from backend with a response of {str(response.status_code)}: {response.text}"
        ) from e


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
                raise exceptions.BitcoindRPCError(
                    f"Cannot communicate with Bitcoin Core at `{clean_url_for_log(url)}`. (server is set to run on {config.NETWORK_NAME}, is backend?)"
                )
            if response.status_code in (401,):
                raise exceptions.BitcoindRPCError(
                    f"Authorization error connecting to {clean_url_for_log(url)}: {response.status_code} {response.reason}"
                )
            if response.status_code == 503:
                raise ConnectionError("Received 503 error from backend")
            if response.status_code not in (200, 500):
                raise exceptions.BitcoindRPCError(str(response.status_code) + " " + response.reason)
            break
        except (Timeout, ReadTimeout, ConnectionError, ChunkedEncodingError):
            logger.warning(
                "Could not connect to backend at `%s`. (Attempt: %s)",
                clean_url_for_log(url),
                tries,
                stack_info=config.VERBOSE > 0,
            )
            time.sleep(5)
        except Exception as e:  # pylint: disable=broad-except
            broken_error = e
            break
    if broken_error:
        raise broken_error

    # Handle json decode errors
    response_json = get_json_response(response)

    if "error" in response_json and isinstance(response_json["error"], str):
        response_json["error"] = {"message": response_json["error"], "code": -1}

    # Batch query returns a list
    if isinstance(response_json, list):
        result = response_json
    elif "error" not in response_json.keys() or response_json["error"] is None:  # noqa: E711
        result = response_json["result"]
    elif "Block height out of range" in response_json["error"]["message"]:
        # this error should be managed by the caller
        raise exceptions.BlockOutOfRange(response_json["error"]["message"])
    elif response_json["error"]["code"] in [-28, -8, -5, -2, -1]:
        # "Verifying blocks..." or "Block height out of range" or "The network does not appear to fully agree!""
        warning_message = f"Error calling {payload}: {response_json['error']}. Sleeping for ten seconds and retrying."
        if response_json["error"]["code"] == -5:  # RPC_INVALID_ADDRESS_OR_KEY
            warning_message += f" Is `txindex` enabled in {config.BTC_NAME} Core?"
        logger.warning(warning_message, stack_info=config.VERBOSE > 0)
        if should_retry():
            # If Bitcoin Core takes more than `sys.getrecursionlimit() * 10 = 9970`
            # seconds to start, this'll hit the maximum recursion depth limit.
            time.sleep(10)
            return rpc_call(payload, retry=retry + 1)
        raise exceptions.BitcoindRPCError(warning_message)
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


def rpc(method, params, no_retry=False):
    if is_api_request() or no_retry:
        return safe_rpc(method, params)

    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    return rpc_call(payload)


def safe_rpc_payload(payload):
    start_time = time.time()
    method = payload["method"] if isinstance(payload, dict) else payload[0]["method"]
    try:
        response = requests.post(
            config.BACKEND_URL,
            data=json.dumps(payload),
            headers={"content-type": "application/json"},
            verify=(not config.BACKEND_SSL_NO_VERIFY),
            timeout=config.REQUESTS_TIMEOUT,
        )
        if response is None:
            raise exceptions.BitcoindRPCError(
                f"Cannot communicate with Bitcoin Core at `{clean_url_for_log(config.BACKEND_URL)}`. (server is set to run on {config.NETWORK_NAME}, is backend?)"
            )
        response = response.json()
        if isinstance(response, list):
            return response
        if "result" not in response and "error" in response:
            if response["error"] is None or "message" not in response["error"]:
                message = "Unknown error"
            else:
                message = response["error"]["message"]
            raise exceptions.BitcoindRPCError(message)
        if response["result"] is None:
            raise exceptions.BitcoindRPCError("No result returned")
        return response["result"]
    except (requests.exceptions.RequestException, json.decoder.JSONDecodeError, KeyError) as e:
        raise exceptions.BitcoindRPCError(f"Error calling {method}: {str(e)}") from e
    finally:
        elapsed = time.time() - start_time
        logger.trace(f"Bitcoin Core RPC call {method} took {elapsed:.3f}s")


# no retry for requests from the API
def safe_rpc(method, params):
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    return safe_rpc_payload(payload)


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
def getrawtransaction(tx_hash, verbose=False, no_retry=False):
    return rpc("getrawtransaction", [tx_hash, 1 if verbose else 0], no_retry=no_retry)


def getrawtransaction_batch(tx_hashes, verbose=False, return_dict=False, no_retry=False):
    if len(tx_hashes) == 0:
        return {}

    # Process transactions in batches of MAX_RPC_BATCH_SIZE
    all_raw_transactions = {} if return_dict else []

    for i in range(0, len(tx_hashes), config.MAX_RPC_BATCH_SIZE):
        batch = tx_hashes[i : i + config.MAX_RPC_BATCH_SIZE]

        payload = [
            {
                "method": "getrawtransaction",
                "params": [tx_hash, 1 if verbose else 0],
                "jsonrpc": "2.0",
                "id": j,
            }
            for j, tx_hash in enumerate(batch)
        ]

        if no_retry:
            batch_results = safe_rpc_payload(payload)
        else:
            batch_results = rpc_call(payload)

        # Process results for this batch
        if return_dict:
            for result in batch_results:
                if "result" in result and result["result"] is not None:
                    # Use the batch array to get the correct tx_hash
                    batch_index = result["id"]
                    tx_hash = batch[batch_index]
                    all_raw_transactions[tx_hash] = result["result"]
        else:
            for result in batch_results:
                if "result" in result and result["result"] is not None:
                    all_raw_transactions.append(result["result"])

    return all_raw_transactions


def createrawtransaction(inputs, outputs):
    return rpc("createrawtransaction", [inputs, outputs])


def getrawmempool(verbose=False):
    return rpc("getrawmempool", [bool(verbose)])


@functools.lru_cache(maxsize=1000)
def get_utxo_address_and_value(utxo, no_retry=False):
    tx_hash = utxo.split(":")[0]
    vout = int(utxo.split(":")[1])
    try:
        transaction = getrawtransaction(tx_hash, True, no_retry=no_retry)
    except exceptions.BitcoindRPCError as e:
        raise exceptions.InvalidUTXOError(f"Could not find UTXO {utxo}") from e
    if vout >= len(transaction["vout"]):
        raise exceptions.InvalidUTXOError("vout index out of range")
    if "address" not in transaction["vout"][vout]["scriptPubKey"]:
        raise exceptions.InvalidUTXOError("vout does not have an address")
    return transaction["vout"][vout]["scriptPubKey"]["address"], transaction["vout"][vout]["value"]


def safe_get_utxo_address(utxo):
    try:
        return get_utxo_address_and_value(utxo, no_retry=True)[0]
    except exceptions.InvalidUTXOError:
        return "unknown"


def is_valid_utxo(utxo):
    if not utxosinfo.is_utxo_format(utxo):
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
    tip = get_chain_tip()
    while block_count < block_index:
        logger.debug(
            "Waiting for Bitcoin Core to process block %d... (Bitcoin Core Block Height = %d, Network Block Height = %d)",
            block_index,
            block_count,
            tip,
        )
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


def get_decoded_transaction(tx_hash, block_index=None, no_retry=False):
    if tx_hash in TRANSACTIONS_CACHE:
        return TRANSACTIONS_CACHE[tx_hash]

    raw_tx = getrawtransaction(tx_hash, no_retry=no_retry)
    tx = deserialize.deserialize_tx(raw_tx, block_index=block_index)

    add_transaction_in_cache(tx_hash, tx)

    return tx


def get_tx_out_amount(tx_hash, vout):
    raw_tx = getrawtransaction(tx_hash, True)
    return raw_tx["vout"][vout]["value"]


def get_utxo_value(tx_hash, vout):
    return get_tx_out_amount(tx_hash, vout)


def sendrawtransaction(signedhex: str):
    """
    Proxy to `sendrawtransaction` RPC call.
    :param signedhex: The signed transaction hex.
    """
    try:
        return rpc("sendrawtransaction", [signedhex])
    except Exception as e:  # pylint: disable=broad-except
        raise exceptions.BitcoindRPCError(f"Error broadcasting transaction: {str(e)}") from e


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
                        if (
                            pubkeyhash
                            == PublicKey.from_hex(pubkey).get_segwit_address().to_string()
                        ):
                            return pubkey
                    except binascii.Error:
                        pass
            elif "coinbase" not in vin:
                scriptsig = vin["scriptSig"]
                asm = scriptsig["asm"].split(" ")
                if len(asm) == 2:  # p2pkh
                    # catch unhexlify errs for when asm[1] isn't a pubkey (eg; for P2SH)
                    try:
                        pubkey = asm[1]
                        if (
                            pubkeyhash
                            == PublicKey.from_hex(pubkey).get_address(compressed=False).to_string()
                        ):
                            return pubkey
                        if (
                            pubkeyhash
                            == PublicKey.from_hex(pubkey).get_address(compressed=True).to_string()
                        ):
                            return pubkey
                    except binascii.Error:
                        pass
        for vout in tx["vout"]:
            asm = vout["scriptPubKey"]["asm"].split(" ")
            if len(asm) == 3 and asm[2] == "OP_CHECKSIG":  # p2pk
                try:
                    pubkey = asm[1]
                    if (
                        pubkeyhash
                        == PublicKey.from_hex(pubkey).get_address(compressed=False).to_string()
                    ):
                        return pubkey
                except (binascii.Error, AttributeError):
                    pass
                try:
                    if (
                        pubkeyhash
                        == PublicKey.from_hex(pubkey).get_address(compressed=True).to_string()
                    ):
                        return pubkey
                except (binascii.Error, AttributeError):
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


def get_vin_info(vin, no_retry=False):
    vin_info = vin.get("info")
    if vin_info is None:
        raise exceptions.RSFetchError("No vin info found")
    else:
        return vin_info["value"], vin_info["script_pub_key"], vin_info["is_segwit"]


def get_vin_info_legacy(vin, no_retry=False):
    try:
        vin_ctx = get_decoded_transaction(vin["hash"], no_retry=no_retry)
        vout = vin_ctx["vout"][vin["n"]]
        return vout["value"], vout["script_pub_key"]
    except exceptions.BitcoindRPCError as e:
        raise exceptions.DecodeError("vin not found") from e


def get_transaction(tx_hash: str, result_format: str = "json"):
    """
    Get a transaction from the blockchain
    :param tx_hash: The transaction hash (e.g. $LAST_TX_HASH)
    :param format: Whether to return JSON output or raw hex (e.g. hex)
    """
    return getrawtransaction(tx_hash, verbose=result_format == "json")
