import asyncio
import logging
import signal
import struct

import zmq
import zmq.asyncio

from counterpartycore.lib import blocks, config, mempool
from counterpartycore.lib.kickstart import blocks_parser

logger = logging.getLogger(config.LOGGER_NAME)

port = 28332


class BlockchainWatcher:
    def __init__(self, db):
        self.db = db
        self.loop = asyncio.get_event_loop()
        self.zmqContext = zmq.asyncio.Context()
        self.zmqSubSocket = self.zmqContext.socket(zmq.SUB)
        self.zmqSubSocket.setsockopt(zmq.RCVHWM, 0)
        self.zmqSubSocket.setsockopt_string(zmq.SUBSCRIBE, "rawblock")
        self.zmqSubSocket.setsockopt_string(zmq.SUBSCRIBE, "rawtx")
        self.zmqSubSocket.setsockopt_string(zmq.SUBSCRIBE, "sequence")
        self.zmqSubSocket.connect("tcp://127.0.0.1:%i" % port)
        self.decoded_tx_cache = {}
        self.block_cache = {}

    async def handle(self):
        topic, body, seq = await self.zmqSubSocket.recv_multipart()
        sequence = "Unknown"
        if len(seq) == 4:
            sequence = str(struct.unpack("<I", seq)[-1])
        logger.debug("Received message: %s %s" % (topic, sequence))

        if topic == b"rawblock":
            block = blocks_parser.BlockchainParser().deserialize_block(body.hex())
            if block["block_hash"] not in self.block_cache:
                self.block_cache[block["block_hash"]] = block
        elif topic == b"rawtx":
            # decode transactions as they come in
            tx = blocks_parser.BlockchainParser().deserialize_tx(body.hex())
            if tx["tx_hash"] not in self.decoded_tx_cache:
                self.decoded_tx_cache[tx["tx_hash"]] = tx
        elif topic == b"sequence":
            hash = body[:32].hex()
            label = chr(body[32])
            # new transaction in mempool
            if label == "A":
                # parse the transaction
                decoded_tx = self.decoded_tx_cache[hash]
                mempool.parse_mempool_transaction(self.db, decoded_tx)
            elif label == "R":
                # transaction removed from mempool for non-block inclusion reasons
                mempool.clean_transaction_events(self.db, hash)
            # new block connected
            elif label in ["C"]:
                mempool.clean_mempool(self.db)
                blocks.parse_new_block(self.db, self.block_cache[hash])
            # block disconnected (reorg)
            elif label in ["D"]:
                mempool.clean_mempool(self.db)
                blocks.disconnect_block(self.db, hash)
        # schedule ourselves to receive the next message
        if not self.paused:
            asyncio.ensure_future(self.handle())

    def start(self):
        self.loop.add_signal_handler(signal.SIGINT, self.stop)
        self.loop.create_task(self.handle())
        self.loop.run_forever()

    def stop(self):
        self.loop.stop()
        self.zmqContext.destroy()
