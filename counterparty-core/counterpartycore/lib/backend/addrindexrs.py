import hashlib
import json
import logging
import socket
import time

import bitcoin.wallet

from counterpartycore.lib import config

logger = logging.getLogger(config.LOGGER_NAME)


READ_BUF_SIZE = 65536


def _script_pubkey_to_hash(spk):
    return hashlib.sha256(spk).digest()[::-1].hex()


def _address_to_hash(addr):
    script_pubkey = bitcoin.wallet.CBitcoinAddress(addr).to_scriptPubKey()
    return _script_pubkey_to_hash(script_pubkey)


# Basic class to communicate with addrindexrs.
# No locking thread.
# Assume only one instance of this class is used at a time and not concurrently.
# This class does not handle most of the errors, it's up to the caller to do so.
# This class assumes responses are always not longer than READ_BUF_SIZE (65536 bytes).
# This class assumes responses are always valid JSON.

ADDRINDEXRS_CLIENT_TIMEOUT = 60.0


class AddrindexrsSocketError(Exception):
    pass


class AddrindexrsSocketTimeoutError(Exception):
    pass


class AddrindexrsSocket:
    def __init__(self):
        self.next_message_id = 0
        self.connect()

    def connect(self):
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.settimeout(ADDRINDEXRS_CLIENT_TIMEOUT)
            self.sock.connect((config.INDEXD_CONNECT, config.INDEXD_PORT))
        except Exception:
            logger.warning("Failed to connect to addrindexrs, retrying in 10s...")
            time.sleep(10)
            self.connect()

    def _send(self, query, timeout=ADDRINDEXRS_CLIENT_TIMEOUT):
        query["id"] = self.next_message_id

        message = (json.dumps(query) + "\n").encode("utf8")

        self.sock.send(message)

        self.next_message_id += 1

        start_time = time.time()
        while True:
            try:
                data = self.sock.recv(READ_BUF_SIZE)
            except (TimeoutError, ConnectionResetError) as e:
                raise AddrindexrsSocketError("Timeout or connection reset. Please retry.") from e
            if data:
                response = json.loads(data.decode("utf-8"))  # assume valid JSON
                if "id" not in response:
                    raise AddrindexrsSocketError("No ID in response")
                if response["id"] != query["id"]:
                    raise AddrindexrsSocketError("ID mismatch in response")
                if "error" in response:
                    if response["error"] == "no txs for address":
                        return {}
                    raise AddrindexrsSocketError(response["error"])
                if "result" not in response:
                    raise AddrindexrsSocketError("No error and no result in response")
                return response["result"]

            duration = time.time() - start_time
            if duration > timeout:
                raise AddrindexrsSocketTimeoutError("Timeout. Please retry.")

    def send(self, query, timeout=ADDRINDEXRS_CLIENT_TIMEOUT, retry=0):
        try:
            return self._send(query, timeout=timeout)
        except BrokenPipeError:
            if retry > 3:
                raise Exception("Too many retries, please check addrindexrs")  # noqa: B904
            self.sock.close()
            self.connect()
            return self.send(query, timeout=timeout, retry=retry + 1)

    def get_oldest_tx(self, address, block_index, timeout=ADDRINDEXRS_CLIENT_TIMEOUT):
        try:
            hsh = _address_to_hash(address)
            query = {
                "method": "blockchain.scripthash.get_oldest_tx",
                "params": [hsh, block_index],
            }
            return self.send(query, timeout=timeout)
        except AddrindexrsSocketTimeoutError:
            logger.warning(
                f"Timeout when fetching oldest tx for {address} at block {block_index}. Retrying in 5s..."
            )
            time.sleep(5)
            self.sock.close()
            self.connect()
            return self.get_oldest_tx(address, block_index, timeout=timeout)


# We hardcoded certain addresses to reproduce or fix `addrindexrs` bug.
GET_OLDEST_TX_HARDCODED = {
    # In comments the real result that `addrindexrs` should have returned.
    "825096-bc1q66u8n4q0ld3furqugr0xzakpedrc00wv8fagmf": {},  # {'block_index': 820886, 'tx_hash': 'e5d130a583983e5d9a9a9175703300f7597eadb6b54fe775055110907b4079ed'}
    # In comments the buggy result that `addrindexrs` returned.
    "820326-1GsjsKKT4nH4GPmDnaxaZEDWgoBpmexwMA": {
        "block_index": 820321,
        "tx_hash": "b61ac3ab1ba9d63d484e8f83e8b9607bd932c8f4b742095445c3527ab575d972",
    },  # {}
}
ADDRINDEXRS_CLIENT = None


def get_oldest_tx(address: str, block_index: int):
    if block_index is None:
        raise ValueError("block_index is required")
    current_block_index = block_index
    hardcoded_key = f"{current_block_index}-{address}"
    if hardcoded_key in GET_OLDEST_TX_HARDCODED:
        result = GET_OLDEST_TX_HARDCODED[hardcoded_key]
    else:
        global ADDRINDEXRS_CLIENT  # noqa: PLW0603
        if ADDRINDEXRS_CLIENT is None:
            ADDRINDEXRS_CLIENT = AddrindexrsSocket()
        result = ADDRINDEXRS_CLIENT.get_oldest_tx(address, block_index=current_block_index)

    with open("oldest_tx.json", "a") as f:
        line_data = {f"{address}-{block_index}": result}
        f.write(json.dumps(line_data) + "\n")

    return result
