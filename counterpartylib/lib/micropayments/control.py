import copy
import pycoin
from . import validate
from . import exceptions
from micropayment_core import util
from micropayment_core import keys
from micropayment_core import scripts
from counterpartylib.lib import backend
from counterpartylib.lib import config


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


def get_published_commits(dispatcher, state, netcode):
    commits_found = []
    deposit_script = state["deposit_script"]
    deposit_address = util.script_address(deposit_script, netcode)
    deposit_transactions = dispatcher.get("search_raw_transactions")(
        address=deposit_address, unconfirmed=True
    )
    deposit_txids = [tx["txid"] for tx in deposit_transactions]
    commits = state["commits_active"] + state["commits_revoked"]
    for commit_script in [commit["script"] for commit in commits]:
        commit_address = util.script_address(commit_script, netcode)
        commit_transactions = dispatcher.get("search_raw_transactions")(
            address=commit_address, unconfirmed=True
        )
        for commit_transaction in commit_transactions:

            # spend: deposit -> commit
            if commit_transaction["txid"] in deposit_txids:
                commits_found.append(commit_transaction["hex"])
    return commits_found


def make_deposit(dispatcher, asset, payer_pubkey, payee_pubkey,
                 spend_secret_hash, expire_time, quantity, netcode):

    # validate input
    _validate_deposit(dispatcher, asset, payer_pubkey, payee_pubkey,
                      spend_secret_hash, expire_time, quantity, netcode)

    # create deposit
    rawtx, script = _create_deposit(
        dispatcher, asset, payer_pubkey, payee_pubkey, spend_secret_hash,
        expire_time, quantity, netcode
    )

    # setup initial state
    state = copy.deepcopy(INITIAL_STATE)
    state["asset"] = asset
    state["deposit_script"] = script

    return {
        "state": state,
        "topublish": rawtx
    }


def set_deposit(dispatcher, asset, deposit_script, expected_payee_pubkey,
                expected_spend_secret_hash):

    # validate input
    validate.pubkey(expected_payee_pubkey)
    validate.hash160(expected_spend_secret_hash)
    validate.deposit_script(deposit_script, expected_payee_pubkey,
                            expected_spend_secret_hash)
    validate.is_asset(dispatcher, asset)

    # setup initial state
    state = copy.deepcopy(INITIAL_STATE)
    state["asset"] = asset
    state["deposit_script"] = deposit_script

    return state


def request_commit(dispatcher, state, quantity, revoke_secret_hash, netcode):

    # validate input
    validate.is_state(dispatcher, state, netcode)
    validate.is_quantity(quantity)
    validate.hash160(revoke_secret_hash)
    _validate_transfer_quantity(dispatcher, state, quantity, netcode)

    # update state
    state["commits_requested"].append(revoke_secret_hash)
    return state


def create_commit(dispatcher, state, quantity, revoke_secret_hash,
                  delay_time, netcode):

    # validate input
    validate.is_state(dispatcher, state, netcode)
    validate.is_quantity(quantity)
    validate.hash160(revoke_secret_hash)
    validate.is_sequence(delay_time)
    _validate_transfer_quantity(dispatcher, state, quantity, netcode)

    # create deposit script and rawtx
    deposit_script = state["deposit_script"]
    rawtx, commit_script = _create_commit(
        dispatcher, state["asset"], deposit_script, quantity,
        revoke_secret_hash, delay_time, netcode
    )

    # update state
    _order_active(dispatcher, state)
    state["commits_active"].append({
        "rawtx": rawtx, "script": commit_script
    })

    return {
        "state": state,
        "commit_script": commit_script,
        "tosign": {
            "commit_rawtx": rawtx,
            "deposit_script": state["deposit_script"]
        }
    }


def add_commit(dispatcher, state, commit_rawtx, commit_script, netcode):

    # validate input
    validate.is_state(dispatcher, state, netcode)
    validate.commit_script(commit_script, state["deposit_script"])
    validate.is_commit_rawtx(
        dispatcher, commit_rawtx, state["asset"],
        state["deposit_script"], commit_script, netcode
    )
    validate.inputs_confirmed(dispatcher, commit_rawtx)

    # update state
    script = commit_script
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
            return state

    raise exceptions.NoRevokeSecretForCommit(
        commit_script, script_revoke_secret_hash
    )


def revoke_hashes_until(dispatcher, state, quantity, surpass, netcode):

    # validate input
    validate.is_state(dispatcher, state, netcode)
    validate.is_unsigned(quantity)

    # get revoke secret hashes
    revoke_secret_hashes = []
    _order_active(dispatcher, state)
    exact_match = False
    for commit in reversed(state["commits_active"][:]):
        commit_quantity, btc_quantity = get_transferred(
            dispatcher, commit["rawtx"], asset=state["asset"]
        )
        exact_match = (quantity == commit_quantity or quantity == 0)
        if quantity < commit_quantity:
            script = commit["script"]
            secret_hash = scripts.get_commit_revoke_secret_hash(script)
            revoke_secret_hashes.append(secret_hash)
        else:
            break

    # prevent revoking past quantity unless explicitly requested
    if not exact_match and not surpass and len(revoke_secret_hashes) > 0:
        revoke_secret_hashes.pop()

    return revoke_secret_hashes


def revoke_all(dispatcher, state, secrets, netcode):

    # validate input
    validate.is_state(dispatcher, state, netcode)
    validate.is_list(secrets)
    for secret in secrets:
        validate.is_hex(secret)

    # update state
    for secret in secrets:
        _revoke(state, secret)

    return state


def highest_commit(dispatcher, state, netcode):

    # validate input
    validate.is_state(dispatcher, state, netcode)

    _order_active(dispatcher, state)
    if len(state["commits_active"]) == 0:
        return None
    return state["commits_active"][-1]


def transferred_amount(dispatcher, state, netcode):

    # validate input
    validate.is_state(dispatcher, state, netcode)

    if len(state["commits_active"]) == 0:
        return 0
    _order_active(dispatcher, state)
    commit = state["commits_active"][-1]
    asset_quantity, btc_quantity = get_transferred(
        dispatcher, commit["rawtx"], asset=state["asset"]
    )
    return asset_quantity


def payouts(dispatcher, state, netcode):

    # validate input
    validate.is_state(dispatcher, state, netcode)

    # find recoverables and make payout transactions
    payouts = []
    recoverable_scripts = _get_payout_recoverable(dispatcher, state, netcode)
    if len(recoverable_scripts) > 0:
        deposit_script = state["deposit_script"]
        payee_pubkey = scripts.get_deposit_payee_pubkey(deposit_script)
        for script in recoverable_scripts:
            rawtx = _create_recover_commit(
                dispatcher, state["asset"], payee_pubkey,
                script, "payout", netcode
            )
            payouts.append({
                "payout_rawtx": rawtx, "commit_script": script,
            })
    return payouts


def recoverables(dispatcher, state, spend_secret, netcode):

    # validate input
    validate.is_state(dispatcher, state, netcode)
    validate.is_spend_secret(state, spend_secret)

    deposit_script = state["deposit_script"]
    payer_pubkey = scripts.get_deposit_payer_pubkey(deposit_script)
    recoverables = {"revoke": [], "change": [], "expire": []}

    # If revoked commit published, recover funds asap!
    revokable = _get_revoke_recoverable(dispatcher, state, netcode)
    if len(revokable) > 0:
        for script, secret in revokable:
            rawtx = _create_recover_commit(
                dispatcher, state["asset"], payer_pubkey,
                script, "revoke", netcode, revoke_recover=True
            )
            recoverables["revoke"].append({
                "revoke_rawtx": rawtx,
                "commit_script": script,
                "revoke_secret": secret
            })

    # If deposit expired recover the coins!
    if _can_expire_recover(dispatcher, state, netcode):
        rawtx = _recover_deposit(
            dispatcher, state["asset"], payer_pubkey,
            deposit_script, "expire", netcode,
        )
        recoverables["expire"].append({
            "expire_rawtx": rawtx,
            "deposit_script": state["deposit_script"]
        })

    else:

        # If not expired and spend secret exposed by payout recover change!
        address = util.script_address(deposit_script, netcode)
        if _can_spend_from_address(dispatcher, state["asset"], address):
            if spend_secret is None:
                spend_secret = _find_spend_secret(dispatcher, state, netcode)
            if spend_secret is not None:
                rawtx = _recover_deposit(
                    dispatcher, state["asset"], payer_pubkey,
                    deposit_script, "change", netcode
                )
                recoverables["change"].append({
                    "change_rawtx": rawtx,
                    "deposit_script": state["deposit_script"],
                    "spend_secret": spend_secret
                })

    return recoverables


def get_utxos(dispatcher, address, sequence=None):
    all_utxos = dispatcher.get("get_unspent_txouts")(
        address=address, unconfirmed=False
    )
    valid_utxos = []
    for utxo in all_utxos:
        if sequence is None or utxo["confirmations"] >= sequence:
            valid_utxos.append(utxo)
    return valid_utxos


def get_balance(dispatcher, address, asset):
    result = dispatcher.get("get_balances")(filters=[
        {'field': 'address', 'op': '==', 'value': address},
        {'field': 'asset', 'op': '==', 'value': asset},
    ])
    if not result:
        return 0, 0
    asset_balance = result[0]["quantity"]
    utxos = dispatcher.get("get_unspent_txouts")(
        address=address, unconfirmed=False
    )
    btc_balance = sum(map(lambda utxo: util.to_satoshis(utxo["amount"]), utxos))
    return asset_balance, btc_balance


def get_spendable(dispatcher, address, asset, sequence=None):
    max_asset, max_btc = get_balance(dispatcher, address, asset)
    utxos = get_utxos(dispatcher, address, sequence=sequence)
    if sequence is None:
        return max_asset, max_btc, utxos
    utxo_sum = 0
    for utxo in utxos:
        utxo_sum += util.to_satoshis(utxo["amount"])
    return max_asset, utxo_sum, utxos


def _btc_transferred(dispatcher, rawtx, address):

    def get_txs_func(txids):
        return dispatcher.get("getrawtransaction_batch")(txhash_list=txids)

    netcode = keys.netcode_from_address(address)
    tx = util.load_tx(get_txs_func, rawtx)

    total = 0
    for tx_out in tx.txs_out:
        try:
            if tx_out.bitcoin_address(netcode=netcode) == address:
                total += tx_out.coin_value
        except Exception:
            pass  # XXX work around pycoin bug
            # FIXME add pycoin issue, to know when to remove work around
    if not tx.is_coinbase():
        for tx_out in tx.unspents:
            if tx_out.bitcoin_address(netcode=netcode) == address:
                total -= tx_out.coin_value
    return total


def get_transferred(dispatcher, rawtx, asset=None, address=None):
    quantity = 0
    try:
        src, dest, btc, fee, data = dispatcher.get("get_tx_info")(tx_hex=rawtx)
        if data:
            message_type_id, unpacked = dispatcher.get("unpack")(data_hex=data)
            assert(message_type_id == 0)

            if asset is not None and asset != unpacked["asset"]:
                raise exceptions.AssetMissmatch(asset, unpacked["asset"])
            assert(address is None or address == src or address == dest)

            # by default return payee view
            if address is None or dest == address:
                return unpacked["quantity"], btc

            # address is source
            quantity = -unpacked["quantity"]
    except Exception:
        pass  # not a counterparty tx

    # must count tx outputs - inputs for payer view
    if address is None:
        return quantity, 0
    return quantity, _btc_transferred(dispatcher, rawtx, address)


def deposit_ttl(dispatcher, state, clearance, netcode):
    validate.is_unsigned(clearance)
    validate.is_state(dispatcher, state, netcode)
    script = state["deposit_script"]
    t = scripts.get_deposit_expire_time(script)
    confirms, asset_balance, btc_balance = _deposit_status(
        dispatcher, state["asset"], script, netcode
    )
    if confirms == 0 and asset_balance == 0 and btc_balance == 0:
        return None  # no deposit made yet
    return max(t - (confirms + clearance), 0)


def _deposit_status(dispatcher, asset, script, netcode):
    address = util.script_address(script, netcode)
    transactions = dispatcher.get("search_raw_transactions")(
        address=address, unconfirmed=False
    )
    if len(transactions) == 0:
        return 0, 0, 0
    all_confirms = [tx.get("confirmations") for tx in transactions]
    asset_balance, btc_balance, utxos = get_spendable(
        dispatcher, address, asset
    )
    return max(all_confirms), asset_balance, btc_balance


def _validate_channel_unused(dispatcher, channel_address):
    transactions = dispatcher.get("search_raw_transactions")(
        address=channel_address, unconfirmed=True
    )
    if len(transactions) > 0:
        raise exceptions.ChannelAlreadyUsed(channel_address, transactions)


def _recover_tx(dispatcher, asset, dest_address, script, netcode, sequence):

    # get channel info
    src_address = util.script_address(script, netcode)
    asset_balance, btc_balance, utxos = get_spendable(dispatcher, src_address,
                                                      asset, sequence=sequence)

    # recover btc is possible
    optimal_fee = _get_fee()
    dust_size = _get_dust_size()
    if btc_balance >= (optimal_fee + dust_size):
        fee = optimal_fee
        extra_btc = btc_balance - fee
    elif btc_balance >= dust_size:
        extra_btc = dust_size
        fee = btc_balance - dust_size  # suboptimal fee
    # < dust_size impossable due to previous _can_spend_from_address check

    # create tx
    rawtx = dispatcher.get("create_send")(
        source=src_address,
        destination=dest_address,
        quantity=asset_balance,
        asset=asset,
        regular_dust_size=extra_btc,
        fee=fee,
        disable_utxo_locks=True,
        custom_inputs=utxos
    )

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


def _create_recover_commit(dispatcher, asset, pubkey, script,
                           spend_type, netcode, revoke_recover=False):
    dest_address = keys.address_from_pubkey(pubkey, netcode=netcode)
    if revoke_recover:
        delay_time = 0  # can ignore delay fro revoke recover
    else:
        delay_time = scripts.get_commit_delay_time(script)
    return _recover_tx(dispatcher, asset, dest_address, script,
                       netcode, delay_time)


def _recover_deposit(dispatcher, asset, pubkey, script,
                     spend_type, netcode):
    dest_address = keys.address_from_pubkey(pubkey, netcode=netcode)
    expire_time = scripts.get_deposit_expire_time(script)
    rawtx = _recover_tx(
        dispatcher, asset, dest_address, script, netcode,
        expire_time if spend_type == "expire" else None
    )
    return rawtx


def _create_commit(dispatcher, asset, deposit_script, quantity,
                   revoke_secret_hash, delay_time, netcode):

    # create script
    payer_pubkey = scripts.get_deposit_payer_pubkey(deposit_script)
    payee_pubkey = scripts.get_deposit_payee_pubkey(deposit_script)
    spend_secret_hash = scripts.get_deposit_spend_secret_hash(deposit_script)
    commit_script = scripts.compile_commit_script(
        payer_pubkey, payee_pubkey, spend_secret_hash,
        revoke_secret_hash, delay_time
    )

    # create tx
    src_address = util.script_address(deposit_script, netcode)
    dest_address = util.script_address(commit_script, netcode)
    asset_balance, btc_balance, utxos = get_spendable(
        dispatcher, src_address, asset
    )
    fee = int(btc_balance / 3)
    if quantity == asset_balance:  # spend all btc as change tx not needed
        extra_btc = btc_balance - fee
    else:  # provide extra btc for future payout/revoke tx fees
        extra_btc = int(btc_balance / 3)
    rawtx = dispatcher.get("create_send")(
        source=src_address,
        destination=dest_address,
        quantity=quantity,
        asset=asset,
        regular_dust_size=extra_btc,
        fee=fee,
        disable_utxo_locks=True
    )
    return rawtx, commit_script


def _get_fee():
    fee_per_kb = config.DEFAULT_FEE_PER_KB

    # Cannot be cover in unit tests but manually tested.
    if config.ESTIMATE_FEE_PER_KB:  # pragma: no cover
        _fee_per_kb = backend.fee_per_kb(1)  # pragma: no cover
        if _fee_per_kb is not None:  # pragma: no cover
            fee_per_kb = max(_fee_per_kb, fee_per_kb)  # pragma: no cover

    return int(fee_per_kb / 2)


def _get_dust_size():
    return config.DEFAULT_REGULAR_DUST_SIZE


def _get_fee_multaple(factor=1):
    return int((_get_fee() + _get_dust_size()) * factor)


def _create_deposit(dispatcher, asset, payer_pubkey, payee_pubkey,
                    spend_secret_hash, expire_time, quantity, netcode):

    script = scripts.compile_deposit_script(payer_pubkey, payee_pubkey,
                                            spend_secret_hash, expire_time)
    dest_address = util.script_address(script, netcode)
    _validate_channel_unused(dispatcher, dest_address)
    payer_address = keys.address_from_pubkey(payer_pubkey, netcode)
    extra_btc = _get_fee_multaple(3)  # for change + commit + recover tx
    rawtx = dispatcher.get("create_send")(
        source=payer_address,
        destination=dest_address,
        quantity=quantity,
        asset=asset,
        regular_dust_size=(extra_btc or _get_dust_size()),
        fee=_get_fee(),
        disable_utxo_locks=True
    )
    return rawtx, script


def _can_spend_from_address(dispatcher, asset, address, sequence=None):
    asset_amount, utxo_sum, utxos = get_spendable(
        dispatcher, address, asset, sequence=sequence
    )
    return len(utxos) > 0 and utxo_sum > _get_dust_size()


def _validate_transfer_quantity(dispatcher, state, quantity, netcode):
    script = state["deposit_script"]
    confirms, asset_balance, btc_balance = _deposit_status(
        dispatcher, state["asset"], script, netcode
    )
    if quantity > asset_balance:
        raise exceptions.InvalidTransferQuantity(quantity, asset_balance)


def _order_active(dispatcher, state):

    def sort_func(entry):
        asset_quantity, btc_quantity = get_transferred(
            dispatcher, entry["rawtx"], asset=state["asset"]
        )
        return asset_quantity
    state["commits_active"].sort(key=sort_func)


def _revoke(state, secret):
    secret_hash = util.hash160hex(secret)
    for commit in state["commits_active"][:]:
        script = commit["script"]
        if secret_hash == scripts.get_commit_revoke_secret_hash(script):
            state["commits_active"].remove(commit)
            commit["revoke_secret"] = secret  # save secret
            del commit["rawtx"]  # forget rawtx so we can never publish
            state["commits_revoked"].append(commit)


def _get_payout_recoverable(dispatcher, state, netcode):
    _scripts = []
    for commit in (state["commits_active"] + state["commits_revoked"]):
        script = commit["script"]
        delay_time = scripts.get_commit_delay_time(script)
        address = util.script_address(script, netcode=netcode)
        if _can_spend_from_address(dispatcher, state["asset"], address):
            utxos = dispatcher.get("get_unspent_txouts")(
                address=address, unconfirmed=False
            )
            for utxo in utxos:
                if utxo["confirmations"] >= delay_time:
                    _scripts.append(script)
    return _scripts


def _can_expire_recover(dispatcher, state, netcode):
    return (
        # deposit was made
        state["deposit_script"] is not None and

        # deposit expired
        deposit_ttl(dispatcher, state, 0, netcode) == 0 and

        # funds to recover
        _can_deposit_spend(dispatcher, state, netcode)
    )


def _can_deposit_spend(dispatcher, state, netcode):
    script = state["deposit_script"]
    address = util.script_address(script, netcode)
    expire_time = scripts.get_deposit_expire_time(script)
    return _can_spend_from_address(
        dispatcher, state["asset"], address, sequence=expire_time
    )


def _validate_deposit(dispatcher, asset, payer_pubkey, payee_pubkey,
                      spend_secret_hash, expire_time, quantity, netcode):

    # validate untrusted input data
    validate.pubkey(payer_pubkey)
    validate.pubkey(payee_pubkey)
    validate.hash160(spend_secret_hash)
    validate.is_sequence(expire_time)
    validate.is_quantity(quantity)
    validate.is_asset(dispatcher, asset)

    # get balances
    address = keys.address_from_pubkey(payer_pubkey, netcode)
    asset_balance, btc_balance, utxos = get_spendable(
        dispatcher, address, asset
    )

    # check asset balance
    if asset_balance < quantity:
        raise exceptions.InsufficientFunds(quantity, asset_balance,
                                           address, asset)

    # check btc balance
    extra_btc = _get_fee_multaple(3)
    if btc_balance < extra_btc:
        raise exceptions.InsufficientFunds(extra_btc, btc_balance,
                                           address, "BTC")


def _find_spend_secret(dispatcher, state, netcode):
    for commit in state["commits_active"] + state["commits_revoked"]:
        script = commit["script"]
        address = util.script_address(script, netcode=netcode)
        transactions = dispatcher.get("search_raw_transactions")(
            address=address, unconfirmed=True
        )
        if len(transactions) == 1:
            continue  # only the commit, no payout or revoke
        for transaction in transactions:
            _spend_secret = scripts.get_spend_secret(
                transaction["hex"], script
            )
            if _spend_secret is not None:
                return _spend_secret
    return None


def _get_revoke_recoverable(dispatcher, state, netcode):
    revokable = []  # (script, secret)
    for commit in state["commits_revoked"]:
        script = commit["script"]
        address = util.script_address(script, netcode=netcode)
        if _can_spend_from_address(dispatcher, state["asset"], address):
            revokable.append((script, commit["revoke_secret"]))
    return revokable
