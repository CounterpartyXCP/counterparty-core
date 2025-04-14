import binascii
import decimal
import hashlib
import itertools
import json
import os
import string
from operator import itemgetter
from urllib.parse import urlparse

import pygit2
from bitcoinutils.setup import setup
from counterpartycore.lib import config

D = decimal.Decimal


def chunkify(l, n):  # noqa: E741
    n = max(1, n)
    return [l[i : i + n] for i in range(0, len(l), n)]


def flat(z):
    return list(z)


def accumulate(l):  # noqa: E741
    it = itertools.groupby(l, itemgetter(0))
    for key, subiter in it:
        yield key, sum(item[1] for item in subiter)


def active_options(given_config, options):
    """Checks if options active in some given config."""
    return given_config & options == options


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
            return f"{o:.8f}"
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
    current_network = network or config.NETWORK_NAME
    if current_network.startswith("testnet"):
        current_network = "testnet"
    setup(current_network)


def is_valid_tx_hash(tx_hash):
    if all(c in string.hexdigits for c in tx_hash) and len(tx_hash) == 64:
        return True
    return False


def is_process_alive(pid):
    """Check For the existence of a unix pid."""
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    return True


def dhash(text):
    if not isinstance(text, bytes):
        text = bytes(str(text), "utf-8")

    return hashlib.sha256(hashlib.sha256(text).digest()).digest()


def dhash_string(text):
    return binascii.hexlify(dhash(text)).decode()


def bytes_to_string(bytes_in: bytes) -> str:
    try:
        return bytes_in.decode("utf-8")
    except UnicodeDecodeError:
        return binascii.hexlify(bytes_in).decode("utf-8")


def get_current_commit_hash(not_from_env=False):
    if not not_from_env:
        current_commit = os.environ.get("CURRENT_COMMIT")
        if current_commit:
            return current_commit

    try:
        repo = pygit2.Repository(pygit2.discover_repository("."))  # pylint: disable=E1101

        commit_hash = str(repo.head.target)

        branch_name = repo.head.shorthand
        if repo.head_is_detached:
            branch_name = "HEAD detached"

        return f"{branch_name} - {commit_hash}"
    except pygit2.GitError:  # pylint: disable=E1101
        return None


def classify_mime_type(mime_type):
    # Types that start with "text/" are textual
    if (
        mime_type.startswith("text/")
        or mime_type.startswith("message/")
        or mime_type.endswith("+xml")
    ):
        return "text"

    # List of application types that are textual
    if mime_type in [
        "application/xml",
        "application/javascript",
        "application/json",
        "application/manifest+json",
        "application/x-python-code",
        "application/x-sh",
        "application/x-csh",
        "application/x-tex",
        "application/x-latex",
    ]:
        return "text"

    # By default, consider the MIME type as binary
    return "binary"


def content_to_bytes(content: str, mime_type: str) -> bytes:
    file_type = classify_mime_type(mime_type)
    if file_type == "text":
        return content.encode("utf-8")
    return binascii.unhexlify(content)


def bytes_to_content(content: bytes, mime_type: str) -> str:
    file_type = classify_mime_type(mime_type)
    if file_type == "text":
        return content.decode("utf-8")
    return binascii.hexlify(content).decode("utf-8")
