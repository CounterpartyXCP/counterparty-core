import asyncio
import logging
import struct
import time
import traceback

import zmq
import zmq.asyncio

from counterpartycore.lib import (
    backend,
    blocks,
    check,
    config,
    deserialize,
    exceptions,
    ledger,
    mempool,
)

logger = logging.getLogger(config.LOGGER_NAME)


MEMPOOL_BLOCK_MAX_SIZE = 100

NOTIFICATION_TYPES = ["pubrawtx", "pubhashtx", "pubsequence", "pubrawblock"]


def get_zmq_notifications_addresses():
    zmq_notification = backend.bitcoind.get_zmq_notifications()

    if len(zmq_notification) == 0:
        raise exceptions.BitcoindZMQError("Bitcoin Core was started without ZMQ notifications.")

    notification_types = sorted([notification["type"] for notification in zmq_notification])
    if notification_types != sorted(NOTIFICATION_TYPES):
        raise exceptions.BitcoindZMQError(
            f"Bitcoin Core ZMQ notifications are incorrect. The following notification must be enabled: {NOTIFICATION_TYPES}"
        )

    notification_addresses = {
        notification["type"]: notification["address"] for notification in zmq_notification
    }
    if (
        notification_addresses["pubrawtx"] != notification_addresses["pubhashtx"]
        or notification_addresses["pubrawtx"] != notification_addresses["pubsequence"]
    ):
        raise exceptions.BitcoindZMQError(
            "Bitcoin Core ZMQ notifications must use the same address for `pubhashtx`, `pubrawtx` and `pubsequence`."
        )

    return notification_addresses["pubrawtx"], notification_addresses["pubrawblock"]


def start_blockchain_watcher(db):
    try:
        follower_daemon = BlockchainWatcher(db)
        follower_daemon.start()
        return follower_daemon
    except exceptions.BitcoindZMQError as e:
        logger.error(e)
        logger.warning("Sleeping 5 seconds, catching up again then retrying...")
        time.sleep(5)
        blocks.catch_up(db, check_asset_conservation=False)
        return start_blockchain_watcher(db)


class BlockchainWatcher:
    def __init__(self, db):
        logger.debug("Initializing blockchain watcher...")
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
        # clean mempool before starting
        mempool.clean_mempool(self.db)

    def connect_to_zmq(self):
        self.zmq_context = zmq.asyncio.Context()
        self.zmq_sub_socket_sequence = self.zmq_context.socket(zmq.SUB)
        self.zmq_sub_socket_sequence.setsockopt(zmq.RCVHWM, 0)
        self.zmq_sub_socket_sequence.setsockopt(zmq.RCVTIMEO, 1000)
        self.zmq_sub_socket_sequence.setsockopt_string(zmq.SUBSCRIBE, "rawtx")
        self.zmq_sub_socket_sequence.setsockopt_string(zmq.SUBSCRIBE, "hashtx")
        self.zmq_sub_socket_sequence.setsockopt_string(zmq.SUBSCRIBE, "sequence")
        self.zmq_sub_socket_sequence.connect(self.zmq_sequence_address)
        self.zmq_sub_socket_rawblock = self.zmq_context.socket(zmq.SUB)
        self.zmq_sub_socket_rawblock.setsockopt(zmq.RCVHWM, 0)
        self.zmq_sub_socket_sequence.setsockopt(zmq.RCVTIMEO, 1000)
        self.zmq_sub_socket_rawblock.setsockopt_string(zmq.SUBSCRIBE, "rawblock")
        self.zmq_sub_socket_rawblock.connect(self.zmq_rawblock_address)

    def check_software_version_if_needed(self):
        if time.time() - self.last_software_version_check_time > 60 * 60 * 24:
            check.software_version()
            self.last_software_version_check_time = time.time()

    def receive_rawblock(self, body):
        # parse blocks as they come in
        decoded_block = deserialize.deserialize_block(body.hex(), use_txid=True)
        # check if already parsed by block.catch_up()
        existing_block = ledger.get_block_by_hash(self.db, decoded_block["block_hash"])
        if existing_block is None:
            blocks.parse_new_block(self.db, decoded_block)
            mempool.clean_mempool(self.db)

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
                if len(self.mempool_block) == MEMPOOL_BLOCK_MAX_SIZE:
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
        except zmq.ZMQError:
            logger.trace("No message available in topic %s", topic_name)
            return
        self.receive_message(topic, body, seq)

    async def handle(self):
        self.check_software_version_if_needed()
        try:
            # sequence topic
            await self.receive_multipart(self.zmq_sub_socket_sequence, "sequence")
            # check every 10 seconds rawblock topic
            if time.time() - self.last_block_check_time > 10:
                await self.receive_multipart(self.zmq_sub_socket_rawblock, "rawblock")
                self.last_block_check_time = time.time()
        except Exception as e:
            logger.error(traceback.format_exc())
            self.stop()
            raise e
        # schedule ourselves to receive the next message
        asyncio.ensure_future(self.handle())

    def start(self):
        logger.info("Starting blockchain watcher...")
        self.loop.create_task(self.handle())
        self.loop.run_forever()

    def stop(self):
        logger.info("Stopping blockchain watcher...")
        self.loop.stop()
        self.zmq_context.destroy()
