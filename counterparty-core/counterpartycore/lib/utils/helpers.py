import decimal
import itertools
import json
import string
from operator import itemgetter
from urllib.parse import urlparse

from bitcoinutils.setup import setup
from counterpartycore.lib import config

D = decimal.Decimal


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


ID_SEPARATOR = "_"


def make_id(hash_1, hash_2):
    return hash_1 + ID_SEPARATOR + hash_2


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

    def reset_instance(cls):
        """Force reinitialization of the singleton instance."""
        if cls in cls._instances:
            del cls._instances[cls]


def format_duration(seconds):
    duration_seconds = int(seconds)
    hours, remainder = divmod(duration_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    return f"{hours}h {minutes}m {seconds}s"


def is_url(url):
    try:
        result = urlparse(url)
        return all([result.scheme, result.netloc])
    except ValueError:
        return False


class ApiJsonEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, decimal.Decimal):
            return "{0:.8f}".format(o)
        if isinstance(o, bytes):
            return o.hex()
        if callable(o):
            return o.__name__
        if hasattr(o, "__class__"):
            return str(o)
        return super().default(o)


def to_json(obj, indent=None, sort_keys=False):
    return json.dumps(obj, cls=ApiJsonEncoder, indent=indent, sort_keys=sort_keys)


def to_short_json(obj):
    return json.dumps(obj, cls=ApiJsonEncoder, indent=None, sort_keys=True, separators=(",", ":"))


def divide(value1, value2):
    decimal.getcontext().prec = 16
    if value2 == 0 or value1 == 0:
        return D(0)
    return D(value1) / D(value2)


def setup_bitcoinutils(network=None):
    if network is not None:
        setup(network)
        return
    if config.NETWORK_NAME == "testnet4":
        setup("testnet")
    else:
        setup(config.NETWORK_NAME)


def is_valid_tx_hash(tx_hash):
    if all(c in string.hexdigits for c in tx_hash) and len(tx_hash) == 64:
        return True
    return False
