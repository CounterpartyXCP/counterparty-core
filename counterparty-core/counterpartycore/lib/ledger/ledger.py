import fractions
import logging
from decimal import Decimal as D

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.ledger.caches import AssetCache, OrdersCache
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.ledger.events import insert_record, insert_update
from counterpartycore.lib.ledger.supplies import asset_supply
from counterpartycore.lib.parser import protocol
from counterpartycore.lib.utils import assetnames

logger = logging.getLogger(config.LOGGER_NAME)


#####################
#     ISSUANCES     #
#####################


def generate_asset_id(asset_name, block_index):
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

    if asset_id < 26**3:
        raise exceptions.AssetNameError("too short")

    return asset_id


def generate_asset_name(asset_id, block_index):
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


def get_asset_id(db, asset_name, block_index):
    """Return asset_id from asset_name."""
    if not protocol.enabled("hotfix_numeric_assets"):
        return generate_asset_id(asset_name, block_index)
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


def get_asset_name(db, asset_id, block_index):
    """Return asset_name from asset_id."""
    if not protocol.enabled("hotfix_numeric_assets"):
        return generate_asset_name(asset_id, block_index)
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
        except Exception as e:  # noqa: F841
            logger.warning(f"Invalid subasset {asset_name}")
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


def value_output(quantity, asset, divisible):
    def norm(num, places):
        """Round only if necessary."""
        num = round(num, places)
        fmt = "{:." + str(places) + "f}"
        # pylint: disable=C0209
        num = fmt.format(num)
        return num.rstrip("0") + "0" if num.rstrip("0")[-1] == "." else num.rstrip("0")

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
    if asset not in ["leverage", "value", "fraction", "price", "odds"] and divisible == None:  # noqa: E711
        divisible = is_divisible(db, asset)
    return value_output(quantity, asset, divisible)


def value_in(db, quantity, asset, divisible=None):
    if asset not in ["leverage", "value", "fraction", "price", "odds"] and divisible == None:  # noqa: E711
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


def get_asset_issuances_quantity(db, asset):
    cursor = db.cursor()
    query = """
        SELECT COUNT(*) AS issuances_count
        FROM issuances
        WHERE (status = ? AND asset = ?)
        ORDER BY tx_index DESC
    """
    bindings = ("valid", asset)
    cursor.execute(query, bindings)
    issuances = cursor.fetchall()
    return issuances[0]["issuances_count"]


def get_assets_last_issuance(state_db, asset_list):
    assets_info = []
    cursor = state_db.cursor()
    fields = ["asset", "asset_longname", "description", "issuer", "divisible", "locked"]

    asset_name_list = [asset for asset in asset_list if asset and "." not in asset]
    if len(asset_name_list) > 0:
        query = f"""
            SELECT {", ".join(fields)} FROM assets_info
            WHERE asset IN ({",".join(["?"] * len(asset_name_list))})
        """  # nosec B608  # noqa: S608
        cursor.execute(query, asset_name_list)
        assets_info += cursor.fetchall()

    asset_longname_list = [asset for asset in asset_list if asset and "." in asset]
    if len(asset_longname_list) > 0:
        query = f"""
            SELECT {", ".join(fields)} FROM assets_info
            WHERE asset_longname IN ({",".join(["?"] * len(asset_longname_list))})
        """  # nosec B608  # noqa: S608
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
    query = f"""SELECT * FROM issuances WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608
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
    """  # nosec B608  # noqa: S608
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
    asset["supply"] = asset_supply(db, issuance["asset"])
    asset["locked"] = locked
    return asset


#####################
#    BROADCASTS     #
#####################


def get_oracle_last_price(db, oracle_address, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM broadcasts
        WHERE source = :source AND status = :status AND block_index < :block_index
        ORDER by tx_index DESC LIMIT 1
    """
    bindings = {"source": oracle_address, "status": "valid", "block_index": block_index}
    cursor.execute(query, bindings)
    broadcasts = cursor.fetchall()
    cursor.close()

    if len(broadcasts) == 0:
        return None, None, None, None

    oracle_broadcast = broadcasts[0]
    oracle_label = oracle_broadcast["text"].split("-")
    if len(oracle_label) == 2:
        fiat_label = oracle_label[1]
    else:
        fiat_label = ""

    return (
        oracle_broadcast["value"],
        oracle_broadcast["fee_fraction_int"],
        fiat_label,
        oracle_broadcast["block_index"],
    )


def get_broadcasts_by_source(db, address: str, status: str = "valid", order_by: str = "DESC"):
    """
    Returns the broadcasts of a source
    :param str address: The address to return (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param str status: The status of the broadcasts to return (e.g. valid)
    :param str order_by: The order of the broadcasts to return (e.g. ASC)
    """
    if order_by not in ["ASC", "DESC"]:
        raise exceptions.InvalidArgument("Invalid order_by parameter")
    cursor = db.cursor()
    query = f"""
        SELECT * FROM broadcasts
        WHERE (status = ? AND source = ?)
        ORDER BY tx_index {order_by}
    """  # nosec B608  # noqa: S608
    bindings = (status, address)
    cursor.execute(query, bindings)
    return cursor.fetchall()


#####################
#       BURNS       #
#####################


def get_burns(db, address: str = None, status: str = "valid"):
    """
    Returns the burns of an address
    :param str address: The address to return
    :param str status: The status of the burns to return
    """
    cursor = db.cursor()
    where = []
    bindings = []
    if status is not None:
        where.append("status = ?")
        bindings.append(status)
    if address is not None:
        where.append("source = ?")
        bindings.append(address)
    # no sql injection here
    query = f"""SELECT * FROM burns WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


######################################
#       BLOCKS AND TRANSACTIONS      #
######################################


def get_addresses(db, address=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if address is not None:
        where.append("address = ?")
        bindings.append(address)
    # no sql injection here
    query = f"""SELECT *, MAX(rowid) AS rowid FROM addresses WHERE ({" AND ".join(where)}) GROUP BY address"""  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_send_msg_index(db, tx_hash):
    cursor = db.cursor()
    last_msg_index = cursor.execute(
        """
        SELECT MAX(msg_index) as msg_index FROM sends WHERE tx_hash = ?
    """,
        (tx_hash,),
    ).fetchone()
    if last_msg_index and last_msg_index["msg_index"] is not None:
        msg_index = last_msg_index["msg_index"] + 1
    else:
        msg_index = 0
    return msg_index


#####################
#     DISPENSERS    #
#####################

### SELECTS ###


def get_dispenser_info(db, tx_hash=None, tx_index=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if tx_hash is not None:
        where.append("tx_hash = ?")
        bindings.append(tx_hash)
    if tx_index is not None:
        where.append("tx_index = ?")
        bindings.append(tx_index)
    # no sql injection here
    query = f"""
        SELECT *
        FROM dispensers
        WHERE ({" AND ".join(where)})
        ORDER BY rowid DESC LIMIT 1
    """  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_dispensers_info(db, tx_hash_list):
    cursor = db.cursor()
    query = """
        SELECT *, MAX(rowid) AS rowid FROM dispensers
        WHERE tx_hash IN ({})
        GROUP BY tx_hash
    """.format(",".join(["?" for e in range(0, len(tx_hash_list))]))  # nosec B608  # noqa: S608
    cursor.execute(query, tx_hash_list)
    dispensers = cursor.fetchall()
    result = {}
    for dispenser in dispensers:
        del dispenser["rowid"]
        tx_hash = dispenser["tx_hash"]
        del dispenser["tx_hash"]
        del dispenser["asset"]
        result[tx_hash] = dispenser
    return result


def get_refilling_count(db, dispenser_tx_hash):
    cursor = db.cursor()
    query = """
        SELECT count(*) cnt
        FROM dispenser_refills
        WHERE dispenser_tx_hash = ?
    """
    bindings = (dispenser_tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()[0]["cnt"]


def get_pending_dispensers(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid
            FROM dispensers
            WHERE close_block_index = :close_block_index
            GROUP BY source, asset
        )
        WHERE status = :status_closing
        ORDER BY tx_index
    """
    bindings = {
        "close_block_index": block_index,
        "status_closing": 11,  # STATUS_CLOSING
    }
    cursor.execute(query, bindings)
    result = cursor.fetchall()

    return result


def get_dispensers_count(db, source, status, origin):
    cursor = db.cursor()
    query = """
        SELECT count(*) cnt FROM (
            SELECT *, MAX(rowid)
            FROM dispensers
            WHERE source = ? AND origin = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index
    """
    bindings = (source, origin, status)
    cursor.execute(query, bindings)
    return cursor.fetchall()[0]["cnt"]


def get_dispenses_count(db, dispenser_tx_hash, from_block_index):
    cursor = db.cursor()
    query = """
        SELECT COUNT(*) AS dispenses_count
        FROM dispenses
        WHERE dispenser_tx_hash = :dispenser_tx_hash
        AND block_index >= :block_index
    """
    bindings = {"dispenser_tx_hash": dispenser_tx_hash, "block_index": from_block_index}
    cursor.execute(query, bindings)
    dispenses_count_result = cursor.fetchall()[0]
    return dispenses_count_result["dispenses_count"]


def get_last_refills_block_index(db, dispenser_tx_hash):
    cursor = db.cursor()
    query = """
        SELECT MAX(block_index) AS max_block_index
        FROM dispenser_refills
        WHERE dispenser_tx_hash = :dispenser_tx_hash
    """
    bindings = {"dispenser_tx_hash": dispenser_tx_hash}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_dispenser(db, tx_hash):
    cursor = db.cursor()
    query = """
        SELECT * FROM dispensers
        WHERE tx_hash = ?
        ORDER BY rowid DESC LIMIT 1
    """
    bindings = (tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_dispensers(
    db,
    status_in=None,
    source_in=None,
    address=None,
    asset=None,
    origin=None,
    status=None,
    tx_hash=None,
    order_by=None,
    group_by=None,
):
    cursor = db.cursor()
    bindings = []
    # where for immutable fields
    first_where = []
    if address is not None:
        first_where.append("source = ?")
        bindings.append(address)
    if source_in is not None:
        first_where.append(f"source IN ({','.join(['?' for e in range(0, len(source_in))])})")
        bindings += source_in
    if asset is not None:
        first_where.append("asset = ?")
        bindings.append(asset)
    if origin is not None:
        first_where.append("origin = ?")
        bindings.append(origin)
    # where for mutable fields
    second_where = []
    if status is not None:
        second_where.append("status = ?")
        bindings.append(status)
    if status_in is not None:
        second_where.append(f"status IN ({','.join(['?' for e in range(0, len(status_in))])})")
        bindings += status_in
    # build query
    first_where_str = " AND ".join(first_where)
    if first_where_str != "":
        first_where_str = f"WHERE ({first_where_str})"
    second_where_str = " AND ".join(second_where)
    if second_where_str != "":
        second_where_str = f"WHERE ({second_where_str})"
    order_clause = f"ORDER BY {order_by}" if order_by is not None else "ORDER BY tx_index"
    group_clause = f"GROUP BY {group_by}" if group_by is not None else "GROUP BY asset, source"
    # no sql injection here
    query = f"""
        SELECT *, rowid FROM (
            SELECT *, MAX(rowid) as rowid
            FROM dispensers
            {first_where_str}
            {group_clause}
        ) {second_where_str}
        {order_clause}
    """  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_all_dispensables(db):
    cursor = db.cursor()
    query = """SELECT DISTINCT source AS source FROM dispensers"""
    dispensables = {}
    for row in cursor.execute(query).fetchall():
        dispensables[row["source"]] = True
    return dispensables


### UPDATES ###


def update_dispenser(db, rowid, update_data, dispenser_info):
    insert_update(db, "dispensers", "rowid", rowid, update_data, "DISPENSER_UPDATE", dispenser_info)


#####################
#       BETS        #
#####################

### SELECTS ###


def get_pending_bet_matches(db, feed_address, order_by=None):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM bet_matches
            WHERE feed_address = ?
            GROUP BY id
        ) WHERE status = ?
    """
    if order_by is not None:
        query += f""" ORDER BY {order_by}"""
    else:
        query += f""" ORDER BY rowid"""  # noqa: F541
    bindings = (feed_address, "pending")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bet_matches_to_expire(db, block_time):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM bet_matches
            WHERE deadline < ? AND deadline > ?
            GROUP BY id
        ) WHERE status = ?
        ORDER BY rowid
    """
    bindings = (
        block_time - config.TWO_WEEKS,
        block_time
        - 2 * config.TWO_WEEKS,  # optimize query: assuming before that we have already expired
        "pending",
    )
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bet(db, bet_hash: str):
    """
    Returns the information of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 5d097b4729cb74d927b4458d365beb811a26fcee7f8712f049ecbe780eb496ed)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM bets
        WHERE tx_hash = ?
        ORDER BY rowid DESC LIMIT 1
    """
    bindings = (bet_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bets_to_expire(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bets
            WHERE expire_index = ? - 1
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (block_index, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_matching_bets(db, feed_address, bet_type):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bets
            WHERE (feed_address = ? AND bet_type = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (feed_address, bet_type, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bet_by_feed(db, address: str, status: str = "open"):
    """
    Returns the bets of a feed
    :param str address: The address of the feed (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param str status: The status of the bet (e.g. filled)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bets
            WHERE feed_address = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (address, status)
    cursor.execute(query, bindings)
    return cursor.fetchall()


### UPDATES ###


def update_bet(db, tx_hash, update_data):
    insert_update(db, "bets", "tx_hash", tx_hash, update_data, "BET_UPDATE")


def update_bet_match_status(db, id, status):
    update_data = {"status": status}
    insert_update(db, "bet_matches", "id", id, update_data, "BET_MATCH_UPDATE")


#####################
#       ORDERS      #
#####################

### SELECTS ###


def get_pending_order_matches(db, tx0_hash, tx1_hash):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid FROM order_matches
            WHERE (
                tx0_hash in (:tx0_hash, :tx1_hash) OR
                tx1_hash in (:tx0_hash, :tx1_hash)
            )
            GROUP BY id
        ) WHERE status = :status
        ORDER BY rowid
    """
    bindings = {"status": "pending", "tx0_hash": tx0_hash, "tx1_hash": tx1_hash}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_pending_btc_order_matches(db, address):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid
            FROM order_matches
            WHERE (tx0_address = ? AND forward_asset = ?) OR (tx1_address = ? AND backward_asset = ?)
        ) WHERE status = ?
        ORDER BY rowid
    """
    bindings = (address, config.BTC, address, config.BTC, "pending")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_match(db, id):
    cursor = db.cursor()
    query = """
        SELECT *, rowid
        FROM order_matches
        WHERE id = ?
        ORDER BY rowid DESC LIMIT 1"""
    bindings = (id,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_matches_to_expire(db, block_index):
    cursor = db.cursor()
    query = """SELECT * FROM (
        SELECT *, MAX(rowid) AS rowid
        FROM order_matches
        WHERE match_expire_index = ? - 1
        GROUP BY id
    ) WHERE status = ?
    ORDER BY rowid
    """
    bindings = (block_index, "pending")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order(db, order_hash: str):
    """
    Returns the information of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. 23f68fdf934e81144cca31ce8ef69062d553c521321a039166e7ba99aede0776)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM orders
        WHERE tx_hash = ?
        ORDER BY rowid DESC LIMIT 1
    """
    bindings = (order_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_first_block_index(cursor, tx_hash):
    query = """
        SELECT block_index FROM orders
        WHERE tx_hash = ?
        ORDER BY rowid ASC LIMIT 1
    """
    bindings = (tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchone()["block_index"]


def get_orders_to_expire(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE expire_index = ? - 1
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (block_index, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_open_btc_orders(db, address):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE (source = ? AND give_asset = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (address, config.BTC, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_matching_orders_no_cache(db, tx_hash, give_asset, get_asset):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE (tx_hash != ? AND give_asset = ? AND get_asset = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (tx_hash, get_asset, give_asset, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_matching_orders(db, tx_hash, give_asset, get_asset):
    if CurrentState().block_parser_status() == "catching up":
        return OrdersCache(db).get_matching_orders(tx_hash, give_asset, get_asset)
    return get_matching_orders_no_cache(db, tx_hash, give_asset, get_asset)


def insert_order(db, order):
    insert_record(db, "orders", order, "OPEN_ORDER")
    if not CurrentState().parsing_mempool():
        OrdersCache(db).insert_order(order)


### UPDATES ###


def update_order(db, tx_hash, update_data):
    insert_update(db, "orders", "tx_hash", tx_hash, update_data, "ORDER_UPDATE")
    if not CurrentState().parsing_mempool():
        OrdersCache(db).update_order(tx_hash, update_data)


def mark_order_as_filled(db, tx0_hash, tx1_hash, source=None):
    select_bindings = {"tx0_hash": tx0_hash, "tx1_hash": tx1_hash}

    where_source = ""
    if source is not None:
        where_source = f" AND source = :source"  # noqa: F541
        select_bindings["source"] = source

    # no sql injection here
    select_query = f"""
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM orders
            WHERE
                tx_hash in (:tx0_hash, :tx1_hash)
                {where_source}
            GROUP BY tx_hash
        ) WHERE give_remaining = 0 OR get_remaining = 0
    """  # nosec B608  # noqa: S608

    cursor = db.cursor()
    cursor.execute(select_query, select_bindings)
    for order in cursor:
        update_data = {"status": "filled"}
        insert_update(
            db,
            "orders",
            "rowid",
            order["rowid"],
            update_data,
            "ORDER_FILLED",
            {"tx_hash": order["tx_hash"]},
        )
        if not CurrentState().parsing_mempool():
            OrdersCache(db).update_order(order["tx_hash"], update_data)


def update_order_match_status(db, id, status):
    update_data = {"status": status}
    # add `order_match_id` for backward compatibility
    insert_update(
        db, "order_matches", "id", id, update_data, "ORDER_MATCH_UPDATE", {"order_match_id": id}
    )


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
    if not sums:
        return 0, 0
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
