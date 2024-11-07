"""
Construct and serialize the Bitcoin transactions that are Counterparty transactions.

This module contains no consensus‐critical code.
"""

import binascii
import decimal
import inspect
import logging
import sys

from counterpartycore.lib import (
    arc4,  # noqa: F401 # TODO: need for test: clean that up
    backend,
    config,
    deserialize,
    exceptions,
    gettxinfo,
    script,
    util,
)
from counterpartycore.lib.transaction_helper import (
    common_serializer,
    p2sh_serializer,
    transaction_inputs,
    transaction_outputs,
)

logger = logging.getLogger(config.LOGGER_NAME)


D = decimal.Decimal


def collect_public_keys(pubkeys):
    # Get provided pubkeys.
    if isinstance(pubkeys, str):
        provided_pubkeys = pubkeys.split(",")
    elif isinstance(pubkeys, list):
        provided_pubkeys = pubkeys
    elif pubkeys is None:
        provided_pubkeys = []
    else:
        raise exceptions.TransactionError("Invalid pubkeys.")

    for pubkey in provided_pubkeys:
        try:
            if not script.is_fully_valid(binascii.unhexlify(pubkey)):
                raise exceptions.ComposeError(f"invalid public key: {pubkey}")
        except binascii.Error as e:
            raise exceptions.ComposeError(f"invalid public key: {pubkey}") from e
    return provided_pubkeys


def determine_encoding(
    data,
    desired_encoding="auto",
    op_return_max_size=config.OP_RETURN_MAX_SIZE,
):
    # Data encoding methods (choose and validate).
    if not data:
        return None

    if desired_encoding == "auto":
        if len(data) + len(config.PREFIX) <= op_return_max_size:
            encoding = "opreturn"
        else:
            encoding = "multisig"
    else:
        encoding = desired_encoding

    if encoding == "p2sh":
        raise exceptions.TransactionError("`P2SH` encoding deprecated, please use `multisig`")

    if encoding not in ("pubkeyhash", "multisig", "opreturn"):
        raise exceptions.TransactionError("Unknown encoding‐scheme.")

    return encoding


def check_transaction_sanity(db, source, tx_info, unsigned_tx_hex, encoding, inputs):
    (desired_source, desired_destination_outputs, desired_data) = tx_info
    if util.is_utxo_format(desired_source):
        desired_source, _ = backend.bitcoind.get_utxo_address_and_value(desired_source)
    desired_source = script.make_canonical(desired_source)
    desired_destination = (
        script.make_canonical(desired_destination_outputs[0][0])
        if desired_destination_outputs
        else ""
    )
    if desired_data == None:  # noqa: E711
        desired_data = b""

    # Parsed transaction info.
    try:
        parsed_source, parsed_destination, x, y, parsed_data, extra = (
            # TODO: inject
            gettxinfo.get_tx_info_new(
                db,
                deserialize.deserialize_tx(unsigned_tx_hex, use_txid=True),
                util.CURRENT_BLOCK_INDEX,
                p2sh_is_segwit=script.is_bech32(desired_source),
                composing=True,
            )
        )

        if encoding == "p2sh":
            # make_canonical can't determine the address, so we blindly change the desired to the parsed
            desired_source = parsed_source
    except exceptions.BTCOnlyError:
        # Skip BTC‐only transactions.
        return

    desired_source = script.make_canonical(desired_source)

    # Check desired info against parsed info.
    desired = (desired_source, desired_destination, desired_data)
    parsed = (parsed_source, parsed_destination, parsed_data)
    if desired != parsed:
        transaction_inputs.UTXOLocks().unlock_utxos(source, inputs)

        raise exceptions.TransactionError(
            f"Constructed transaction does not parse correctly: {desired} ≠ {parsed}"
        )


def serialize_transaction(
    inputs,
    source,
    provided_pubkeys,
    destination_outputs,
    data_output,
    change_output,
    encoding,
    dust_return_pubkey,
    p2sh_source_multisig_pubkeys,
    p2sh_source_multisig_pubkeys_required,
    p2sh_pretx_txid,
    segwit,
    exclude_utxos,
):
    pretx_txid = unsigned_pretx_hex = unsigned_tx_hex = None

    if encoding == "p2sh":
        pretx_txid, unsigned_pretx_hex, unsigned_tx_hex = p2sh_serializer.serialize_p2sh(
            inputs,
            source,
            provided_pubkeys,
            destination_outputs,
            data_output,
            change_output,
            dust_return_pubkey,
            p2sh_source_multisig_pubkeys,
            p2sh_source_multisig_pubkeys_required,
            p2sh_pretx_txid,
            segwit,
            exclude_utxos,
        )
    else:
        unsigned_tx = common_serializer.serialise(
            encoding,
            inputs,
            destination_outputs,
            data_output,
            change_output,
            dust_return_pubkey=dust_return_pubkey,
        )
        unsigned_tx_hex = binascii.hexlify(unsigned_tx).decode("utf-8")

    return unsigned_pretx_hex, unsigned_tx_hex, pretx_txid


def construct(
    db,
    tx_info,
    pubkeys=None,
    encoding="auto",
    fee_per_kb=None,
    exact_fee=None,
    fee_provided=0,
    confirmation_target=config.ESTIMATE_FEE_CONF_TARGET,
    regular_dust_size=config.DEFAULT_REGULAR_DUST_SIZE,
    multisig_dust_size=config.DEFAULT_MULTISIG_DUST_SIZE,
    op_return_value=config.DEFAULT_OP_RETURN_VALUE,
    op_return_max_size=config.OP_RETURN_MAX_SIZE,
    allow_unconfirmed_inputs=False,
    unspent_tx_hash=None,
    exclude_utxos=None,
    inputs_set=None,
    disable_utxo_locks=False,
    segwit=False,
    dust_return_pubkey=None,
    p2sh_source_multisig_pubkeys=None,
    p2sh_source_multisig_pubkeys_required=None,
    p2sh_pretx_txid=None,
    use_utxos_with_balances=False,
    exclude_utxos_with_balances=False,
    force_inputs_set=False,
):
    # Extract tx_info
    (address_or_utxo, destinations, data) = tx_info

    # if source is an utxo we force the construction function to use it in inputs
    # by passing it as force_utxo
    force_utxo = None
    if util.is_utxo_format(address_or_utxo):
        source, _value = backend.bitcoind.get_utxo_address_and_value(address_or_utxo)
        force_utxo = address_or_utxo
    else:
        source = address_or_utxo

    # Collect pubkeys
    provided_pubkeys = collect_public_keys(pubkeys)

    # Sanity checks.
    if source:
        script.validate(source)
    if exact_fee is not None and not isinstance(exact_fee, int):
        raise exceptions.TransactionError("Exact fees must be in satoshis.")
    if not isinstance(fee_provided, int):
        raise exceptions.TransactionError("Fee provided must be in satoshis.")

    """Determine encoding method"""

    encoding = determine_encoding(data, encoding, op_return_max_size)

    """Outputs"""

    (
        destination_outputs,
        destination_btc_out,
        data_array,
        data_btc_out,
        data_output,
        dust_return_pubkey,
    ) = transaction_outputs.prepare_outputs(
        data,
        source,
        destinations,
        provided_pubkeys,
        encoding,
        multisig_dust_size,
        regular_dust_size,
        dust_return_pubkey,
        op_return_value,
        exact_fee,
        fee_per_kb,
    )

    """Inputs"""

    (inputs, change_output, btc_in, final_fee) = transaction_inputs.prepare_inputs(
        db,
        source,
        data,
        destination_outputs,
        destination_btc_out,
        data_array,
        data_btc_out,
        provided_pubkeys,
        encoding,
        p2sh_pretx_txid,
        allow_unconfirmed_inputs,
        unspent_tx_hash,
        inputs_set,
        fee_per_kb,
        confirmation_target,
        exact_fee,
        fee_provided,
        regular_dust_size,
        multisig_dust_size,
        disable_utxo_locks,
        exclude_utxos,
        use_utxos_with_balances,
        exclude_utxos_with_balances,
        force_utxo,
    )

    """Finish"""

    (unsigned_pretx_hex, unsigned_tx_hex, pretx_txid) = serialize_transaction(
        inputs,
        source,
        provided_pubkeys,
        destination_outputs,
        data_output,
        change_output,
        encoding,
        dust_return_pubkey,
        p2sh_source_multisig_pubkeys,
        p2sh_source_multisig_pubkeys_required,
        p2sh_pretx_txid,
        segwit,
        exclude_utxos,
    )

    """Sanity Check"""

    if (encoding == "p2sh" and pretx_txid) or encoding != "p2sh":
        check_transaction_sanity(db, source, tx_info, unsigned_tx_hex, encoding, inputs)

    logger.debug("TX Construct - Transaction constructed.")

    return {
        "btc_in": btc_in,
        "btc_out": destination_btc_out + data_btc_out,
        "btc_change": change_output[1] if change_output else None,
        "btc_fee": final_fee,
        "unsigned_tx_hex": unsigned_tx_hex,
        "unsigned_pretx_hex": unsigned_pretx_hex,
        "data": config.PREFIX + data if data else None,
    }


def get_default_args(func):
    signature = inspect.signature(func)
    return {
        k: v.default
        for k, v in signature.parameters.items()
        if v.default is not inspect.Parameter.empty
    }


def compose_data(db, name, params, accept_missing_params=False, skip_validation=False):
    compose_method = sys.modules[f"counterpartycore.lib.messages.{name}"].compose
    compose_params = inspect.getfullargspec(compose_method)[0]
    missing_params = [p for p in compose_params if p not in params and p != "db"]
    if accept_missing_params:  # for API v1 backward compatibility
        for param in missing_params:
            params[param] = None
    else:
        if len(missing_params) > 0:
            default_values = get_default_args(compose_method)
            for param in missing_params:
                if param in default_values:
                    params[param] = default_values[param]
                else:
                    raise exceptions.ComposeError(
                        f"missing parameters: {', '.join(missing_params)}"
                    )
    params["skip_validation"] = skip_validation
    return compose_method(db, **params)


def compose_transaction(db, name, params, accept_missing_params=False, **construct_kwargs):
    """Create and return a transaction."""
    skip_validation = not construct_kwargs.pop("validate", True)
    tx_info = compose_data(db, name, params, accept_missing_params, skip_validation)
    transaction_info = construct(db, tx_info, **construct_kwargs)
    return transaction_info
