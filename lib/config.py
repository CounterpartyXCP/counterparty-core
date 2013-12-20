import sys
import os
import hashlib
import appdirs
import decimal
D = decimal.Decimal

# Obsolete in Python 3.4.
ASSET_NAME = {0: 'BTC', 1: 'XCP'}
ASSET_ID = {'BTC': 0, 'XCP': 1}

UNIT = 100000000    # The same across currencies.
FOUR = D(10) ** -4
EIGHT = D(10) ** -8

# JSON‐RPC Options
CONFIGFILE = os.path.expanduser('~') + '/.bitcoin/bitcoin.conf'
RPCCONNECT = 'localhost'
# RPCPORT = '8332'  # mainnet
RPCPORT = '18332'   # testnet
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
RPC = 'http://'+RPCUSER+':'+RPCPASSWORD+'@'+RPCCONNECT+':'+RPCPORT

# Database location
data_dir = appdirs.user_data_dir('Counterparty', 'Counterparty')
if not os.path.isdir(data_dir):
    os.mkdir(data_dir)
DB_VERSION = 1
LEDGER = data_dir + '/ledger.' + str(DB_VERSION) + '.db'

# Bitcoin protocol
DUST_SIZE = 5430
MIN_FEE = 10000 # Counterparty transactions are all under 1KB in size.

# Counterparty protocol
# BLOCK_FIRST = 273648          # mainnet
BLOCK_FIRST = 153560            # testnet
BURN_START = 153000             # testnet
BURN_END = 156000               # testnet
# PREFIX = b'CPCOINXXXX'        # 10 bytes
PREFIX = b'TEST'                # 4 bytes (possibly accidentally created)
TXTYPE_FORMAT = '>I'

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
