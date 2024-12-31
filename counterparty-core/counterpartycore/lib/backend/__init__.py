from counterpartycore.lib import backend, config, exceptions


def list_unspent(source, allow_unconfirmed_inputs):
    # first try with Bitcoin Core
    unspent_list = backend.bitcoind.list_unspent(source, allow_unconfirmed_inputs)
    if len(unspent_list) > 0:
        return unspent_list

    # then try with Electrs
    if config.ELECTRS_URL is None:
        raise exceptions.ComposeError(
            "No UTXOs found with Bitcoin Core and Electr is not configured, use the `inputs_set` parameter to provide UTXOs"
        )
    return backend.electrs.list_unspent(source, allow_unconfirmed_inputs)


def search_pubkey(source, tx_hashes=None):
    # first search with Bitcoin Core
    if isinstance(tx_hashes, list) and len(tx_hashes) > 0:
        pubkey = backend.bitcoind.search_pubkey_in_transactions(source, tx_hashes)
        if pubkey is not None:
            return pubkey
    # then search with Electrs
    if config.ELECTRS_URL is None:
        return None
    pubkey = backend.electrs.search_pubkey(source)
    if pubkey is not None:
        return pubkey
    return None
