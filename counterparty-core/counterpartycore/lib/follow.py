import asyncio
import logging
import signal
import struct
import time
import traceback

import zmq
import zmq.asyncio

from counterpartycore.lib import blocks, config, mempool, util
from counterpartycore.lib.kickstart import blocks_parser

logger = logging.getLogger(config.LOGGER_NAME)

sequence_port = 28332
rawblock_port = 28333

MEMPOOL_BLOCK_MAX_SIZE = 100


class BlockchainWatcher:
    def __init__(self, db):
        logger.debug("Initializing blockchain watcher...")
        self.db = db
        self.loop = asyncio.get_event_loop()
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

        self.raw_tx_cache = {}
        self.decoded_tx_cache = {}
        self.decoded_block_cache = {}
        self.mempool_block = []
        self.mempool_block_hashes = []
        self.hash_by_sequence = {}
        self.last_block_check = 0

    def receive_message(self, topic, body, seq):
        sequence = "Unknown"
        if len(seq) == 4:
            sequence = str(struct.unpack("<I", seq)[-1])
        logger.trace("Received message: %s %s" % (topic, sequence))

        if topic == b"rawblock":
            # parse blocks as they come in
            mempool.clean_mempool(self.db)
            decoded_block = blocks_parser.BlockchainParser().deserialize_block(body.hex())
            util.CURRENT_BLOCK_INDEX += 1
            decoded_block["block_index"] = util.CURRENT_BLOCK_INDEX
            blocks.parse_new_block(self.db, decoded_block)
        elif topic == b"hashtx":
            self.hash_by_sequence[sequence] = body.hex()
        elif topic == b"rawtx":
            tx_hash = self.hash_by_sequence.get(sequence)
            if tx_hash not in self.raw_tx_cache:
                self.raw_tx_cache[tx_hash] = body.hex()
        elif topic == b"sequence":
            hash = body[:32].hex()
            label = chr(body[32])
            # new transaction in mempool
            if label == "A":
                if hash not in self.mempool_block_hashes:
                    self.mempool_block_hashes.append(hash)
                    # get transaction from cache
                    raw_tx = self.raw_tx_cache.get(hash)
                    # add transaction to mempool block
                    logger.trace("Adding transaction to mempool block: %s" % hash)
                    logger.trace("Mempool block size: %s" % len(self.mempool_block))
                    self.mempool_block.append(raw_tx)
                    if len(self.mempool_block) == MEMPOOL_BLOCK_MAX_SIZE:
                        mempool.parse_mempool_transactions(self.db, self.mempool_block)
                        self.mempool_block = []
                        self.mempool_block_hashes = []
            # transaction removed from mempool for non-block inclusion reasons
            elif label == "R":
                mempool.clean_transaction_events(self.db, hash)
            # block disconnected (reorg)
            elif label in ["D"]:
                mempool.clean_mempool(self.db)
                blocks.disconnect_block(self.db, hash)

    async def handle(self):
        try:
            # sequence topic
            topic, body, seq = await self.zmq_sub_socket_sequence.recv_multipart()
            self.receive_message(topic, body, seq)
            # rawblock topic
            if time.time() - self.last_block_check > 10:
                try:
                    topic, body, seq = await self.zmq_sub_socket_rawblock.recv_multipart(
                        flags=zmq.NOBLOCK
                    )
                    self.receive_message(topic, body, seq)
                except zmq.ZMQError:
                    logger.trace(
                        "No rawblock message available ---------------------------------------------------"
                    )
                    pass
                self.last_block_check = time.time()
        except Exception as e:
            print(traceback.format_exc())
            self.stop()
            raise e
        # schedule ourselves to receive the next message
        asyncio.ensure_future(self.handle())

    def start(self):
        logger.info("Starting blockchain watcher...")
        self.loop.add_signal_handler(signal.SIGINT, self.stop)
        self.loop.create_task(self.handle())
        self.loop.run_forever()

    def stop(self):
        self.loop.stop()
        self.zmq_context.destroy()
