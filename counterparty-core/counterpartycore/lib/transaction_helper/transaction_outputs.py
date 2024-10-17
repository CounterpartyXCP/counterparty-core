import binascii
import logging

from counterpartycore.lib import (
    backend,
    config,
    exceptions,
    script,
    util,
)
from counterpartycore.lib.transaction_helper import p2sh_serializer

logger = logging.getLogger(config.LOGGER_NAME)


def chunks(l, n):  # noqa: E741
    """Yield successive n‐sized chunks from l."""
    for i in range(0, len(l), n):
        yield l[i : i + n]


def pubkeyhash_to_pubkey(pubkeyhash, provided_pubkeys=None):
    # Search provided pubkeys.
    if provided_pubkeys:
        if not isinstance(provided_pubkeys, list):  # noqa: E721
            provided_pubkeys = [provided_pubkeys]
        for pubkey in provided_pubkeys:
            if pubkeyhash == script.pubkey_to_pubkeyhash(util.unhexlify(pubkey)):
                return pubkey
            elif pubkeyhash == script.pubkey_to_p2whash(util.unhexlify(pubkey)):
                return pubkey

    # Search blockchain.
    raw_transactions = backend.electr.get_history(pubkeyhash)
    for tx_id in raw_transactions:
        tx = raw_transactions[tx_id]
        for vin in tx["vin"]:
            if "witness" in vin:
                if len(vin["witness"]) >= 2:
                    # catch unhexlify errs for when txinwitness[1] isn't a witness program (eg; for P2W)
                    try:
                        pubkey = vin["witness"][1]
                        if pubkeyhash == script.pubkey_to_p2whash(util.unhexlify(pubkey)):
                            return pubkey
                    except binascii.Error:
                        pass
            elif "is_coinbase" not in vin or not vin["is_coinbase"]:
                asm = vin["scriptsig_asm"].split(" ")
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
            if value is None:  # noqa: E711
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
    destination_outputs,
    provided_pubkeys,
    encoding,
    multisig_dust_size,
    regular_dust_size,
    dust_return_pubkey,
    op_return_value,
    exact_fee,
    fee_per_kb,
):
    source_is_p2sh = script.is_p2sh(source)

    if dust_return_pubkey:
        dust_return_pubkey = binascii.unhexlify(dust_return_pubkey)

    ps2h_dust_return_pubkey = config.P2SH_DUST_RETURN_PUBKEY

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

            chunk_size = p2sh_serializer.maximum_data_chunk_size(pubkeylength)
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

    if encoding == "p2sh":
        _size_for_fee, _datatx_necessary_fee, data_value, data_btc_out = (
            p2sh_serializer.calculate_outputs(
                destination_outputs, data_array, fee_per_kb, exact_fee
            )
        )
    else:
        data_btc_out = data_value * len(data_array)

    logger.trace(
        f"TX Construct - data_btc_out={data_btc_out} (data_value={data_value} len(data_array)={len(data_array)})"
    )

    return data_value, data_array, data_btc_out, dust_return_pubkey


def prepare_outputs(
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
):
    """Destinations"""

    destination_outputs = compute_destinations_and_values(
        destinations, encoding, multisig_dust_size, regular_dust_size, provided_pubkeys
    )
    destination_btc_out = sum([value for address, value in destination_outputs])

    """Data"""

    data_value, data_array, data_btc_out, dust_return_pubkey = prepare_data_output(
        data,
        source,
        destination_outputs,
        provided_pubkeys,
        encoding,
        multisig_dust_size,
        regular_dust_size,
        dust_return_pubkey,
        op_return_value,
        exact_fee,
        fee_per_kb,
    )
    data_output = (data_array, data_value) if len(data_array) > 0 else None

    return (
        destination_outputs,
        destination_btc_out,
        data_array,
        data_btc_out,
        data_output,
        dust_return_pubkey,
    )
