import os

# Variables prefixed with `DEFAULT` should be able to be overridden by
# configuration file and command‐line arguments.

UNIT = 100000000  # The same across assets.


# Semantic Version
__version__ = "11.2.0"  # for hatch
VERSION_STRING = __version__
version = VERSION_STRING.split("-", maxsplit=1)[0].split(".")
VERSION_MAJOR = int(version[0])
VERSION_MINOR = int(version[1])
VERSION_REVISION = int(version[2])
VERSION_PRE_RELEASE = "-".join(VERSION_STRING.split("-")[1:])

DEFAULT_ELECTRS_URLS_MAINNET = [
    "https://blockstream.info/api",
    "https://mempool.space/api",
]
DEFAULT_ELECTRS_URLS_TESTNET3 = ["https://blockstream.info/testnet/api"]
DEFAULT_ELECTRS_URLS_TESTNET4 = ["https://mempool.space/testnet4/api"]
DEFAULT_ELECTRS_URLS_SIGNET = ["https://mempool.space/signet/api"]


UPGRADE_ACTIONS = {
    "mainnet": {
        "10.3.0": [("reparse", 0)],
        "10.5.0": [("reparse", 865999)],
        "10.6.0": [("reparse", 867000)],
        "10.7.0": [("reparse", 869900)],
        "10.8.0": [("rollback", 871780)],
        "10.9.0-rc.1": [("rollback", 871780)],
        "10.9.0": [("rollback", 871780)],
        "11.0.0": [("refresh_state_db", 0)],
        "11.0.1": [("rollback", 902000)],
        "11.0.2": [("refresh_state_db", 0)],
        "11.0.3": [("reparse", 911955)],
        "11.0.4": [("rollback", 926807)],
        "11.1.0": [("rollback", 941000)],
        "11.2.0": [("refresh_state_db", 0)],
    },
    "testnet3": {
        "10.3.0": [("reparse", 0)],
        "10.5.0": [("reparse", 2925799)],
        "10.6.0": [("reparse", 2925799)],
        "10.7.0": [("reparse", 2925799)],
        "10.8.0": [("rollback", 3522632)],
        "10.9.0-rc.1": [("rollback", 3522632)],
        "10.9.0": [("rollback", 3522632)],
        "10.10.0": [("rollback", 3522632)],
        "11.0.0": [("refresh_state_db", 0)],
        "11.0.1": [("rollback", 4410000)],
        "11.0.2": [("refresh_state_db", 0)],
        "11.0.3": [("reparse", 2820893)],
        "11.0.4-alpha.1": [("reparse", 4017708)],
        "11.0.4": [("reparse", 4017708)],
        "11.1.0": [("refresh_state_db", 0)],
        "11.2.0": [("refresh_state_db", 0)],
    },
    "testnet4": {
        "10.10.0": [("rollback", 64492)],
        "11.0.0": [("refresh_state_db", 0)],
        "11.0.1": [("rollback", 85000)],
        "11.0.2": [("refresh_state_db", 0)],
        "11.0.3": [("reparse", 99290)],
        "11.1.0": [("refresh_state_db", 0)],
        "11.2.0": [("refresh_state_db", 0)],
    },
    "signet": {
        "11.0.2": [("refresh_state_db", 0)],
        "11.0.3": [("reparse", 266993)],
        "11.1.0": [("refresh_state_db", 0)],
        "11.2.0": [("refresh_state_db", 0)],
    },
}


# Counterparty protocol
TXTYPE_FORMAT = ">I"
SHORT_TXTYPE_FORMAT = "B"

TWO_WEEKS = 2 * 7 * 24 * 3600
MAX_EXPIRATION = 4 * 2016  # Two months

MEMPOOL_BLOCK_HASH = "mempool"
MEMPOOL_BLOCK_INDEX = 9999999


# SQLite3
MAX_INT = 2**63 - 1


# Bitcoin Core
OP_RETURN_MAX_SIZE = 80  # bytes


# Currency agnosticism
BTC = "BTC"
XCP = "XCP"

BTC_NAME = "Bitcoin"
XCP_NAME = "Counterparty"
APP_NAME = XCP_NAME.lower()
FULL_APP_NAME = "Counterparty Core"
LOGGER_NAME = APP_NAME

DEFAULT_API_PORT_REGTEST = 24000
DEFAULT_API_PORT_TESTNET3 = 14000
DEFAULT_API_PORT_TESTNET4 = 44000
DEFAULT_API_PORT_SIGNET = 34000
DEFAULT_API_PORT = 4000

DEFAULT_RPC_PORT_REGTEST = 24100
DEFAULT_RPC_PORT_TESTNET3 = 14100
DEFAULT_RPC_PORT_TESTNET4 = 44100
DEFAULT_RPC_PORT_SIGNET = 34100
DEFAULT_RPC_PORT = 4100

DEFAULT_BACKEND_PORT_REGTEST = 18443
DEFAULT_BACKEND_PORT_TESTNET3 = 18332
DEFAULT_BACKEND_PORT_TESTNET4 = 48332
DEFAULT_BACKEND_PORT_SIGNET = 38332
DEFAULT_BACKEND_PORT = 8332

DEFAULT_ZMQ_SEQUENCE_PORT_REGTEST = 29332
DEFAULT_ZMQ_SEQUENCE_PORT_TESTNET3 = 19332
DEFAULT_ZMQ_SEQUENCE_PORT_TESTNET4 = 49332
DEFAULT_ZMQ_SEQUENCE_PORT_SIGNET = 39332
DEFAULT_ZMQ_SEQUENCE_PORT = 9332

DEFAULT_ZMQ_RAWBLOCK_PORT_REGTEST = 29333
DEFAULT_ZMQ_RAWBLOCK_PORT_TESTNET3 = 19333
DEFAULT_ZMQ_RAWBLOCK_PORT_TESTNET4 = 49333
DEFAULT_ZMQ_RAWBLOCK_PORT_SIGNET = 39333
DEFAULT_ZMQ_RAWBLOCK_PORT = 9333

DEFAULT_ZMQ_PUBLISHER_PORT_REGTEST = 24001
DEFAULT_ZMQ_PUBLISHER_PORT_TESTNET3 = 14001
DEFAULT_ZMQ_PUBLISHER_PORT_TESTNET4 = 44001
DEFAULT_ZMQ_PUBLISHER_PORT_SIGNET = 34001
DEFAULT_ZMQ_PUBLISHER_PORT = 4001

# Dedicated health-check listener, isolated from the public API worker pool
# (see issue #3460). API_PORT + 1 is taken by the ZMQ publisher, so use + 2.
DEFAULT_HEALTHZ_PORT_REGTEST = 24002
DEFAULT_HEALTHZ_PORT_TESTNET3 = 14002
DEFAULT_HEALTHZ_PORT_TESTNET4 = 44002
DEFAULT_HEALTHZ_PORT_SIGNET = 34002
DEFAULT_HEALTHZ_PORT = 4002

# Readiness is considered "caught up" when the last parsed block is within this
# many blocks of the backend tip, or when it advanced within the recent window.
DEFAULT_HEALTHZ_READY_LAG_BLOCKS = 1
DEFAULT_HEALTHZ_READY_RECENT_PARSE_SECONDS = 120
# Readiness reports "degraded" (503) only when the public worker pool has been
# saturated (all threads busy AND a non-empty queue) for at least this long.
# Set to 0 to disable the saturation axis of readiness entirely.
DEFAULT_HEALTHZ_SATURATION_GRACE_SECONDS = 5
# Liveness fails only if the health sampler heartbeat is staler than this (a
# genuine deadlock of the health process), never on ledger lag or saturation.
DEFAULT_HEALTHZ_LIVENESS_HEARTBEAT_TIMEOUT_SECONDS = 30

UNSPENDABLE_REGTEST = "mvCounterpartyXXXXXXXXXXXXXXW24Hef"
UNSPENDABLE_TESTNET3 = "mvCounterpartyXXXXXXXXXXXXXXW24Hef"
UNSPENDABLE_TESTNET4 = "mvCounterpartyXXXXXXXXXXXXXXW24Hef"
UNSPENDABLE_SIGNET = "mvCounterpartyXXXXXXXXXXXXXXW24Hef"
UNSPENDABLE_MAINNET = "1CounterpartyXXXXXXXXXXXXXXXUWLpVr"

ADDRESSVERSION_TESTNET3 = b"\x6f"
P2SH_ADDRESSVERSION_TESTNET3 = b"\xc4"
PRIVATEKEY_VERSION_TESTNET3 = b"\xef"
MAGIC_BYTES_TESTNET3 = b"\xfa\xbf\xb5\xda"  # For bip-0010

ADDRESSVERSION_TESTNET4 = b"\x6f"
P2SH_ADDRESSVERSION_TESTNET4 = b"\xc4"
PRIVATEKEY_VERSION_TESTNET4 = b"\xef"
MAGIC_BYTES_TESTNET4 = b"\xfa\xbf\xb5\xda"  # For bip-0010

ADDRESSVERSION_MAINNET = b"\x00"
P2SH_ADDRESSVERSION_MAINNET = b"\x05"
PRIVATEKEY_VERSION_MAINNET = b"\x80"
MAGIC_BYTES_MAINNET = b"\xf9\xbe\xb4\xd9"  # For bip-0010

ADDRESSVERSION_REGTEST = b"\x6f"
P2SH_ADDRESSVERSION_REGTEST = b"\xc4"
PRIVATEKEY_VERSION_REGTEST = b"\xef"
MAGIC_BYTES_REGTEST = b"\xda\xb5\xbf\xfa"

ADDRESSVERSION_SIGNET = b"\x6f"
P2SH_ADDRESSVERSION_SIGNET = b"\xc4"
PRIVATEKEY_VERSION_SIGNET = b"\xef"
MAGIC_BYTES_SIGNET = b"\x0a\x03\xcf\x40"  # For bip-0010

BLOCK_FIRST_TESTNET3 = 310000
BLOCK_FIRST_TESTNET3_HASH = "000000001f605ec6ee8d2c0d21bf3d3ded0a31ca837acc98893876213828989d"
BURN_START_TESTNET3 = 310000
BURN_END_TESTNET3 = 99999999  # in a very long time...
OLD_BURN_END_TESTNET3 = 4017708  # in a very long time...

BLOCK_FIRST_TESTNET4 = 63240
BLOCK_FIRST_TESTNET4_HASH = "00000000ffa7082b07d16d8ee02d275ad80a4450350e53835f0f264d72b36cd7"
BURN_START_TESTNET4 = 63240
BURN_END_TESTNET4 = 4017708

BLOCK_FIRST_MAINNET = 278270
BLOCK_FIRST_MAINNET_HASH = "00000000000000017bac9a8e85660ad348050c789922d5f8fe544d473368be1a"
BURN_START_MAINNET = 278310
BURN_END_MAINNET = 283810

BLOCK_FIRST_REGTEST = 101
BLOCK_FIRST_REGTEST_HASH = "0f9188f13cb7b2c71f2a335e3a4fc328bf5beb436012afca590b1a11466e2206"
BURN_START_REGTEST = 101
BURN_END_REGTEST = 150000000

BLOCK_FIRST_SIGNET = 255100
BLOCK_FIRST_SIGNET_HASH = "00000000ffa7082b07d16d8ee02d275ad80a4450350e53835f0f264d72b36cd7"
BURN_START_SIGNET = 255110
BURN_END_SIGNET = 999999999


# Protocol defaults
# NOTE: If the DUST_SIZE constants are changed, they MUST also be changed in counterblockd/lib/config.py as well
DEFAULT_REGULAR_DUST_SIZE = 546
DEFAULT_MULTISIG_DUST_SIZE = 1000  # OMFG: We been overpaying by 10x for years (7800!=780) <https://bitcointalk.org/index.php?topic=528023.msg7469941#msg7469941>
DEFAULT_SEGWIT_DUST_SIZE = 330
DEFAULT_OP_RETURN_VALUE = 0
DEFAULT_FEE_PER_KB_ESTIMATE_SMART = 1024
DEFAULT_FEE_PER_KB = 25000  # sane/low default, also used as minimum when estimated fee is used
ESTIMATE_FEE_PER_KB = (
    True  # when True will use `estimatesmartfee` from bitcoind instead of DEFAULT_FEE_PER_KB
)
ESTIMATE_FEE_CONF_TARGET = 3
ESTIMATE_FEE_MODE = "CONSERVATIVE"

# UI defaults
DEFAULT_FEE_FRACTION_REQUIRED = 0.009  # 0.90%
DEFAULT_FEE_FRACTION_PROVIDED = 0.01  # 1.00%


DEFAULT_REQUESTS_TIMEOUT = 20  # 20 seconds
# Separate (shorter) TCP connect timeout so an unreachable/stalled backend
# fails the connect quickly instead of hanging for the full read timeout.
DEFAULT_BACKEND_CONNECT_TIMEOUT = 5  # 5 seconds
# Jittered exponential backoff for the parser connection-retry loop, so many
# nodes recovering from the same backend outage do not reconnect in lockstep.
BACKEND_RETRY_BASE_SLEEP = 1  # 1 second
BACKEND_RETRY_MAX_SLEEP = 30  # cap between retries
DEFAULT_RPC_BATCH_SIZE = 20  # A 1 MB block can hold about 4200 transactions.
MAX_RPC_BATCH_SIZE = 100  # Maximum number of transactions to send in a single RPC call.

# Custom exit codes
EXITCODE_UPDATE_REQUIRED = 5

BACKEND_RAW_TRANSACTIONS_CACHE_SIZE = 1000
BACKEND_RPC_BATCH_NUM_WORKERS = 6

DEFAULT_UTXO_LOCKS_MAX_ADDRESSES = 1000
DEFAULT_UTXO_LOCKS_MAX_AGE = 3.0  # in seconds

ADDRESS_OPTION_REQUIRE_MEMO = 1
ADDRESS_OPTION_MAX_VALUE = ADDRESS_OPTION_REQUIRE_MEMO  # Or list of all the address options
OLD_STYLE_API = True

API_LIMIT_ROWS = 1000

# Max number of Bitcoin backend RPC calls a single API request may trigger before
# it is rejected with a 400 (issue #3461). Bounds the getrawtransaction fan-out of
# transaction-info and compose endpoints so one request cannot generate unbounded
# backend work. 0 = unlimited (matches the API_LIMIT_ROWS convention).
API_MAX_BACKEND_RPC_CALLS = 1000

MPMA_LIMIT = 1000

PROTOCOL_CHANGES_URL = "https://counterparty.io/protocol_changes.json"
# PROTOCOL_CHANGES_URL = "https://raw.githubusercontent.com/CounterpartyXCP/counterparty-core/refs/heads/master/counterparty-core/counterpartycore/protocol_changes.json"


BOOTSTRAP_URL_BASE = "https://storage.googleapis.com/counterparty-bootstrap"
# Version tag embedded in the bootstrap snapshot file names (e.g. "v11.2.0").
# Versioned names let several releases coexist in the bucket and guarantee that a
# node downloads the snapshot matching its own version.
BOOTSTRAP_VERSION = f"v{VERSION_STRING}"

# Ledger / state database base file names per network (as stored in the bucket).
# testnet3 is intentionally absent: it is deprecated and no snapshots are produced
# for it anymore (see `prepare-bootstrap`).
_BOOTSTRAP_DB_NAMES = {
    "mainnet": ("counterparty.db", "state.db"),
    "testnet4": ("counterparty.testnet4.db", "state.testnet4.db"),
    "signet": ("counterparty.signet.db", "state.signet.db"),
}


def _bootstrap_urls(bootstrap_version=BOOTSTRAP_VERSION):
    urls = {}
    for network, db_names in _BOOTSTRAP_DB_NAMES.items():
        urls[network] = [
            (
                f"{BOOTSTRAP_URL_BASE}/{db_name}.{bootstrap_version}.zst",
                f"{BOOTSTRAP_URL_BASE}/{db_name}.{bootstrap_version}.sig",
            )
            for db_name in db_names
        ]
    return urls


BOOTSTRAP_URLS = _bootstrap_urls()

API_MAX_LOG_SIZE = (
    10 * 1024 * 1024
)  # max log size of 20 MB before rotation (make configurable later)
API_MAX_LOG_COUNT = 10

NO_TELEMETRY = False
TELEMETRY_INTERVAL = 5 * 60
INFLUX_DB_URL = "http://telemetry.counterparty.io:8086"
INFLUX_DB_TOKEN = (
    "7iViyy6TEVwmpH-YPE7shO36fzfGsyVYm0DC2tuLv0ZDTLp5uqRTW2Zv9IBcujF5zQRV6mauGdb1W3n7UrUu6A=="  # noqa S105 # nosec B105
)
INFLUX_DB_ORG = "counterparty"
INFLUX_DB_BUCKET = "node-telemetry"

LOG_IN_CONSOLE = False

DEFAULT_DB_CONNECTION_POOL_SIZE = 10
# Maximum total connections across all threads (0 = unlimited)
DEFAULT_DB_MAX_CONNECTIONS = 50

DEFAULT_UTXO_VALUE = 546

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))
LEDGER_DB_MIGRATIONS_DIR = os.path.join(CURRENT_DIR, "ledger", "migrations")
STATE_DB_MIGRATIONS_DIR = os.path.join(CURRENT_DIR, "api", "migrations")

PROFILE_INTERVAL_MINUTES = 15

CURRENT_COMMIT = "Unknown"
ENABLE_ALL_PROTOCOL_CHANGES = False
DISABLE_API_CACHE = False
# The legacy v1 JSON-RPC API (`/`, `/api/`, `/rpc/`, `/v1/`) is disabled by
# default: cheap POST requests can trigger expensive database work and large
# Bitcoin RPC fan-out, an outsized denial-of-service surface. Self-hosters who
# still need it can opt back in with `--enable-api-v1` (see the startup warning).
ENABLE_API_V1 = False
API_CACHE_SIZE = 1000  # max entries in the API response cache (BLOCK_CACHE)
# Total-rows budget for the API response cache (BLOCK_CACHE); 0 disables the row
# bound (entry count still applies). Bounds cache memory while letting many small
# entries stay cached. Worst single entry is API_LIMIT_ROWS rows.
API_CACHE_MAX_ROWS = 50000
