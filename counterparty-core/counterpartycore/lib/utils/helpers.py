import binascii
import decimal
import hashlib
import json
import mimetypes
import os
import string
import threading
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
    totals = {}
    for key, value in l:
        totals[key] = totals.get(key, 0) + value
    yield from totals.items()


def active_options(given_config, options):
    """Checks if options active in some given config."""
    return given_config & options == options


ID_SEPARATOR = "_"


def make_id(hash_1, hash_2):
    return hash_1 + ID_SEPARATOR + hash_2


# SQL form of ``make_id``: reconstructs the composite TEXT match ``id``
# (``tx0hash_tx1hash``) from the compact ``tx0_hash``/``tx1_hash`` BLOB columns
# kept on the match tables. ``hex_lower`` is the UDF registered on the ledger
# and state connections (see ``hashcodec.register_db_functions``).
MATCH_ID_SQL = f"hex_lower(tx0_hash) || '{ID_SEPARATOR}' || hex_lower(tx1_hash)"


# ORACLES
def satoshirate_to_fiat(satoshirate):
    return round(satoshirate / 100.0, 2)


class SingletonMeta(type):
    _instances = {}
    # Class-level lock prevents double-instantiation when two MainProcess
    # threads (e.g. an APIv1 worker calling LedgerDBConnectionPool() and
    # the parser thread doing the same) both pass the `not in _instances`
    # check before either has stored its instance. Without the lock, both
    # call __init__, both store, the second overwrites the first, one
    # APSW connection leaks, and the canonical singleton may be the wrong
    # one (later .close() on _instances[cls] closes the wrong instance).
    _lock = threading.Lock()

    def __call__(cls, *args, **kwargs):
        """
        Possible changes to the value of the `__init__` argument do not affect
        the returned instance.
        """
        if cls not in cls._instances:
            with cls._lock:
                # Re-check inside the lock (double-checked locking) so we don't
                # construct twice if two threads both pass the outer check.
                if cls not in cls._instances:
                    instance = super().__call__(*args, **kwargs)
                    cls._instances[cls] = instance
        return cls._instances[cls]

    def reset_instance(cls):
        """Force reinitialization of the singleton instance."""
        with cls._lock:
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
    if value2 == 0 or value1 == 0:
        return D(0)
    with decimal.localcontext() as ctx:
        ctx.prec = 16
        return D(value1) / D(value2)


def setup_bitcoinutils(network=None):
    current_network = network or config.NETWORK_NAME
    if current_network.startswith("testnet") or current_network == "signet":
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

        if repo.head_is_detached:
            return commit_hash

        branch_name = repo.head.shorthand
        return f"{branch_name} - {commit_hash}"
    except pygit2.GitError:  # pylint: disable=E1101
        return None


TEXTUAL_APPLICATION_MIME_TYPES = frozenset(
    [
        "application/xml",
        "application/javascript",
        "application/ecmascript",
        "application/x-javascript",
        "application/json",
        "application/manifest+json",
        "application/x-python-code",
        "application/x-sh",
        "application/x-csh",
        "application/x-tex",
        "application/x-latex",
        "application/postscript",
        "application/yaml",
        "application/x-yaml",
        "application/sql",
    ]
)


# Hard-coded MIME-type allow-list used by `check_content` once
# `extended_mime_types_support` activates. This MUST be deterministic
# across operating systems and Python builds: previously we relied on
# `mimetypes.types_map` populated by `mimetypes.init()`, but that reads
# /etc/mime.types (Unix) or the Windows registry, so the set of accepted
# types varied per node (~799 on macOS without /etc/mime.types, ~1000+
# on Ubuntu, ~200 on Alpine). A CBOR issuance / fairminter / broadcast
# carrying e.g. `application/x-vnd.mozilla.xml-encoded` would have been
# accepted on a Debian node and rejected on a macOS node, forking the
# chain. The list below is a fixed snapshot covering:
#   - Python's built-in `mimetypes._types_map_default` (~92 types) so we
#     don't regress vs. the legacy pre-gate behaviour
#   - the textual `application/*` types from
#     `TEXTUAL_APPLICATION_MIME_TYPES` (kept in sync below)
#   - the ordinal-inscription staples (`audio/ogg`, `audio/wav`,
#     `audio/flac`, `image/webp`, `image/apng`, `model/stl`,
#     `model/gltf-binary`, etc.) since the immediate motivation for
#     this protocol change is to permit ord-style inscriptions whose
#     MIME types are not all in Python's built-in defaults.
EXTENDED_MIME_TYPES_VALID = frozenset(
    [
        # ----- application/* (binary + textual) -----
        "application/atom+xml",
        "application/ecmascript",
        "application/gzip",
        "application/javascript",
        "application/json",
        "application/ld+json",
        "application/manifest+json",
        "application/msword",
        "application/n-quads",
        "application/n-triples",
        "application/octet-stream",
        "application/oda",
        "application/ogg",
        "application/pdf",
        "application/pkcs7-mime",
        "application/postscript",
        "application/rss+xml",
        "application/sql",
        "application/trig",
        "application/vnd.apple.mpegurl",
        "application/vnd.ms-excel",
        "application/vnd.ms-powerpoint",
        "application/wasm",
        "application/x-7z-compressed",
        "application/x-bcpio",
        "application/x-bzip",
        "application/x-bzip2",
        "application/x-cpio",
        "application/x-csh",
        "application/x-dvi",
        "application/x-gtar",
        "application/x-hdf",
        "application/x-hdf5",
        "application/x-javascript",
        "application/x-latex",
        "application/x-mif",
        "application/x-netcdf",
        "application/x-pkcs12",
        "application/x-pn-realaudio",
        "application/x-python-code",
        "application/x-rar-compressed",
        "application/x-sh",
        "application/x-shar",
        "application/x-shockwave-flash",
        "application/x-sv4cpio",
        "application/x-sv4crc",
        "application/x-tar",
        "application/x-tcl",
        "application/x-tex",
        "application/x-texinfo",
        "application/x-troff",
        "application/x-troff-man",
        "application/x-troff-me",
        "application/x-troff-ms",
        "application/x-ustar",
        "application/x-wais-source",
        "application/x-yaml",
        "application/xhtml+xml",
        "application/xml",
        "application/yaml",
        "application/zip",
        # ----- audio/* -----
        "audio/3gpp",
        "audio/3gpp2",
        "audio/aac",
        "audio/basic",
        "audio/flac",
        "audio/midi",
        "audio/mp4",
        "audio/mpeg",
        "audio/ogg",
        "audio/opus",
        "audio/wav",
        "audio/webm",
        "audio/x-aiff",
        "audio/x-flac",
        "audio/x-m4a",
        "audio/x-pn-realaudio",
        "audio/x-wav",
        # ----- font/* -----
        "font/otf",
        "font/ttf",
        "font/woff",
        "font/woff2",
        # ----- image/* -----
        "image/apng",
        "image/avif",
        "image/bmp",
        "image/gif",
        "image/heic",
        "image/heif",
        "image/ief",
        "image/jpeg",
        "image/png",
        "image/svg+xml",
        "image/tiff",
        "image/vnd.microsoft.icon",
        "image/webp",
        "image/x-cmu-raster",
        "image/x-icon",
        "image/x-portable-anymap",
        "image/x-portable-bitmap",
        "image/x-portable-graymap",
        "image/x-portable-pixmap",
        "image/x-rgb",
        "image/x-xbitmap",
        "image/x-xpixmap",
        "image/x-xwindowdump",
        # ----- message/* -----
        "message/rfc822",
        # ----- model/* (ordinal 3D inscriptions) -----
        "model/gltf+json",
        "model/gltf-binary",
        "model/stl",
        # ----- text/* -----
        "text/css",
        "text/csv",
        "text/html",
        "text/javascript",
        "text/markdown",
        "text/n3",
        "text/plain",
        "text/richtext",
        "text/tab-separated-values",
        "text/vtt",
        "text/x-python",
        "text/x-rst",
        "text/x-setext",
        "text/x-sgml",
        "text/x-vcard",
        "text/xml",
        "text/yaml",
        # ----- video/* -----
        "video/3gpp",
        "video/3gpp2",
        "video/mp4",
        "video/mpeg",
        "video/ogg",
        "video/quicktime",
        "video/webm",
        "video/x-flv",
        "video/x-matroska",
        "video/x-msvideo",
        "video/x-sgi-movie",
    ]
    # Belt-and-braces: also accept everything classified as textual
    # `application/*`, so the two allow-lists can never drift apart.
).union(TEXTUAL_APPLICATION_MIME_TYPES)


def _strip_mime_parameters(mime_type):
    # `audio/ogg;codecs=opus` -> `audio/ogg`; only called from the
    # `extended_mime_types_support`-gated branches. The non-string guard
    # is for the post-gate path: a CBOR-decoded `mime_type` may be any
    # scalar (post-taproot_support; see `fuzz_cbor_test.py`), and after
    # the gate we want validation to flag it cleanly via "Invalid mime
    # type" rather than halt with `AttributeError`. Pre-gate callers
    # never reach here -- the legacy classifier raises `AttributeError`,
    # which is consensus-baked behaviour caught by `unpack`'s broad-except.
    if not isinstance(mime_type, str):
        return ""
    return mime_type.split(";")[0].strip()


def classify_mime_type(mime_type, block_index=None):
    # Imported lazily to avoid a circular dependency:
    # `protocol` -> `currentstate` -> `helpers`.
    # pylint: disable=import-outside-toplevel
    from counterpartycore.lib.parser import protocol  # noqa: PLC0415

    # After `extended_mime_types_support`, MIME parameters (e.g. `;codecs=opus`)
    # are tolerated and additional structured-suffix types (`+json`) are
    # treated as textual.
    if protocol.enabled("extended_mime_types_support", block_index=block_index):
        # Halt-vector guard gated with the same protocol change: pre-gate, a
        # non-string `mime_type` raises `AttributeError` here -- preserved
        # because the historical behaviour (caught downstream by `unpack`'s
        # broad-except, which falls back to legacy struct decoding with
        # `mime_type="text/plain"`) is consensus-baked since taproot_support
        # activated. Changing it pre-gate would diverge from any node still
        # running the legacy code.
        if not isinstance(mime_type, str):
            return "binary"
        target = _strip_mime_parameters(mime_type)
        if (
            target.startswith("text/")
            or target.startswith("message/")
            or target.endswith("+xml")
            or target.endswith("+json")
        ):
            return "text"
        if target in TEXTUAL_APPLICATION_MIME_TYPES:
            return "text"
        return "binary"

    if (
        mime_type.startswith("text/")
        or mime_type.startswith("message/")
        or mime_type.endswith("+xml")
    ):
        return "text"

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

    return "binary"


def content_to_bytes(content: str, mime_type: str, block_index=None) -> bytes:
    file_type = classify_mime_type(mime_type, block_index=block_index)
    if file_type == "text":
        return content.encode("utf-8")
    return binascii.unhexlify(content)


def bytes_to_content(content: bytes, mime_type: str, block_index=None) -> str:
    file_type = classify_mime_type(mime_type, block_index=block_index)
    if file_type == "text":
        return content.decode("utf-8")
    return binascii.hexlify(content).decode("utf-8")


def check_content(mime_type, content, block_index=None):
    # Imported lazily to avoid a circular dependency.
    # pylint: disable=import-outside-toplevel
    from counterpartycore.lib.parser import protocol  # noqa: PLC0415

    problems = []
    content_mime_type = mime_type or "text/plain"
    if protocol.enabled("extended_mime_types_support", block_index=block_index):
        # Validate against the deterministic hard-coded allow-list.
        # `mimetypes.init()` MUST NOT be called here: it loads
        # /etc/mime.types / Windows registry, which differs per node and
        # would fork consensus. See `EXTENDED_MIME_TYPES_VALID` above.
        type_to_check = _strip_mime_parameters(content_mime_type)
        valid_types = EXTENDED_MIME_TYPES_VALID
    else:
        # Pre-gate: stay on Python's built-in `_types_map_default`
        # (the ~92 stable defaults), which is what the legacy code
        # used implicitly. Note: without `mimetypes.init()`, the
        # platform-specific entries are NOT loaded -- this is the
        # historical behaviour we are preserving for the legacy path.
        type_to_check = content_mime_type
        # Use the built-in default map only; never `types_map.values()` which
        # picks up OS-specific entries if anything calls mimetypes.init().
        valid_types = mimetypes._types_map_default.values()  # noqa: SLF001  # pylint: disable=protected-access
    if type_to_check not in valid_types:
        problems.append(f"Invalid mime type: {mime_type}")
    try:
        content_to_bytes(content, content_mime_type, block_index=block_index)
    except Exception as e:  # pylint: disable=broad-exception-caught
        problems.append(f"Error converting description to bytes: {e}")
    return problems
