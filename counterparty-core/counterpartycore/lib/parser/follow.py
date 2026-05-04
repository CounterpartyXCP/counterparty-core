import asyncio
import logging
import os
import struct
import threading
import time

import zmq
import zmq.asyncio
from sentry_sdk import capture_exception

from counterpartycore.lib import (
    backend,
    config,
    exceptions,
    ledger,
)
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.monitors import sentry
from counterpartycore.lib.monitors.telemetry.oneshot import TelemetryOneShot
from counterpartycore.lib.parser import blocks, check, deserialize, mempool
from counterpartycore.lib.utils import helpers

logger = logging.getLogger(config.LOGGER_NAME)


MEMPOOL_BLOCK_MAX_SIZE = 100
ZMQ_TIMEOUT = 3000

NOTIFICATION_TYPES = ["pubrawtx", "pubhashtx", "pubsequence", "pubrawblock"]

RAW_MEMPOOL = []


def get_zmq_notifications_addresses():
    try:
        zmq_notification = backend.bitcoind.get_zmq_notifications()
    except exceptions.BitcoindRPCError as e:
        raise exceptions.BitcoindZMQError("Error getting ZMQ notifications") from e

    if len(zmq_notification) == 0:
        raise exceptions.BitcoindZMQError("Bitcoin Core ZeroMQ notifications are not enabled.")

    notification_types = sorted([notification["type"] for notification in zmq_notification])
    if notification_types != sorted(NOTIFICATION_TYPES):
        raise exceptions.BitcoindZMQError(
            f"Bitcoin Core ZeroMQ notifications are incorrectly configured. The following notification must be enabled: {NOTIFICATION_TYPES}"
        )

    notification_addresses = {
        notification["type"]: notification["address"] for notification in zmq_notification
    }
    if (
        notification_addresses["pubrawtx"] != notification_addresses["pubhashtx"]
        or notification_addresses["pubrawtx"] != notification_addresses["pubsequence"]
    ):
        raise exceptions.BitcoindZMQError(
            "Bitcoin Core ZeroMQ notifications must use the same address for `pubhashtx`, `pubrawtx` and `pubsequence`."
        )

    pubrawtx_port = notification_addresses["pubrawtx"].split(":")[-1]
    pubrawblock_port = notification_addresses["pubrawblock"].split(":")[-1]
    pubrawtx_address = f"tcp://{config.BACKEND_CONNECT}:{pubrawtx_port}"
    pubrawblock_address = f"tcp://{config.BACKEND_CONNECT}:{pubrawblock_port}"

    return pubrawtx_address, pubrawblock_address


def start_blockchain_watcher(db):
    try:
        CurrentState().set_ledger_state(db, "Following")
        return BlockchainWatcher(db)
    except exceptions.BitcoindZMQError as e:
        logger.error(e)
        logger.warning("Sleeping 5 seconds, catching up again, then retrying...")
        time.sleep(5)
        blocks.catch_up(db)
        return start_blockchain_watcher(db)


class BlockchainWatcher:
    def __init__(self, db):
        logger.debug("Initializing blockchain watcher...")
        sentry.init()
        self.zmq_sequence_address, self.zmq_rawblock_address = get_zmq_notifications_addresses()
        self.db = db
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)
        # Pre-declare ZMQ attributes so connect_to_zmq() can safely close any
        # prior instance on reconnect without tripping pylint
        # access-member-before-definition warnings.
        self.zmq_context = None
        self.zmq_sub_socket_sequence = None
        self.zmq_sub_socket_rawblock = None
        self.connect_to_zmq()
        self.mempool_block = []
        self.mempool_block_hashes = []
        self.raw_tx_cache = {}
        self.hash_by_sequence = {}
        self.last_block_check_time = 0
        self.last_software_version_check_time = 0
        self.last_mempool_parsing_time = 0
        # catch up and clean mempool before starting
        self.stop_event = threading.Event()
        self.mempool_parser = None
        if not config.NO_MEMPOOL:
            mempool.clean_mempool(self.db)
            self.mempool_parser = RawMempoolParser(self.db)
            self.mempool_parser.start()

    def connect_to_zmq(self):
        # Close any prior sockets + context so a reconnect (called on
        # ZMQError in receive_multipart) doesn't leak file descriptors and
        # eventually exhaust the per-process limit on long-running indexers
        # with flapping ZMQ connections.
        if self.zmq_sub_socket_sequence is not None:
            try:
                self.zmq_sub_socket_sequence.close(linger=0)
            except Exception as e:  # pylint: disable=broad-except
                logger.debug("Error closing zmq_sub_socket_sequence: %s", e)
        if self.zmq_sub_socket_rawblock is not None:
            try:
                self.zmq_sub_socket_rawblock.close(linger=0)
            except Exception as e:  # pylint: disable=broad-except
                logger.debug("Error closing zmq_sub_socket_rawblock: %s", e)
        if self.zmq_context is not None:
            try:
                self.zmq_context.term()
            except Exception as e:  # pylint: disable=broad-except
                logger.debug("Error terminating zmq_context: %s", e)

        self.zmq_context = zmq.asyncio.Context()
        self.zmq_sub_socket_sequence = self.zmq_context.socket(zmq.SUB)
        self.zmq_sub_socket_sequence.setsockopt(zmq.RCVHWM, 0)
        self.zmq_sub_socket_sequence.setsockopt(zmq.RCVTIMEO, ZMQ_TIMEOUT)
        self.zmq_sub_socket_sequence.setsockopt_string(zmq.SUBSCRIBE, "rawtx")
        self.zmq_sub_socket_sequence.setsockopt_string(zmq.SUBSCRIBE, "hashtx")
        if not config.NO_MEMPOOL:
            self.zmq_sub_socket_sequence.setsockopt_string(zmq.SUBSCRIBE, "sequence")
        self.zmq_sub_socket_sequence.connect(self.zmq_sequence_address)
        self.zmq_sub_socket_rawblock = self.zmq_context.socket(zmq.SUB)
        self.zmq_sub_socket_rawblock.setsockopt(zmq.RCVHWM, 0)
        # Was setting RCVTIMEO on zmq_sub_socket_sequence twice (typo); rawblock
        # uses zmq.NOBLOCK at recv time so the missing timeout was harmless,
        # but make the timeout symmetric in case anyone removes NOBLOCK later.
        self.zmq_sub_socket_rawblock.setsockopt(zmq.RCVTIMEO, ZMQ_TIMEOUT)
        self.zmq_sub_socket_rawblock.setsockopt_string(zmq.SUBSCRIBE, "rawblock")
        self.zmq_sub_socket_rawblock.connect(self.zmq_rawblock_address)

    def check_software_version_if_needed(self):
        if time.time() - self.last_software_version_check_time > 60 * 60 * 24:
            checked = check.software_version()
            if checked:
                self.last_software_version_check_time = time.time()

    def receive_rawblock(self, body):
        # parse blocks as they come in
        try:
            decoded_block = deserialize.deserialize_block(
                body.hex(),
                parse_vouts=True,
                block_index=CurrentState().current_block_index() + 1,
            )
            # check if already parsed by block.catch_up()
            existing_block = ledger.blocks.get_block_by_hash(self.db, decoded_block["block_hash"])
            if existing_block is None:
                previous_block = ledger.blocks.get_block_by_hash(
                    self.db, decoded_block["hash_prev"]
                )
                if previous_block is None:
                    # catch up with rpc if previous block is missing
                    logger.debug("Previous block is missing. Catching up...")
                    blocks.catch_up(self.db)
                    CurrentState().set_ledger_state(self.db, "Following")
                    if not config.NO_MEMPOOL:
                        try:
                            mempool.clean_mempool(self.db)
                        except (
                            exceptions.BitcoindRPCError,
                            exceptions.BitcoindZMQError,
                        ) as e:
                            logger.warning(
                                "clean_mempool failed after catch_up (will retry next block): %s",
                                e,
                            )
                else:
                    # Atomic: parse_new_block + clean_mempool share one outer
                    # transaction so a reader (e.g. APIWatcher polling the
                    # ledger DB) cannot observe BLOCK_PARSED visible while
                    # the just-confirmed tx's mempool rows are still around.
                    # Without this, scenarios_test races on `mempool/events`
                    # being empty right after wait_for_counterparty_server
                    # returns: the APIWatcher had already seen the commit
                    # from parse_new_block (and bumped LAST_BLOCK_PARSED in
                    # state_db) while the separate clean_mempool DELETEs had
                    # not yet committed in ledger_db.
                    with self.db:
                        blocks.parse_new_block(self.db, decoded_block)
                        if not config.NO_MEMPOOL:
                            try:
                                mempool.clean_mempool(self.db)
                            except (
                                exceptions.BitcoindRPCError,
                                exceptions.BitcoindZMQError,
                            ) as e:
                                # A transient RPC failure inside getrawmempool
                                # must not roll back the just-parsed block;
                                # the next receive_rawblock will retry the
                                # mempool sweep. We still keep the block
                                # commit because chain progress is critical.
                                logger.warning(
                                    "clean_mempool failed (will retry next block): %s", e
                                )
                    CurrentState().set_ledger_state(self.db, "Following")
                if not config.NO_TELEMETRY:
                    TelemetryOneShot().submit()
        except exceptions.ParseTransactionError:
            # Consensus halt; let the outer handler stop the watcher.
            raise
        except Exception as e:  # pylint: disable=broad-except
            # Operational failures (malformed rawblock, transient telemetry/RPC
            # error) should not tear down the watcher -- next ZMQ message or
            # the next is_late() tick will trigger catch_up() to recover.
            logger.warning("receive_rawblock skipped: %s", e)
            capture_exception(e)

    def receive_hashtx(self, body, sequence):
        self.hash_by_sequence[sequence] = body.hex()

    def receive_rawtx(self, body, sequence):
        tx_hash = self.hash_by_sequence.get(sequence)
        if tx_hash is None:
            # when tx never seen in the mempool is included in a block
            decoded_tx = deserialize.deserialize_tx(body.hex())
            tx_hash = decoded_tx["tx_hash"]
        if sequence in self.hash_by_sequence:
            self.hash_by_sequence.pop(sequence)
        # first time seeing this transaction means from mempool
        if tx_hash not in self.raw_tx_cache:
            self.raw_tx_cache[tx_hash] = body.hex()
        # second time seeing this transaction means from valid block
        # we can remove it from the cache
        else:
            self.raw_tx_cache.pop(tx_hash)

    def need_to_parse_mempool_block(self):
        mempool_block_max_size = 100 if config.NETWORK_NAME == "mainnet" else 1
        mempool_block_timeout = 60 if config.NETWORK_NAME == "mainnet" else 5
        if len(self.mempool_block) == 0:
            return False
        if len(self.mempool_block) >= mempool_block_max_size:
            return True
        time_since_last_mempool_parsing = time.time() - self.last_mempool_parsing_time
        if time_since_last_mempool_parsing > mempool_block_timeout:
            return True
        return False

    def receive_sequence(self, body):
        item_hash = body[:32].hex()
        label = chr(body[32])
        # new transaction in mempool
        if label == "A":
            if item_hash not in self.mempool_block_hashes:
                self.mempool_block_hashes.append(item_hash)
                # get transaction from cache
                raw_tx = self.raw_tx_cache.get(item_hash)
                if raw_tx is None:
                    try:
                        raw_tx = backend.bitcoind.getrawtransaction(item_hash, no_retry=True)
                    except exceptions.BitcoindRPCError:
                        logger.warning("Transaction not found in bitcoind: %s", item_hash)
                        return
                # add transaction to mempool block
                # logger.trace("Adding transaction to mempool block: %s", item_hash)
                # logger.trace("Mempool block size: %s", len(self.mempool_block))
                self.mempool_block.append(raw_tx)
                # parse mempool block if needed
                if self.need_to_parse_mempool_block():
                    # parse mempool block
                    not_supported = mempool.parse_mempool_transactions(self.db, self.mempool_block)
                    NotSupportedTransactionsCache().add(not_supported)
                    self.last_mempool_parsing_time = time.time()
                    # reset mempool block
                    self.mempool_block = []
                    self.mempool_block_hashes = []
                    logger.trace("Waiting for new transactions in the mempool or a new block...")
        # transaction removed from mempool for non-block inclusion reasons
        elif label == "R":
            logger.debug("Removing transaction from mempool: %s", item_hash)
            mempool.clean_transaction_from_mempool(self.db, item_hash)

    def receive_message(self, topic, body, seq):
        sequence = "Unknown"
        if len(seq) == 4:
            sequence = str(struct.unpack("<I", seq)[-1])
        # logger.trace("Received message: %s %s", topic, sequence)
        if topic == b"rawblock":
            self.receive_rawblock(body)
        elif topic == b"hashtx":
            self.receive_hashtx(body, sequence)
        elif topic == b"rawtx":
            self.receive_rawtx(body, sequence)
        elif topic == b"sequence":
            self.receive_sequence(body)

    async def receive_multipart(self, socket, topic_name):
        try:
            flags = 0 if topic_name == "sequence" else zmq.NOBLOCK
            topic, body, seq = await socket.recv_multipart(flags=flags)
        except zmq.ZMQError as e:
            if e.errno == zmq.EAGAIN:
                logger.trace("No message available in topic `%s`", topic_name)
                return
            raise e
        except Exception as e:  # pylint: disable=broad-except
            logger.error("Error receiving message: %s. Reconnecting...", e)
            capture_exception(e)
            self.connect_to_zmq()
            return
        try:
            self.receive_message(topic, body, seq)
        except Exception as e:  # pylint: disable=broad-except
            logger.error("Error processing message: %s", e)
            # import traceback
            # print(traceback.format_exc())  # for debugging
            capture_exception(e)
            raise e

    def is_late(self):
        last_parsed_block = ledger.blocks.get_last_block(self.db)
        if last_parsed_block:
            last_parsed_block_index = last_parsed_block["block_index"]
            try:
                bitcoind_block_index = backend.bitcoind.getblockcount()
            except exceptions.BitcoindRPCError as e:
                # Don't tear down the watcher on a transient auth/RPC flap;
                # the outer handle() loop catches and stop()s on any raise.
                logger.warning("is_late: getblockcount failed: %s", e)
                return False
            return last_parsed_block_index < bitcoind_block_index
        return False

    async def handle(self):
        self.check_software_version_if_needed()
        late_since = None

        while not self.stop_event.is_set():
            try:
                if not config.NO_MEMPOOL:
                    if len(RAW_MEMPOOL) > 0:
                        mempool_block = RAW_MEMPOOL.pop(0)
                        logger.trace(
                            f"Processing {len(mempool_block)} transaction(s) from the raw mempool..."
                        )
                        not_supported_tx_hashes = mempool.parse_mempool_transactions(
                            self.db, mempool_block, timestamps=self.mempool_parser.timestamps
                        )
                        NotSupportedTransactionsCache().add(not_supported_tx_hashes)
                    else:
                        # sequence topic
                        await self.receive_multipart(self.zmq_sub_socket_sequence, "sequence")

                # check rawblock topic
                check_block_delay = 10 if config.NETWORK_NAME == "mainnet" else 0.5

                if time.time() - self.last_block_check_time > check_block_delay:
                    await self.receive_multipart(self.zmq_sub_socket_rawblock, "rawblock")
                    self.last_block_check_time = time.time()

                    if self.is_late():
                        if late_since is None:
                            late_since = time.time()
                    else:
                        late_since = None
                    if late_since is not None and time.time() - late_since > 60:
                        logger.warning("ZMQ is late. Catching up...")
                        blocks.catch_up(self.db)
                        CurrentState().set_ledger_state(self.db, "Following")
                        # Mirror the post-catch_up behaviour of receive_rawblock:
                        # without this sweep, any mempool tx that confirmed in
                        # the blocks parsed by catch_up() stays visible via
                        # `mempool/events` until the next ZMQ rawblock arrives,
                        # because clean_mempool only runs in receive_rawblock
                        # and at watcher startup. Same reason scenarios_test
                        # races on `mempool/events` after a `cancel` tx that
                        # was confirmed via this code path.
                        if not config.NO_MEMPOOL:
                            try:
                                mempool.clean_mempool(self.db)
                            except (
                                exceptions.BitcoindRPCError,
                                exceptions.BitcoindZMQError,
                            ) as e:
                                logger.warning(
                                    "clean_mempool failed after catch_up "
                                    "(will retry next block): %s",
                                    e,
                                )
                        late_since = None

                # Yield control to the event loop to allow other tasks to run
                await asyncio.sleep(0)
            except asyncio.CancelledError:
                logger.debug("BlockchainWatcher.handle() was cancelled.")
                break  # Exit the loop if the task is cancelled
            except Exception as e:  # pylint: disable=broad-except
                logger.error("Error in handle loop: %s", e)
                capture_exception(e)
                # import traceback
                # print(traceback.format_exc())  # for debugging
                self.stop()
                break  # Optionally break the loop on other exceptions

    def start(self):
        logger.debug("Starting blockchain watcher...")
        # Schedule the handle coroutine once
        self.task = self.loop.create_task(self.handle())
        try:
            self.loop.run_forever()
        finally:
            self.loop.close()

    def stop(self):
        # Protect entire shutdown from KeyboardInterrupt
        try:
            logger.debug("Stopping blockchain watcher...")
            # Signal the handle loop to stop
            self.stop_event.set()
            # Cancel the handle task
            if self.task and not self.task.done():
                self.task.cancel()
            # Stop the event loop (thread-safe in Python 3.9+)
            if self.loop.is_running():
                self.loop.call_soon_threadsafe(self.loop.stop)
            # Clean up ZMQ sockets and context
            try:
                # Close sockets first with linger=0 to avoid blocking
                self.zmq_sub_socket_sequence.setsockopt(zmq.LINGER, 0)
                self.zmq_sub_socket_sequence.close()
                self.zmq_sub_socket_rawblock.setsockopt(zmq.LINGER, 0)
                self.zmq_sub_socket_rawblock.close()
                self.zmq_context.term()
            except Exception as e:  # pylint: disable=broad-except
                logger.debug("Error cleaning up ZMQ: %s", e)
            # Stop mempool parser
            if self.mempool_parser:
                self.mempool_parser.stop()
            logger.debug("Blockchain watcher stopped.")
        except KeyboardInterrupt:
            pass  # Ignore repeated Ctrl+C during shutdown


def get_raw_mempool(db):
    logger.debug("Getting raw mempool...")
    raw_mempool = backend.bitcoind.getrawmempool(verbose=True)

    timestamps = {}
    cursor = db.cursor()
    txhash_list = []
    for txid, tx_info in raw_mempool.items():
        if NotSupportedTransactionsCache().is_not_supported(txid):
            continue
        existing_tx_in_mempool = cursor.execute(
            "SELECT * FROM mempool WHERE tx_hash = ? LIMIT 1", (txid,)
        ).fetchone()
        if existing_tx_in_mempool:
            continue
        txhash_list.append(txid)
        timestamps[txid] = tx_info["time"]

    chunks = helpers.chunkify(txhash_list, config.MAX_RPC_BATCH_SIZE)

    logger.debug("Found %s transaction(s) in the raw mempool...", len(txhash_list))
    return chunks, timestamps


class RawMempoolParser(threading.Thread):
    def __init__(self, db):
        threading.Thread.__init__(self, name="RawMempoolParser")
        self.db = db
        self.daemon = True
        self.stop_event = threading.Event()
        self.tx_hashes_chunks, self.timestamps = get_raw_mempool(self.db)

    def run(self):
        logger.debug("Starting RawMempoolParser...")
        start = time.time()

        counter = 0
        while len(self.tx_hashes_chunks) > 0 and not self.stop_event.is_set():
            txhash_list = self.tx_hashes_chunks.pop(0)
            logger.trace(
                f"Getting {len(txhash_list)} raw transactions by batch from the raw mempool..."
            )
            raw_transactions = backend.bitcoind.getrawtransaction_batch(txhash_list)
            RAW_MEMPOOL.append(raw_transactions)
            counter += len(txhash_list)
        elapsed = time.time() - start
        logger.debug(
            "RawMempoolParser stopped. %d transactions processed in %.2f seconds.", counter, elapsed
        )

    def stop(self):
        try:
            logger.debug("Stopping RawMempoolParser...")
            self.db.interrupt()
            self.stop_event.set()
            self.join(timeout=5)  # Don't wait forever
        except KeyboardInterrupt:
            pass  # Ignore repeated Ctrl+C during shutdown


class NotSupportedTransactionsCache(metaclass=helpers.SingletonMeta):
    def __init__(self):
        # Use set for O(1) lookups instead of O(n) list
        self.not_suppported_txs = set()
        # Keep a list for ordering (for backup/restore)
        self._ordered_txs = []
        self.cache_path = os.path.join(
            config.CACHE_DIR, f"not_supported_tx_cache.{config.NETWORK_NAME}.txt"
        )
        self.restore()

    def restore(self):
        if os.path.exists(self.cache_path):
            with open(self.cache_path, "r", encoding="utf-8") as f:
                self._ordered_txs = [line.strip() for line in f]
                self.not_suppported_txs = set(self._ordered_txs)
            logger.debug(
                "Restored %d not supported transactions from cache", len(self.not_suppported_txs)
            )

    def backup(self):
        with open(self.cache_path, "w", encoding="utf-8") as f:
            f.write("\n".join(self._ordered_txs))
        logger.trace(
            f"Backed up {len(self.not_suppported_txs)} not supported transactions to cache"
        )

    def clear(self):
        self.not_suppported_txs = set()
        self._ordered_txs = []
        if os.path.exists(self.cache_path):
            os.remove(self.cache_path)

    def add(self, more_not_supported_txs):
        for tx in more_not_supported_txs:
            if tx not in self.not_suppported_txs:
                self.not_suppported_txs.add(tx)
                self._ordered_txs.append(tx)
        self.backup()

    def is_not_supported(self, tx_hash):
        return tx_hash in self.not_suppported_txs
