import os, json, time, logging, binascii
import logging
logger = logging.getLogger(__name__)

from .bc_data_stream import BCDataStream
from .utils import b2h, double_hash, ib2h, inverse_hash, decode_value

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

class BlockchainParser():

    def __init__(self, bitcoind_dir):
        self.blocks_dir = os.path.join(bitcoind_dir, 'blocks')
        self.file_num = -1
        self.current_file_size = 0
        self.current_block_file = None
        self.data_stream = None
        self.blocks_leveldb_path = os.path.join(self.blocks_dir, 'index')
        self.blocks_leveldb = open_leveldb(self.blocks_leveldb_path)
        self.txindex_leveldb_path = os.path.join(bitcoind_dir, 'indexes', 'txindex')
        self.txindex_leveldb = open_leveldb(self.txindex_leveldb_path)


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

        transaction['vin'] = []
        for i in range(vds.read_compact_size()):
            transaction['vin'].append(self.read_tx_in(vds))

        transaction['vout'] = []
        for i in range(vds.read_compact_size()):
            transaction['vout'].append(self.read_tx_out(vds))

        if transaction['segwit']:
            offset_before_tx_witnesses = vds.read_cursor - start_pos
            for vin in transaction['vin']:
                vin['tx_witnesses'] = []
                witnesses_count = vds.read_compact_size()
                for i in range(witnesses_count):
                    witness_length = vds.read_compact_size()
                    witness = b2h(vds.read_bytes(witness_length))
                    vin['tx_witnesses'].append(witness)

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
            data_file_path = os.path.join(self.blocks_dir, 'blk%05d.dat' % (self.file_num,))
            self.current_block_file = open(data_file_path, "rb")
            self.data_stream = BCDataStream()
            self.data_stream.map_file(self.current_block_file, pos_in_file)
        else:
            self.data_stream.seek_file(pos_in_file)

    def read_raw_block(self, block_hash, only_header=False, use_txid=True):
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
        return block

    def read_raw_transaction(self, tx_hash, use_txid=True):
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

    def close(self):
        if self.current_block_file:
            self.current_block_file.close()
        self.blocks_leveldb.close()
        self.txindex_leveldb.close()

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