import asyncio
import logging
import struct
import time

import zmq
import zmq.asyncio
from sentry_sdk import capture_exception

from counterpartycore.lib import (
    backend,
    blocks,
    check,
    config,
    deserialize,
    exceptions,
    ledger,
    mempool,
    sentry,
    util,
)
from counterpartycore.lib.telemetry.oneshot import TelemetryOneShot

logger = logging.getLogger(config.LOGGER_NAME)


MEMPOOL_BLOCK_MAX_SIZE = 100
ZMQ_TIMEOUT = 3000

NOTIFICATION_TYPES = ["pubrawtx", "pubhashtx", "pubsequence", "pubrawblock"]


def get_zmq_notifications_addresses():
    zmq_notification = backend.bitcoind.get_zmq_notifications()

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
        follower_daemon = BlockchainWatcher(db)
        follower_daemon.start()
        return follower_daemon
    except exceptions.BitcoindZMQError as e:
        logger.error(e)
        logger.warning("Sleeping 5 seconds, catching up again, then retrying...")
        time.sleep(5)
        blocks.catch_up(db, check_asset_conservation=False)
        return start_blockchain_watcher(db)


class BlockchainWatcher:
    def __init__(self, db):
        logger.debug("Initializing blockchain watcher...")
        sentry.init()
        self.zmq_sequence_address, self.zmq_rawblock_address = get_zmq_notifications_addresses()
        self.db = db
        self.loop = asyncio.get_event_loop()
        self.connect_to_zmq()
        self.mempool_block = []
        self.mempool_block_hashes = []
        self.raw_tx_cache = {}
        self.hash_by_sequence = {}
        self.last_block_check_time = 0
        self.last_software_version_check_time = 0
        # catch up and clean mempool before starting
        if not config.NO_MEMPOOL:
            mempool.parse_raw_mempool(self.db)
            mempool.clean_mempool(self.db)

    def connect_to_zmq(self):
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
        self.zmq_sub_socket_sequence.setsockopt(zmq.RCVTIMEO, ZMQ_TIMEOUT)
        self.zmq_sub_socket_rawblock.setsockopt_string(zmq.SUBSCRIBE, "rawblock")
        self.zmq_sub_socket_rawblock.connect(self.zmq_rawblock_address)

    def check_software_version_if_needed(self):
        if time.time() - self.last_software_version_check_time > 60 * 60 * 24:
            checked = check.software_version()
            if checked:
                self.last_software_version_check_time = time.time()

    def receive_rawblock(self, body):
        # parse blocks as they come in
        decoded_block = deserialize.deserialize_block(body.hex(), use_txid=True)
        # check if already parsed by block.catch_up()
        existing_block = ledger.get_block_by_hash(self.db, decoded_block["block_hash"])
        if existing_block is None:
            previous_block = ledger.get_block_by_hash(self.db, decoded_block["hash_prev"])
            if previous_block is None:
                # catch up with rpc if previous block is missing
                logger.debug("Previous block is missing. Catching up...")
                blocks.catch_up(self.db, check_asset_conservation=False)
            else:
                blocks.parse_new_block(self.db, decoded_block)
            mempool.clean_mempool(self.db)
            if not config.NO_TELEMETRY:
                TelemetryOneShot().submit()

    def receive_hashtx(self, body, sequence):
        self.hash_by_sequence[sequence] = body.hex()

    def receive_rawtx(self, body, sequence):
        tx_hash = self.hash_by_sequence.get(sequence)
        if tx_hash is None:
            # when tx never seen in the mempool is included in a block
            decoded_tx = deserialize.deserialize_tx(body.hex(), use_txid=True)
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
                        raw_tx = backend.bitcoind.getrawtransaction(item_hash)
                    except exceptions.BitcoindRPCError:
                        logger.trace("Transaction not found in bitcoind: %s", item_hash)
                        return
                # add transaction to mempool block
                # logger.trace("Adding transaction to mempool block: %s", item_hash)
                # logger.trace("Mempool block size: %s", len(self.mempool_block))
                self.mempool_block.append(raw_tx)
                mempool_block_max_size = 100 if config.NETWORK_NAME == "mainnet" else 1
                if len(self.mempool_block) == mempool_block_max_size:
                    # parse mempool block
                    mempool.parse_mempool_transactions(self.db, self.mempool_block)
                    # reset mempool block
                    self.mempool_block = []
                    self.mempool_block_hashes = []
                    logger.debug("Waiting for new transactions from mempool or new block...")
        # transaction removed from mempool for non-block inclusion reasons
        elif label == "R":
            mempool.clean_transaction_events(self.db, item_hash)

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
        except Exception as e:
            logger.error("Error receiving message: %s. Reconnecting...", e)
            capture_exception(e)
            self.connect_to_zmq()
            return
        try:
            self.receive_message(topic, body, seq)
        except Exception as e:
            logger.error("Error processing message: %s", e)
            # import traceback
            # print(traceback.format_exc())  # for debugging
            capture_exception(e)
            raise e

    async def handle(self):
        self.check_software_version_if_needed()
        util.BLOCK_PARSER_STATUS = "following"

        # sequence topic
        if not config.NO_MEMPOOL:
            await self.receive_multipart(self.zmq_sub_socket_sequence, "sequence")
        # check rawblock topic
        check_block_delay = 10 if config.NETWORK_NAME == "mainnet" else 0.5
        if time.time() - self.last_block_check_time > check_block_delay:
            await self.receive_multipart(self.zmq_sub_socket_rawblock, "rawblock")
            self.last_block_check_time = time.time()

        # schedule ourselves to receive the next message
        asyncio.ensure_future(self.handle())

    def start(self):
        logger.debug("Starting blockchain watcher...")
        self.loop.create_task(self.handle())
        self.loop.run_forever()

    def stop(self):
        logger.debug("Stopping blockchain watcher...")
        self.loop.stop()
        self.zmq_context.destroy()
