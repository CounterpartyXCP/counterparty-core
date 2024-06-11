import binascii
import logging
import multiprocessing
import os

# Used to pickle and unpickle blocks from shared_memory
import pickle  # nosec B403
import signal
from collections import OrderedDict
from multiprocessing import JoinableQueue, Process, shared_memory

import apsw

from counterpartycore.lib import config, deserialize, gettxinfo, util
from counterpartycore.lib.exceptions import DecodeError

from .bc_data_stream import BCDataStream
from .utils import (
    decode_value,
    ib2h,
    inverse_hash,
    remove_shm_from_resource_tracker,
)

logger = logging.getLogger(config.LOGGER_NAME)

import multiprocessing  # noqa: E402, F811

multiprocessing.set_start_method("spawn", force=True)

TX_CACHE_MAX_SIZE = 15000

DESERIALIZE_TX_CACHE_MAX_SIZE = 10000
DESERIALIZE_TX_CACHE = OrderedDict()


def open_leveldb(db_dir):
    try:
        import plyvel
    except:  # noqa: E722
        raise Exception("Please install the plyvel package via pip3.")  # noqa: B904

    try:
        return plyvel.DB(db_dir, create_if_missing=False, compression=None)
    except plyvel._plyvel.IOError as e:
        logger.info(str(e))
        raise Exception("Ensure that bitcoind is stopped.")  # noqa: B904


def fetch_blocks(bitcoind_dir, db_path, queue, first_block_index, parser_config):
    signal.signal(signal.SIGTERM, signal.SIG_DFL)
    signal.signal(signal.SIGINT, signal.default_int_handler)
    remove_shm_from_resource_tracker()

    for attribute in parser_config:
        setattr(config, attribute, parser_config[attribute])

    db = apsw.Connection(db_path, flags=apsw.SQLITE_OPEN_READONLY)
    cursor = db.cursor()
    try:
        cursor.execute(
            """SELECT block_hash, block_index FROM kickstart_blocks
                        WHERE block_index > ?
                        ORDER BY block_index
                        """,
            (first_block_index,),
        )
        all_blocks = cursor.fetchall()
        cursor.close()
        db.close()

        parser = BlockchainParser(bitcoind_dir)
        shm = None
        for db_block in all_blocks:
            if queue.full():
                logger.debug("Queue is full, waiting for blocks to be parsed.")
                queue.join()
            block = parser.read_raw_block(
                db_block[0],
                use_txid=util.enabled("correct_segwit_txids", block_index=db_block[1]),
            )

            util.CURRENT_BLOCK_INDEX = db_block[1]
            for i, transaction in enumerate(block["transactions"]):  # noqa: B007
                try:
                    block["transactions"][i]["parsed_vouts"] = gettxinfo.parse_transaction_vouts(
                        block["transactions"][i]
                    )
                except DecodeError:
                    block["transactions"][i]["parsed_vouts"] = "DecodeError"

            serialized_block = pickle.dumps(block, protocol=pickle.HIGHEST_PROTOCOL)
            block_length = len(serialized_block)
            name = db_block[0][-8:]
            try:
                shm = shared_memory.SharedMemory(name, create=True, size=block_length)
            except FileExistsError:
                shm = shared_memory.SharedMemory(name)
                shm.close()
                shm.unlink()
                shm = shared_memory.SharedMemory(name, create=True, size=block_length)
            shm.buf[:block_length] = serialized_block
            queue.put(shm.name)
            shm.close()
        queue.put(None)
    except KeyboardInterrupt:
        if shm:
            shm.close()
            shm.unlink()
    finally:
        parser.close()


class BlockchainParser:
    def __init__(self, bitcoind_dir=None, db_path=None, first_block_index=0, queue_size=100):
        self.blocks_dir = os.path.join(bitcoind_dir, "blocks")
        self.file_num = -1
        self.current_file_size = 0
        self.current_block_file = None
        self.data_stream = None
        self.shm = None
        self.queue = None

        self.tx_cache = OrderedDict()
        if db_path is not None:
            self.blocks_leveldb = None
            self.txindex_leveldb_path = os.path.join(bitcoind_dir, "indexes", "txindex")
            self.txindex_leveldb = open_leveldb(self.txindex_leveldb_path)
            self.queue = JoinableQueue(queue_size)
            parser_config = {}
            for attribute in dir(config):
                if attribute.isupper():
                    parser_config[attribute] = getattr(config, attribute)
            self.fetch_process = Process(
                target=fetch_blocks,
                args=(bitcoind_dir, db_path, self.queue, first_block_index, parser_config),
            )
            self.fetch_process.start()
        else:
            self.blocks_leveldb_path = os.path.join(self.blocks_dir, "index")
            self.blocks_leveldb = open_leveldb(self.blocks_leveldb_path)
            self.txindex_leveldb = None
            self.fetch_process = None

    def next_block(self, timeout=None):
        block_hash = self.queue.get(timeout=timeout)
        if block_hash is None:
            return None
        self.shm = shared_memory.SharedMemory(name=block_hash)
        block = pickle.loads(self.shm.buf[: self.shm.size])  # nosec B301  # noqa: S301
        self.shm.close()
        self.shm.unlink()
        return block

    def block_parsed(self):
        self.queue.task_done()

    def put_in_cache(self, transaction):
        # save transaction to cache
        self.tx_cache[transaction["tx_hash"]] = transaction
        if len(self.tx_cache) > TX_CACHE_MAX_SIZE:
            self.tx_cache.popitem(last=False)

    def prepare_data_stream(self, file_num, pos_in_file):
        if self.data_stream is None or file_num != self.file_num:
            self.file_num = file_num
            if self.current_block_file:
                self.current_block_file.close()
            data_file_path = os.path.join(self.blocks_dir, f"blk{self.file_num:05d}.dat")
            self.current_block_file = open(data_file_path, "rb")
            self.data_stream = BCDataStream()
            self.data_stream.map_file(self.current_block_file, pos_in_file)
        else:
            self.data_stream.seek_file(pos_in_file)

    def read_raw_block(self, block_hash, only_header=False, use_txid=True):
        block_key = bytes("b", "utf-8") + binascii.unhexlify(inverse_hash(block_hash))
        block_data = self.blocks_leveldb.get(block_key)
        ds = BCDataStream()
        ds.write(block_data)

        version = ds.read_var_int()  # noqa: F841
        height = ds.read_var_int()
        status = ds.read_var_int()  # noqa: F841
        tx_count = ds.read_var_int()
        file_num = ds.read_var_int()
        block_pos_in_file = ds.read_var_int() - 8
        block_undo_pos_in_file = ds.read_var_int()  # noqa: F841
        block_header = ds.read_bytes(80)  # noqa: F841
        self.prepare_data_stream(file_num, block_pos_in_file)
        block = deserialize.read_block(self.data_stream, only_header=only_header, use_txid=use_txid)
        block["block_index"] = height
        block["tx_count"] = tx_count
        return block

    def read_raw_transaction(self, tx_hash, use_txid=True):
        # return transaction from cache if exists
        if tx_hash in self.tx_cache:
            return self.tx_cache[tx_hash]
        # logger.warning('Transaction not found in cache, reading from disk.')

        tx_key = bytes("t", "utf-8") + binascii.unhexlify(inverse_hash(tx_hash))
        tx_data = self.txindex_leveldb.get(tx_key)

        ds = BCDataStream()
        ds.write(tx_data)

        file_num = ds.read_var_int()
        block_pos_in_file = ds.read_var_int()
        tx_pos_in_block = ds.read_var_int()
        tx_pos_in_file = block_pos_in_file + 80 + tx_pos_in_block

        self.prepare_data_stream(file_num, tx_pos_in_file)

        transaction = deserialize.read_transaction(self.data_stream, use_txid=use_txid)

        return transaction

    def close(self):
        if self.current_block_file:
            self.current_block_file.close()
        if self.blocks_leveldb:
            self.blocks_leveldb.close()
        if self.txindex_leveldb:
            self.txindex_leveldb.close()
        if self.fetch_process:
            self.fetch_process.terminate()
            self.fetch_process.join()
        if self.shm:
            try:
                self.shm.close()
                self.shm.unlink()
            except FileNotFoundError:
                pass
        if self.queue:
            self.queue.close()


class ChainstateParser:
    def __init__(self, leveldb_dir):
        self.ldb = open_leveldb(leveldb_dir)
        self.obfuscation_key = self.ldb.get(b"\x0e\x00obfuscate_key")[1:]

    def get_value(self, key):
        value = self.ldb.get(key)
        if value:
            value = decode_value(self.obfuscation_key, value)
        return value

    def get_last_block_hash(self):
        block_hash = self.get_value(bytes("B", "utf-8"))
        block_hash = ib2h(block_hash)
        return block_hash

    def close(self):
        self.ldb.close()
