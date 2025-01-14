import binascii
import logging

import requests
from bitcoinutils.keys import PublicKey

from counterpartycore.lib import config, exceptions

logger = logging.getLogger(config.LOGGER_NAME)


def electr_query(url):
    if config.ELECTRS_URL is None:
        raise exceptions.ElectrsError("Electrs server not configured")
    try:
        full_url = f"{config.ELECTRS_URL}/{url}"
        logger.debug(f"Querying Electrs: {full_url}")
        return requests.get(full_url, timeout=10).json()
    except requests.exceptions.RequestException as e:
        raise exceptions.ElectrsError(f"Electrs error: {e}") from e


def get_utxos(address, unconfirmed: bool = False, unspent_tx_hash: str = None):
    """
    Returns a list of unspent outputs for a specific address
    :param address: The address to search for (e.g. $ADDRESS_7)
    :param unconfirmed: Include unconfirmed transactions
    :param unspent_tx_hash: Filter by unspent_tx_hash
    """
    utxo_list = electr_query(f"address/{address}/utxo")
    result = []
    for utxo in utxo_list:
        if not utxo["status"]["confirmed"] and not unconfirmed:
            continue
        if unspent_tx_hash and utxo["txid"] != unspent_tx_hash:
            continue
        utxo["amount"] = utxo["value"] / 10**8
        result.append(utxo)
    return result


def get_history(address: str, unconfirmed: bool = False):
    """
    Returns all transactions involving a given address
    :param address: The address to search for (e.g. $ADDRESS_3)
    """
    tx_list = electr_query(f"address/{address}/txs")
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


def pubkey_from_tx(tx, pubkeyhash):
    for vin in tx["vin"]:
        if "witness" in vin:
            if len(vin["witness"]) >= 2:
                # catch unhexlify errs for when txinwitness[1] isn't a witness program (eg; for P2W)
                try:
                    pubkey = vin["witness"][1]
                    if pubkeyhash == PublicKey.from_hex(pubkey).get_segwit_address().to_string():
                        return pubkey
                except binascii.Error:
                    pass
        elif "is_coinbase" not in vin or not vin["is_coinbase"]:
            asm = vin["scriptsig_asm"].split(" ")
            if len(asm) == 4:  # p2pkh
                # catch unhexlify errs for when asm[2] isn't a pubkey (eg; for P2SH)
                try:
                    pubkey = asm[3]
                    if (
                        pubkeyhash
                        == PublicKey.from_hex(pubkey).get_address(compressed=False).to_string()
                    ):
                        return pubkey
                    if (
                        pubkeyhash
                        == PublicKey.from_hex(pubkey).get_address(compressed=True).to_string()
                    ):
                        return pubkey
                except binascii.Error:
                    pass
    for vout in tx["vout"]:
        asm = vout["scriptpubkey_asm"].split(" ")
        if len(asm) == 3:  # p2pk
            try:
                pubkey = asm[1]
                if (
                    pubkeyhash
                    == PublicKey.from_hex(pubkey).get_address(compressed=False).to_string()
                ):
                    return pubkey
                if (
                    pubkeyhash
                    == PublicKey.from_hex(pubkey).get_address(compressed=True).to_string()
                ):
                    return pubkey
            except binascii.Error:
                pass
    return None


def search_pubkey(pubkeyhash):
    transactions = get_history(pubkeyhash)
    for tx in transactions:
        pubkey = pubkey_from_tx(tx, pubkeyhash)
        if pubkey:
            return pubkey
    return None


def list_unspent(source, allow_unconfirmed_inputs):
    electr_unspent_list = get_utxos(
        source,
        unconfirmed=allow_unconfirmed_inputs,
    )
    if len(electr_unspent_list) > 0:
        unspent_list = []
        for unspent in electr_unspent_list:
            unspent_list.append(
                {
                    "txid": unspent["txid"],
                    "vout": unspent["vout"],
                    "value": unspent["value"],
                    "amount": unspent["value"] / config.UNIT,
                }
            )
        return unspent_list

    return []
