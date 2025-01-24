import hashlib
import logging
import random
import re

from counterpartycore.lib import config, exceptions

logger = logging.getLogger(config.LOGGER_NAME)

B26_DIGITS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
# subasset contain only characters a-zA-Z0-9.-_@!
SUBASSET_DIGITS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_@!"
SUBASSET_REVERSE = {
    "a": 1,
    "b": 2,
    "c": 3,
    "d": 4,
    "e": 5,
    "f": 6,
    "g": 7,
    "h": 8,
    "i": 9,
    "j": 10,
    "k": 11,
    "l": 12,
    "m": 13,
    "n": 14,
    "o": 15,
    "p": 16,
    "q": 17,
    "r": 18,
    "s": 19,
    "t": 20,
    "u": 21,
    "v": 22,
    "w": 23,
    "x": 24,
    "y": 25,
    "z": 26,
    "A": 27,
    "B": 28,
    "C": 29,
    "D": 30,
    "E": 31,
    "F": 32,
    "G": 33,
    "H": 34,
    "I": 35,
    "J": 36,
    "K": 37,
    "L": 38,
    "M": 39,
    "N": 40,
    "O": 41,
    "P": 42,
    "Q": 43,
    "R": 44,
    "S": 45,
    "T": 46,
    "U": 47,
    "V": 48,
    "W": 49,
    "X": 50,
    "Y": 51,
    "Z": 52,
    "0": 53,
    "1": 54,
    "2": 55,
    "3": 56,
    "4": 57,
    "5": 58,
    "6": 59,
    "7": 60,
    "8": 61,
    "9": 62,
    ".": 63,
    "-": 64,
    "_": 65,
    "@": 66,
    "!": 67,
}


# checks and validates subassets (PARENT.SUBASSET)
#   throws exceptions for assset or subasset names with invalid syntax
#   returns (None, None) if the asset is not a subasset name
def parse_subasset_from_asset_name(asset, allow_subassets_on_numerics=False):
    subasset_parent = None
    subasset_child = None
    subasset_longname = None
    chunks = asset.split(".", 1)
    if len(chunks) == 2:
        subasset_parent = chunks[0]
        subasset_child = chunks[1]
        subasset_longname = asset

        # validate parent asset
        validate_subasset_parent_name(subasset_parent, allow_subassets_on_numerics)

        # validate child asset
        validate_subasset_longname(subasset_longname, subasset_child)

    return (subasset_parent, subasset_longname)


# throws exceptions for invalid subasset names
def validate_subasset_longname(subasset_longname, subasset_child=None):
    if subasset_child is None:
        chunks = subasset_longname.split(".", 1)
        if len(chunks) == 2:
            subasset_child = chunks[1]
        else:
            subasset_child = ""

    if len(subasset_child) < 1:
        raise exceptions.AssetNameError("subasset name too short")
    if len(subasset_longname) > 250:
        raise exceptions.AssetNameError("subasset name too long")

    # can't start with period, can't have consecutive periods, can't contain anything not in SUBASSET_DIGITS
    previous_digit = "."
    for c in subasset_child:
        if c not in SUBASSET_DIGITS:
            raise exceptions.AssetNameError("subasset name contains invalid character:", c)
        if c == "." and previous_digit == ".":
            raise exceptions.AssetNameError("subasset name contains consecutive periods")
        previous_digit = c
    if previous_digit == ".":
        raise exceptions.AssetNameError("subasset name ends with a period")

    return True


def is_numeric(s):
    pattern = r"^A(\d{17,20})$"
    match = re.match(pattern, s)
    if match:
        numeric_part = match.group(1)
        numeric_value = int(numeric_part)
        lower_bound = 26**12 + 1
        upper_bound = 256**8

        return lower_bound <= numeric_value <= upper_bound

    return False


def legacy_validate_subasset_parent_name(asset_name):
    if asset_name == config.BTC:
        raise exceptions.AssetNameError(f"parent asset cannot be {config.BTC}")
    if asset_name == config.XCP:
        raise exceptions.AssetNameError(f"parent asset cannot be {config.XCP}")
    if len(asset_name) < 4:
        raise exceptions.AssetNameError("parent asset name too short")
    if len(asset_name) >= 13:
        raise exceptions.AssetNameError("parent asset name too long")
    if asset_name[0] == "A":
        raise exceptions.AssetNameError("parent asset name starts with 'A'")
    for c in asset_name:
        if c not in B26_DIGITS:
            raise exceptions.AssetNameError("parent asset name contains invalid character:", c)
    return True


# throws exceptions for invalid subasset names
def validate_subasset_parent_name(asset_name, allow_subassets_on_numerics):
    if not allow_subassets_on_numerics:
        return legacy_validate_subasset_parent_name(asset_name)

    if asset_name == config.BTC:
        raise exceptions.AssetNameError(f"parent asset cannot be {config.BTC}")
    if asset_name == config.XCP:
        raise exceptions.AssetNameError(f"parent asset cannot be {config.XCP}")
    if len(asset_name) < 4:
        raise exceptions.AssetNameError("parent asset name too short")
    if len(asset_name) > 21:
        raise exceptions.AssetNameError("parent asset name too long")

    if not is_numeric(asset_name):
        for c in asset_name:
            if c not in B26_DIGITS:
                raise exceptions.AssetNameError("parent asset name contains invalid character:", c)

    return True


def compact_subasset_longname(string):
    """Compacts a subasset name string into an array of bytes to save space using a base68 encoding scheme.
    Assumes all characters provided belong to SUBASSET_DIGITS.
    """
    name_int = 0
    for i, c in enumerate(string[::-1]):
        name_int += (68**i) * SUBASSET_REVERSE[c]
    return name_int.to_bytes((name_int.bit_length() + 7) // 8, byteorder="big")


def expand_subasset_longname(raw_bytes):
    """Expands an array of bytes into a subasset name string."""
    integer = int.from_bytes(raw_bytes, byteorder="big")
    if integer == 0:
        return ""
    ret = ""
    while integer != 0:
        ret = SUBASSET_DIGITS[integer % 68 - 1] + ret
        integer //= 68
    return ret


def generate_random_asset(subasset_longname=None):
    # deterministic random asset name for regtest
    if config.REGTEST and subasset_longname:
        return "A" + str(
            int(hashlib.shake_256(bytes(subasset_longname, "utf8")).hexdigest(4), 16) + 26**12 + 1
        )
    # Standard pseudo-random generators are suitable for our purpose.
    return "A" + str(random.randint(26**12 + 1, 2**64 - 1))  # nosec B311  # noqa: S311


def gen_random_asset_name(seed, add=0):
    return "A" + str(
        int(hashlib.shake_256(bytes(seed, "utf8")).hexdigest(4), 16) + 26**12 + 1 + add
    )


def asset_exists(db, name):
    cursor = db.cursor()
    cursor.execute(
        "SELECT * FROM issuances WHERE asset = ?",
        (name,),
    )
    if cursor.fetchall():
        return True
    return False


def deterministic_random_asset_name(db, seed):
    asset_name = gen_random_asset_name(seed)
    add = 0
    while asset_exists(db, asset_name):
        asset_name = gen_random_asset_name(seed, add=add)
        add += 1
    return asset_name
