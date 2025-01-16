import binascii
import logging
import struct
from io import BytesIO

from arc4 import ARC4
from bitcoinutils.keys import PublicKey

from counterpartycore.lib import backend, config, exceptions
from counterpartycore.lib.exceptions import BTCOnlyError, DecodeError
from counterpartycore.lib.ledger import ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import dispenser
from counterpartycore.lib.parser import gettxinfolegacy, messagetype, p2sh, protocol
from counterpartycore.lib.utils import base58, multisig, script
from counterpartycore.lib.utils.opcodes import *  # noqa: F403

logger = logging.getLogger(config.LOGGER_NAME)


def get_checksig(asm):
    try:
        op_dup, op_hash160, pubkeyhash, op_equalverify, op_checksig = asm
    except ValueError:
        raise exceptions.DecodeError("invalid OP_CHECKSIG") from None

    if (op_dup, op_hash160, op_equalverify, op_checksig) == (
        OP_DUP,  # noqa: F405
        OP_HASH160,  # noqa: F405
        OP_EQUALVERIFY,  # noqa: F405
        OP_CHECKSIG,  # noqa: F405
    ) and type(pubkeyhash) == bytes:  # noqa: E721
        return pubkeyhash

    raise exceptions.DecodeError("invalid OP_CHECKSIG")


def get_checkmultisig(asm):
    # N-of-2
    if len(asm) == 5 and asm[3] == 2 and asm[4] == OP_CHECKMULTISIG:  # noqa: F405
        pubkeys, signatures_required = asm[1:3], asm[0]
        if all([type(pubkey) == bytes for pubkey in pubkeys]):  # noqa: E721
            return pubkeys, signatures_required
    # N-of-3
    if len(asm) == 6 and asm[4] == 3 and asm[5] == OP_CHECKMULTISIG:  # noqa: F405
        pubkeys, signatures_required = asm[1:4], asm[0]
        if all([type(pubkey) == bytes for pubkey in pubkeys]):  # noqa: E721
            return pubkeys, signatures_required
    raise exceptions.DecodeError("invalid OP_CHECKMULTISIG")


def decode_checksig(asm, decoded_tx):
    pubkeyhash = get_checksig(asm)
    key = binascii.unhexlify(decoded_tx["vin"][0]["hash"])
    chunk = ARC4(key).decrypt(pubkeyhash)
    if chunk[1 : len(config.PREFIX) + 1] == config.PREFIX:  # Data
        # Padding byte in each output (instead of just in the last one) so that encoding methods may be mixed. Also, it’s just not very much data.
        chunk_length = chunk[0]
        chunk = chunk[1 : chunk_length + 1]
        destination, data = None, chunk[len(config.PREFIX) :]
    else:  # Destination
        pubkeyhash = binascii.hexlify(pubkeyhash).decode("utf-8")
        destination, data = base58.base58_check_encode(pubkeyhash, config.ADDRESSVERSION), None
    return destination, data


def decode_scripthash(asm):
    destination = base58.base58_check_encode(
        binascii.hexlify(asm[1]).decode("utf-8"), config.P2SH_ADDRESSVERSION
    )
    return destination, None


def decode_checkmultisig(asm, decoded_tx):
    pubkeys, signatures_required = get_checkmultisig(asm)
    chunk = b""
    for pubkey in pubkeys[:-1]:  # (No data in last pubkey.)
        chunk += pubkey[1:-1]  # Skip sign byte and nonce byte.
    key = binascii.unhexlify(decoded_tx["vin"][0]["hash"])
    chunk = ARC4(key).decrypt(chunk)
    if chunk[1 : len(config.PREFIX) + 1] == config.PREFIX:  # Data
        # Padding byte in each output (instead of just in the last one) so that encoding methods may be mixed. Also, it’s just not very much data.
        chunk_length = chunk[0]
        chunk = chunk[1 : chunk_length + 1]
        destination, data = None, chunk[len(config.PREFIX) :]
    else:  # Destination
        pubkeyhashes = [
            PublicKey.from_hex(binascii.hexlify(pubkey).decode("utf-8")).get_address().to_string()
            for pubkey in pubkeys
        ]
        destination, data = (
            multisig.construct_array(signatures_required, pubkeyhashes, len(pubkeyhashes)),
            None,
        )

    return destination, data


def is_valid_der(der):
    if not isinstance(der, bytes):
        return False
    try:
        s = BytesIO(der)
        compound = s.read(1)[0]
        if compound != 0x30:
            return False
        length = s.read(1)[0]
        if length + 2 != len(der):
            return False
        marker = s.read(1)[0]
        if marker != 0x02:
            return False
        rlength = s.read(1)[0]
        _r = int(s.read(rlength).hex(), 16)
        marker = s.read(1)[0]
        if marker != 0x02:
            return False
        slength = s.read(1)[0]
        s = int(s.read(slength).hex(), 16)
        if len(der) != 6 + rlength + slength:
            return False
        return True
    except Exception:
        return False


def is_valid_schnorr(schnorr):
    p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
    n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141

    if not isinstance(schnorr, bytes):
        return False
    if len(schnorr) not in [64, 65]:
        return False
    if len(schnorr) == 65:
        schnorr = schnorr[:-1]
    try:
        r = int.from_bytes(schnorr[0:32], byteorder="big")
        s = int.from_bytes(schnorr[32:64], byteorder="big")
    except Exception:
        return False
    if (r >= p) or (s >= n):
        return False
    return True


def get_der_signature_sighash_flag(value):
    if is_valid_der(value[:-1]):
        return value[-1:]
    return None


def get_schnorr_signature_sighash_flag(value):
    if is_valid_schnorr(value):
        if len(value) == 65:
            return value[-1:]
        return b"\x01"  # SIGHASH_ALL


def collect_sighash_flags(script_sig, witnesses):
    flags = []

    # P2PK, P2PKH, P2MS
    if script_sig != b"":
        asm = script.script_to_asm(script_sig)
        for item in asm:
            flag = get_der_signature_sighash_flag(item)
            if flag is not None:
                flags.append(flag)

    if len(witnesses) == 0:
        return flags

    witnesses = [
        binascii.unhexlify(witness) if isinstance(witness, str) else witness
        for witness in witnesses
    ]

    # P2WPKH
    if len(witnesses) == 2:
        flag = get_der_signature_sighash_flag(witnesses[0])
        if flag is not None:
            flags.append(flag)
        return flags

    # P2TR key path spend
    if len(witnesses) == 1:
        flag = get_schnorr_signature_sighash_flag(witnesses[0])
        if flag is not None:
            flags.append(flag)
        return flags

    # Other cases
    if len(witnesses) >= 3:
        for item in witnesses:
            flag = get_schnorr_signature_sighash_flag(item) or get_der_signature_sighash_flag(item)
            if flag is not None:
                flags.append(flag)
        return flags

    return flags


class SighashFlagError(DecodeError):
    pass


# known transactions with invalid SIGHASH flag
SIGHASH_FLAG_TRANSACTION_WHITELIST = [
    "c8091f1ef768a2f00d48e6d0f7a2c2d272a5d5c8063db78bf39977adcb12e103"
]


def check_signatures_sighash_flag(decoded_tx):
    if decoded_tx["tx_id"] in SIGHASH_FLAG_TRANSACTION_WHITELIST:
        return

    script_sig = decoded_tx["vin"][0]["script_sig"]
    witnesses = []
    if decoded_tx["segwit"]:
        witnesses = decoded_tx["vtxinwit"][0]

    flags = collect_sighash_flags(script_sig, witnesses)

    if len(flags) == 0:
        error = f"impossible to determine SIGHASH flag for transaction {decoded_tx['tx_id']}"
        logger.debug(error)
        raise SighashFlagError(error)

    # first input must be signed with SIGHASH_ALL or SIGHASH_ALL|SIGHASH_ANYONECANPAY
    authorized_flags = [b"\x01", b"\x81"]
    for flag in flags:
        if flag not in authorized_flags:
            error = f"invalid SIGHASH flag for transaction {decoded_tx['tx_id']}"
            logger.debug(error)
            raise SighashFlagError(error)


def get_transaction_sources(decoded_tx):
    sources = []
    outputs_value = 0

    for vin in decoded_tx["vin"]:  # Loop through inputs.
        vout_value, script_pubkey, _is_segwit = backend.bitcoind.get_vin_info(vin)

        outputs_value += vout_value

        asm = script.script_to_asm(script_pubkey)

        if asm[-1] == OP_CHECKSIG:  # noqa: F405
            new_source, new_data = decode_checksig(asm, decoded_tx)
            if new_data or not new_source:
                raise DecodeError("data in source")
        elif asm[-1] == OP_CHECKMULTISIG:  # noqa: F405
            new_source, new_data = decode_checkmultisig(asm, decoded_tx)
            if new_data or not new_source:
                raise DecodeError("data in source")
        elif asm[0] == OP_HASH160 and asm[-1] == OP_EQUAL and len(asm) == 3:  # noqa: F405
            new_source, new_data = decode_scripthash(asm)
            if new_data or not new_source:
                raise DecodeError("data in source")
        elif protocol.enabled("segwit_support") and asm[0] == b"":
            # Segwit output
            new_source = script.script_to_address(script_pubkey)
            new_data = None
        else:
            raise DecodeError("unrecognised source type")

        # old; append to sources, results in invalid addresses
        # new; first found source is source, the rest can be anything (to fund the TX for example)
        if not (protocol.enabled("first_input_is_source") and len(sources)):
            # Collect unique sources.
            if new_source not in sources:
                sources.append(new_source)

    return "-".join(sources), outputs_value


def get_transaction_source_from_p2sh(decoded_tx, p2sh_is_segwit):
    p2sh_encoding_source = None
    data = b""
    outputs_value = 0

    for vin in decoded_tx["vin"]:
        vout_value, _script_pubkey, is_segwit = backend.bitcoind.get_vin_info(vin)

        if protocol.enabled("prevout_segwit_fix"):
            prevout_is_segwit = is_segwit
        else:
            prevout_is_segwit = p2sh_is_segwit

        outputs_value += vout_value

        # Ignore transactions with invalid script.
        asm = script.script_to_asm(vin["script_sig"])

        new_source, new_destination, new_data = p2sh.decode_p2sh_input(
            asm, p2sh_is_segwit=prevout_is_segwit
        )
        # this could be a p2sh source address with no encoded data
        if new_data is None:
            continue

        if new_source is not None:
            if p2sh_encoding_source is not None and new_source != p2sh_encoding_source:
                # this p2sh data input has a bad source address
                raise DecodeError("inconsistent p2sh inputs")

            p2sh_encoding_source = new_source

        assert not new_destination

        data += new_data

    return p2sh_encoding_source, data, outputs_value


def get_dispensers_outputs(db, potential_dispensers):
    outputs = []
    for destination, btc_amount in potential_dispensers:
        if destination is None or btc_amount is None:
            continue
        if dispenser.is_dispensable(db, destination, btc_amount):
            outputs.append((destination, btc_amount))
    return outputs


def get_dispensers_tx_info(sources, dispensers_outputs):
    source, destination, btc_amount, fee, data, outs = b"", None, None, None, None, []

    dispenser_source = sources.split("-")[0]
    out_index = 0
    for out in dispensers_outputs:
        if out[0] is None or out[1] is None:
            continue
        if out[0] != dispenser_source:
            source = dispenser_source
            destination = out[0]
            btc_amount = out[1]
            fee = 0
            data = struct.pack(config.SHORT_TXTYPE_FORMAT, dispenser.DISPENSE_ID)
            data += b"\x00"

            if protocol.enabled("multiple_dispenses"):
                outs.append({"destination": out[0], "btc_amount": out[1], "out_index": out_index})
            else:
                break  # Prevent inspection of further dispenses (only first one is valid)

        out_index = out_index + 1

    return source, destination, btc_amount, fee, data, outs


def get_tx_info_new(db, decoded_tx, block_index, p2sh_is_segwit=False, composing=False):
    """Get multisig transaction info.
    The destinations, if they exists, always comes before the data output; the
    change, if it exists, always comes after.
    """

    # Ignore coinbase transactions.
    if decoded_tx["coinbase"]:
        raise DecodeError("coinbase transaction")

    # Get destinations and data outputs.
    if "parsed_vouts" not in decoded_tx:
        raise DecodeError("no parsed_vouts in decoded_tx")
    if isinstance(decoded_tx["parsed_vouts"], Exception):
        raise DecodeError(str(decoded_tx["parsed_vouts"]))
    if decoded_tx["parsed_vouts"] == "DecodeError":
        raise DecodeError("unrecognised output type")

    destinations, btc_amount, fee, data, potential_dispensers = decoded_tx["parsed_vouts"]

    # source can be determined by parsing the p2sh_data transaction
    #   or from the first spent output
    sources = []
    fee_added = False
    # P2SH encoding signalling
    p2sh_encoding_source = None
    if protocol.enabled("p2sh_encoding") and data == b"P2SH":
        p2sh_encoding_source, data, outputs_value = get_transaction_source_from_p2sh(
            decoded_tx, p2sh_is_segwit
        )
        fee += outputs_value
        fee_added = True

    # Only look for source if data were found or destination is `UNSPENDABLE`,
    # for speed.
    dispensers_outputs = []
    if not data and destinations != [
        config.UNSPENDABLE,
    ]:
        if protocol.enabled("disable_vanilla_btc_dispense", block_index):
            raise BTCOnlyError("no data and not unspendable")

        if protocol.enabled("dispensers", block_index) and not composing:
            dispensers_outputs = get_dispensers_outputs(db, potential_dispensers)
            if len(dispensers_outputs) == 0:
                raise BTCOnlyError("no data and not unspendable")
        else:
            raise BTCOnlyError("no data and not unspendable")

    # Collect all (unique) source addresses.
    #   if we haven't found them yet
    if p2sh_encoding_source is None:
        if not composing:
            check_signatures_sighash_flag(decoded_tx)
        sources, outputs_value = get_transaction_sources(decoded_tx)
        if not fee_added:
            fee += outputs_value
    else:  # use the source from the p2sh data source
        sources = p2sh_encoding_source

    if not data and destinations != [
        config.UNSPENDABLE,
    ]:
        assert protocol.enabled(
            "dispensers", block_index
        )  # else an exception would have been raised above
        assert len(dispensers_outputs) > 0  # else an exception would have been raised above
        return get_dispensers_tx_info(sources, dispensers_outputs)

    destinations = "-".join(destinations)

    try:
        message_type_id, _ = messagetype.unpack(data, block_index)
    except struct.error:  # Deterministically raised.
        message_type_id = None

    if message_type_id == dispenser.DISPENSE_ID and protocol.enabled(
        "enable_dispense_tx", block_index=block_index
    ):
        # if there is a dispense prefix we assume all potential_dispensers are dispensers
        # that's mean we don't need to call get_dispensers_outputs()
        # and so we avoid a db query (dispenser.is_dispensable()).
        # If one of them is not a dispenser `dispenser.dispense()` will silently skip it
        return get_dispensers_tx_info(sources, potential_dispensers)

    return sources, destinations, btc_amount, round(fee), data, []


def _get_tx_info(db, decoded_tx, block_index, p2sh_is_segwit=False, composing=False):
    """Get the transaction info. Calls one of two subfunctions depending on signature type."""
    if not block_index:
        block_index = CurrentState().current_block_index()

    if protocol.enabled("p2sh_addresses", block_index=block_index):  # Protocol change.
        return get_tx_info_new(
            db,
            decoded_tx,
            block_index,
            p2sh_is_segwit=p2sh_is_segwit,
            composing=composing,
        )
    elif protocol.enabled("multisig_addresses", block_index=block_index):  # Protocol change.
        return get_tx_info_new(
            db,
            decoded_tx,
            block_index,
            composing=composing,
        )
    else:
        return gettxinfolegacy.get_tx_info_legacy(decoded_tx, block_index)


def select_utxo_destination(vouts):
    for n, vout in enumerate(vouts):
        try:
            asm = script.script_to_asm(vout["script_pub_key"])
            if asm[0] == OP_RETURN:  # noqa: F405
                continue
        except DecodeError:
            # invalid script are considered as no-OP_RETURN
            # and so can be considered as destination
            # this is to be compatible with Ordinal's behavior
            pass
        return n
    return None


def get_inputs_with_balance(db, decoded_tx):
    sources = []
    # we check that each vin does not contain assets..
    for vin in decoded_tx["vin"]:
        utxo = vin["hash"] + ":" + str(vin["n"])
        if ledger.utxo_has_balance(db, utxo):
            sources.append(utxo)
    return sources


def get_first_non_op_return_output(decoded_tx):
    n = select_utxo_destination(decoded_tx["vout"])
    if n is not None:
        destination = decoded_tx["tx_hash"] + ":" + str(n)
        return destination
    return None


def get_op_return_vout(decoded_tx):
    for n, vout in enumerate(decoded_tx["vout"]):
        try:
            asm = script.script_to_asm(vout["script_pub_key"])
            if asm[0] == OP_RETURN:  # noqa: F405
                return n
        except DecodeError:
            pass
    return None


KNOWN_SOURCES = {
    "92ad58f5aa35c503489efbdd2a466e942baa9ac5cd67cb7544adf03e47a457d0": "a71da7169db3672408c7b25f84be425839548e63fa480c0478f91e3c2aa3ec67:0",
    "c80143886181ebbc782d23a50acca0f5ea7ac005d3164d7c76fc5e14f72d47c8": "",
}


def get_utxos_info(db, decoded_tx):
    op_return_vout = get_op_return_vout(decoded_tx)
    if decoded_tx["tx_id"] in KNOWN_SOURCES:
        sources = KNOWN_SOURCES[decoded_tx["tx_id"]]
    else:
        sources = ",".join(get_inputs_with_balance(db, decoded_tx))
    return [
        sources,  # sources
        get_first_non_op_return_output(decoded_tx) or "",  # destination
        str(len(decoded_tx["vout"])),  # number of outputs
        str(op_return_vout) if op_return_vout is not None else "",  # op_return output
    ]


def update_utxo_balances_cache(db, utxos_info, data, destination, block_index):
    if (
        protocol.enabled("utxo_support", block_index=block_index)
        and not CurrentState().parsing_mempool()
    ):
        transaction_type = messagetype.get_transaction_type(
            data, destination, utxos_info, block_index
        )
        if utxos_info[0] != "":
            # always remove from cache inputs with balance
            ledger.UTXOBalancesCache(db).remove_balance(utxos_info[0])
            # add to cache the destination if it's not a detach
            if utxos_info[1] != "" and transaction_type != "detach":
                ledger.UTXOBalancesCache(db).add_balance(utxos_info[1])
        elif utxos_info[1] != "" and transaction_type == "attach":
            # add to cache the destination if it's an attach
            ledger.UTXOBalancesCache(db).add_balance(utxos_info[1])


def get_tx_info(db, decoded_tx, block_index, composing=False):
    """Get the transaction info. Returns normalized None data for DecodeError and BTCOnlyError."""
    data, destination, utxos_info = None, None, []

    if protocol.enabled("utxo_support", block_index=block_index):
        # utxos_info contains sources (inputs with balances),
        # destination (first non-OP_RETURN output),
        # number of outputs and the OP_RETURN index
        utxos_info = get_utxos_info(db, decoded_tx)

    try:
        source, destination, btc_amount, fee, data, dispensers_outs = _get_tx_info(
            db, decoded_tx, block_index, composing=composing
        )
        return source, destination, btc_amount, fee, data, dispensers_outs, utxos_info
    except DecodeError as e:  # noqa: F841
        return b"", None, None, None, None, None, utxos_info
    except BTCOnlyError as e:  # noqa: F841
        return b"", None, None, None, None, None, utxos_info
    finally:
        # update utxo balances cache before parsing the transaction
        # to catch chained utxo moves
        update_utxo_balances_cache(db, utxos_info, data, destination, block_index)
