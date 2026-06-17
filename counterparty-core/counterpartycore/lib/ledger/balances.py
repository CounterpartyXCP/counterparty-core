import logging

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.ledger.caches import UTXOBalancesCache
from counterpartycore.lib.parser import protocol, utxosinfo
from counterpartycore.lib.utils import database

logger = logging.getLogger(config.LOGGER_NAME)


def _holder_filter(db, address):
    """Build the (where_clause, bindings) for a single address-or-utxo balance
    lookup. An address resolves to its compact ``address_id``; a UTXO string is
    split into the stored ``(utxo_tx_hash, utxo_vout)`` pair. Returns the
    SELECT/GROUP-BY target columns too (``address`` vs ``utxo_tx_hash,
    utxo_vout``) so the rowtracer can reconstruct the ``utxo`` string."""
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        tx_hash, vout = database.split_utxo(address)
        return "utxo_tx_hash, utxo_vout", "(utxo_tx_hash = ? AND utxo_vout = ?)", [tx_hash, vout]
    return "address", "address = ?", [database.address_index_from_name(db, address)]


def get_balance(db, address, asset, raise_error_if_no_balance=False, return_list=False):
    """Get balance of contract or address."""
    cursor = db.cursor()

    _target, where_clause, where_bindings = _holder_filter(db, address)

    query = f"""
        SELECT * FROM balances
        WHERE ({where_clause} AND asset = ?)
        ORDER BY rowid DESC LIMIT 1
    """  # noqa: S608 # nosec B608
    bindings = (*where_bindings, database.asset_index_from_name(db, asset))
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

    target, where_clause, where_bindings = _holder_filter(db, address)

    # ``asset`` is stored as the compact asset_index; ordering by it would
    # return assets in index order, but the iteration order here is
    # consensus-relevant: move/detach/sweep handlers process each balance in
    # this order (msg_index, debit/credit -> ledger_hash). Order by the
    # resolved asset *name* to reproduce the exact pre-normalization ordering
    # (the GROUP BY previously emitted rows in asset-name order). The WHERE pins
    # a single address/utxo, so address ordering is irrelevant here. The
    # ``utxo_tx_hash, utxo_vout`` target lets the rowtracer rebuild ``utxo``.
    query = f"""
        SELECT {target}, asset, quantity, utxo_address, MAX(rowid)
        FROM balances
        WHERE {where_clause}
        GROUP BY {target}, asset
        ORDER BY (SELECT asset_name FROM assets WHERE asset_index = asset)
    """  # noqa: S608 # nosec B608
    cursor.execute(query, where_bindings)
    return cursor.fetchall()


def get_utxo_balances(db, utxo: str):
    return get_address_balances(db, utxo)


def get_address_assets(db, address):
    cursor = db.cursor()

    _target, where_clause, where_bindings = _holder_filter(db, address)

    query = f"""
        SELECT DISTINCT asset
        FROM balances
        WHERE {where_clause}
        GROUP BY asset
    """  # noqa: S608 # nosec B608
    cursor.execute(query, where_bindings)
    return cursor.fetchall()


def get_balances_count(db, address):
    cursor = db.cursor()

    _target, where_clause, where_bindings = _holder_filter(db, address)

    query = f"""
        SELECT COUNT(*) AS cnt FROM (
            SELECT DISTINCT asset
            FROM balances
            WHERE {where_clause}
            GROUP BY asset
        )
    """  # noqa: S608 # nosec B608
    cursor.execute(query, where_bindings)
    return cursor.fetchall()


def get_asset_balances(db, asset: str, exclude_zero_balances: bool = True):
    """
    Returns the asset balances
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param bool exclude_zero_balances: Whether to exclude zero balances (e.g. True)
    """
    cursor = db.cursor()
    # ``address`` is the compact address_id; ordering by it would sort by id,
    # not by the address string. Order by the resolved string to reproduce the
    # pre-normalization ordering (callers may iterate this; keep it stable).
    query = """
        SELECT address, asset, quantity, MAX(rowid)
        FROM balances
        WHERE asset = ?
        GROUP BY address, asset
        ORDER BY (SELECT al.address FROM address_list al WHERE al.address_id = balances.address)
    """
    if exclude_zero_balances:
        query = f"""
            SELECT * FROM (
                {query}
            ) WHERE quantity > 0
        """  # nosec B608  # noqa: S608 # nosec B608
    bindings = (database.asset_index_from_name(db, asset),)
    cursor.execute(query, bindings)
    return cursor.fetchall()
