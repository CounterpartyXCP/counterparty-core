import requests

from counterpartycore.lib import config


def get_utxos(address, unconfirmed: bool = False, unspent_tx_hash: str = None):
    """
    Returns a list of unspent outputs for a specific address
    :param address: The address to search for (e.g. $ADDRESS_7)
    :param unconfirmed: Include unconfirmed transactions
    :param unspent_tx_hash: Filter by unspent_tx_hash
    """
    url = f"{config.ELECTR_URL}/address/{address}/utxo"
    utxo_list = requests.get(url, timeout=10).json()
    result = []
    for utxo in utxo_list:
        if not utxo["status"]["confirmed"] and not unconfirmed:
            continue
        if unspent_tx_hash and utxo["txid"] != unspent_tx_hash:
            continue
        result.append(utxo)
    return result


def get_history(address: str, unconfirmed: bool = False):
    """
    Returns all transactions involving a given address
    :param address: The address to search for (e.g. $ADDRESS_3)
    """
    url = f"{config.ELECTR_URL}/address/{address}/history"
    tx_list = requests.get(url, timeout=10).json()
    result = []
    for tx in tx_list:
        if tx["status"]["confirmed"] or unconfirmed:
            result.append(tx)
    return result


def get_utxos_by_addresses(addresses: str, unconfirmed: bool = False, unspent_tx_hash: str = None):
    """
    Returns a list of unspent outputs for a list of addresses
    :param addresses: The addresses to search for (e.g. $ADDRESS_7,$ADDRESS_8)
    :param unconfirmed: Include unconfirmed transactions
    :param unspent_tx_hash: Filter by unspent_tx_hash
    """
    unspents = []
    for address in addresses.split(","):
        address_unspents = get_utxos(address, unconfirmed, unspent_tx_hash)
        for unspent in address_unspents:
            unspent["address"] = address
        unspents += address_unspents
    return unspents
