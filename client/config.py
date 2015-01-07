"""Variables prefixed with `DEFAULT` should be able to be overridden by
configuration file and command‐line arguments."""

UNIT = 100000000        # The same across assets.


# Versions
VERSION_MAJOR = 1
VERSION_MINOR = 0
VERSION_REVISION = 0
VERSION_STRING = str(VERSION_MAJOR) + '.' + str(VERSION_MINOR) + '.' + str(VERSION_REVISION)

TWO_WEEKS = 2 * 7 * 24 * 3600
MAX_EXPIRATION = 4 * 2016   # Two months

# SQLite3
MAX_INT = 2**63 - 1

# Currency agnosticism
BTC = 'BTC'
XCP = 'XCP'
BTC_NAME = 'Bitcoin'
XCP_NAME = 'Counterparty'

XCP_CLIENT = 'counterparty-client'

DEFAULT_COUNTERPARTY_RPC_PORT_TESTNET = 14000
DEFAULT_COUNTERPARTY_RPC_PORT = 4000

DEFAULT_WALLET_PORT_TESTNET = 18332
DEFAULT_WALLET_PORT = 8332

ADDRESSVERSION_TESTNET = b'\x6f'
PRIVATEKEY_VERSION_TESTNET = b'\xef'
ADDRESSVERSION_MAINNET = b'\x00'
PRIVATEKEY_VERSION_MAINNET = b'\x80'

# Protocol defaults
# NOTE: If the DUST_SIZE constants are changed, they MUST also be changed in counterblockd/lib/config.py as well
    # TODO: This should be updated, given their new configurability.
# TODO: The dust values should be lowered by 90%, once transactions with smaller outputs start confirming faster: <https://github.com/mastercoin-MSC/spec/issues/192>
DEFAULT_REGULAR_DUST_SIZE = 5430         # TODO: This is just a guess. I got it down to 5530 satoshis.
DEFAULT_MULTISIG_DUST_SIZE = 7800        # <https://bitcointalk.org/index.php?topic=528023.msg7469941#msg7469941>
DEFAULT_OP_RETURN_VALUE = 0
DEFAULT_FEE_PER_KB = 10000                # Bitcoin Core default is 10000.  # TODO: Lower 10x later, too.


# UI defaults
DEFAULT_FEE_FRACTION_REQUIRED = .009   # 0.90%
DEFAULT_FEE_FRACTION_PROVIDED = .01    # 1.00%


HTTP_TIMEOUT = 60 * 60  # One hour


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
