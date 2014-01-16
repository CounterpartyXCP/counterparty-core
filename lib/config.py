import sys
import os
import hashlib

# Units
UNIT = 100000000        # The same across currencies.

# Versions
VERSION = 0.1
DB_VERSION = 4

# Bitcoin protocol
# DUST_SIZE = 5430      # OP_RETURN
DUST_SIZE = 5430 * 2    # Multi‐sig (TODO: This is just a guess.)
MIN_FEE = 10000         # Counterparty transactions are all under 1KB in size.
DATA_VALUE = 0

# Counterparty protocol
TXTYPE_FORMAT = '>I'

# SQLite3
MAX_INT = 2**63 - 1

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
