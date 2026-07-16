import binascii
import functools
import json
import logging
import random
import re
import time
from collections import OrderedDict
from decimal import Decimal as D
from multiprocessing import current_process
from threading import current_thread

import requests
from bitcoinutils.keys import PublicKey
from ecdsa.ellipticcurve import MalformedPointError
from requests.exceptions import (  # pylint: disable=redefined-builtin
    ChunkedEncodingError,
    ConnectionError,
    ReadTimeout,
    Timeout,
)

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser import deserialize, p2sh, protocol, utxosinfo
from counterpartycore.lib.utils import multisig, script

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


def _rpc_headers():
    # Always send JSON content-type; conditionally include the X-API-Key
    # header so the backend (e.g. Cloud Armor in front of bitcoind) can
    # apply a higher per-key rate-limit bucket. Falls back to no header
    # when `BACKEND_API_KEY` is unset, preserving the previous request
    # shape for self-hosted nodes.
    headers = {"content-type": "application/json"}
    api_key = getattr(config, "BACKEND_API_KEY", None)
    if api_key:
        headers["X-API-Key"] = api_key
    return headers


# for testing
def should_retry():
    if CurrentState().stopping():
        return False
    return True


def request_timeout():
    """Timeout passed to ``requests``. When a distinct connect timeout is
    configured, return a ``(connect, read)`` tuple so a stalled/unreachable
    backend fails the TCP connect quickly instead of hanging for the full
    read timeout. Falls back to the single read timeout otherwise."""
    connect_timeout = getattr(config, "BACKEND_CONNECT_TIMEOUT", None)
    if connect_timeout:
        return (connect_timeout, config.REQUESTS_TIMEOUT)
    return config.REQUESTS_TIMEOUT


def skip_rpc_retry(no_retry=False):
    """Whether an RPC call must fail fast instead of entering the unbounded
    connection-retry loop.

    True for synchronous public API requests (which must never pin a Waitress/
    Gunicorn worker while a degraded backend retries) and whenever the caller
    explicitly opts out of retries. False for the parser/indexing path, which
    must keep retrying to preserve consensus correctness (a skipped VIN would
    fork the ledger)."""
    return no_retry or is_api_request()


def retry_backoff(tries):
    """Jittered backoff (seconds) for the parser connection-retry loop.

    Exponential growth capped at ``BACKEND_RETRY_MAX_SLEEP`` with full jitter,
    so many independent nodes recovering from the same backend outage do not
    reconnect in lockstep (a synchronized retry storm)."""
    base = getattr(config, "BACKEND_RETRY_BASE_SLEEP", 1)
    cap = getattr(config, "BACKEND_RETRY_MAX_SLEEP", 30)
    ceiling = min(cap, base * (2 ** min(tries, 10)))
    # full jitter: sleep uniformly in [base, ceiling]
    return random.uniform(min(base, ceiling), ceiling)  # noqa: S311


def interruptible_sleep(duration, check_interval=0.5):
    """Sleep for duration seconds, but check for stop condition every check_interval seconds."""
    elapsed = 0.0
    while elapsed < duration:
        if CurrentState().stopping():
            return False  # Interrupted
        sleep_time = min(check_interval, duration - elapsed)
        time.sleep(sleep_time)
        elapsed += sleep_time
    return True  # Completed without interruption


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
            if not interruptible_sleep(5):
                raise exceptions.BitcoindRPCError("Shutdown requested during JSON retry") from e
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
                headers=_rpc_headers(),
                verify=(not config.BACKEND_SSL_NO_VERIFY),
                timeout=request_timeout(),
                auth=("__cookie__", config.BACKEND_COOKIE) if config.BACKEND_COOKIE else None,
            )

            if response is None:  # noqa: E711
                raise exceptions.BitcoindRPCError(
                    f"Cannot communicate with Bitcoin Core at `{clean_url_for_log(url)}`. (server is set to run on {config.NETWORK_NAME}, is backend?)"
                )
            if response.status_code in (401,):
                raise exceptions.BitcoindRPCError(
                    f"Authorization error connecting to {clean_url_for_log(url)}: {response.status_code} {response.reason}"
                )
            if response.status_code in (502, 503, 504):
                # Transient gateway errors (commonly emitted by a reverse proxy
                # or SSH tunnel sitting in front of the backend when it is
                # briefly unreachable/overloaded). Route them through the
                # connection-retry path instead of raising, so catch-up waits
                # and retries rather than mis-resolving a VIN.
                raise ConnectionError(f"Received {response.status_code} error from backend")
            if response.status_code == 429:
                # Rate limited - retry with exponential backoff
                backoff_time = min(2**tries, 60)  # Max 60 seconds
                logger.warning(
                    "Rate limited by backend (429 Too Many Requests). Retrying in %s seconds... (Attempt: %s)",
                    backoff_time,
                    tries,
                    stack_info=config.VERBOSE > 0,
                )
                if should_retry():
                    if not interruptible_sleep(backoff_time):
                        raise exceptions.BitcoindRPCError(
                            "Shutdown requested during rate limit backoff"
                        )
                    continue
                raise exceptions.BitcoindRPCError(str(response.status_code) + " " + response.reason)
            if response.status_code not in (200, 500):
                raise exceptions.BitcoindRPCError(str(response.status_code) + " " + response.reason)
            break
        except (Timeout, ReadTimeout, ConnectionError, ChunkedEncodingError) as e:
            # A synchronous public API request must never enter this unbounded
            # loop and pin a worker; fail fast so the caller returns a bounded,
            # retryable error. The parser path keeps retrying (consensus
            # correctness) with jittered backoff to avoid a retry storm.
            if is_api_request():
                raise exceptions.BitcoindRPCError(
                    f"Could not connect to backend at `{clean_url_for_log(url)}`: {e}"
                ) from e
            backoff = retry_backoff(tries)
            logger.warning(
                "Could not connect to backend at `%s`. Retrying in %.1fs. (Attempt: %s)",
                clean_url_for_log(url),
                backoff,
                tries,
                stack_info=config.VERBOSE > 0,
            )
            if not interruptible_sleep(backoff):
                raise exceptions.BitcoindRPCError(
                    "Shutdown requested during connection retry"
                ) from e
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
            if not interruptible_sleep(10):
                raise exceptions.BitcoindRPCError("Shutdown requested during error retry")
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
    if skip_rpc_retry(no_retry):
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
            headers=_rpc_headers(),
            verify=(not config.BACKEND_SSL_NO_VERIFY),
            timeout=request_timeout(),
            auth=("__cookie__", config.BACKEND_COOKIE) if config.BACKEND_COOKIE else None,
        )
        if response is None:
            raise exceptions.BitcoindRPCError(
                f"Cannot communicate with Bitcoin Core at `{clean_url_for_log(config.BACKEND_URL)}`. (server is set to run on {config.NETWORK_NAME}, is backend?)"
            )
        if response.status_code == 429:
            raise exceptions.BitcoindRPCError("429 Too Many Requests")
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

        # Mirror the single-call dispatcher in rpc(): API requests (and explicit
        # no_retry callers) must fail fast via safe_rpc_payload rather than enter
        # rpc_call's unbounded retry loop, which would otherwise pin an API worker
        # while a degraded backend retries forever.
        if skip_rpc_retry(no_retry):
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
    # A failure to *fetch* the transaction (RPC error, node behind/pruned) is a
    # transient, node-local condition: it MUST propagate as ``BitcoindRPCError``
    # so callers can retry/halt. Do NOT turn it into ``InvalidUTXOError`` — that
    # would be indistinguishable from a *resolved* output that genuinely has no
    # address, and a caller treating it as "unknown" would write a
    # non-deterministic value into consensus state (see safe_get_utxo_address).
    transaction = getrawtransaction(tx_hash, True, no_retry=no_retry)
    if vout >= len(transaction["vout"]):
        raise exceptions.InvalidUTXOError("vout index out of range")
    script_pub_key = transaction["vout"][vout]["scriptPubKey"]
    address = script_pub_key.get("address")
    if address is None and protocol.enabled("multisig_utxo_addresses"):
        address = get_multisig_address_from_script_pub_key(script_pub_key)
    if address is None:
        raise exceptions.InvalidUTXOError("vout does not have an address")
    return address, transaction["vout"][vout]["value"]


def get_multisig_address_from_script_pub_key(script_pub_key):
    if "hex" not in script_pub_key:
        return None
    try:
        if script.get_output_type(script_pub_key["hex"]) != "P2MS":
            return None
        asm = script.script_to_asm(script_pub_key["hex"])
        pubkeys = asm[1:-2]
        pubkeyhashes = [p2sh.pubkey_to_pubkeyhash(pubkey) for pubkey in pubkeys]
        return multisig.construct_array(asm[0], pubkeyhashes, asm[-2])
    except (exceptions.DecodeError, exceptions.MultiSigAddressError):
        return None


def safe_get_utxo_address(utxo):
    # "unknown" is returned ONLY for the deterministic case where the output is
    # resolvable but has no decodable address (non-standard script). That value
    # is reproducible on every node and is part of consensus history (canonical
    # mainnet balances carry it). A transient RPC failure instead raises
    # ``BitcoindRPCError`` and is left to propagate so the parser retries (and
    # ultimately halts) rather than writing a node-dependent "unknown" into the
    # ledger — which would silently fork consensus. Retries are re-enabled here
    # (no ``no_retry``): the address-less case never hits the RPC retry path, so
    # retrying only guards against genuine transient RPC failures.
    try:
        return get_utxo_address_and_value(utxo)[0]
    except exceptions.InvalidUTXOError:
        return "unknown"


def is_valid_utxo(utxo):
    if not utxosinfo.is_utxo_format(utxo):
        return False
    # Compose-time validation only (non-consensus): any failure to resolve the
    # UTXO — missing address or an RPC error (e.g. the tx does not exist) — means
    # it can't be used as a UTXO, so report it invalid rather than propagating.
    try:
        get_utxo_address_and_value(utxo)
        return True
    except (exceptions.InvalidUTXOError, exceptions.BitcoindRPCError):
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
        if not interruptible_sleep(10):
            return  # Interrupted, exit early
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


def reset_caches():
    """Clear in-memory backend caches that may hold data tied to a specific
    block_index. TRANSACTIONS_CACHE holds `deserialize_tx` output which
    honours protocol gates, so a cache hit after a reorg can return data
    deserialised under the orphaned chain's gates. Called from rollback."""
    TRANSACTIONS_CACHE.clear()
    BLOCKS_CACHE.clear()
    # Also clear the @functools.lru_cache wrappers; without these calls
    # an orphaned UTXO's cached (address, value) tuple persists across
    # reorg even though Bitcoin Core may no longer recognise the tx.
    # Same for getrawtransaction's cached payloads.
    # Test fixtures monkey-patch these with plain functions that don't
    # carry the lru_cache `cache_clear` attribute, so guard with hasattr.
    if hasattr(getrawtransaction, "cache_clear"):
        getrawtransaction.cache_clear()
    if hasattr(get_utxo_address_and_value, "cache_clear"):
        get_utxo_address_and_value.cache_clear()


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
                    except (binascii.Error, MalformedPointError):
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
                    except (binascii.Error, MalformedPointError):
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
                except (binascii.Error, AttributeError, MalformedPointError):
                    pass
                try:
                    if (
                        pubkeyhash
                        == PublicKey.from_hex(pubkey).get_address(compressed=True).to_string()
                    ):
                        return pubkey
                except (binascii.Error, AttributeError, MalformedPointError):
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
                    "value": int(D(str(unspent["amount"])) * D(config.UNIT)),
                    "amount": unspent["amount"],
                    "script_pub_key": unspent["scriptPubKey"],
                }
            )
        return unspent_list

    return []


def get_vin_info(vin, no_retry=False):
    vin_info = vin.get("info")
    if vin_info is None:
        return get_vin_info_legacy(vin, no_retry=no_retry)
    return vin_info["value"], vin_info["script_pub_key"], vin_info["is_segwit"]


def get_vin_info_legacy(vin, no_retry=False):
    try:
        vin_ctx = get_decoded_transaction(vin["hash"], no_retry=no_retry)
        vout = vin_ctx["vout"][vin["n"]]
        # `is_segwit` MUST match the Rust fetcher (indexer/bitcoin_client.rs). Before the
        # `fix_is_segwit` protocol change (block 902000) it is whether the *parent
        # transaction* carries any witness (equivalently `txid != wtxid`), NOT whether
        # the prevout output is itself a witness program. Computing it with
        # `is_segwit_output()` unconditionally applies the post-fix semantics to pre-fix
        # blocks, which flips the source of P2SH-encoded transactions funded by a segwit
        # parent from bech32 to base58 and forks the ledger (observed at block 832867).
        if protocol.enabled("fix_is_segwit"):
            is_segwit = script.is_segwit_output(vout["script_pub_key"])
        else:
            is_segwit = vin_ctx["segwit"]
        return (
            vout["value"],
            vout["script_pub_key"],
            is_segwit,
        )
    except exceptions.BitcoindRPCError as e:
        # While parsing the mempool the parent transaction may legitimately be
        # unavailable (e.g. not yet relayed). Skipping the *unconfirmed* tx is
        # safe: it will be re-evaluated once it confirms.
        if CurrentState().parsing_mempool():
            logger.warning(
                "Failed to lookup parent transaction %s for VIN resolution. "
                "Skipping unconfirmed (mempool) transaction.",
                vin["hash"],
            )
            raise exceptions.DecodeError("vin not found") from e
        # During catch-up the parent of a *confirmed* transaction must exist.
        # A failure here is an infrastructure error (unhealthy/overloaded
        # backend, a transient gateway 5xx, missing `txindex`, ...), NOT
        # evidence that the transaction is non-Counterparty. Silently treating
        # it as BTC-only would drop a real Counterparty transaction and
        # permanently fork the ledger from consensus (this is exactly what
        # happened at block 510556). Halt instead: the surrounding block is
        # rolled back atomically and retried on the next run, so a transient
        # blip never corrupts the ledger.
        if CurrentState().stopping():
            # A clean shutdown interrupted the lookup; propagate the original
            # (shutdown) error rather than the consensus-corruption warning.
            raise
        raise exceptions.BitcoindRPCError(
            f"Failed to resolve parent transaction {vin['hash']} for VIN resolution "
            "while parsing a confirmed block. Refusing to silently skip a confirmed "
            "transaction, which would corrupt consensus. Is `txindex` enabled and the "
            "backend healthy?"
        ) from e


def get_transaction(tx_hash: str, result_format: str = "json"):
    """
    Get a transaction from the blockchain
    :param tx_hash: The transaction hash (e.g. $LAST_TX_HASH)
    :param format: Whether to return JSON output or raw hex (e.g. hex)
    """
    return getrawtransaction(tx_hash, verbose=result_format == "json")
