import os, json, time, logging, binascii
import logging
logger = logging.getLogger(__name__)

from .bc_data_stream import BCDataStream
from .utils import b2h, double_hash, ib2h, inverse_hash

def open_leveldb(db_dir):
    try:
        import plyvel
    except:
        raise Exception("Please install the plyvel package via pip3.")

    try:
        return plyvel.DB(db_dir, create_if_missing=False)
    except plyvel._plyvel.IOError as e:
        logger.info(str(e))
        raise Exception("Ensure that bitcoind is stopped.")

class BlockchainParser():

    def __init__(self, blocks_dir, leveldb_dir):
        self.blocks_dir = blocks_dir 
        self.leveldb_dir = leveldb_dir
        self.file_num = -1
        self.current_file_size = 0
        self.current_block_file = None
        self.data_stream = None
        self.ldb = open_leveldb(self.leveldb_dir)

    def read_tx_in(self, vds):
        tx_in = {}
        tx_in['txid'] = ib2h(vds.read_bytes(32))
        tx_in['vout'] = vds.read_uint32()
        script_sig_size = vds.read_compact_size()
        tx_in['scriptSig'] = b2h(vds.read_bytes(script_sig_size))
        tx_in['sequence'] = vds.read_uint32()
        if tx_in['txid'] == '0000000000000000000000000000000000000000000000000000000000000000':
            tx_in = {
                'coinbase': tx_in['scriptSig'],
                'sequence': tx_in['sequence']
            }
        return tx_in

    def read_tx_out(self, vds):
        tx_out = {}
        tx_out['value'] = vds.read_int64() / 100000000
        script = vds.read_bytes(vds.read_compact_size())
        tx_out['scriptPubKey'] = {
            'hex': b2h(script)
        }
        return tx_out

    def read_transaction(self, vds):
        transaction = {}
        start_pos = vds.read_cursor
        transaction['version'] = vds.read_int32()

        transaction['vin'] = []
        for i in range(vds.read_compact_size()):
            transaction['vin'].append(self.read_tx_in(vds))

        transaction['vout'] = []
        for i in range(vds.read_compact_size()):
            transaction['vout'].append(self.read_tx_out(vds))

        transaction['lock_time'] = vds.read_uint32()
        data = vds.input[start_pos:vds.read_cursor]
        transaction['tx_hash'] = ib2h(double_hash(data))
        transaction['__data__'] = b2h(data)
        return transaction

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
        block_header['__header__'] = b2h(header)
        return block_header

    def read_block(self, vds):
        block = self.read_block_header(vds)
        block['transaction_count'] = vds.read_compact_size()
        block['transactions'] = []
        for i in range(block['transaction_count']):
            block['transactions'].append(self.read_transaction(vds))
        return block

    def prepare_data_stream(self, file_num, pos_in_file):
        if self.data_stream is None or file_num != self.file_num:
            self.file_num = file_num
            if self.current_block_file:
                self.current_block_file.close()
            data_file_path = os.path.join(self.blocks_dir, 'blk%05d.dat' % (self.file_num,))
            self.current_block_file = open(data_file_path, "rb")
            self.data_stream = BCDataStream()
            self.data_stream.map_file(self.current_block_file, pos_in_file)
        else:
            self.data_stream.seek_file(pos_in_file)

    def read_raw_block(self, block_hash):
        block_hash = binascii.unhexlify(inverse_hash(block_hash))
        block_data = self.ldb.get(bytes('b', 'utf-8') + block_hash)
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

        block = self.read_block(self.data_stream)
        block['block_index'] = height

        return block

    def read_raw_transaction(self, tx_hash):
        tx_hash = binascii.unhexlify(inverse_hash(tx_hash))
        tx_data = self.ldb.get(bytes('t', 'utf-8') + tx_hash)
 
        ds = BCDataStream()
        ds.write(tx_data)

        file_num = ds.read_var_int()
        block_pos_in_file = ds.read_var_int()
        tx_pos_in_block = ds.read_var_int()
        tx_pos_in_file = block_pos_in_file + 80 + tx_pos_in_block
        
        self.prepare_data_stream(file_num, tx_pos_in_file)

        transaction = self.read_transaction(self.data_stream)

        return transaction

    def close(self):
        if self.current_block_file:
            self.current_block_file.close()
        self.ldb.close()

class ChainstateParser():

    def __init__(self, leveldb_dir):
        self.ldb = open_leveldb(leveldb_dir)

    def get_last_block_hash(self):
        block_hash = self.ldb.get(bytes('B', 'utf-8'))
        block_hash = ib2h(block_hash)
        return block_hash

    def close(self):
        self.ldb.close()
