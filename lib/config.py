import sys
import os
import hashlib
import decimal
D = decimal.Decimal

UNIT = 100000000    # The same across currencies.
FOUR = D(10) ** -4
EIGHT = D(10) ** -8

# Database location
DB_VERSION = 2

# Bitcoin protocol
DUST_SIZE = 5430
MIN_FEE = 10000 # Counterparty transactions are all under 1KB in size.

# Counterparty protocol
BLOCK_FIRST = 153560            # testnet
BURN_START = 153000             # testnet
BURN_END = 156000               # testnet
# PREFIX = b'CPCOINXXXX'        # 10 bytes
PREFIX = b'TEST'                # 4 bytes (possibly accidentally created)
TXTYPE_FORMAT = '>I'

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
