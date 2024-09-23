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
    config,
    deserialize,
    exceptions,
    gettxinfo,
    script,
    util,
)
from counterpartycore.lib.backend import addrindexrs
from counterpartycore.lib.messages import dispense  # noqa: F401
from counterpartycore.lib.transaction_helper import p2sh_encoding, serializer, transaction_inputs

logger = logging.getLogger(config.LOGGER_NAME)

# Constants
OP_RETURN = b"\x6a"
OP_PUSHDATA1 = b"\x4c"
OP_DUP = b"\x76"
OP_HASH160 = b"\xa9"
OP_EQUALVERIFY = b"\x88"
OP_CHECKSIG = b"\xac"
OP_0 = b"\x00"
OP_1 = b"\x51"
OP_2 = b"\x52"
OP_3 = b"\x53"
OP_CHECKMULTISIG = b"\xae"
OP_EQUAL = b"\x87"

D = decimal.Decimal


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

    raise exceptions.UnknownPubKeyError(
        "Public key was neither provided nor published in blockchain."
    )


def multisig_pubkeyhashes_to_pubkeys(address, provided_pubkeys=None):
    signatures_required, pubkeyhashes, signatures_possible = script.extract_array(address)
    pubkeys = [pubkeyhash_to_pubkey(pubkeyhash, provided_pubkeys) for pubkeyhash in pubkeyhashes]
    return script.construct_array(signatures_required, pubkeys, signatures_possible)


def get_dust_return_pubkey(source, provided_pubkeys):
    """Return the pubkey to which dust from data outputs will be sent.

    This pubkey is used in multi-sig data outputs (as the only real pubkey) to
    make those the outputs spendable. It is derived from the source address, so
    that the dust is spendable by the creator of the transaction.
    """
    # Get hex dust return pubkey.
    # inject `script`
    if script.is_multisig(source):
        a, self_pubkeys, b = script.extract_array(
            multisig_pubkeyhashes_to_pubkeys(source, provided_pubkeys)
        )
        dust_return_pubkey_hex = self_pubkeys[0]
    else:
        dust_return_pubkey_hex = pubkeyhash_to_pubkey(source, provided_pubkeys)

    # Convert hex public key into the (binary) dust return pubkey.
    try:
        dust_return_pubkey = binascii.unhexlify(dust_return_pubkey_hex)
    except binascii.Error:
        raise script.InputError("Invalid private key.")  # noqa: B904

    return dust_return_pubkey


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

    if encoding == "p2sh" and not util.enabled("p2sh_encoding"):
        raise exceptions.TransactionError("P2SH encoding not enabled yet")

    elif encoding not in ("pubkeyhash", "multisig", "opreturn", "p2sh"):
        raise exceptions.TransactionError("Unknown encoding‐scheme.")

    return encoding


def compute_destinations_and_values(
    destination_outputs, encoding, multisig_dust_size, regular_dust_size, provided_pubkeys
):
    # Destination outputs.
    # Replace multi‐sig addresses with multi‐sig pubkeys. Check that the
    # destination output isn’t a dust output. Set null values to dust size.
    destination_outputs_new = []
    if encoding != "p2sh":
        for address, value in destination_outputs:
            # Value.
            if script.is_multisig(address):
                dust_size = multisig_dust_size
            else:
                dust_size = regular_dust_size
            if value == None:  # noqa: E711
                value = dust_size  # noqa: PLW2901
            elif value < dust_size:
                raise exceptions.TransactionError("Destination output is dust.")
            # Address.
            script.validate(address)
            if script.is_multisig(address):
                destination_outputs_new.append(
                    (
                        multisig_pubkeyhashes_to_pubkeys(address, provided_pubkeys),
                        value,
                    )
                )
            else:
                destination_outputs_new.append((address, value))
    return destination_outputs_new


def prepare_data_output(
    data,
    source,
    source_is_p2sh,
    ps2h_dust_return_pubkey,
    encoding,
    multisig_dust_size,
    regular_dust_size,
    provided_pubkeys,
    dust_return_pubkey,
    op_return_value,
):
    data_value = 0
    data_array = []
    if data:
        # @TODO: p2sh encoding require signable dust key
        if encoding == "multisig":
            # dust_return_pubkey should be set or explicitly set to False to use the default configured for the node
            #  the default for the node is optional so could fail
            if (source_is_p2sh and dust_return_pubkey is None) or (
                dust_return_pubkey is False and ps2h_dust_return_pubkey is None
            ):
                raise exceptions.TransactionError(
                    "Can't use multisig encoding when source is P2SH and no dust_return_pubkey is provided."
                )
            elif dust_return_pubkey is False:
                dust_return_pubkey = binascii.unhexlify(ps2h_dust_return_pubkey)

        if not dust_return_pubkey:
            if encoding == "multisig" or encoding == "p2sh" and not source_is_p2sh:
                dust_return_pubkey = get_dust_return_pubkey(source, provided_pubkeys)
            else:
                dust_return_pubkey = None

        # Divide data into chunks.
        if encoding == "pubkeyhash":
            # Prefix is also a suffix here.
            chunk_size = 20 - 1 - 8
        elif encoding == "multisig":
            # Two pubkeys, minus length byte, minus prefix, minus two nonces,
            # minus two sign bytes.
            chunk_size = (33 * 2) - 1 - len(config.PREFIX) - 2 - 2
        elif encoding == "p2sh":
            pubkeylength = -1
            if dust_return_pubkey is not None:
                pubkeylength = len(dust_return_pubkey)

            chunk_size = p2sh_encoding.maximum_data_chunk_size(pubkeylength)
        elif encoding == "opreturn":
            chunk_size = config.OP_RETURN_MAX_SIZE
            if len(data) + len(config.PREFIX) > chunk_size:
                raise exceptions.TransactionError("One `OP_RETURN` output per transaction.")
        data_array = list(chunks(data, chunk_size))

        # Data outputs.
        if encoding == "multisig":
            data_value = multisig_dust_size
        elif encoding == "p2sh":
            data_value = 0  # this will be calculated later
        elif encoding == "opreturn":
            data_value = op_return_value
        else:
            # Pay‐to‐PubKeyHash, e.g.
            data_value = regular_dust_size
    else:
        dust_return_pubkey = None

    return data_value, data_array, dust_return_pubkey


def check_transaction_sanity(db, source, tx_info, unsigned_tx_hex, encoding, inputs):
    (desired_source, desired_destination_outputs, desired_data) = tx_info
    desired_source = script.make_canonical(desired_source)
    desired_destination = (
        script.make_canonical(desired_destination_outputs[0][0])
        if desired_destination_outputs
        else ""
    )
    # NOTE: Include change in destinations for BTC transactions.
    # if change_output and not desired_data and desired_destination != config.UNSPENDABLE:
    #    if desired_destination == '':
    #        desired_destination = desired_source
    #    else:
    #        desired_destination += f'-{desired_source}'
    # NOTE
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
        if not script.is_fully_valid(binascii.unhexlify(pubkey)):
            raise exceptions.ComposeError(f"invalid public key: {pubkey}")
    return provided_pubkeys


def construct(
    db,
    tx_info,
    pubkeys=None,
    encoding="auto",
    fee_per_kb=None,
    fee=None,
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
):
    exact_fee = fee
    ps2h_dust_return_pubkey = config.P2SH_DUST_RETURN_PUBKEY

    (source, destination_outputs, data) = tx_info

    provided_pubkeys = collect_public_keys(pubkeys)

    if dust_return_pubkey:
        dust_return_pubkey = binascii.unhexlify(dust_return_pubkey)

    if p2sh_source_multisig_pubkeys:
        p2sh_source_multisig_pubkeys = [binascii.unhexlify(p) for p in p2sh_source_multisig_pubkeys]

    # Source.
    # If public key is necessary for construction of (unsigned)
    # transaction, use the public key provided, or find it from the
    # blockchain.
    if source:
        script.validate(source)

    source_is_p2sh = script.is_p2sh(source)

    # Normalize source
    if script.is_multisig(source):
        source_address = multisig_pubkeyhashes_to_pubkeys(source, provided_pubkeys)
    else:
        source_address = source

    # Sanity checks.
    if exact_fee and not isinstance(exact_fee, int):
        raise exceptions.TransactionError("Exact fees must be in satoshis.")
    if not isinstance(fee_provided, int):
        raise exceptions.TransactionError("Fee provided must be in satoshis.")

    """Determine encoding method"""

    encoding = determine_encoding(data, encoding, op_return_max_size)
    if encoding:
        logger.debug(f"TX Construct - Constructing `{encoding.upper()}` transaction from {source}.")
    else:
        logger.debug(f"TX Construct - Constructing transaction from {source}.")

    """Destinations"""

    destination_outputs = compute_destinations_and_values(
        destination_outputs, encoding, multisig_dust_size, regular_dust_size, provided_pubkeys
    )
    destination_btc_out = sum([value for address, value in destination_outputs])

    """Data"""

    data_value, data_array, dust_return_pubkey = prepare_data_output(
        data,
        source,
        source_is_p2sh,
        ps2h_dust_return_pubkey,
        encoding,
        multisig_dust_size,
        regular_dust_size,
        provided_pubkeys,
        dust_return_pubkey,
        op_return_value,
    )

    if encoding == "p2sh":
        _size_for_fee, _datatx_necessary_fee, data_value, data_btc_out = (
            p2sh_encoding.calculate_outputs(destination_outputs, data_array, fee_per_kb, exact_fee)
        )
        # replace the data value
        data_output = (data_array, data_value)
    else:
        data_output = (data_array, data_value) if len(data_array) > 0 else None
        data_btc_out = data_value * len(data_array)

    logger.trace(
        f"TX Construct - data_btc_out={data_btc_out} (data_value={data_value} len(data_array)={len(data_array)})"
    )

    """Inputs"""

    inputs, change_quantity, btc_in, final_fee = transaction_inputs.prepare_inputs(
        encoding,
        data,
        destination_outputs,
        data_array,
        destination_btc_out,
        data_btc_out,
        source,
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
    )

    """Finish"""

    if change_quantity:
        change_output = (source_address, change_quantity)
    else:
        change_output = None

    unsigned_pretx_hex = None
    unsigned_tx_hex = None

    pretx_txid = None
    if encoding == "p2sh":
        pretx_txid, unsigned_pretx_hex, unsigned_tx_hex = p2sh_encoding.serialize_p2sh(
            inputs,
            source,
            source_address,
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
        # Serialise inputs and outputs.
        unsigned_tx = serializer.serialise(
            encoding,
            inputs,
            destination_outputs,
            data_output,
            change_output,
            dust_return_pubkey=dust_return_pubkey,
        )
        unsigned_tx_hex = binascii.hexlify(unsigned_tx).decode("utf-8")

    """Sanity Check"""

    if (encoding == "p2sh" and pretx_txid) or encoding != "p2sh":
        check_transaction_sanity(db, source, tx_info, unsigned_tx_hex, encoding, inputs)

    logger.debug("TX Construct - Transaction constructed.")

    return {
        "btc_in": btc_in,
        "btc_out": destination_btc_out + data_btc_out,
        "btc_change": change_quantity,
        "btc_fee": final_fee,
        "unsigned_tx_hex": unsigned_tx_hex,
        "unsigned_pretx_hex": unsigned_pretx_hex,
        "data": config.PREFIX + data if data else None,
    }


def chunks(l, n):  # noqa: E741
    """Yield successive n‐sized chunks from l."""
    for i in range(0, len(l), n):
        yield l[i : i + n]


def get_default_args(func):
    signature = inspect.signature(func)
    return {
        k: v.default
        for k, v in signature.parameters.items()
        if v.default is not inspect.Parameter.empty
    }


def compose_data(db, name, params, accept_missing_params=False):
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
    return compose_method(db, **params)


def compose_transaction(db, name, params, accept_missing_params=False, **construct_kwargs):
    """Create and return a transaction."""
    tx_info = compose_data(db, name, params, accept_missing_params)
    transaction_info = construct(db, tx_info, **construct_kwargs)
    return transaction_info
