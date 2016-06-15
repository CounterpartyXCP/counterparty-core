# coding: utf-8
# Copyright (c) 2016 Fabian Barkhau <fabian.barkhau@gmail.com>
# License: MIT (see LICENSE file)


import copy
import pycoin
from . import util
from . import validate
from . import exceptions
from . import scripts


INITIAL_STATE = {
    "asset": None,

    "deposit_script": None,

    # Quantity not needed as payer may change it. If its heigher its
    # against our self intrest to throw away money. If its lower it
    # gives us a better resolution when reversing the channel.
    "commits_requested": [],  # ["revoke_secret_hash"]

    # must be ordered lowest to heighest at all times!
    "commits_active": [],     # [{
    #                             "rawtx": hex,
    #                             "script": hex,
    #                           }]

    "commits_revoked": [],    # [{
    #                             "script": hex,
    #                             "revoke_secret": hex
    #                           }]
}


def make_deposit(dispatcher, asset, payer_pubkey, payee_pubkey,
                 spend_secret_hash, expire_time, quantity,
                 netcode, fee, regular_dust_size):
    """Create deposit and setup initial payer state.

    Args:
        asset (str): Counterparty asset.
        payer_pubkey (str): Hex encoded public key in sec format.
        payee_pubkey (str): Hex encoded public key in sec format.
        spend_secret_hash (str): Hex encoded hash160 of spend secret.
        expire_time (int): Channel expire time in blocks given as int.
        quantity (int): Asset quantity for deposit.

    Returns:
        {
            "state": channel_state,
            "topublish": unsigned_deposit_rawtx,
            "deposit_script": hex_encoded
        }

    Raises:
        counterpartylib.lib.micropayments.exceptions.InvalidHexData
        counterpartylib.lib.micropayments.exceptions.InvalidPubKey
        counterpartylib.lib.micropayments.exceptions.InvalidHash160
        counterpartylib.lib.micropayments.exceptions.InvalidSequence
        counterpartylib.lib.micropayments.exceptions.InvalidQuantity
        counterpartylib.lib.micropayments.exceptions.InsufficientFunds
        counterpartylib.lib.micropayments.exceptions.ChannelAlreadyUsed
    """

    # validate input
    _validate_deposit(dispatcher, asset, payer_pubkey, payee_pubkey,
                      spend_secret_hash, expire_time, quantity,
                      netcode, fee, regular_dust_size)

    # create deposit
    rawtx, script = _create_deposit(
        dispatcher, asset, payer_pubkey, payee_pubkey, spend_secret_hash,
        expire_time, quantity, netcode, fee, regular_dust_size
    )

    # setup initial state
    state = copy.deepcopy(INITIAL_STATE)
    state["asset"] = asset
    state["deposit_script"] = util.b2h(script)

    return {
        "state": state,
        "topublish": rawtx,
        "deposit_script": util.b2h(script)
    }


def set_deposit(asset, deposit_script, expected_payee_pubkey,
                expected_spend_secret_hash):
    """Setup initial payee state for given deposit.

    Args:
        asset (str): Counterparty asset.
        deposit_script (str): Channel deposit p2sh script.
        expected_payee_pubkey (str): To validate deposit for payee.
        expected_spend_secret_hash (str): To validate deposit secret hash.

    Returns: {"state": updated_state}

    Raises:
        counterpartylib.lib.micropayments.exceptions.InvalidHexData
        counterpartylib.lib.micropayments.exceptions.InvalidPubKey
        counterpartylib.lib.micropayments.exceptions.InvalidDepositScript
        counterpartylib.lib.micropayments.exceptions.IncorrectPubKey
        counterpartylib.lib.micropayments.exceptions.IncorrectSpendSecretHash
    """

    # validate input
    # FIXME validate asset
    validate.pubkey(expected_payee_pubkey)
    validate.deposit_script(deposit_script, expected_payee_pubkey,
                            expected_spend_secret_hash)

    # setup initial state
    state = copy.deepcopy(INITIAL_STATE)
    state["asset"] = asset
    state["deposit_script"] = deposit_script

    return {"state": state}


def request_commit(dispatcher, state, quantity, revoke_secret_hash, netcode):
    """Request commit for given quantity and revoke secret hash.

    Args:
        state (dict): Current payee channel state.
        quantity (int): Asset quantity for commit.
        revoke_secret_hash (str): Revoke secret hash for commit.

    Returns:
        {
            "state": updated_channel_state,
            "quantity": quantity,
            "revoke_secret_hash": revoke_secret_hash
        }

    Raises:
        counterpartylib.lib.micropayments.exceptions.InvalidState
        counterpartylib.lib.micropayments.exceptions.InvalidHash160
        counterpartylib.lib.micropayments.exceptions.InvalidQuantity
        ValueError
    """

    # validate input
    validate.state(state)
    validate.is_quantity(quantity)
    validate.hash160(revoke_secret_hash)
    _validate_transfer_quantity(dispatcher, state, quantity, netcode)

    # update state
    state["commits_requested"].append(revoke_secret_hash)

    return {
        "state": state,
        "quantity": quantity,
        "revoke_secret_hash": revoke_secret_hash
    }


def create_commit(dispatcher, state, quantity, revoke_secret_hash,
                  delay_time, netcode, fee, regular_dust_size):
    """Create commit for given quantit, revoke secret hash and delay time.

    Args:
        state (dict): Current payer channel state.
        quantity (int): Asset quantity for commit.
        revoke_secret_hash (str): Revoke secret hash for commit.
        delay_time (int): Blocks payee must wait before payout.

    Returns:
        {
            "state": updated_channel_state,
            "commit_script": hex_encoded,
            "tosign": {
                "rawtx": unsigned_commit_rawtx,
                "deposit_script": hex_encoded
            }
        }

    Raises:
        counterpartylib.lib.micropayments.exceptions.InvalidState
        counterpartylib.lib.micropayments.exceptions.InvalidQuantity
        counterpartylib.lib.micropayments.exceptions.InvalidHash160
        counterpartylib.lib.micropayments.exceptions.InvalidSequence
        ValueError
    """

    # validate input
    validate.state(state)
    validate.is_quantity(quantity)
    validate.hash160(revoke_secret_hash)
    validate.is_sequence(delay_time)
    _validate_transfer_quantity(dispatcher, state, quantity, netcode)

    # create deposit script and rawtx
    deposit_script = util.h2b(state["deposit_script"])
    rawtx, commit_script = _create_commit(
        dispatcher, state["asset"], deposit_script, quantity,
        revoke_secret_hash, delay_time, netcode, fee, regular_dust_size
    )

    # update state
    _order_active(dispatcher, state)
    state["commits_active"].append({
        "rawtx": rawtx, "script": util.b2h(commit_script)
    })

    return {
        "state": state,
        "commit_script": util.b2h(commit_script),
        "tosign": {
            "rawtx": rawtx,
            "deposit_script": state["deposit_script"]
        }
    }


def add_commit(dispatcher, state, commit_rawtx, commit_script):
    """Add commit to channel state.

    Args:
        state (dict): Current payee channel state.
        commit_rawtx (str): Commit transaction signed by payer.
        commit_script (str): Commit p2sh script.

    Returns: {"state": updated_state}

    Raises:
        counterpartylib.lib.micropayments.exceptions.InvalidHexData
        counterpartylib.lib.micropayments.exceptions.InvalidState
        counterpartylib.lib.micropayments.exceptions.IncorrectPubKey
        counterpartylib.lib.micropayments.exceptions.IncorrectSpendSecretHash
    """

    # validate input
    validate.state(state)
    validate.commit_script(commit_script, state["deposit_script"])
    # FIXME validate rawtx for deposit script
    # FIXME validate rawtx signed by payer
    # FIXME validate rawtx asset correct

    # update state
    script = util.h2b(commit_script)
    script_revoke_secret_hash = scripts.get_commit_revoke_secret_hash(script)
    for revoke_secret_hash in state["commits_requested"][:]:

        # revoke secret hash must match as it would
        # otherwise break the channels reversability
        if script_revoke_secret_hash == revoke_secret_hash:

            # remove from requests
            state["commits_requested"].remove(revoke_secret_hash)

            # add to active
            _order_active(dispatcher, state)
            state["commits_active"].append({
                "rawtx": commit_rawtx,
                "script": commit_script
            })
            return {"state": state}

    raise ValueError("No revoke secret for given commit script.")


def revoke_secret_hashes_above(dispatcher, state, quantity):
    """Get revoke secret hashes for commits above the given quantity.

    Args:
        state (dict): Current payee channel state.
        quantity (int): Return revoke secret hash if commit gt quantity.

    Returns: List of hex encoded revoke secret hashes.

    Raises:
        counterpartylib.lib.micropayments.exceptions.InvalidState
        counterpartylib.lib.micropayments.exceptions.InvalidQuantity
    """

    # validate input
    validate.state(state)
    validate.is_quantity(quantity)

    # get revoke secret hashes
    revoke_secret_hashes = []
    _order_active(dispatcher, state)
    for commit in reversed(state["commits_active"][:]):
        asset = state["asset"]
        rawtx = commit["rawtx"]
        if quantity < _get_quantity(dispatcher, asset, rawtx):
            script = util.h2b(commit["script"])
            secret_hash = scripts.get_commit_revoke_secret_hash(script)
            revoke_secret_hashes.append(secret_hash)
        else:
            break

    return revoke_secret_hashes


def revoke_all(state, secrets):
    """Revoke all commits matching the given secrets.

    Args:
        state (dict): Current payee/payer channel state.
        secrets (list): List of hex encoded commit revoke secrets.

    Returns: {"state": updated_state}

    Raises:
        counterpartylib.lib.micropayments.exceptions.InvalidState
    """

    # validate input
    validate.state(state)
    validate.is_list(secrets)
    for secret in secrets:
        validate.is_hex(secret)

    # update state
    list(map(lambda s: _revoke(state, s), secrets))

    return {"state": state}


def highest_commit(dispatcher, state):
    """Get highest commit be signed/published for closing the channel.

    Args:
        state (dict): Current payee channel state.

    Returns:
        If no commits have been made:
            None

        If commits have been made:
            {
                "commit_rawtx": half_signed_commit_rawtx,
                "deposit_script": hex_encoded
            }

    Raises:
        counterpartylib.lib.micropayments.exceptions.InvalidState
    """

    # validate input
    validate.state(state)

    _order_active(dispatcher, state)
    if len(state["commits_active"]) == 0:
        return None
    commit = state["commits_active"][-1]

    return {
        "commit_rawtx": commit["rawtx"],
        "deposit_script": state["deposit_script"],
    }


def transferred_amount(dispatcher, state):
    """Get asset quantity transferred from payer to payee.

    Args:
        state (dict): Current payee/payer channel state.

    Returns:
        Quantity transferred in satoshis.

    Raises:
        counterpartylib.lib.micropayments.exceptions.InvalidState
    """

    if len(state["commits_active"]) == 0:
        return 0
    _order_active(dispatcher, state)
    commit = state["commits_active"][-1]
    return _get_quantity(dispatcher, state["asset"], commit["rawtx"])


def payouts(dispatcher, state, netcode, fee, regular_dust_size):
    """Find published commits and make payout transactions.

    Args:
        state (dict): Current payee channel state.

    Returns:
        [{
            "payout_rawtx": unsigned_rawtx,
            "commit_script": hex_encoded
        }]

    Raises:
        counterpartylib.lib.micropayments.exceptions.InvalidState
    """

    # validate input
    validate.state(state)

    # find recoverables and make payout transactions
    payouts = []
    recoverable_scripts = _get_payout_recoverable(dispatcher, state, netcode)
    if len(recoverable_scripts) > 0:
        deposit_script = util.h2b(state["deposit_script"])
        payee_pubkey = scripts.get_deposit_payee_pubkey(deposit_script)
        for script in recoverable_scripts:
            rawtx = _create_recover_commit(
                dispatcher, state["asset"], payee_pubkey, script, "payout",
                netcode, fee, regular_dust_size
            )
            payouts.append({
                "payout_rawtx": rawtx, "commit_script": util.b2h(script)
            })
    return payouts


def recoverables(dispatcher, state, netcode, fee, regular_dust_size):
    """Find and make recoverable change, timeout and revoke transactions.

    Args:
        state (dict): Current payee channel state.

    Returns:
        {
            "change":[{
                "change_rawtx": unsigned_rawtx,
                "deposit_script": hex_encoded,
                "spend_secret": hex_encoded
            }],
            "expire":[{
                "expire_rawtx": unsigned_rawtx,
                "deposit_script": hex_encoded
            }],
            "revoke":[{
                "revoke_rawtx": unsigned_rawtx,
                "commit_script": hex_encoded,
                "revoke_secret": hex_encoded
            }]
        }

    Raises:
        counterpartylib.lib.micropayments.exceptions.InvalidState
    """

    # validate input
    validate.state(state)

    deposit_script = util.h2b(state["deposit_script"])
    payer_pubkey = scripts.get_deposit_payer_pubkey(deposit_script)
    recoverables = {"revoke": [], "change": [], "expire": []}

    # If revoked commit published, recover funds asap!
    revokable = _get_revoke_recoverable(dispatcher, state, netcode)
    if len(revokable) > 0:
        for script, secret in revokable:
            rawtx = _create_recover_commit(
                dispatcher, state["asset"], payer_pubkey, script, "revoke",
                netcode, fee, regular_dust_size
            )
            recoverables["revoke"].append({
                "revoke_rawtx": rawtx,
                "commit_script": util.b2h(script),
                "revoke_secret": secret
            })

    # If deposit expired recover the coins!
    if _can_expire_recover(dispatcher, state, netcode):
        rawtx = _recover_deposit(
            dispatcher, state["asset"], payer_pubkey, deposit_script,
            "expire", netcode, fee, regular_dust_size
        )
        recoverables["expire"].append({
            "expire_rawtx": rawtx,
            "deposit_script": state["deposit_script"]
        })

    else:

        # If not expired and spend secret exposed by payout
        # recover change!
        address = util.script2address(deposit_script, netcode)
        if _can_spend_from_address(dispatcher, state["asset"], address):
            _spend_secret = _find_spend_secret(dispatcher, state, netcode)
            if _spend_secret is not None:
                rawtx = _recover_deposit(
                    dispatcher, state["asset"], payer_pubkey, deposit_script,
                    "change", netcode, fee, regular_dust_size
                )
                recoverables["change"].append({
                    "change_rawtx": rawtx,
                    "deposit_script": state["deposit_script"],
                    "spend_secret": _spend_secret
                })

    return recoverables


def _deposit_status(dispatcher, asset, script, netcode):
    address = util.script2address(script, netcode)
    transactions = dispatcher.get("search_raw_transactions")(address)
    if len(transactions) == 0:
        return 0, 0, 0
    asset_balance, btc_balance = _get_address_balance(
        dispatcher, asset, address
    )
    oldest_confirms = transactions[0]["confirmations"]
    newest_confirms = transactions[-1]["confirmations"]
    if newest_confirms == 0:
        return 0, asset_balance, btc_balance
    return oldest_confirms, asset_balance, btc_balance


def _validate_channel_unused(dispatcher, channel_address):
    transactions = dispatcher.get("search_raw_transactions")(channel_address)
    if len(transactions) > 0:
        raise exceptions.ChannelAlreadyUsed(channel_address, transactions)


def _recover_tx(dispatcher, asset, dest_address,
                script, netcode, fee, regular_dust_size, sequence):

    # get channel info
    src_address = util.script2address(script, netcode)
    asset_balance, btc_balance = _get_address_balance(
        dispatcher, asset, src_address
    )

    # create expire tx
    rawtx = _create_tx(dispatcher, asset, src_address, dest_address,
                       asset_balance, btc_balance - fee, fee, regular_dust_size)

    # prep for script compliance and signing
    tx = pycoin.tx.Tx.from_hex(rawtx)
    if sequence:
        tx.version = 2  # enable relative lock-time, see bip68 & bip112
    for txin in tx.txs_in:
        if sequence:
            txin.sequence = sequence  # relative lock-time
        utxo_rawtx = dispatcher.get("getrawtransaction")(
            tx_hash=util.b2h_rev(txin.previous_hash)
        )
        utxo_tx = pycoin.tx.Tx.from_hex(utxo_rawtx)
        tx.unspents.append(utxo_tx.txs_out[txin.previous_index])
    rawtx = tx.as_hex()
    return rawtx


def _create_recover_commit(dispatcher, asset, pubkey, script, spend_type,
                           netcode, fee, regular_dust_size):
    dest_address = util.pubkey2address(pubkey, netcode=netcode)
    delay_time = scripts.get_commit_delay_time(script)
    return _recover_tx(dispatcher, asset, dest_address, script, netcode, fee,
                       regular_dust_size, delay_time)


def _recover_deposit(dispatcher, asset, pubkey, script, spend_type,
                     netcode, fee, regular_dust_size):
    dest_address = util.pubkey2address(pubkey, netcode=netcode)
    expire_time = scripts.get_deposit_expire_time(script)
    rawtx = _recover_tx(
        dispatcher, asset, dest_address, script,
        netcode, fee, regular_dust_size,
        expire_time if spend_type == "expire" else None
    )
    return rawtx


def _create_commit(dispatcher, asset, deposit_script, quantity,
                   revoke_secret_hash, delay_time, netcode,
                   fee, regular_dust_size):

    # create script
    payer_pubkey = scripts.get_deposit_payer_pubkey(deposit_script)
    payee_pubkey = scripts.get_deposit_payee_pubkey(deposit_script)
    spend_secret_hash = scripts.get_deposit_spend_secret_hash(deposit_script)
    commit_script = scripts.compile_commit_script(
        payer_pubkey, payee_pubkey, spend_secret_hash,
        revoke_secret_hash, delay_time
    )

    # create tx
    src_address = util.script2address(deposit_script, netcode)
    dest_address = util.script2address(commit_script, netcode)
    asset_balance, btc_balance = _get_address_balance(
        dispatcher, asset, src_address
    )
    if quantity == asset_balance:  # spend all btc as change tx not needed
        extra_btc = btc_balance - fee
    else:  # provide extra btc for future payout/revoke tx fees
        extra_btc = (fee + regular_dust_size)
    rawtx = _create_tx(dispatcher, asset, src_address, dest_address, quantity,
                       extra_btc, fee, regular_dust_size)

    return rawtx, commit_script


def _create_deposit(dispatcher, asset, payer_pubkey, payee_pubkey,
                    spend_secret_hash, expire_time, quantity, netcode, fee,
                    regular_dust_size):

    script = scripts.compile_deposit_script(payer_pubkey, payee_pubkey,
                                            spend_secret_hash, expire_time)
    dest_address = util.script2address(script, netcode)
    _validate_channel_unused(dispatcher, dest_address)
    payer_address = util.pubkey2address(payer_pubkey, netcode)

    # provide extra btc for future closing channel fees
    # change tx or recover + commit tx + payout tx or revoke tx
    extra_btc = (fee + regular_dust_size) * 3

    rawtx = _create_tx(dispatcher, asset, payer_address, dest_address,
                       quantity, extra_btc, fee, regular_dust_size)
    return rawtx, script


def _create_tx(dispatcher, asset, source_address, dest_address, quantity,
               extra_btc, fee, regular_dust_size):
    assert(extra_btc >= 0)
    rawtx = dispatcher.get("create_send")(
        source=source_address,
        destination=dest_address,
        quantity=quantity,
        asset=asset,
        regular_dust_size=(extra_btc or regular_dust_size),
        fee=fee
    )
    assert(_get_quantity(dispatcher, asset, rawtx) == quantity)
    return rawtx


def _can_spend_from_address(dispatcher, asset, address):

    # has assets, btc
    if _get_address_balance(dispatcher, asset, address) == (0, 0):
        return False

    # TODO check if btc > fee

    # can only spend if all txs confirmed
    transactions = dispatcher.get("search_raw_transactions")(address)
    latest_confirms = transactions[-1]["confirmations"]
    return latest_confirms > 0


def _get_address_balance(dispatcher, asset, address):
    result = dispatcher.get("get_balances")(filters=[
        {'field': 'address', 'op': '==', 'value': address},
        {'field': 'asset', 'op': '==', 'value': asset},
    ])
    if not result:  # TODO what causes this?
        return 0, 0
    asset_balance = result[0]["quantity"]
    utxos = dispatcher.get("get_unspent_txouts")(address)
    btc_balance = sum(map(lambda utxo: util.tosatoshis(utxo["amount"]), utxos))
    return asset_balance, btc_balance


def _get_quantity(dispatcher, expected_asset, rawtx):
    result = dispatcher.get("get_tx_info")(tx_hex=rawtx)
    src, dest, btc, fee, data = result
    result = dispatcher.get("unpack")(data_hex=data)
    message_type_id, unpacked = result
    if message_type_id != 0:
        msg = "Incorrect message type id: {0} != {1}"
        raise ValueError(msg.format(message_type_id, 0))
    if expected_asset != unpacked["asset"]:
        msg = "Incorrect asset: expected {0} != {1} found!"
        raise ValueError(msg.format(expected_asset, unpacked["asset"]))
    return unpacked["quantity"]


def _validate_transfer_quantity(dispatcher, state, quantity, netcode):
    script = util.h2b(state["deposit_script"])
    confirms, asset_balance, btc_balance = _deposit_status(
        dispatcher, state["asset"], script, netcode
    )
    if quantity > asset_balance:
        msg = "Amount greater total: {0} > {1}"
        raise ValueError(msg.format(quantity, asset_balance))


def _order_active(dispatcher, state):

    def sort_func(entry):
        return _get_quantity(dispatcher, state["asset"], entry["rawtx"])
    state["commits_active"].sort(key=sort_func)


def _revoke(state, secret):
    secret_hash = util.hash160hex(secret)
    for commit in state["commits_active"][:]:
        script = util.h2b(commit["script"])
        if secret_hash == scripts.get_commit_revoke_secret_hash(script):
            state["commits_active"].remove(commit)
            commit["revoke_secret"] = secret  # save secret
            del commit["rawtx"]  # forget rawtx so we can never publish
            state["commits_revoked"].append(commit)


def _get_payout_recoverable(dispatcher, state, netcode):
    _scripts = []
    for commit in (state["commits_active"] + state["commits_revoked"]):
        script = util.h2b(commit["script"])
        delay_time = scripts.get_commit_delay_time(script)
        address = util.script2address(script, netcode=netcode)
        if _can_spend_from_address(dispatcher, state["asset"], address):
            for utxo in dispatcher.get("get_unspent_txouts")(address):
                if utxo["confirmations"] >= delay_time:
                    _scripts.append(script)
    return _scripts


def _can_expire_recover(dispatcher, state, netcode):
    return (
        # deposit was made
        state["deposit_script"] is not None and

        # deposit expired
        _is_deposit_expired(dispatcher, state, netcode) and

        # funds to recover
        _can_deposit_spend(dispatcher, state, netcode)
    )


def _can_deposit_spend(dispatcher, state, netcode):
    script = util.h2b(state["deposit_script"])
    address = util.script2address(script, netcode)
    return _can_spend_from_address(dispatcher, state["asset"], address)


def _is_deposit_expired(dispatcher, state, netcode):
    script = util.h2b(state["deposit_script"])
    t = scripts.get_deposit_expire_time(script)
    confirms, asset_balance, btc_balance = _deposit_status(
        dispatcher, state["asset"], script, netcode
    )
    return confirms >= t


def _validate_deposit(dispatcher, asset, payer_pubkey, payee_pubkey,
                      spend_secret_hash, expire_time, quantity,
                      netcode, fee, regular_dust_size):

    # validate untrusted input data
    validate.pubkey(payer_pubkey)
    validate.pubkey(payee_pubkey)
    validate.hash160(spend_secret_hash)
    validate.is_sequence(expire_time)
    validate.is_quantity(quantity)
    # FIXME validate asset

    # get balances
    address = util.pubkey2address(payer_pubkey, netcode)
    asset_balance, btc_balance = _get_address_balance(
        dispatcher, asset, address
    )

    # check asset balance
    if asset_balance < quantity:
        raise exceptions.InsufficientFunds(quantity, asset_balance)

    # check btc balance
    extra_btc = (fee + regular_dust_size) * 3
    if btc_balance < extra_btc:
        raise exceptions.InsufficientFunds(extra_btc, btc_balance)


def _find_spend_secret(dispatcher, state, netcode):
    for commit in state["commits_active"] + state["commits_revoked"]:
        script = util.h2b(commit["script"])
        address = util.script2address(
            script, netcode=netcode
        )

        transactions = dispatcher.get("search_raw_transactions")(address)
        if len(transactions) == 1:
            continue  # only the commit, no payout
        for transaction in transactions:
            _spend_secret = scripts.get_spend_secret(transaction["hex"], script)
            if _spend_secret is not None:
                return _spend_secret
    return None


def _get_revoke_recoverable(dispatcher, state, netcode):
    revokable = []  # (script, secret)
    for commit in state["commits_revoked"]:
        script = util.h2b(commit["script"])
        address = util.script2address(script, netcode=netcode)
        if _can_spend_from_address(dispatcher, state["asset"], address):
            revokable.append((script, commit["revoke_secret"]))
    return revokable
