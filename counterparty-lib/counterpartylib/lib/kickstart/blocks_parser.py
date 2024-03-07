import os, logging, binascii
from multiprocessing import Process, JoinableQueue, shared_memory
from collections import OrderedDict
# Used to pickle and unpickle blocks from shared_memory
import pickle # nosec B403
import signal
import time

import apsw

from .bc_data_stream import BCDataStream
from .utils import b2h, double_hash, ib2h, inverse_hash, decode_value, remove_shm_from_resource_tracker
from counterpartylib.lib import ledger, config, gettxinfo
from counterpartylib.lib.exceptions import DecodeError

logger = logging.getLogger(__name__)

import multiprocessing
multiprocessing.set_start_method("spawn", force=True)

TX_CACHE_MAX_SIZE = 15000

def open_leveldb(db_dir):
    try:
        import plyvel
    except:
        raise Exception("Please install the plyvel package via pip3.")

    try:
        return plyvel.DB(db_dir, create_if_missing=False, compression=None)
    except plyvel._plyvel.IOError as e:
        logger.info(str(e))
        raise Exception("Ensure that bitcoind is stopped.")


def fetch_blocks(bitcoind_dir, db_path, queue, first_block_index, parser_config):
    signal.signal(signal.SIGTERM, signal.SIG_DFL)
    signal.signal(signal.SIGINT, signal.default_int_handler)
    remove_shm_from_resource_tracker()

    for attribute in parser_config:
        setattr(config, attribute, parser_config[attribute])

    db = apsw.Connection(db_path, flags=apsw.SQLITE_OPEN_READONLY)
    cursor = db.cursor()
    try:
        cursor.execute('''SELECT block_hash, block_index FROM kickstart_blocks
                        WHERE block_index > ?
                        ORDER BY block_index
                        ''',
                        (first_block_index ,))
        all_blocks = cursor.fetchall()
        cursor.close()
        db.close()

        parser = BlockchainParser(bitcoind_dir)
        shm = None
        for db_block in all_blocks:
            if queue.full():
                logger.debug('Queue is full, waiting for blocks to be parsed.')
                queue.join()
            block = parser.read_raw_block(
                db_block[0],
                use_txid=ledger.enabled("correct_segwit_txids", block_index=db_block[1])
            )

            ledger.CURRENT_BLOCK_INDEX = db_block[1]
            for i, transaction in enumerate(block['transactions']):
                try:
                    block['transactions'][i]['parsed_vouts'] = gettxinfo.parse_transaction_vouts(block['transactions'][i])
                except DecodeError:
                    block['transactions'][i]['parsed_vouts'] = "DecodeError"

            serialized_block = pickle.dumps(block, protocol=pickle.HIGHEST_PROTOCOL)
            block_length = len(serialized_block)
            name = db_block[0][-8:]
            try:
                shm = shared_memory.SharedMemory(name, create=True, size=block_length)
            except FileExistsError:
                shm = shared_memory.SharedMemory(name)
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


class BlockchainParser():

    def __init__(self, bitcoind_dir=None, db_path=None, first_block_index=0, queue_size=100):
        if bitcoind_dir is None: # for deserialize_tx()
            return

        self.blocks_dir = os.path.join(bitcoind_dir, 'blocks')
        self.file_num = -1
        self.current_file_size = 0
        self.current_block_file = None
        self.data_stream = None
        self.shm = None
        self.queue = None

        self.tx_cache = OrderedDict()
        if db_path is not None:
            self.blocks_leveldb = None
            self.txindex_leveldb_path = os.path.join(bitcoind_dir, 'indexes', 'txindex')
            self.txindex_leveldb = open_leveldb(self.txindex_leveldb_path)
            self.queue = JoinableQueue(queue_size)
            parser_config = {}
            for attribute in dir(config):
                if attribute.isupper():
                    parser_config[attribute] = getattr(config, attribute)
            self.fetch_process = Process(target=fetch_blocks, args=(
                bitcoind_dir, db_path, self.queue, first_block_index, parser_config
            ))
            self.fetch_process.start()
        else:
            self.blocks_leveldb_path = os.path.join(self.blocks_dir, 'index')
            self.blocks_leveldb = open_leveldb(self.blocks_leveldb_path)
            self.txindex_leveldb = None
            self.fetch_process = None


    def next_block(self, timeout=None):
        block_hash = self.queue.get(timeout=timeout)
        if block_hash is None:
            return None
        self.shm = shared_memory.SharedMemory(name=block_hash)
        block = pickle.loads(self.shm.buf[:self.shm.size]) # nosec B301
        self.shm.close()
        self.shm.unlink()
        return block


    def block_parsed(self):
        self.queue.task_done()


    def read_tx_in(self, vds):
        tx_in = {}
        tx_in["hash"] = vds.read_bytes(32)
        tx_in["n"] = vds.read_uint32()
        script_sig_size = vds.read_compact_size()
        tx_in['scriptSig'] = vds.read_bytes(script_sig_size)
        tx_in['nSequence'] = vds.read_uint32()
        tx_in['coinbase'] = False
        if tx_in['hash'] == b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00':
            tx_in['coinbase'] = True
        return tx_in


    def read_tx_out(self, vds):
        tx_out = {}
        tx_out['nValue'] = vds.read_int64()
        script = vds.read_bytes(vds.read_compact_size())
        tx_out['scriptPubKey'] = script
        return tx_out


    def read_transaction(self, vds, use_txid=True):
        transaction = {}
        start_pos = vds.read_cursor
        transaction['version'] = vds.read_int32()

        flag = vds.read_bytes(2)
        if flag == b'\x00\x01':
            transaction['segwit'] = True
        else:
            transaction['segwit'] = False
            vds.read_cursor = vds.read_cursor - 2

        transaction['coinbase'] = False
        transaction['vin'] = []
        for i in range(vds.read_compact_size()):
            vin = self.read_tx_in(vds)
            transaction['vin'].append(vin)
            transaction['coinbase'] = transaction['coinbase'] or vin['coinbase']

        transaction['vout'] = []
        for i in range(vds.read_compact_size()):
            transaction['vout'].append(self.read_tx_out(vds))

        transaction['vtxinwit'] = []
        if transaction['segwit']:
            offset_before_tx_witnesses = vds.read_cursor - start_pos
            for vin in transaction['vin']:
                witnesses_count = vds.read_compact_size()
                for i in range(witnesses_count):
                    witness_length = vds.read_compact_size()
                    witness = vds.read_bytes(witness_length)
                    transaction['vtxinwit'].append(witness)

        transaction['lock_time'] = vds.read_uint32()
        data = vds.input[start_pos:vds.read_cursor]

        transaction['tx_hash'] = ib2h(double_hash(data))
        if transaction['segwit']:
            hash_data = data[:4] + data[6:offset_before_tx_witnesses] + data[-4:]
            transaction['tx_id'] = ib2h(double_hash(hash_data))
            if use_txid:
                transaction['tx_hash'] = transaction['tx_id']

        transaction['__data__'] = b2h(data)

        return transaction


    def put_in_cache(self, transaction):
        # save transaction to cache
        self.tx_cache[transaction['tx_hash']] = transaction
        if len(self.tx_cache) > TX_CACHE_MAX_SIZE:
            self.tx_cache.popitem(last=False)


    def read_block_header(self, vds):
        block_header = {}
        block_header['magic_bytes'] = vds.read_int32()
        #if block_header['magic_bytes'] != 118034699:
        #   raise Exception('Not a block')
        block_header['block_size'] = vds.read_int32()
        header_start = vds.read_cursor
        block_header['version'] = vds.read_int32()
        block_header['hash_prev'] = ib2h(vds.read_bytes(32))
        block_header['hash_merkle_root'] = ib2h(vds.read_bytes(32))
        block_header['block_time'] = vds.read_uint32()
        block_header['bits'] = vds.read_uint32()
        block_header['nonce'] = vds.read_uint32()
        header_end = vds.read_cursor
        header = vds.input[header_start:header_end]
        block_header['block_hash'] = ib2h(double_hash(header))
        #block_header['__header__'] = b2h(header)
        return block_header


    def read_block(self, vds, only_header=False, use_txid=True):
        block = self.read_block_header(vds)
        if only_header:
            return block
        block['transaction_count'] = vds.read_compact_size()
        block['transactions'] = []
        for i in range(block['transaction_count']):
            block['transactions'].append(self.read_transaction(vds, use_txid=use_txid))
        return block


    def prepare_data_stream(self, file_num, pos_in_file):
        if self.data_stream is None or file_num != self.file_num:
            self.file_num = file_num
            if self.current_block_file:
                self.current_block_file.close()
            data_file_path = os.path.join(self.blocks_dir, f'blk{self.file_num:05d}.dat')
            self.current_block_file = open(data_file_path, "rb")
            self.data_stream = BCDataStream()
            self.data_stream.map_file(self.current_block_file, pos_in_file)
        else:
            self.data_stream.seek_file(pos_in_file)

    def read_raw_block(self, block_hash, only_header=False, use_txid=True):
        #print('Reading raw block:', block_hash, only_header)
        block_key = bytes('b', 'utf-8') + binascii.unhexlify(inverse_hash(block_hash))
        block_data = self.blocks_leveldb.get(block_key)
        ds = BCDataStream()
        ds.write(block_data)

        version = ds.read_var_int()
        height = ds.read_var_int()
        status = ds.read_var_int()
        tx_count = ds.read_var_int()
        file_num = ds.read_var_int()
        block_pos_in_file = ds.read_var_int() - 8
        block_undo_pos_in_file = ds.read_var_int()
        block_header = ds.read_bytes(80)
        self.prepare_data_stream(file_num, block_pos_in_file)
        block = self.read_block(self.data_stream, only_header=only_header, use_txid=use_txid)
        block['block_index'] = height
        block['tx_count'] = tx_count
        return block

    def read_raw_transaction(self, tx_hash, use_txid=True):
        # return transaction from cache if exists
        if tx_hash in self.tx_cache:
            return self.tx_cache[tx_hash]
        #logger.warning('Transaction not found in cache, reading from disk.')

        tx_key = bytes('t', 'utf-8') + binascii.unhexlify(inverse_hash(tx_hash))
        tx_data = self.txindex_leveldb.get(tx_key)

        ds = BCDataStream()
        ds.write(tx_data)

        file_num = ds.read_var_int()
        block_pos_in_file = ds.read_var_int()
        tx_pos_in_block = ds.read_var_int()
        tx_pos_in_file = block_pos_in_file + 80 + tx_pos_in_block

        self.prepare_data_stream(file_num, tx_pos_in_file)

        transaction = self.read_transaction(self.data_stream, use_txid=use_txid)

        return transaction


    def deserialize_tx(self, tx_hex, use_txid=None):
        ds = BCDataStream()
        ds.map_hex(tx_hex)
        if use_txid is None:
            use_txid = ledger.enabled("correct_segwit_txids")
        return self.read_transaction(
            ds,
            use_txid=use_txid
        )


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


class ChainstateParser():

    def __init__(self, leveldb_dir):
        self.ldb = open_leveldb(leveldb_dir)
        self.obfuscation_key = self.ldb.get(b'\x0e\x00obfuscate_key')[1:]

    def get_value(self, key):
        value = self.ldb.get(key)
        if value:
            value = decode_value(self.obfuscation_key, value)
        return value

    def get_last_block_hash(self):
        block_hash = self.get_value(bytes('B', 'utf-8'))
        block_hash = ib2h(block_hash)
        return block_hash

    def close(self):
        self.ldb.close()