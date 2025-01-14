import binascii
import decimal
import hashlib
import itertools
import json
import logging
import os
from operator import itemgetter
from urllib.parse import urlparse

import requests
from arc4 import ARC4
from counterparty_rs import utils as pycoin_rs_utils

from counterpartycore.lib import config

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_BLOCK_INDEX = None
CURRENT_TX_HASH = None
PARSING_MEMPOOL = False
BLOCK_PARSER_STATUS = "starting"
CURRENT_BACKEND_HEIGHT = None
CURRENT_BLOCK_TIME = None

D = decimal.Decimal


# Obsolete in Python 3.4, with enum module.
BET_TYPE_NAME = {0: "BullCFD", 1: "BearCFD", 2: "Equal", 3: "NotEqual"}
BET_TYPE_ID = {"BullCFD": 0, "BearCFD": 1, "Equal": 2, "NotEqual": 3}

json_dump = lambda x: json.dumps(x, sort_keys=True, indent=4)  # noqa: E731
json_print = lambda x: print(json_dump(x))  # noqa: E731


class RPCError(Exception):
    pass


# TODO: Move to `util_test.py`.
# TODO: This doesn’t timeout properly. (If server hangs, then unhangs, no result.)
def api(method, params):
    """Poll API via JSON-RPC."""
    headers = {"content-type": "application/json"}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }

    response = requests.post(config.RPC, data=json.dumps(payload), headers=headers, timeout=10)
    if response == None:  # noqa: E711
        raise RPCError(f"Cannot communicate with {config.XCP_NAME} server.")
    elif response.status_code != 200:
        if response.status_code == 500:
            raise RPCError("Malformed API call.")
        else:
            raise RPCError(str(response.status_code) + " " + response.reason)

    response_json = response.json()
    if "error" not in response_json.keys() or response_json["error"] == None:  # noqa: E711
        try:
            return response_json["result"]
        except KeyError:
            raise RPCError(response_json)  # noqa: B904
    else:
        raise RPCError(f"{response_json['error']['message']} ({response_json['error']['code']})")


def chunkify(l, n):  # noqa: E741
    n = max(1, n)
    return [l[i : i + n] for i in range(0, len(l), n)]


def flat(z):
    return [x for x in z]


def accumulate(l):  # noqa: E741
    it = itertools.groupby(l, itemgetter(0))
    for key, subiter in it:
        yield key, sum(item[1] for item in subiter)


def active_options(config, options):
    """Checks if options active in some given config."""
    return config & options == options


def dhash(text):
    if not isinstance(text, bytes):
        text = bytes(str(text), "utf-8")

    return hashlib.sha256(hashlib.sha256(text).digest()).digest()


def dhash_string(text):
    return binascii.hexlify(dhash(text)).decode()


# Why on Earth does `binascii.hexlify()` return bytes?!
def hexlify(x):
    """Return the hexadecimal representation of the binary data. Decode from ASCII to UTF-8."""
    return binascii.hexlify(x).decode("ascii")


def unhexlify(hex_string):
    return binascii.unhexlify(bytes(hex_string, "utf-8"))


ID_SEPARATOR = "_"


def make_id(hash_1, hash_2):
    return hash_1 + ID_SEPARATOR + hash_2


def parse_id(match_id):
    assert match_id[64] == ID_SEPARATOR
    return match_id[:64], match_id[65:]  # UTF-8 encoding means that the indices are doubled.


# ORACLES
def satoshirate_to_fiat(satoshirate):
    return round(satoshirate / 100.0, 2)


class SingletonMeta(type):
    _instances = {}

    def __call__(cls, *args, **kwargs):
        """
        Possible changes to the value of the `__init__` argument do not affect
        the returned instance.
        """
        if cls not in cls._instances:
            instance = super().__call__(*args, **kwargs)
            cls._instances[cls] = instance
        return cls._instances[cls]


def format_duration(seconds):
    duration_seconds = int(seconds)
    hours, remainder = divmod(duration_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    return f"{hours}h {minutes}m {seconds}s"


def b2h(b):
    return binascii.hexlify(b).decode("utf-8")


def random_hex(length):
    return binascii.b2a_hex(os.urandom(length))


def double_hash(b):
    return hashlib.sha256(hashlib.sha256(b).digest()).digest()


def inverse_hash(hashstring):
    return pycoin_rs_utils.inverse_hash(hashstring)


def ib2h(b):
    return inverse_hash(b2h(b))


def is_url(url):
    try:
        result = urlparse(url)
        return all([result.scheme, result.netloc])
    except ValueError:
        return False


def init_arc4(seed):
    if isinstance(seed, str):
        seed = binascii.unhexlify(seed)
    return ARC4(seed)


def arc4_decrypt(cyphertext, decoded_tx):
    """Un-obfuscate. Initialise key once per attempt."""
    vin_hash = binascii.unhexlify(decoded_tx["vin"][0]["hash"])
    key = init_arc4(vin_hash)
    return key.decrypt(cyphertext)
