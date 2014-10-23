import io, binascii, copy, json
from .bc_data_stream import BCDataStream
from .utils import b2h

from pycoin.tx.UnsignedTx import UnsignedTx, UnsignedTxOut 
from pycoin.tx.TxOut import TxOut
from pycoin.tx.TxIn import TxIn
from pycoin.tx.Tx import Tx, SIGHASH_ALL
from pycoin.encoding import h2b
from pycoin.convention import tx_fee

from lib.tx_script import TxScript

class RawTransaction():

    def __init__(self, unsigned_hex=''):
        self.unsigned_hex = unsigned_hex 
        if unsigned_hex!='':
            self.parse_transaction()

    def parse_tx_in(self):
        tx_in = {}
        tx_in['txid'] = self.data_stream.read_bytes(32)
        tx_in['vout'] = self.data_stream.read_uint32()
        tx_in['scriptSig'] = {
            'hex': self.data_stream.read_bytes(self.data_stream.read_compact_size())
        }
        tx_in['sequence'] = self.data_stream.read_uint32()
        self.data['vin'].append(tx_in)

        unsigned_tx_out = UnsignedTxOut(tx_in['txid'], tx_in['vout'], 0, tx_in['scriptSig']['hex']) 
        self.unsigned_txs_out.append(unsigned_tx_out)

    def parse_tx_out(self):
        tx_out = {}
        tx_out['value'] = self.data_stream.read_int64()
        tx_out['n'] = len(self.data['vout'])
        tx_out['scriptPubKey'] = {
            'hex': self.data_stream.read_bytes(self.data_stream.read_compact_size())
        }
        self.data['vout'].append(tx_out)

        new_tx_out = TxOut(tx_out['value'], tx_out['scriptPubKey']['hex'])
        self.new_txs_out.append(new_tx_out)

    def parse_transaction(self):
        self.unsigned_txs_out = []
        self.new_txs_out = []

        self.data_stream = BCDataStream()
        self.data_stream.write(h2b(self.unsigned_hex))

        start_pos = self.data_stream.read_cursor
        self.data = {'vin':[], 'vout':[]}
        self.data['version'] = self.data_stream.read_int32()
        self.version = self.data['version']

        n_vin = self.data_stream.read_compact_size()
        for i in range(n_vin):
            self.parse_tx_in()

        n_vout = self.data_stream.read_compact_size()
        for i in range(n_vout):
            self.parse_tx_out()

        self.data['lockTime'] = self.data_stream.read_uint32()
        self.lock_time = self.data['lockTime'] 
        self.data['__data__'] = self.data_stream.input[start_pos:self.data_stream.read_cursor]

        self.pycoin_tx = UnsignedTx(self.version, self.unsigned_txs_out, self.new_txs_out, self.lock_time)

    def to_json(self, pretty=False, return_dict=False):
        json_dict = copy.deepcopy(self.data)
        
        del(json_dict['__data__'])

        for tx_in in json_dict['vin']:
            tx_in['txid'] = b2h(tx_in['txid'][::-1])
            tx_script = TxScript(tx_in['scriptSig']['hex'])
            tx_in['scriptSig']['asm'] = tx_script.to_asm()
            tx_in['scriptSig']['hex'] = b2h(tx_in['scriptSig']['hex'])

        for tx_out in json_dict['vout']:
            tx_script = TxScript(tx_out['scriptPubKey']['hex'])
            tx_out['scriptPubKey']['asm'] = tx_script.to_asm()
            tx_out['scriptPubKey']['hex'] = b2h(tx_out['scriptPubKey']['hex'])

        if return_dict:
            return json_dict
        if pretty:
            return json.dumps(json_dict, sort_keys=True, indent=4, separators=(',', ': '))
        else:
            return json.dumps(json_dict)

    def sign(self, solver):
        new_tx = self.pycoin_tx.sign(solver)
        s = io.BytesIO()
        new_tx.stream(s)
        tx_bytes = s.getvalue()
        tx_hex = binascii.hexlify(tx_bytes).decode("utf8")
        return tx_hex

    # inputs = [{"txid":txid,"vout":vout, "scriptPubKey":scriptPubKey, "amount":amount},...] 
    # outputs = {address:amount, ...} 
    # amount in satoshi
    def create_raw_transaction(inputs, outputs):
        coins_sources = []
        coins_to = []
        total_unspent = 0
        total_spent = 0

        for intx in inputs:
            tx_out = TxOut(intx['amount'], h2b(intx['scriptPubKey']))
            coins_source = (h2b(intx['txid'])[::-1], intx['vout'], tx_out)
            coins_sources.append(coins_source)
            total_unspent += intx['amount']

        for outtx in outputs:
            self.coins_to.append((outtx['amount'], address))
            total_spent += outtx['amount']

        fee = total_unspent - total_spent

        if fee < 0:
            message = "not enough source coins (%s BTC) for destination (%s BTC). Short %s BTC" %  (satoshi_to_btc(total_unspent), satoshi_to_btc(total_spent), satoshi_to_btc(-fee))
            raise Exception(message)
        
        unsigned_tx = UnsignedTx.standard_tx(coins_from, coins_to)
        s = io.BytesIO()
        unsigned_tx.stream(s)
        tx_bytes = s.getvalue()
        tx_hex = binascii.hexlify(tx_bytes).decode("utf8")
        return tx_hex
        


