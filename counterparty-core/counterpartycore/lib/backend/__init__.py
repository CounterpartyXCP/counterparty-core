import binascii
import logging

from counterpartycore.lib import config, script, util
from counterpartycore.lib.backend import addrindexrs  # noqa: F401

logger = logging.getLogger(config.LOGGER_NAME)


BLOCKCHAIN_CACHE = {}


def backend():
    addrindexrs.init()
    return addrindexrs


def stop():
    logger.info("Stopping backend...")
    addrindexrs.stop()


def get_oldest_tx(address: str, block_index: int):
    return backend().get_oldest_tx(address, block_index=block_index)


class UnknownPubKeyError(Exception):
    pass


def pubkeyhash_to_pubkey(pubkeyhash, provided_pubkeys=None):
    # Search provided pubkeys.
    if provided_pubkeys:
        if type(provided_pubkeys) != list:  # noqa: E721
            provided_pubkeys = [provided_pubkeys]
        for pubkey in provided_pubkeys:
            if pubkeyhash == script.pubkey_to_pubkeyhash(util.unhexlify(pubkey)):
                return pubkey
            elif pubkeyhash == script.pubkey_to_p2whash(util.unhexlify(pubkey)):
                return pubkey

    # Search blockchain.
    raw_transactions = addrindexrs.search_raw_transactions(pubkeyhash, unconfirmed=True)
    for tx_id in raw_transactions:
        tx = raw_transactions[tx_id]
        for vin in tx["vin"]:
            if "txinwitness" in vin:
                if len(vin["txinwitness"]) >= 2:
                    # catch unhexlify errs for when txinwitness[1] isn't a witness program (eg; for P2W)
                    try:
                        pubkey = vin["txinwitness"][1]
                        if pubkeyhash == script.pubkey_to_p2whash(util.unhexlify(pubkey)):
                            return pubkey
                    except binascii.Error:
                        pass
            elif "coinbase" not in vin:
                scriptsig = vin["scriptSig"]
                asm = scriptsig["asm"].split(" ")
                if len(asm) >= 2:
                    # catch unhexlify errs for when asm[1] isn't a pubkey (eg; for P2SH)
                    try:
                        pubkey = asm[1]
                        if pubkeyhash == script.pubkey_to_pubkeyhash(util.unhexlify(pubkey)):
                            return pubkey
                    except binascii.Error:
                        pass

    raise UnknownPubKeyError("Public key was neither provided nor published in blockchain.")


def multisig_pubkeyhashes_to_pubkeys(address, provided_pubkeys=None):
    signatures_required, pubkeyhashes, signatures_possible = script.extract_array(address)
    pubkeys = [pubkeyhash_to_pubkey(pubkeyhash, provided_pubkeys) for pubkeyhash in pubkeyhashes]
    return script.construct_array(signatures_required, pubkeys, signatures_possible)
