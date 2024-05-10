import asyncio
import logging
import struct
import time
import traceback

import zmq
import zmq.asyncio

from counterpartycore.lib import blocks, config, deserialize, ledger, mempool

logger = logging.getLogger(config.LOGGER_NAME)

sequence_port = 28332
rawblock_port = 28333

MEMPOOL_BLOCK_MAX_SIZE = 100


class BlockchainWatcher:
    def __init__(self, db):
        logger.debug("Initializing blockchain watcher...")
        self.db = db
        self.loop = asyncio.get_event_loop()
        self.connect_to_zmq()
        self.mempool_block = []
        self.mempool_block_hashes = []
        self.raw_tx_cache = {}
        self.hash_by_sequence = {}
        self.last_block_check_time = 0
        # clean mempool before starting
        mempool.clean_mempool(self.db)

    def connect_to_zmq(self):
        self.zmq_context = zmq.asyncio.Context()
        self.zmq_sub_socket_sequence = self.zmq_context.socket(zmq.SUB)
        self.zmq_sub_socket_sequence.setsockopt(zmq.RCVHWM, 0)
        self.zmq_sub_socket_sequence.setsockopt_string(zmq.SUBSCRIBE, "rawtx")
        self.zmq_sub_socket_sequence.setsockopt_string(zmq.SUBSCRIBE, "hashtx")
        self.zmq_sub_socket_sequence.setsockopt_string(zmq.SUBSCRIBE, "sequence")
        self.zmq_sub_socket_sequence.connect("tcp://127.0.0.1:%i" % sequence_port)
        self.zmq_sub_socket_rawblock = self.zmq_context.socket(zmq.SUB)
        self.zmq_sub_socket_rawblock.setsockopt(zmq.RCVHWM, 0)
        self.zmq_sub_socket_rawblock.setsockopt_string(zmq.SUBSCRIBE, "rawblock")
        self.zmq_sub_socket_rawblock.connect("tcp://127.0.0.1:%i" % rawblock_port)

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
        hash = body[:32].hex()
        label = chr(body[32])
        # new transaction in mempool
        if label == "A":
            if hash not in self.mempool_block_hashes:
                self.mempool_block_hashes.append(hash)
                # get transaction from cache
                raw_tx = self.raw_tx_cache[hash]
                # add transaction to mempool block
                logger.trace("Adding transaction to mempool block: %s" % hash)
                logger.trace("Mempool block size: %s" % len(self.mempool_block))
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
            mempool.clean_transaction_events(self.db, hash)

    def receive_message(self, topic, body, seq):
        sequence = "Unknown"
        if len(seq) == 4:
            sequence = str(struct.unpack("<I", seq)[-1])
        logger.trace("Received message: %s %s" % (topic, sequence))
        if topic == b"rawblock":
            self.receive_rawblock(body)
        elif topic == b"hashtx":
            self.receive_hashtx(body, sequence)
        elif topic == b"rawtx":
            self.receive_rawtx(body, sequence)
        elif topic == b"sequence":
            self.receive_sequence(body)

    async def handle(self):
        try:
            # sequence topic
            topic, body, seq = await self.zmq_sub_socket_sequence.recv_multipart()
            self.receive_message(topic, body, seq)
            # check every 10 seconds rawblock topic
            if time.time() - self.last_block_check_time > 10:
                try:
                    topic, body, seq = await self.zmq_sub_socket_rawblock.recv_multipart(
                        flags=zmq.NOBLOCK
                    )
                    self.receive_message(topic, body, seq)
                except zmq.ZMQError:
                    logger.trace("No rawblock message available")
                    pass
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
