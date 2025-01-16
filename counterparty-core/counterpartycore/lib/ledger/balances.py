import logging

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.ledger.caches import UTXOBalancesCache
from counterpartycore.lib.parser import protocol, utxosinfo

logger = logging.getLogger(config.LOGGER_NAME)


def get_balance(db, address, asset, raise_error_if_no_balance=False, return_list=False):
    """Get balance of contract or address."""
    cursor = db.cursor()

    field_name = "address"
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        field_name = "utxo"

    query = f"""
        SELECT * FROM balances
        WHERE ({field_name} = ? AND asset = ?)
        ORDER BY rowid DESC LIMIT 1
    """  # noqa: S608
    bindings = (address, asset)
    balances = list(cursor.execute(query, bindings))
    cursor.close()
    if return_list:
        return balances
    if not balances and raise_error_if_no_balance:
        raise exceptions.BalanceError(f"No balance for this address and asset: {address}, {asset}.")
    if not balances:
        return 0
    return balances[0]["quantity"]


def utxo_has_balance(db, utxo):
    return UTXOBalancesCache(db).has_balance(utxo)


def get_address_balances(db, address: str):
    """
    Returns the balances of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    """
    cursor = db.cursor()

    field_name = "address"
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        field_name = "utxo"

    query = f"""
        SELECT {field_name}, asset, quantity, utxo_address, MAX(rowid)
        FROM balances
        WHERE {field_name} = ?
        GROUP BY {field_name}, asset
    """  # noqa: S608
    bindings = (address,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_utxo_balances(db, utxo: str):
    return get_address_balances(db, utxo)


def get_address_assets(db, address):
    cursor = db.cursor()

    field_name = "address"
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        field_name = "utxo"

    query = f"""
        SELECT DISTINCT asset
        FROM balances
        WHERE {field_name}=:address
        GROUP BY asset
    """  # noqa: S608
    bindings = {"address": address}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_balances_count(db, address):
    cursor = db.cursor()

    field_name = "address"
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        field_name = "utxo"

    query = f"""
        SELECT COUNT(*) AS cnt FROM (
            SELECT DISTINCT asset
            FROM balances
            WHERE {field_name}=:address
            GROUP BY asset
        )
    """  # noqa: S608
    bindings = {"address": address}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_asset_balances(db, asset: str, exclude_zero_balances: bool = True):
    """
    Returns the asset balances
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param bool exclude_zero_balances: Whether to exclude zero balances (e.g. True)
    """
    cursor = db.cursor()
    query = """
        SELECT address, asset, quantity, MAX(rowid)
        FROM balances
        WHERE asset = ?
        GROUP BY address, asset
        ORDER BY address
    """
    if exclude_zero_balances:
        query = f"""
            SELECT * FROM (
                {query}
            ) WHERE quantity > 0
        """  # nosec B608  # noqa: S608
    bindings = (asset,)
    cursor.execute(query, bindings)
    return cursor.fetchall()
