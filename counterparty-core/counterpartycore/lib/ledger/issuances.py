#####################
#     ISSUANCES     #
#####################

import fractions
import logging
from decimal import Decimal as D

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.ledger.caches import AssetCache
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.ledger.events import insert_update
from counterpartycore.lib.ledger.supplies import asset_supply
from counterpartycore.lib.parser import protocol
from counterpartycore.lib.utils import assetnames

logger = logging.getLogger(config.LOGGER_NAME)


def generate_asset_id(asset_name):
    """Create asset_id from asset_name."""
    if asset_name == config.BTC:
        return 0
    elif asset_name == config.XCP:
        return 1

    if len(asset_name) < 4:
        raise exceptions.AssetNameError("too short")

    # Numeric asset names.
    if protocol.enabled("numeric_asset_names"):  # Protocol change.
        if asset_name[0] == "A":
            # Must be numeric.
            try:
                asset_id = int(asset_name[1:])
            except ValueError:
                raise exceptions.AssetNameError("non‐numeric asset name starts with ‘A’")  # noqa: B904

            # Number must be in range.
            if not (26**12 + 1 <= asset_id <= 2**64 - 1):
                raise exceptions.AssetNameError("numeric asset name not in range")

            return asset_id
        elif len(asset_name) >= 13:
            raise exceptions.AssetNameError("long asset names must be numeric")

    if asset_name[0] == "A":
        raise exceptions.AssetNameError("non‐numeric asset name starts with ‘A’")

    # Convert the Base 26 string to an integer.
    n = 0
    for c in asset_name:
        n *= 26
        if c not in assetnames.B26_DIGITS:
            raise exceptions.AssetNameError("invalid character:", c)
        digit = assetnames.B26_DIGITS.index(c)
        n += digit
    asset_id = n

    # sanity check
    assert asset_id >= 26**3

    return asset_id


def generate_asset_name(asset_id):
    """Create asset_name from asset_id."""
    if asset_id == 0:
        return config.BTC
    elif asset_id == 1:
        return config.XCP

    if asset_id < 26**3:
        raise exceptions.AssetIDError("too low")

    if protocol.enabled("numeric_asset_names"):  # Protocol change.
        if asset_id <= 2**64 - 1:
            if 26**12 + 1 <= asset_id:
                asset_name = "A" + str(asset_id)
                return asset_name
        else:
            raise exceptions.AssetIDError("too high")

    # Divide that integer into Base 26 string.
    res = []
    n = asset_id
    while n > 0:
        n, r = divmod(n, 26)
        res.append(assetnames.B26_DIGITS[r])
    asset_name = "".join(res[::-1])

    """
    return asset_name + checksum.compute(asset_name)
    """
    return asset_name


def get_asset_id(db, asset_name):
    """Return asset_id from asset_name."""
    if not protocol.enabled("hotfix_numeric_assets"):
        return generate_asset_id(asset_name)
    cursor = db.cursor()
    query = """
        SELECT * FROM assets
        WHERE asset_name = ?
    """
    bindings = (asset_name,)
    cursor.execute(query, bindings)
    assets = list(cursor)
    if len(assets) == 1:
        return int(assets[0]["asset_id"])
    else:
        raise exceptions.AssetError(f"No such asset: {asset_name}")


def get_asset_name(db, asset_id):
    """Return asset_name from asset_id."""
    if not protocol.enabled("hotfix_numeric_assets"):
        return generate_asset_name(asset_id)
    cursor = db.cursor()
    query = """
        SELECT * FROM assets
        WHERE asset_id = ?
    """
    bindings = (str(asset_id),)
    cursor.execute(query, bindings)
    assets = list(cursor)
    if len(assets) == 1:
        return assets[0]["asset_name"]
    elif not assets:
        return 0  # Strange, I know…


# If asset_name is an existing subasset (PARENT.child) then return the corresponding numeric asset name (A12345)
#   If asset_name is not an existing subasset, then return the unmodified asset_name
def resolve_subasset_longname(db, asset_name):
    if protocol.enabled("subassets"):
        subasset_longname = None
        try:
            _subasset_parent, subasset_longname = assetnames.parse_subasset_from_asset_name(
                asset_name, protocol.enabled("allow_subassets_on_numerics")
            )
        except Exception:  # pylint: disable=broad-except  # noqa: F841
            logger.warning("Invalid subasset %s", asset_name)
            subasset_longname = None

        if subasset_longname is not None:
            cursor = db.cursor()
            query = """
                SELECT asset_name FROM assets
                WHERE asset_longname = ?
            """
            bindings = (subasset_longname,)
            cursor.execute(query, bindings)
            assets = list(cursor)
            cursor.close()
            if len(assets) == 1:
                return assets[0]["asset_name"]

    return asset_name


def is_divisible(db, asset):
    """Check if the asset is divisible."""
    if asset in (config.BTC, config.XCP):
        return True
    else:
        cursor = db.cursor()
        query = """
            SELECT * FROM issuances
            WHERE (status = ? AND asset = ?)
            ORDER BY tx_index DESC
        """
        bindings = ("valid", asset)
        cursor.execute(query, bindings)
        issuances = cursor.fetchall()
        if not issuances:
            raise exceptions.AssetError(f"No such asset: {asset}")
        return issuances[0]["divisible"]


def value_input(quantity, asset, divisible):
    if asset == "leverage":
        return round(quantity)

    if asset in ("value", "fraction", "price", "odds"):
        return float(quantity)  # TODO: Float?!

    if divisible:
        quantity = D(quantity) * config.UNIT
        if quantity == quantity.to_integral():
            return int(quantity)
        else:
            raise exceptions.QuantityError(
                "Divisible assets have only eight decimal places of precision."
            )
    else:
        quantity = D(quantity)
        if quantity != round(quantity):
            raise exceptions.QuantityError("Fractional quantities of indivisible assets.")
        return round(quantity)


def norm(num, places):
    """Round only if necessary."""
    num = round(num, places)
    fmt = "{:." + str(places) + "f}"
    num = fmt.format(num)
    return num.rstrip("0") + "0" if num.rstrip("0")[-1] == "." else num.rstrip("0")


def value_output(quantity, asset, divisible):
    if asset == "fraction":
        return str(norm(D(quantity) * D(100), 6)) + "%"

    if asset in ("leverage", "value", "price", "odds"):
        return norm(quantity, 6)

    if divisible:
        quantity = D(quantity) / D(config.UNIT)
        if quantity == quantity.to_integral():
            return str(quantity) + ".0"  # For divisible assets, display the decimal point.
        else:
            return norm(quantity, 8)
    else:
        quantity = D(quantity)
        if quantity != round(quantity):
            raise exceptions.QuantityError("Fractional quantities of indivisible assets.")
        return round(quantity)


def value_out(db, quantity, asset, divisible=None):
    if asset not in ["leverage", "value", "fraction", "price", "odds"] and divisible is None:
        divisible = is_divisible(db, asset)
    return value_output(quantity, asset, divisible)


def value_in(db, quantity, asset, divisible=None):
    if asset not in ["leverage", "value", "fraction", "price", "odds"] and divisible is None:
        divisible = is_divisible(db, asset)
    return value_input(quantity, asset, divisible)


def price(numerator, denominator):
    """Return price as Fraction or Decimal."""
    if protocol.after_block_or_test_network(
        CurrentState().current_block_index(), 294500
    ):  # Protocol change.
        return fractions.Fraction(numerator, denominator)
    else:
        numerator = D(numerator)
        denominator = D(denominator)
        return D(numerator / denominator)


def get_asset_issuer(db, asset):
    """Check if the asset is divisible."""
    if asset in (config.BTC, config.XCP):
        return True
    else:
        cursor = db.cursor()
        query = """
            SELECT * FROM issuances
            WHERE (status = ? AND asset = ?)
            ORDER BY tx_index DESC
        """
        bindings = ("valid", asset)
        cursor.execute(query, bindings)
        issuances = cursor.fetchall()
        if not issuances:
            raise exceptions.AssetError(f"No such asset: {asset}")
        return issuances[0]["issuer"]


def get_asset_description(db, asset):
    if asset in (config.BTC, config.XCP):
        return ""
    else:
        cursor = db.cursor()
        query = """
            SELECT * FROM issuances
            WHERE (status = ? AND asset = ?)
            ORDER BY tx_index DESC
        """
        bindings = ("valid", asset)
        cursor.execute(query, bindings)
        issuances = cursor.fetchall()
        if not issuances:
            raise exceptions.AssetError(f"No such asset: {asset}")
        return issuances[0]["description"]


def get_issuances_count(db, address):
    cursor = db.cursor()
    query = """
        SELECT COUNT(DISTINCT(asset)) cnt
        FROM issuances
        WHERE issuer = ?
    """
    bindings = (address,)
    cursor.execute(query, bindings)
    return cursor.fetchall()[0]["cnt"]


def get_asset_issued(db, address):
    cursor = db.cursor()
    query = """
        SELECT DISTINCT(asset)
        FROM issuances
        WHERE issuer = ?
    """
    bindings = (address,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_assets_last_issuance(state_db, asset_list):
    assets_info = []
    cursor = state_db.cursor()
    fields = ["asset", "asset_longname", "description", "issuer", "divisible", "locked", "owner"]

    asset_name_list = [asset for asset in asset_list if asset and "." not in asset]
    if len(asset_name_list) > 0:
        query = f"""
            SELECT {", ".join(fields)} FROM assets_info
            WHERE asset IN ({",".join(["?"] * len(asset_name_list))})
        """  # nosec B608  # noqa: S608 # nosec B608
        cursor.execute(query, asset_name_list)
        assets_info += cursor.fetchall()

    asset_longname_list = [asset for asset in asset_list if asset and "." in asset]
    if len(asset_longname_list) > 0:
        query = f"""
            SELECT {", ".join(fields)} FROM assets_info
            WHERE asset_longname IN ({",".join(["?"] * len(asset_longname_list))})
        """  # nosec B608  # noqa: S608 # nosec B608
        cursor.execute(query, asset_longname_list)
        assets_info += cursor.fetchall()

    result = {
        "BTC": {
            "divisible": True,
            "asset_longname": None,
            "description": "The Bitcoin cryptocurrency",
            "locked": False,
            "issuer": None,
        },
        "XCP": {
            "divisible": True,
            "asset_longname": None,
            "description": "The Counterparty protocol native currency",
            "locked": True,
            "issuer": None,
        },
    }
    for asset_info in assets_info:
        if asset_info["asset_longname"] and asset_info["asset_longname"] in asset_list:
            result[asset_info["asset_longname"]] = asset_info
            result[asset_info["asset"]] = asset_info
        else:
            asset = asset_info["asset"]
            del asset_info["asset"]
            result[asset] = asset_info

    return result


def get_issuances(
    db,
    asset=None,
    status=None,
    locked=None,
    block_index=None,
    first=False,
    last=False,
    current_block_index=None,
):
    cursor = db.cursor()
    cursor = db.cursor()
    where = []
    bindings = []
    if status is not None:
        where.append("status = ?")
        bindings.append(status)
    if asset is not None:
        where.append("asset = ?")
        bindings.append(asset)
    if locked is not None:
        where.append("locked = ?")
        bindings.append(locked)
    if block_index is not None:
        where.append("block_index = ?")
        bindings.append(block_index)
    # no sql injection here
    query = f"""SELECT * FROM issuances WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608 # nosec B608
    if protocol.enabled("fix_get_issuances", current_block_index):
        order_fields = "rowid, tx_index"
    else:
        order_fields = "tx_index"
    if first:
        query += f""" ORDER BY {order_fields} ASC"""  # noqa: F541
    elif last:
        query += f""" ORDER BY {order_fields} DESC"""  # noqa: F541
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_assets_by_longname(db, asset_longname):
    cursor = db.cursor()
    query = """
        SELECT * FROM assets
        WHERE (asset_longname = ?)
    """
    bindings = (asset_longname,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_last_issuance_no_cache(db, asset):
    last_issuance = get_asset(db, asset)
    del last_issuance["supply"]
    return last_issuance


def get_last_issuance(db, asset):
    return AssetCache(db).assets.get(asset)


def get_asset(db, asset):
    cursor = db.cursor()
    name_field = "asset_longname" if "." in asset else "asset"
    query = f"""
        SELECT * FROM issuances
        WHERE ({name_field} = ? AND status = ?)
        ORDER BY tx_index DESC
    """  # nosec B608  # noqa: S608 # nosec B608
    bindings = (asset, "valid")
    cursor.execute(query, bindings)
    issuances = cursor.fetchall()
    if not issuances:
        return None

    locked = False
    for issuance in issuances:
        if issuance["locked"]:
            locked = True
            break

    asset = issuances[0]
    asset["supply"] = asset_supply(db, issuances[0]["asset"])
    asset["locked"] = locked
    return asset


#####################
#     FAIRMINTER    #
#####################


def get_fairminters_to_open(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT *, MAX(rowid) AS rowid FROM fairminters
        WHERE start_block = :start_block
        GROUP BY tx_hash
        ORDER BY tx_index
    """
    bindings = {
        "start_block": block_index,
    }
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_fairminters_to_close(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid FROM fairminters
            WHERE end_block = :end_block
            GROUP BY tx_hash
        ) WHERE status != :status
        ORDER BY tx_index
    """
    bindings = {
        "status": "closed",
        "end_block": block_index,
    }
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_fairminter_by_asset(db, asset):
    cursor = db.cursor()
    query = """
        SELECT * FROM fairminters
        WHERE asset = ?
        ORDER BY rowid DESC LIMIT 1
    """
    bindings = (asset,)
    cursor.execute(query, bindings)
    return cursor.fetchone()


def get_fairmint_quantities(db, fairminter_tx_hash):
    cursor = db.cursor()
    query = """
        SELECT
            SUM(earn_quantity) AS quantity,
            SUM(paid_quantity) AS paid_quantity,
            SUM(commission) AS commission
        FROM fairmints
        WHERE fairminter_tx_hash = ? AND status = ?
    """
    bindings = (fairminter_tx_hash, "valid")
    cursor.execute(query, bindings)
    sums = cursor.fetchone()
    return (sums["quantity"] or 0) + (sums["commission"] or 0), (sums["paid_quantity"] or 0)


def get_fairminters_by_soft_cap_deadline(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid
            FROM fairminters
            WHERE soft_cap > 0 AND soft_cap_deadline_block = :block_index
            GROUP BY tx_hash
        ) WHERE status = :status
        ORDER BY tx_index
    """
    bindings = {
        "block_index": block_index,
        "status": "open",
    }
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_valid_fairmints(db, fairminter_tx_hash):
    cursor = db.cursor()
    query = """
        SELECT * FROM fairmints
        WHERE fairminter_tx_hash = ? AND status = ?
    """
    bindings = (fairminter_tx_hash, "valid")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def update_fairminter(db, tx_hash, update_data):
    insert_update(db, "fairminters", "tx_hash", tx_hash, update_data, "FAIRMINTER_UPDATE")
