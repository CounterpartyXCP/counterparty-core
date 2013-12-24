#! /usr/bin/python3

import os
import appdirs

from lib import (config, util, exceptions, bitcoin, blocks)
from lib import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, api)

# JSON‐RPC Options
CONFIGFILE = os.path.expanduser('~') + '/.bitcoin/bitcoin.conf'
RPCCONNECT = 'localhost'
# RPCPORT = '8332' # mainnet
RPCPORT = '18332' # testnet
try:
    with open(CONFIGFILE, 'r') as configfile:
        for line in configfile.readlines():
            if line.startswith('#'):
                continue
            array = line.replace('\n', '').split('=')
            if len(array) != 2:
                continue
            key, value = array[:2]
            if key == 'rpcuser': RPCUSER = value
            elif key == 'rpcpassword': RPCPASSWORD = value
            elif key == 'rpcconnect': RPCCONNECT = value
            elif key == 'rpcport': RPCCONNECT = value
except Exception:
    raise exceptions.BitcoinConfError('Put a (valid) copy of your \
bitcoin.conf in ~/.bitcoin/bitcoin.conf')
    sys.exit(1)
config.RPC = 'http://'+RPCUSER+':'+RPCPASSWORD+'@'+RPCCONNECT+':'+RPCPORT

data_dir_default = appdirs.user_data_dir('Counterparty', 'Counterparty')
config.DATABASE = data_dir_default + '/counterparty.' + str(config.DB_VERSION) + '.db'

source = 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'
destination = 'n3BrDB6zDiEPWEE6wLxywFb4Yp9ZY5fHM7'
amount = 100000000
expiration = 10
fee_required = 1000000
fee_provided = 1000000

def test_send_create():
    unsigned_tx_hex = send.create(source, destination, amount, 1)
    assert unsigned_tx_hex == '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff0336150000000000001976a914edb5c902eadd71e698a8ce05ba1d7b31efbaa57b88acce22ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000000000001a6a18544553540000000000000000000000010000000005f5e10000000000'

def test_order_create_buy_xcp():
    unsigned_tx_hex = order.create(source, 0, amount, 1, amount * 2, expiration, 0, fee_provided)
    assert unsigned_tx_hex == '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff02d41cdb0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000346a32544553540000000a00000000000000000000000005f5e1000000000000000001000000000bebc200000a000000000000000000000000'


"""
lib/send.py:30:def parse (db, cursor, tx, message):

lib/api.py:8:def get_balances (address=None, asset_id=None):
lib/api.py:23:def get_sends (validity=None, source=None, destination=None):
lib/api.py:38:def get_orders (validity=None, address=None, show_empty=True, show_expired=True):
lib/api.py:61:def get_order_matches (validity=None, addresses=[], show_expired=True):
lib/api.py:85:def get_btcpays (validity=None):
lib/api.py:98:def get_issuances (validity=None, asset_id=None, issuer=None):
lib/api.py:114:def get_broadcasts (validity=None, source=None):
lib/api.py:129:def get_bets (validity=None, address=None, show_empty=True, show_expired=True):
lib/api.py:147:def get_bet_matches (validity=None, addresses=None, show_expired=True):
lib/api.py:166:def get_dividends (validity=None, address=None, asset_id=None):
lib/api.py:181:def get_burns (validity=True, address=None):
lib/api.py:196:def get_history (address):
lib/util.py:18:def short (string):
lib/util.py:24:def isodt (epoch_time):
lib/util.py:27:def get_time_left (unmatched):
lib/util.py:32:def get_order_match_time_left (matched):
lib/util.py:40:def get_asset_id (asset):
lib/util.py:44:def get_asset_name (asset_id):
lib/util.py:49:def debit (db, cursor, address, asset_id, amount):
lib/util.py:69:def credit (db, cursor, address, asset_id, amount):
lib/util.py:88:def good_feed (cursor, feed_address):
lib/util.py:103:def devise (quantity, asset_id, precision=8):
lib/dividend.py:15:def create (source, amount_per_share, asset_id):
lib/dividend.py:36:def parse (db, cursor, tx, message):
lib/bet.py:26:def get_fee_multiplier (feed_address):
lib/bet.py:39:def create (source, feed_address, bet_type, deadline, wager_amount,
lib/bet.py:67:def parse (db, cursor, tx, message):
lib/bet.py:141:def bet_match (db, cursor, tx):
lib/bet.py:249:def expire (db, cursor, block_index):
lib/issuance.py:13:def create (source, asset_id, amount, divisible):
lib/issuance.py:31:def parse (db, cursor, tx, message):
lib/burn.py:17:def create (source, quantity):
lib/burn.py:39:def parse (db, cursor, tx, message):
lib/broadcast.py:36:def create (source, timestamp, value, fee_multiplier, text):
lib/broadcast.py:43:def parse (db, cursor, tx, message):
lib/btcpay.py:14:def create (order_match_id):
lib/btcpay.py:42:def parse (db, cursor, tx, message):
lib/order.py:15:def create (source, give_id, give_amount, get_id, get_amount, expiration, fee_required, fee_provided):
lib/order.py:30:def parse (db, cursor, tx, message):
lib/order.py:104:def order_match (db, cursor, tx):
lib/order.py:202:def expire (db, cursor, block_index):
lib/blocks.py:19:def parse_block (db, cursor, block_index):
lib/blocks.py:71:def initialise(db, cursor):
lib/blocks.py:277:def get_tx_info (tx):
lib/blocks.py:318:def follow ():
lib/bitcoin.py:28:def rpc (method, params):
lib/bitcoin.py:44:def bitcoind_check ():
lib/bitcoin.py:52:def base58_decode (s, version):
lib/bitcoin.py:81:def var_int (i):
lib/bitcoin.py:91:def op_push (i):
lib/bitcoin.py:102:def eligius (signed_hex):
lib/bitcoin.py:117:def serialize (inputs, outputs, data):
lib/bitcoin.py:161:def get_inputs (source, amount, fee):
lib/bitcoin.py:173:def transaction (source, destination, btc_amount, fee, data, ask=False):
counterpartyd.py:27:def format_order (order):
counterpartyd.py:47:def format_bet (bet):
counterpartyd.py:60:def format_order_match (order_match):
"""
