# pylint: disable=too-many-lines
import binascii
import hashlib
import inspect
import logging
import math
import string
import sys
import threading
import time
from collections import OrderedDict
from decimal import Decimal as D

import cbor2
from arc4 import ARC4  # pylint: disable=no-name-in-module
from bitcoinutils.keys import (
    P2pkhAddress,
    P2shAddress,
    P2trAddress,
    P2wpkhAddress,
    PublicKey,
)
from bitcoinutils.script import Script, b_to_h
from bitcoinutils.transactions import Transaction, TxInput, TxOutput, TxWitnessInput
from bitcoinutils.utils import ControlBlock

from counterpartycore.lib import (
    backend,
    config,
    exceptions,
    ledger,
    messages,
)
from counterpartycore.lib.parser import deserialize, messagetype, utxosinfo
from counterpartycore.lib.utils import database, helpers, multisig, script

MAX_INPUTS_SET = 100
MAX_BTC_OUTPUT_VALUE = 21_000_000 * config.UNIT
MAX_CONFIRMATION_TARGET = 1008

logger = logging.getLogger(config.LOGGER_NAME)


get_output_type = script.get_output_type
is_segwit_output = script.is_segwit_output


def is_address_script(address, script_pub_key):
    if multisig.is_multisig(address):
        asm = script.script_to_asm(script_pub_key)
        pubkeys = [binascii.hexlify(pubkey).decode("utf-8") for pubkey in asm[1:-2]]
        addresses = [
            PublicKey.from_hex(pubkey).get_address(compressed=True).to_string()
            for pubkey in pubkeys
        ]
        script_address = f"{asm[0]}_{'_'.join(addresses)}_{asm[-2]}"
    else:
        script_address = script.script_to_address(script_pub_key)
    return address == script_address


################
#   Outputs    #
################


def address_to_script_pub_key(address, unspent_list=None, construct_params=None, network=None):  # noqa B006
    helpers.setup_bitcoinutils(network)
    if multisig.is_multisig(address):
        signatures_required, addresses, signatures_possible = multisig.extract_array(address)
        pubkeys = [
            search_pubkey(addr, unspent_list or [], construct_params or {}) for addr in addresses
        ]
        if None in pubkeys:
            raise exceptions.ComposeError(
                f"Pubkeys not found for {address}, please provide them with the `pubkeys` parameter"
            )
        multisig_script = Script(
            [signatures_required] + pubkeys + [signatures_possible] + ["OP_CHECKMULTISIG"]
        )
        return multisig_script
    try:
        return P2trAddress(address).to_script_pub_key()
    except (ValueError, TypeError):
        pass
    try:
        return P2wpkhAddress(address).to_script_pub_key()
    except (ValueError, TypeError):
        pass
    try:
        return P2pkhAddress(address).to_script_pub_key()
    except ValueError:
        pass
    try:
        return P2shAddress(address).to_script_pub_key()
    except ValueError as e:
        raise exceptions.ComposeError(f"Invalid address: {address}") from e


def is_segwit_address(address):
    if multisig.is_multisig(address):
        return False
    script_pub_key = address_to_script_pub_key(address)
    return is_segwit_output(script_pub_key.to_hex())


def create_tx_output(value, address_or_script, unspent_list, construct_params):
    try:
        # if hex string we assume it is a script
        if all(c in string.hexdigits for c in address_or_script):
            has_segwit = is_segwit_output(address_or_script)
            # check if it is a valid script
            output_script = Script.from_raw(address_or_script, has_segwit=has_segwit)
        else:
            output_script = address_to_script_pub_key(
                address_or_script, unspent_list, construct_params
            )
    except Exception as e:  # pylint: disable=broad-except
        raise exceptions.ComposeError(
            f"Invalid script or address for output: {address_or_script} (error: {e})"
        ) from e

    return TxOutput(value, output_script)


def regular_dust_size(construct_params):
    if construct_params.get("regular_dust_size") is not None:
        if construct_params["regular_dust_size"] < 0:
            raise exceptions.ComposeError("Invalid regular_dust_size: must be non-negative")
        return construct_params["regular_dust_size"]
    return config.DEFAULT_REGULAR_DUST_SIZE


def multisig_dust_size(construct_params):
    if construct_params.get("multisig_dust_size") is not None:
        if construct_params["multisig_dust_size"] < 0:
            raise exceptions.ComposeError("Invalid multisig_dust_size: must be non-negative")
        return construct_params["multisig_dust_size"]
    return config.DEFAULT_MULTISIG_DUST_SIZE


def segwit_dust_size(construct_params):
    if construct_params.get("segwit_dust_size") is not None:
        return construct_params["segwit_dust_size"]
    return config.DEFAULT_SEGWIT_DUST_SIZE


def dust_size(address, construct_params):
    if multisig.is_multisig(address):
        return multisig_dust_size(construct_params)
    if is_segwit_address(address):
        return segwit_dust_size(construct_params)
    return regular_dust_size(construct_params)


def perpare_non_data_outputs(destinations, unspent_list, construct_params):
    outputs = []
    for dest_address, value in destinations:
        output_value = value or dust_size(dest_address, construct_params)
        outputs.append(create_tx_output(output_value, dest_address, unspent_list, construct_params))
    return outputs


def determine_encoding(source, data, destinations, construct_params):
    desired_encoding = construct_params.get("encoding", "auto")
    if desired_encoding == "auto":
        if len(data) + len(config.PREFIX) <= config.OP_RETURN_MAX_SIZE:
            encoding = "opreturn"
        else:
            encoding = "multisig"
    else:
        encoding = desired_encoding
    if encoding == "taproot":
        if ":" in source:
            raise exceptions.ComposeError("Cannot use `taproot` encoding for UTXO transactions")
        if not is_segwit_address(source):
            raise exceptions.ComposeError("Cannot use `taproot` encoding for non-segwit address")
        if len(destinations) > 0:
            raise exceptions.ComposeError(
                "Cannot use `taproot` encoding for transactions with destinations"
            )
        message_type_id, _message = messagetype.unpack(data)
        if message_type_id == messages.detach.ID:
            raise exceptions.ComposeError("Cannot use `taproot` encoding for `detach` transaction")
    if encoding not in ("multisig", "opreturn", "taproot"):
        raise exceptions.ComposeError(f"Not supported encoding: {encoding}")

    return encoding


def encrypt_data(data, arc4_key):
    key = binascii.unhexlify(arc4_key)
    return ARC4(key).encrypt(data)


def prepare_opreturn_output(data, arc4_key):
    if len(data) + len(config.PREFIX) > config.OP_RETURN_MAX_SIZE:
        raise exceptions.ComposeError("One `OP_RETURN` output per transaction")
    opreturn_data = config.PREFIX + data
    opreturn_data = encrypt_data(opreturn_data, arc4_key)
    return [TxOutput(0, Script(["OP_RETURN", b_to_h(opreturn_data)]))]


def is_valid_pubkey(pubkey):
    try:
        PublicKey.from_hex(pubkey).get_address(compressed=True).to_string()
        return True
    except Exception:  # pylint: disable=broad-exception-caught
        return False


def search_pubkey(source, unspent_list, construct_params):
    # search in provided pubkeys
    if construct_params is not None:
        pubkeys = construct_params.get("pubkeys")
        if pubkeys is not None:
            pubkeys = pubkeys.split(",")
        else:
            pubkeys = []
        if len(pubkeys) > 0:
            for pubkey in pubkeys:
                if PublicKey.from_hex(pubkey).get_address(compressed=True).to_string() == source:
                    return pubkey
    # then search with Bitcoin Core or Electrs
    tx_hashes = [utxo["txid"] for utxo in unspent_list]
    return backend.search_pubkey(source, tx_hashes)


def make_valid_pubkey(pubkey_start):
    """Take a too short data pubkey and make it look like a real pubkey.

    Take an obfuscated chunk of data that is two bytes too short to be a pubkey and
    add a sign byte to its beginning and a nonce byte to its end. Choose these
    bytes so that the resulting sequence of bytes is a fully valid pubkey (i.e. on
    the ECDSA curve). Find the correct bytes by guessing randomly until the check
    passes. (In parsing, these two bytes are ignored.)
    """
    assert isinstance(pubkey_start, bytes)  # noqa: E721
    assert len(pubkey_start) == 31  # One sign byte and one nonce byte required (for 33 bytes).

    random_bytes = hashlib.sha256(
        pubkey_start
    ).digest()  # Deterministically generated, for unit tests.
    sign = (random_bytes[0] & 0b1) + 2  # 0x02 or 0x03
    nonce = initial_nonce = random_bytes[1]

    pubkey = b""
    while not is_valid_pubkey(binascii.hexlify(pubkey).decode("utf-8")):
        # Increment nonce.
        nonce += 1
        assert nonce != initial_nonce

        # Construct a possibly fully valid public key.
        pubkey = bytes([sign]) + pubkey_start + bytes([nonce % 256])

    assert len(pubkey) == 33
    return pubkey


def data_to_pubkey_pairs(data, arc4_key):
    # Two pubkeys, minus length byte, minus prefix, minus two nonces,
    # minus two sign bytes.
    chunk_size = (33 * 2) - 1 - len(config.PREFIX) - 2 - 2
    data_array = helpers.chunkify(data, chunk_size)
    pubkey_pairs = []
    for data_part in data_array:
        # Get data (fake) public key.
        data_chunk = config.PREFIX + data_part
        pad_length = (33 * 2) - 1 - 2 - 2 - len(data_chunk)
        assert pad_length >= 0
        output_data = bytes([len(data_chunk)]) + data_chunk + (pad_length * b"\x00")  # noqa: PLW2901
        output_data = encrypt_data(output_data, arc4_key)
        data_pubkey_1 = make_valid_pubkey(output_data[:31])
        data_pubkey_2 = make_valid_pubkey(output_data[31:])
        pubkey_pairs.append((b_to_h(data_pubkey_1), b_to_h(data_pubkey_2)))
    return pubkey_pairs


def get_source_pubkey(source, unspent_list, construct_params):
    # determine multisig pubkey
    multisig_pubkey = construct_params.get("multisig_pubkey")
    if multisig_pubkey is None:
        multisig_pubkey = search_pubkey(source, unspent_list, construct_params)
    if multisig_pubkey is None:
        raise exceptions.ComposeError(
            f"Pubkey not found for {source}, please provide it with the `multisig_pubkey` parameter"
        )
    if not is_valid_pubkey(multisig_pubkey):
        raise exceptions.ComposeError(f"Invalid multisig pubkey: {multisig_pubkey}")
    return multisig_pubkey


def prepare_multisig_output(source, data, arc4_key, unspent_list, construct_params):
    multisig_pubkey = get_source_pubkey(source, unspent_list, construct_params)
    # generate pubkey pairs from data
    pubkey_pairs = data_to_pubkey_pairs(data, arc4_key)
    outputs = []
    for pubkey_pair in pubkey_pairs:
        output_script = Script(
            [1, pubkey_pair[0], pubkey_pair[1], multisig_pubkey, 3, "OP_CHECKMULTISIG"]
        )
        outputs.append(TxOutput(multisig_dust_size(construct_params), output_script))
    return outputs


def string_to_hex(value):
    """Convert a string to hex representation."""
    return binascii.hexlify(value.encode("utf-8")).decode("utf-8")


def generate_raw_reveal_tx(commit_txid, commit_vout, outputs):
    tx_in = TxInput(commit_txid, commit_vout)
    reveal_tx = Transaction([tx_in], outputs)
    return reveal_tx.serialize()


def is_ordinal_envelope_script(envelope_script):
    return envelope_script.script[2] == string_to_hex("ord")


def utxo_to_address(db, utxo):
    # first try with the database (the ledger DB). ``utxo`` is stored as the
    # compact ``(utxo_tx_hash BLOB, utxo_vout)`` pair; split the string to
    # filter. ``utxo_address`` is the ``address_id`` FK, decoded back to the
    # address string by the rowtracer.
    utxo_tx_hash, utxo_vout = database.split_utxo(utxo)
    sql = "SELECT utxo_address FROM balances WHERE utxo_tx_hash = ? AND utxo_vout = ? LIMIT 1"
    balance = db.execute(sql, (utxo_tx_hash, utxo_vout)).fetchone()
    if balance:
        return balance["utxo_address"]
    # then try with Bitcoin Core
    txid, vout = utxo.split(":")
    try:
        tx = backend.bitcoind.getrawtransaction(txid, verbose=True)
        vout = int(vout)
        address = tx["vout"][vout]["scriptPubKey"]["address"]
        return address
    except Exception as e:  # pylint: disable=broad-except
        raise exceptions.ComposeError(
            f"invalid UTXOs: {utxo} (not found in the database or Bitcoin Core)"
        ) from e


def get_change_address(db, source, construct_params):
    change_address = construct_params.get("change_address")
    if change_address is None:
        if utxosinfo.is_utxo_format(source):
            change_address = utxo_to_address(db, source)
        else:
            change_address = source
    return change_address


def get_reveal_outputs(db, source, envelope_script, unspent_list, construct_params):
    tx_out = TxOutput(0, Script(["OP_RETURN", binascii.hexlify(config.PREFIX).decode("ascii")]))
    outputs = [tx_out]
    if is_ordinal_envelope_script(envelope_script):
        change_address = get_change_address(db, source, construct_params)
        change_amount = regular_dust_size(construct_params)
        outputs.append(
            create_tx_output(change_amount, change_address, unspent_list, construct_params)
        )
    return outputs


def get_reveal_control_block(source_pubkey, envelope_script):
    """Control block of the single-leaf commit `P2TR(source_pubkey, [envelope])`."""
    commit_address = source_pubkey.get_taproot_address([[envelope_script]])
    return ControlBlock(
        source_pubkey,
        scripts=[envelope_script],
        index=0,
        is_odd=commit_address.is_odd(),
    )


def get_reveal_transaction_vsize(outputs, envelope_script, source_pubkey):
    """Virtual size of the reveal transaction once the wallet has signed it.

    The witness is `<signature> <envelope> <control block>`. The signature is
    counted as 65 bytes (SIGHASH_ALL spelled out) rather than the 64 of
    SIGHASH_DEFAULT: the reveal fee is paid out of the commit output and cannot
    be raised afterwards, so the estimate errs on the side of the wallet.
    """
    reveal_tx = Transaction([TxInput("F" * 64, 0)], outputs)
    reveal_tx.has_segwit = True
    control_block = get_reveal_control_block(source_pubkey, envelope_script)
    reveal_tx.witnesses.append(
        TxWitnessInput(["00" * 65, envelope_script.to_hex(), control_block.to_hex()])
    )
    return reveal_tx.get_vsize()


def _pubkey_from_hex(pubkey_hex):
    """bitcoinutils `PublicKey` for a compressed, uncompressed or x-only hex key,
    or None when it is not a valid key. An x-only key is lifted with even parity;
    every caller only ever uses its x coordinate."""
    if not isinstance(pubkey_hex, str):
        return None
    if len(pubkey_hex) == 64:
        pubkey_hex = "02" + pubkey_hex
    if not is_valid_pubkey(pubkey_hex):
        return None
    return PublicKey.from_hex(pubkey_hex)


def xonly_matches_script_pub_key(xonly_hex, script_pub_key):
    """Whether the x-only key `xonly_hex` is a key of the P2WPKH or P2TR output
    `script_pub_key` (hex), i.e. a key the parser accepts in the envelope of a
    reveal from that address (`counterparty-rs/src/reveal.rs`): for P2WPKH the
    key hashing to the program (either parity), for P2TR the BIP86 internal key
    or the output key itself."""
    output_type = get_output_type(script_pub_key)
    if output_type == "P2WPKH":
        for prefix in ("02", "03"):
            if not is_valid_pubkey(prefix + xonly_hex):
                continue
            candidate = PublicKey.from_hex(prefix + xonly_hex)
            if candidate.get_segwit_address().to_script_pub_key().to_hex() == script_pub_key:
                return True
        return False
    if output_type == "P2TR":
        output_key = b_to_h(script.script_to_asm(script_pub_key)[1])
        if xonly_hex == output_key:
            return True
        pubkey = _pubkey_from_hex(xonly_hex)
        if pubkey is None:
            return False
        return pubkey.get_taproot_address().to_script_pub_key().to_hex() == script_pub_key
    return False


def get_reveal_source_pubkey(source, unspent_list, construct_params):
    """The key the reveal transaction must be signed with: a key of `source`.

    Since `require_reveal_source_signature` an inscription reveal is only parsed
    when the `OP_CHECKSIG` key of its envelope belongs to the source -- that is
    how Bitcoin itself ends up proving the source signed the message -- so the
    wallet signs the reveal with its own key instead of the node signing it with
    a throwaway one (GHSA-q27c-r246-f6qw).

    The key is taken from `multisig_pubkey`, else from a matching entry of
    `pubkeys`, else searched in the source's past transactions. A P2TR source
    with no known key falls back to its output key, which the wallet signs for
    with its tweaked private key.
    """
    script_pub_key = address_to_script_pub_key(source, unspent_list, construct_params).to_hex()
    output_type = get_output_type(script_pub_key)
    if output_type not in ("P2WPKH", "P2TR"):
        raise exceptions.ComposeError("`taproot` encoding requires a P2WPKH or P2TR source address")

    multisig_pubkey = construct_params.get("multisig_pubkey")
    if multisig_pubkey:
        pubkey = _pubkey_from_hex(multisig_pubkey)
        if pubkey is None:
            raise exceptions.ComposeError(f"Invalid multisig pubkey: {multisig_pubkey}")
        if not xonly_matches_script_pub_key(pubkey.to_x_only_hex(), script_pub_key):
            raise exceptions.ComposeError(
                "`multisig_pubkey` is not a key of the source address; "
                "the reveal transaction must be signed by the source"
            )
        return pubkey

    for candidate in (construct_params.get("pubkeys") or "").split(","):
        pubkey = _pubkey_from_hex(candidate)
        if pubkey is not None and xonly_matches_script_pub_key(
            pubkey.to_x_only_hex(), script_pub_key
        ):
            return pubkey

    if output_type == "P2WPKH":
        tx_hashes = [utxo["txid"] for utxo in unspent_list]
        pubkey = _pubkey_from_hex(backend.search_pubkey(source, tx_hashes))
        if pubkey is not None and xonly_matches_script_pub_key(
            pubkey.to_x_only_hex(), script_pub_key
        ):
            return pubkey
        raise exceptions.ComposeError(
            f"Pubkey not found for {source}, please provide it with the `multisig_pubkey` parameter"
        )

    # P2TR: the output key is a key the source can sign with (tweaked private key)
    output_key = b_to_h(script.script_to_asm(script_pub_key)[1])
    pubkey = _pubkey_from_hex(output_key)
    if pubkey is None:
        raise exceptions.ComposeError(f"Invalid taproot output key for {source}")
    return pubkey


def generate_ordinal_envelope_script(message_data, message_type_id, content, source_pubkey):
    mime_type = message_data.pop() or "text/plain"
    # construct metadata
    message_data = [message_type_id] + message_data
    metadata = cbor2.dumps(message_data)
    metadata_chunks = helpers.chunkify(metadata, 520)
    metatdata_array = []
    for chunk in metadata_chunks:
        metatdata_array += ["05", binascii.hexlify(chunk).decode("utf-8")]
    # construct content
    content_chunks = helpers.chunkify(content, 520)
    content_array = ["OP_0"]
    content_array += [binascii.hexlify(chunk).decode("utf-8") for chunk in content_chunks]
    # construct script
    script_array = [
        "OP_FALSE",
        "OP_IF",
        string_to_hex("ord"),
        "07",
        string_to_hex("xcp"),
        "01",
        string_to_hex(mime_type),
        *metatdata_array,
        *content_array,
        "OP_ENDIF",
        source_pubkey.to_x_only_hex(),
        "OP_CHECKSIG",
    ]
    return Script(script_array)


def generate_envelope_script(data, source_pubkey, construct_params):
    """Envelope leaf carrying `data`, closed by `<source key> OP_CHECKSIG`.

    `source_pubkey` is the key returned by `get_reveal_source_pubkey()`: the
    reveal is valid only when signed by the source (see that function).
    """
    envelope_script = None

    message_type_id, message = messagetype.unpack(data)
    if message_type_id in [
        messages.fairminter.ID,
        messages.issuance.ID,
        messages.issuance.SUBASSET_ID,
        messages.issuance.LR_ISSUANCE_ID,
        messages.issuance.LR_SUBASSET_ID,
        messages.broadcast.ID,
    ] and construct_params.get("inscription", False):
        message_data = cbor2.loads(message)
        content = message_data.pop()
        if content is not None and isinstance(content, (bytes, str)) and len(content) > 0:
            envelope_script = generate_ordinal_envelope_script(
                message_data, message_type_id, content, source_pubkey
            )

    if envelope_script is None:
        # split the data in chunks of 520 bytes
        datas = helpers.chunkify(data, 520)
        datas = [binascii.hexlify(chunk).decode("utf-8") for chunk in datas]
        # Build inscription envelope script
        envelope_script = Script(
            ["OP_FALSE", "OP_IF", *datas, "OP_ENDIF", source_pubkey.to_x_only_hex(), "OP_CHECKSIG"]
        )

    return envelope_script


def prepare_taproot_output(db, source, data, unspent_list, construct_params):
    # the reveal must be signed by the source: its key closes the envelope
    source_pubkey = get_reveal_source_pubkey(source, unspent_list, construct_params)
    envelope_script = generate_envelope_script(data, source_pubkey, construct_params)
    # generate the reveal outputs
    outputs = get_reveal_outputs(db, source, envelope_script, unspent_list, construct_params)
    # get output values and tx size
    outputs_value = sum(output.amount for output in outputs)
    # commit value must pay fees for the reveal tx
    reveal_tx_vsize = get_reveal_transaction_vsize(outputs, envelope_script, source_pubkey)
    reveal_tx_fees = math.ceil(reveal_tx_vsize * get_sat_per_vbyte(construct_params))
    commit_value = reveal_tx_fees + outputs_value
    commit_value = max(commit_value, config.DEFAULT_SEGWIT_DUST_SIZE)
    # build output: a single-leaf taproot tree with the source key as internal key
    commit_address = source_pubkey.get_taproot_address([[envelope_script]])
    tx_out = TxOutput(commit_value, commit_address.to_script_pub_key())
    return [tx_out], (outputs, envelope_script, source_pubkey)


def prepare_data_outputs(db, source, destinations, data, unspent_list, construct_params):
    encoding = determine_encoding(source, data, destinations, construct_params)
    arc4_key = unspent_list[0]["txid"]
    reveal_tx_info = None
    outputs = []
    if encoding == "multisig":
        outputs = prepare_multisig_output(source, data, arc4_key, unspent_list, construct_params)
    if encoding == "opreturn":
        outputs = prepare_opreturn_output(data, arc4_key)
    if encoding == "taproot":
        outputs, reveal_tx_info = prepare_taproot_output(
            db, source, data, unspent_list, construct_params
        )
    return outputs, reveal_tx_info


def prepare_more_outputs(more_outputs, unspent_list, construct_params):
    output_list = [output.split(":") for output in more_outputs.split(",")]
    outputs = []
    for output in output_list:
        if len(output) != 2:
            raise exceptions.ComposeError(f"Invalid output format: {':'.join(output)}")
        value, address_or_script = output
        # check value
        try:
            value = int(value)
        except ValueError as e:
            raise exceptions.ComposeError(f"Invalid value for output: {':'.join(output)}") from e
        if value < 0 or value > MAX_BTC_OUTPUT_VALUE:
            raise exceptions.ComposeError(f"Invalid value for output: {':'.join(output)}")
        # create output
        tx_output = create_tx_output(value, address_or_script, unspent_list, construct_params)
        outputs.append(tx_output)
    return outputs


def prepare_outputs(db, source, destinations, data, unspent_list, construct_params):
    # prepare non-data outputs
    outputs = perpare_non_data_outputs(destinations, unspent_list, construct_params)
    # prepare data outputs
    reveal_tx_info = None
    if data:
        data_outputs, reveal_tx_info = prepare_data_outputs(
            db, source, destinations, data, unspent_list, construct_params
        )
        outputs += data_outputs
    # Add more outputs if needed
    more_outputs = construct_params.get("more_outputs")
    if more_outputs:
        outputs += prepare_more_outputs(more_outputs, unspent_list, construct_params)
    return outputs, reveal_tx_info


################
#   Inputs     #
################


class UTXOLocks(metaclass=helpers.SingletonMeta):
    # Singleton state is shared across threads in a single gunicorn worker;
    # without this lock, two concurrent compose_transaction calls between
    # filter_unspent_list and lock_inputs can both pick the same UTXO,
    # producing an unsignable second tx the network rejects (UX bug). The
    # lock does NOT cross processes -- multi-worker deployments still need
    # a shared store (file/DB/redis) for cross-worker safety.
    def __init__(self):
        self.max_age = None
        self.max_size = None
        self._mutex = threading.Lock()
        self.init()

    def init(self):
        self.locks = OrderedDict()
        self.set_limits(config.UTXO_LOCKS_MAX_AGE, config.UTXO_LOCKS_MAX_ADDRESSES)

    def set_limits(self, max_age, max_size):
        self.max_age = max_age
        self.max_size = max_size

    def lock(self, utxo):
        with self._mutex:
            self.locks[utxo] = time.time()
            if len(self.locks) > self.max_size:
                self.locks.popitem(last=False)

    def locked(self, utxo):
        with self._mutex:
            return self._locked_unchecked(utxo)

    def _locked_unchecked(self, utxo, now=None):
        if utxo not in self.locks:
            return False
        if (now or time.time()) - self.locks[utxo] > self.max_age:
            del self.locks[utxo]
            return False
        return True

    def filter_unspent_list(self, unspent_list):
        return [utxo for utxo in unspent_list if not self.locked(f"{utxo['txid']}:{utxo['vout']}")]

    def lock_inputs(self, inputs):
        for tx_input in inputs:
            self.lock(f"{tx_input.txid}:{tx_input.txout_index}")

    @staticmethod
    def _input_ids(inputs):
        return [f"{tx_input.txid}:{tx_input.txout_index}" for tx_input in inputs]

    def reserve_inputs(self, inputs):
        """Atomically reserve inputs if none is currently reserved.

        Returns an opaque reservation mapping on success and ``None`` when a
        concurrent compose won the race. The timestamp token lets a failed
        validator release only its own reservation.
        """
        input_ids = self._input_ids(inputs)
        with self._mutex:
            now = time.time()
            if any(self._locked_unchecked(utxo, now=now) for utxo in input_ids):
                return None
            reservation = {utxo: now for utxo in input_ids}
            self.locks.update(reservation)
            while len(self.locks) > self.max_size:
                self.locks.popitem(last=False)
            return reservation

    def release_reservation(self, reservation):
        if reservation is None:
            return
        with self._mutex:
            for utxo, token in reservation.items():
                if self.locks.get(utxo) == token:
                    del self.locks[utxo]

    def replace_reservation(self, reservation, inputs):
        """Atomically replace this request's reservation after a recompose."""
        new_input_ids = self._input_ids(inputs)
        old_input_ids = set(reservation or {})
        with self._mutex:
            now = time.time()
            for utxo in new_input_ids:
                if utxo in old_input_ids and self.locks.get(utxo) == reservation[utxo]:
                    continue
                if self._locked_unchecked(utxo, now=now):
                    return None
            for utxo, token in (reservation or {}).items():
                if utxo not in new_input_ids and self.locks.get(utxo) == token:
                    del self.locks[utxo]
            new_reservation = {utxo: now for utxo in new_input_ids}
            self.locks.update(new_reservation)
            while len(self.locks) > self.max_size:
                self.locks.popitem(last=False)
            return new_reservation


def complete_unspent_list(unspent_list):
    # gather tx hashes with missing data
    txhash_set = set()
    for utxo in unspent_list:
        if "script_pub_key" not in utxo or "value" not in utxo:
            txhash_set.add(utxo["txid"])

    # get missing data from Bitcoin Core
    if len(txhash_set) > 0:
        txhash_list_chunks = helpers.chunkify(list(txhash_set), config.MAX_RPC_BATCH_SIZE)
        txs = {}
        for txhash_list in txhash_list_chunks:
            txs = txs | backend.bitcoind.getrawtransaction_batch(
                txhash_list, verbose=True, return_dict=True
            )

    # complete unspent list with missing data
    completed_unspent_list = []
    for utxo in unspent_list:
        if "script_pub_key" not in utxo or "value" not in utxo:
            txid = utxo["txid"]
            if txid not in txs:
                raise exceptions.ComposeError(
                    f"invalid UTXOs: {txid}:{utxo['vout']} (transaction not found)"
                )
            for vout in txs[txid]["vout"]:
                if vout["n"] == utxo["vout"]:
                    if "script_pub_key" not in utxo:
                        utxo["script_pub_key"] = vout["scriptPubKey"]["hex"]
                    if "value" not in utxo:
                        utxo["value"] = int(D(str(vout["value"])) * D(config.UNIT))
                        utxo["amount"] = vout["value"]
        if "script_pub_key" not in utxo:
            raise exceptions.ComposeError(
                f"invalid UTXOs: {utxo['txid']}:{utxo['vout']}: script_pub_key not found, you can provide it with the `inputs_set` parameter, using <txid>:<vout>:<value>:<script_pub_key> format"
            )
        utxo["is_segwit"] = is_segwit_output(utxo["script_pub_key"])
        completed_unspent_list.append(utxo)
    return completed_unspent_list


def prepare_inputs_set(inputs_set):
    unspent_list = []
    utxos_list = inputs_set.split(",")
    seen_utxos = set()
    if len(utxos_list) > MAX_INPUTS_SET:
        raise exceptions.ComposeError(
            f"too many UTXOs in inputs_set (max. {MAX_INPUTS_SET}): {len(utxos_list)}"
        )
    for utxo in utxos_list:
        utxo_parts = utxo.split(":")

        if len(utxo_parts) == 2:
            txid, vout = utxo.split(":")
            value, script_pub_key = None, None
        elif len(utxo_parts) == 3:
            txid, vout, value = utxo.split(":")
            script_pub_key = None
        elif len(utxo_parts) == 4:
            txid, vout, value, script_pub_key = utxo.split(":")
        else:
            raise exceptions.ComposeError(f"invalid UTXOs: {utxo} (invalid format)")

        if not utxosinfo.is_utxo_format(f"{txid}:{vout}"):
            raise exceptions.ComposeError(f"invalid UTXOs: {utxo} (invalid format)")
        utxo_id = f"{txid}:{vout}"
        if utxo_id in seen_utxos:
            raise exceptions.ComposeError(f"invalid UTXOs: {utxo} (duplicate UTXO)")
        seen_utxos.add(utxo_id)

        unspent = {
            "txid": txid,
            "vout": int(vout),
        }

        if value is not None:
            try:
                unspent["value"] = int(value)
            except ValueError as e:
                raise exceptions.ComposeError(f"invalid UTXOs: {utxo} (invalid value)") from e
            if unspent["value"] < 0 or unspent["value"] > MAX_BTC_OUTPUT_VALUE:
                raise exceptions.ComposeError(f"invalid UTXOs: {utxo} (invalid value)")

        if script_pub_key is not None:
            try:
                script.script_to_asm(script_pub_key)
            except Exception as e:  # pylint: disable=broad-except
                raise exceptions.ComposeError(
                    f"invalid UTXOs: {utxo} (invalid script_pub_key)"
                ) from e
            unspent["script_pub_key"] = script_pub_key

        unspent_list.append(unspent)

    return unspent_list


def ensure_utxo_is_first(utxo, unspent_list):
    txid, vout = utxo.split(":")
    vout = int(vout)
    new_unspent_list = []
    for unspent in unspent_list:
        if unspent["txid"] == txid and unspent["vout"] == vout:
            new_unspent_list.insert(0, unspent)
        else:
            new_unspent_list.append(unspent)

    first_utxo = new_unspent_list[0]
    if first_utxo["txid"] != txid or first_utxo["vout"] != vout:
        try:
            value = backend.bitcoind.get_utxo_value(txid, vout)
        except Exception as e:  # pylint: disable=broad-except
            raise exceptions.ComposeError(f"invalid UTXOs: {utxo} (value not found)") from e
        new_unspent_list.insert(
            0,
            {
                "txid": txid,
                "vout": vout,
                "value": int(D(str(value)) * D(config.UNIT)),
                "amount": value,
            },
        )
    return new_unspent_list


def filter_utxos_with_balances(db, source, unspent_list, construct_params):
    use_utxos_with_balances = construct_params.get("use_utxos_with_balances", False)
    if use_utxos_with_balances:
        return unspent_list

    exclude_utxos_with_balances = construct_params.get("exclude_utxos_with_balances", False)
    new_unspent_list = []
    with_balance_utxos = []
    for utxo in unspent_list:
        str_input = f"{utxo['txid']}:{utxo['vout']}"
        if str_input == source:
            new_unspent_list.append(utxo)
            continue
        utxo_balances = ledger.balances.get_utxo_balances(db, str_input)
        with_balances = len(utxo_balances) > 0 and any(
            balance["quantity"] > 0 for balance in utxo_balances
        )
        if exclude_utxos_with_balances and with_balances:
            continue
        if with_balances:
            with_balance_utxos.append(str_input)
            continue
        new_unspent_list.append(utxo)
    if len(with_balance_utxos) > 0:
        raise exceptions.ComposeError(
            f"invalid UTXOs: {', '.join(with_balance_utxos)} (use `use_utxos_with_balances=True` to include them or `exclude_utxos_with_balances=True` to exclude them silently)"
        )
    return new_unspent_list


def prepare_unspent_list(db, source, construct_params):
    inputs_set = construct_params.get("inputs_set")

    if inputs_set is None:
        # get unspent list from Bitcoin Core or Electrs
        allow_unconfirmed_inputs = construct_params.get("allow_unconfirmed_inputs", False)
        if utxosinfo.is_utxo_format(source):
            source_address = utxo_to_address(db, source)
        else:
            source_address = source
        unspent_list = backend.list_unspent(source_address, allow_unconfirmed_inputs)
        # exclude silentely utxos with balances
        unspent_list = filter_utxos_with_balances(
            db, source, unspent_list, construct_params | {"exclude_utxos_with_balances": True}
        )
    else:
        # prepare unspent list provided by the user
        unspent_list = prepare_inputs_set(inputs_set)

    # exclude utxos if explicitly requested
    exclude_utxos = construct_params.get("exclude_utxos")
    if exclude_utxos is not None:
        exclude_utxos_list = exclude_utxos.split(",")
        # support both txid and txid:vout formats
        exclude_txids = [item for item in exclude_utxos_list if ":" not in item]
        exclude_utxo_ids = [item for item in exclude_utxos_list if ":" in item]
        unspent_list = [
            utxo
            for utxo in unspent_list
            if utxo["txid"] not in exclude_txids
            and f"{utxo['txid']}:{utxo['vout']}" not in exclude_utxo_ids
        ]

    # include only tx_hash if explicitly requested
    unspent_tx_hash = construct_params.get("unspent_tx_hash")  # legacy
    if unspent_tx_hash is not None:
        unspent_list = [utxo for utxo in unspent_list if utxo["txid"] == unspent_tx_hash]

    # excluded locked utxos
    if not construct_params.get("disable_utxo_locks", False):
        unspent_list = UTXOLocks().filter_unspent_list(unspent_list)

    # exclude utxos with balances if needed
    unspent_list = filter_utxos_with_balances(db, source, unspent_list, construct_params)

    if len(unspent_list) == 0:
        raise exceptions.ComposeError(
            f"No UTXOs found for {source}, provide UTXOs with the `inputs_set` parameter"
        )

    # complete unspent list with missing data (value or script_pub_key)
    # so we can sort it by value
    unspent_list = complete_unspent_list(unspent_list)

    # sort unspent list by value
    unspent_list = sorted(unspent_list, key=lambda x: x["value"], reverse=True)

    # if source is an utxo, ensure it is first in the unspent list
    if utxosinfo.is_utxo_format(source):
        unspent_list = ensure_utxo_is_first(source, unspent_list)
        # complete unspent list again with missing data
        unspent_list = complete_unspent_list(unspent_list)

    return unspent_list


def utxos_to_txins(utxos: list):
    inputs = []
    for utxo in utxos:
        tx_input = TxInput(utxo["txid"], utxo["vout"])
        inputs.append(tx_input)
    return inputs


###################
#   Composition   #
##################

OP_0 = "00"
OP_PUSHBYTES_33 = "21"
OP_PUSHBYTES_72 = "48"
OP_PUSHBYTES_73 = "49"

DUMMY_DER_SIG = "3045" + "00" * 69 + "01"
DUMMY_REEDEM_SCRIPT = OP_PUSHBYTES_72 + DUMMY_DER_SIG
DUMMY_PUBKEY = "03" + 32 * "00"
DUMMY_SCHNORR_SIG = "00" * 64 + "01"


# dummies script_sig from https://learnmeabitcoin.com/technical/script/
def get_dummy_script_sig(script_pub_key):
    output_type = get_output_type(script_pub_key)
    script_sig = None
    if output_type == "P2PK":
        script_sig = OP_PUSHBYTES_72 + DUMMY_DER_SIG
    elif output_type == "P2PKH":
        script_sig = OP_PUSHBYTES_72 + DUMMY_DER_SIG + OP_PUSHBYTES_33 + DUMMY_PUBKEY
    elif output_type == "P2MS":
        asm = script.script_to_asm(script_pub_key)
        required_signatures = asm[0]
        script_sig = OP_0 + (required_signatures * (OP_PUSHBYTES_72 + DUMMY_DER_SIG))
    elif output_type == "P2SH":
        script_sig = OP_0 + OP_PUSHBYTES_72 + DUMMY_DER_SIG + OP_PUSHBYTES_73 + DUMMY_REEDEM_SCRIPT
    if script_sig is not None:
        return Script.from_raw(script_sig)
    return None


def get_dummy_witness(script_pub_key):
    output_type = get_output_type(script_pub_key)
    witness = None
    if output_type == "P2WPKH":
        witness = [DUMMY_DER_SIG, DUMMY_PUBKEY]
    elif output_type == "P2WSH":
        witness = [
            OP_PUSHBYTES_72 + DUMMY_DER_SIG + OP_PUSHBYTES_33 + DUMMY_PUBKEY,  # P2PKH unlock script
            script_pub_key,
        ]
    elif output_type == "P2TR":
        witness = [DUMMY_SCHNORR_SIG]
    if witness is not None:
        return TxWitnessInput(witness)
    return None


def generate_dummy_signed_tx(tx, selected_utxos):
    dummy_signed_tx = Transaction.copy(tx)
    for i, utxo in enumerate(selected_utxos):
        dummy_script_sig = get_dummy_script_sig(utxo["script_pub_key"])
        if dummy_script_sig is not None:
            dummy_signed_tx.inputs[i].script_sig = dummy_script_sig
        dummy_witness = get_dummy_witness(utxo["script_pub_key"])
        if dummy_witness is not None:
            dummy_signed_tx.witnesses.append(dummy_witness)
            dummy_signed_tx.has_segwit = True
    return dummy_signed_tx


def get_output_sigops_count(script_pub_key, is_redeem_script=False, is_segwit=False):
    output_type = get_output_type(script_pub_key)
    multiplicator = 1 if is_segwit else 4
    count = 0
    if output_type in ["P2PK", "P2PKH"]:
        count = 1
    elif output_type == "P2MS":
        if is_redeem_script:
            asm = script.script_to_asm(script_pub_key)
            pubkeys_count = int(asm[-2])
            if pubkeys_count > 16:
                count = 20
            else:
                count = pubkeys_count
        else:
            count = 20
    elif output_type in ["P2WPKH", "P2WSH", "P2TR"] and is_redeem_script:
        return 1
    return count * multiplicator


def get_input_sigops_count(script_sig, script_pub_key):
    prevout_type = get_output_type(script_pub_key)
    if prevout_type == "P2SH":
        asm = script.script_to_asm(script_sig)
        redeem_script = binascii.hexlify(asm[-1]).decode("utf-8")
        return get_output_sigops_count(redeem_script, is_redeem_script=True)
    if prevout_type == "P2WPKH":
        return 1
    if prevout_type == "P2WSH":
        return get_output_sigops_count(script_pub_key, is_segwit=True)
    return 0


# source: https://bitcoin.stackexchange.com/questions/67760/how-are-sigops-calculated
def get_tx_sigops_count(tx, selected_utxos):
    sigops_count = 0
    for i, utxo in enumerate(selected_utxos):
        script_pub_key = utxo["script_pub_key"]
        script_sig = tx.inputs[i].script_sig.to_hex()
        sigops_count += get_input_sigops_count(script_sig, script_pub_key)
    for output in tx.outputs:
        sigops_count += get_output_sigops_count(output.script_pubkey.to_hex())
    return sigops_count


# source: https://mempool.space/docs/faq#what-is-adjusted-vsize
def get_size_info(tx, selected_utxos, signed=False):
    if signed:
        signed_tx = tx
    else:
        signed_tx = generate_dummy_signed_tx(tx, selected_utxos)
    sigops_count = get_tx_sigops_count(signed_tx, selected_utxos)
    virtual_size = signed_tx.get_vsize()
    adjusted_vsize = max(sigops_count * 5, virtual_size)
    return adjusted_vsize, virtual_size, sigops_count


def prepare_fee_parameters(construct_params):
    exact_fee = construct_params.get("exact_fee")
    sat_per_vbyte = construct_params.get("sat_per_vbyte")
    confirmation_target = construct_params.get("confirmation_target")
    max_fee = construct_params.get("max_fee")
    if exact_fee is not None and exact_fee < 0:
        raise exceptions.ComposeError("Invalid exact_fee: must be non-negative")
    if sat_per_vbyte is not None and sat_per_vbyte < 0:
        raise exceptions.ComposeError("Invalid sat_per_vbyte: must be non-negative")
    if max_fee is not None and max_fee < 0:
        raise exceptions.ComposeError("Invalid max_fee: must be non-negative")
    if exact_fee is not None:
        sat_per_vbyte, confirmation_target, max_fee = None, None, None
    elif sat_per_vbyte is None:
        if confirmation_target is not None:
            if confirmation_target < 1 or confirmation_target > MAX_CONFIRMATION_TARGET:
                raise exceptions.ComposeError(
                    f"Invalid confirmation_target: must be between 1 and {MAX_CONFIRMATION_TARGET}"
                )
            sat_per_vbyte = backend.bitcoind.satoshis_per_vbyte(confirmation_target)
        else:
            sat_per_vbyte = backend.bitcoind.satoshis_per_vbyte()
    return exact_fee, sat_per_vbyte, max_fee


def get_sat_per_vbyte(construct_params):
    _exact_fee, sat_per_vbyte, _max_fee = prepare_fee_parameters(construct_params)
    if sat_per_vbyte is None:
        confirmation_target = construct_params.get("confirmation_target")
        if confirmation_target is not None:
            sat_per_vbyte = backend.bitcoind.satoshis_per_vbyte(confirmation_target)
        else:
            sat_per_vbyte = backend.bitcoind.satoshis_per_vbyte()
    return sat_per_vbyte


def prepare_inputs_and_change(db, source, outputs, unspent_list, construct_params):
    # prepare fee parameters
    exact_fee, sat_per_vbyte, max_fee = prepare_fee_parameters(construct_params)

    change_address = get_change_address(db, source, construct_params)

    outputs_total = sum(output.amount for output in outputs)

    change_outputs = []
    btc_in = 0
    needed_fee = 0
    size_info = (0, 0, 0)
    # try with one input and increase until the change is enough for the fee
    use_all_inputs_set = construct_params.get("use_all_inputs_set", False)
    input_count = len(unspent_list) if use_all_inputs_set else 1
    while True:
        if input_count > len(unspent_list):
            total_needed = outputs_total + (exact_fee or needed_fee)
            raise exceptions.ComposeError(
                f"Insufficient funds for the target amount: {btc_in} < {total_needed}"
            )

        selected_utxos = unspent_list[:input_count]
        inputs = utxos_to_txins(selected_utxos)
        btc_in = sum(utxo["value"] for utxo in selected_utxos)
        change_amount = int(btc_in - outputs_total)

        # if change is negative, try with more inputs
        if change_amount < 0:
            input_count += 1
            continue
        # if change is not enough for exact_fee, try with more inputs
        if exact_fee is not None and change_amount < exact_fee:
            input_count += 1
            continue

        # if change is enough for exact_fee, add change output and break
        if exact_fee is not None:
            change_amount = int(change_amount - exact_fee)
            if change_amount > dust_size(change_address, construct_params):
                change_outputs.append(
                    create_tx_output(change_amount, change_address, unspent_list, construct_params)
                )
            break

        # else calculate needed fee
        has_segwit = any(utxo["is_segwit"] for utxo in selected_utxos)

        tx = Transaction(
            inputs,
            outputs
            + [create_tx_output(change_amount, change_address, unspent_list, construct_params)],
            has_segwit=has_segwit,
        )

        size_info = get_size_info(tx, selected_utxos)
        adjusted_vsize = size_info[0]
        needed_fee = sat_per_vbyte * adjusted_vsize
        if max_fee is not None:
            needed_fee = min(needed_fee, max_fee)
        needed_fee = math.ceil(needed_fee)

        # if change is enough for needed fee, add change output and break
        if change_amount >= needed_fee:
            change_amount = int(change_amount - needed_fee)
            if change_amount > dust_size(change_address, construct_params):
                change_outputs.append(
                    create_tx_output(change_amount, change_address, unspent_list, construct_params)
                )
            break
        # else try with more inputs
        input_count += 1

    return selected_utxos, btc_in, change_outputs


def get_default_args(func):
    signature = inspect.signature(func)
    return {
        k: v.default
        for k, v in signature.parameters.items()
        if v.default is not inspect.Parameter.empty
    }


def compose_data(db, name, params, accept_missing_params=False, skip_validation=False):
    try:
        compose_method = sys.modules[f"counterpartycore.lib.messages.{name}"].compose
    except KeyError as e:
        raise exceptions.ComposeError(f"message {name} not found") from e
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


# Result fields of a `taproot` encoded transaction, on top of the commit
# `rawtransaction`: the unsigned reveal and what the wallet needs to sign it.
REVEAL_RESULT_KEYS = (
    "reveal_rawtransaction",
    "envelope_script",
    "reveal_control_block",
    "reveal_pubkey",
    "reveal_lock_scripts",
    "reveal_inputs_values",
)


def construct(db, tx_info, construct_params, final_validator=None):
    source, destinations, data = tx_info

    # prepare unspent list
    unspent_list = prepare_unspent_list(db, source, construct_params)

    # prepare outputs
    outputs, reveal_tx_info = prepare_outputs(
        db, source, destinations, data, unspent_list, construct_params
    )

    # prepare inputs and change
    selected_utxos, btc_in, change_outputs = prepare_inputs_and_change(
        db, source, outputs, unspent_list, construct_params
    )
    inputs = utxos_to_txins(selected_utxos)

    locks_enabled = not construct_params.get("disable_utxo_locks", False)
    reservation = None
    if locks_enabled:
        # The filter performed by ``prepare_unspent_list`` is necessarily
        # optimistic. Reserve the final selection with one compare-and-set so
        # two request threads cannot both succeed in the filter->lock gap.
        reservation = UTXOLocks().reserve_inputs(inputs)
        if reservation is None:
            raise exceptions.ComposeError(
                "Selected UTXOs were reserved by another compose request; retry composition"
            )

    try:
        if final_validator is not None:
            refreshed_tx_info = final_validator(tx_info)
            if refreshed_tx_info is not None and refreshed_tx_info != tx_info:
                previous_source = source
                tx_info = refreshed_tx_info
                source, destinations, data = tx_info
                if source != previous_source:
                    unspent_list = prepare_unspent_list(db, source, construct_params)
                outputs, reveal_tx_info = prepare_outputs(
                    db, source, destinations, data, unspent_list, construct_params
                )
                selected_utxos, btc_in, change_outputs = prepare_inputs_and_change(
                    db, source, outputs, unspent_list, construct_params
                )
                inputs = utxos_to_txins(selected_utxos)
            if locks_enabled:
                # Revalidate ownership even when the message bytes did not
                # change: a long validation can outlive the normal lock TTL,
                # allowing another request to reserve the input meanwhile.
                replacement = UTXOLocks().replace_reservation(reservation, inputs)
                if replacement is None:
                    raise exceptions.ComposeError(
                        "Refreshed transaction requires UTXOs reserved by another compose "
                        "request; retry composition"
                    )
                reservation = replacement
    except Exception:
        if locks_enabled:
            UTXOLocks().release_reservation(reservation)
        raise

    # construct transaction
    btc_out = sum(output.amount for output in outputs)
    btc_change = sum(change_output.amount for change_output in change_outputs)
    lock_scripts = [utxo["script_pub_key"] for utxo in selected_utxos]
    inputs_values = [utxo["value"] for utxo in selected_utxos]
    tx = Transaction(inputs, outputs + change_outputs)
    unsigned_tx_hex = tx.serialize()
    adjusted_vsize, virtual_size, sigops_count = get_size_info(tx, selected_utxos)

    result = {
        "rawtransaction": unsigned_tx_hex,
        "btc_in": btc_in,
        "btc_out": btc_out,
        "btc_change": btc_change,
        "btc_fee": btc_in - btc_out - btc_change,
        "data": config.PREFIX + data if data else None,
        "lock_scripts": lock_scripts,
        "inputs_values": inputs_values,
        "signed_tx_estimated_size": {
            "vsize": virtual_size,
            "adjusted_vsize": adjusted_vsize,
            "sigops_count": sigops_count,
        },
    }
    if reveal_tx_info is not None:
        # we need to be sure that the txid will not change after signing
        # in order to be able to generate the reveal tx
        for utxo in selected_utxos:
            if not is_segwit_output(utxo["script_pub_key"]):
                raise exceptions.ComposeError(
                    "Reveal transaction is not supported for legacy inputs"
                )

        # The reveal spends the commit's first output through the envelope leaf
        # and must be signed by the source key that closes the envelope (see
        # `get_reveal_source_pubkey()`), so it is returned unsigned together
        # with everything the wallet needs to add the witness
        # `<signature> <envelope_script> <reveal_control_block>`.
        outputs, envelope_script, source_pubkey = reveal_tx_info
        reveal_tx = Transaction([TxInput(tx.get_txid(), 0)], outputs)
        control_block = get_reveal_control_block(source_pubkey, envelope_script)
        result["reveal_rawtransaction"] = reveal_tx.serialize()
        result["envelope_script"] = envelope_script.to_hex()
        result["reveal_control_block"] = control_block.to_hex()
        result["reveal_pubkey"] = source_pubkey.to_x_only_hex()
        result["reveal_lock_scripts"] = [tx.outputs[0].script_pubkey.to_hex()]
        result["reveal_inputs_values"] = [tx.outputs[0].amount]

    return result, unspent_list


def check_reveal_sanity(source, data, decoded_tx, composed_tx, unspent_list, construct_params):
    """The commit/reveal pair must carry `data` in an envelope closed by a key of
    `source` -- otherwise the reveal is either unsignable by the wallet or, once
    `require_reveal_source_signature` is active, ignored by the network."""
    elements = Script.from_raw(composed_tx["envelope_script"]).script
    if (
        len(elements) < 5
        or elements[-1] != "OP_CHECKSIG"
        or not isinstance(elements[-2], str)
        or len(elements[-2]) != 64
    ):
        raise exceptions.ComposeError("Sanity check error: envelope script does not match the data")
    reveal_pubkey = _pubkey_from_hex(elements[-2])
    if reveal_pubkey is None:
        raise exceptions.ComposeError("Sanity check error: invalid envelope key")

    source_script_pub_key = address_to_script_pub_key(
        source, unspent_list, construct_params
    ).to_hex()
    if not xonly_matches_script_pub_key(reveal_pubkey.to_x_only_hex(), source_script_pub_key):
        raise exceptions.ComposeError(
            "Sanity check error: envelope key does not belong to the source"
        )

    envelope_script = generate_envelope_script(data, reveal_pubkey, construct_params)
    if envelope_script.to_hex() != composed_tx["envelope_script"]:
        raise exceptions.ComposeError("Sanity check error: envelope script does not match the data")

    commit_script_pub_key = (
        reveal_pubkey.get_taproot_address([[envelope_script]]).to_script_pub_key().to_hex()
    )
    if b_to_h(decoded_tx["vout"][0]["script_pub_key"]) != commit_script_pub_key:
        raise exceptions.ComposeError(
            "Sanity check error: commit output does not commit to the envelope"
        )

    reveal_tx = Transaction.from_raw(composed_tx["reveal_rawtransaction"])
    if (
        len(reveal_tx.inputs) != 1
        or reveal_tx.inputs[0].txid != decoded_tx["tx_id"]
        or reveal_tx.inputs[0].txout_index != 0
    ):
        raise exceptions.ComposeError(
            "Sanity check error: reveal transaction does not spend the commit output"
        )


def check_transaction_sanity(tx_info, composed_tx, unspent_list, construct_params):  # pylint: disable=unused-argument
    tx_hex = composed_tx["rawtransaction"]
    source, destinations, data = tx_info
    decoded_tx = deserialize.deserialize_tx(tx_hex, parse_vouts=True)

    total_out = sum(out["value"] for out in decoded_tx["vout"])
    assert total_out == composed_tx["btc_out"] + composed_tx["btc_change"]
    assert composed_tx["btc_in"] == total_out + composed_tx["btc_fee"]
    assert sum(composed_tx["inputs_values"]) == composed_tx["btc_in"]

    # check if source address matches the first input address
    first_utxo_txid = decoded_tx["vin"][0]["hash"]
    first_utxo = f"{first_utxo_txid}:{decoded_tx['vin'][0]['n']}"

    if utxosinfo.is_utxo_format(source):
        source_is_ok = first_utxo == source
    else:
        source_is_ok = is_address_script(source, composed_tx["lock_scripts"][0])

    if not source_is_ok:
        raise exceptions.ComposeError(
            "Sanity check error: source address does not match the first input address"
        )

    # check if destination addresses and values match the outputs
    for i, destination in enumerate(destinations):
        address, value = destination
        out = decoded_tx["vout"][i]

        if not is_address_script(address, out["script_pub_key"]):
            raise exceptions.ComposeError(
                "Sanity check error: destination address does not match the output address"
            )

        value_is_ok = True
        if value is not None:
            if value != out["value"]:
                value_is_ok = False
        elif out["value"] != dust_size(address, construct_params):
            value_is_ok = False

        if not value_is_ok:
            raise exceptions.ComposeError(
                "Sanity check error: destination value does not match the output value"
            )

    # check if data matches the output data
    if data:
        if "reveal_rawtransaction" in composed_tx:
            check_reveal_sanity(
                source, data, decoded_tx, composed_tx, unspent_list, construct_params
            )
        else:
            if isinstance(decoded_tx["parsed_vouts"], Exception):
                raise exceptions.ComposeError(
                    f"Sanity check error: cannot parse the output data from the transaction ({decoded_tx['parsed_vouts']})"
                )
            _, _, _, tx_data, _, _ = decoded_tx["parsed_vouts"]
            if tx_data != data:
                raise exceptions.ComposeError(
                    "Sanity check error: data does not match the output data"
                )


CONSTRUCT_PARAMS = {
    # general parameters
    "encoding": (str, "auto", "The encoding method to use"),
    "validate": (bool, True, "Validate the transaction"),
    # fee parameters
    "sat_per_vbyte": (float, None, "The fee per vbyte in satoshis"),
    "confirmation_target": (
        int,
        config.ESTIMATE_FEE_CONF_TARGET,
        "The number of blocks to target for confirmation",
    ),
    "exact_fee": (int, None, "The exact fee to use in satoshis"),
    "max_fee": (int, None, "The maximum fee to use in satoshis"),
    # inputs parameters
    "inputs_set": (
        str,
        None,
        "A comma-separated list of UTXOs (`<txid>:<vout>`) to use as inputs for the transaction being created. To speed up the composition you can also use the following format for utxos: `<txid>:<vout>:<value>:<script_pub_key>`.",
    ),
    "custom_inputs": (str, None, "Deprecated, use `inputs_set` instead"),
    "allow_unconfirmed_inputs": (
        bool,
        False,
        "Set to true to allow this transaction to utilize unconfirmed UTXOs as inputs",
    ),
    "exclude_utxos": (
        str,
        None,
        "A comma-separated list of UTXOs to exclude when selecting inputs for the transaction. Supports two formats: `<txid>` to exclude all UTXOs from a transaction, or `<txid>:<vout>` to exclude a specific UTXO",
    ),
    "use_utxos_with_balances": (bool, False, "Use UTXO with balances"),
    "exclude_utxos_with_balances": (
        bool,
        False,
        "Exclude silently UTXO with balances instead of raising an exception. Important: the `exclude_utxos_with_balances` will not exclude unconfirmed `attach` and `utxomove`. You need to explicitly exclude them with the `exclude_utxos` parameter",
    ),
    "disable_utxo_locks": (
        bool,
        False,
        "By default, UTXOs utilized when creating a transaction are 'locked' for a few seconds, to prevent a case where rapidly generating create_ calls reuse UTXOs due to their spent status not being updated in bitcoind yet. Specify true for this parameter to disable this behavior, and not temporarily lock UTXOs",
    ),
    "use_all_inputs_set": (bool, False, "Use all UTXOs provide with `inputs_set` parameter"),
    # outputs parameters
    "multisig_pubkey": (
        str,
        None,
        "The public key of the source address. Used as the redeem key of `multisig` encoding and as the key a `taproot` reveal transaction must be signed with; by default it is searched for the source address (a P2TR source falls back to its output key)",
    ),
    "change_address": (str, None, "The address to send the change to"),
    "more_outputs": (
        str,
        None,
        "Additional outputs to include in the transaction in the format `<value>:<address>` or `<value>:<script>`",
    ),
    "pubkeys": (
        str,
        None,
        "Pubkeys needed in case one or more destinations are multisig addresses",
    ),
    # result parameters
    "verbose": (
        bool,
        False,
        "Include additional information in the result including data and psbt",
    ),
    "return_only_data": (bool, False, "Return only the data part of the transaction"),
    "message_only": (bool, False, "Alias for `return_only_data`"),
    "segwit_dust_size": (int, None, "The dust size for segwit outputs (default is 330)"),
    "inscription": (bool, False, "Use Ordinals inscription script when possible"),
    # deprecated parameters
    "fee_per_kb": (int, None, "Deprecated, use `sat_per_vbyte` instead"),
    "fee_provided": (int, None, "Deprecated, use `max_fee` instead"),
    "unspent_tx_hash": (str, None, "Deprecated, use `inputs_set` instead"),
    "dust_return_pubkey": (str, None, "Deprecated, use `multisig_pubkey` instead"),
    "return_psbt": (bool, False, "Deprecated, use `verbose` instead"),
    "regular_dust_size": (int, None, "Deprecated, automatically calculated"),
    "multisig_dust_size": (int, None, "Deprecated, automatically calculated"),
    "extended_tx_info": (bool, False, "Deprecated (API v1 only), use API v2 instead"),
    "old_style_api": (bool, False, "Deprecated (API v1 only), use API v2 instead"),
    "p2sh_pretx_txid": (str, None, "Ignored, P2SH disabled"),
    "segwit": (bool, False, "Ignored, Segwit automatically detected"),
}
DEPRECATED_CONSTRUCT_PARAMS = [
    "fee_per_kb",
    "fee_provided",
    "dust_return_pubkey",
    "return_psbt",
    "regular_dust_size",
    "multisig_dust_size",
    "extended_tx_info",
    "old_style_api",
    "p2sh_pretx_txid",
    "segwit",
    "unspent_tx_hash",
    "custom_inputs",
]


def fee_per_kb_to_sat_per_vbyte(fee_per_kb):
    if fee_per_kb is None or fee_per_kb == 0:
        return 0
    return float(D(fee_per_kb) / D(1024))


def prepare_construct_params(construct_params):
    cleaned_construct_params = construct_params.copy()
    if "message_only" in construct_params:
        if construct_params.get("message_only") and not construct_params.get("return_only_data"):
            cleaned_construct_params["return_only_data"] = construct_params["message_only"]
        cleaned_construct_params.pop("message_only")

    # copy deprecated parameters to new ones
    for deprecated_param, new_param, copyer in [
        ("fee_per_kb", "sat_per_vbyte", fee_per_kb_to_sat_per_vbyte),
        ("fee_provided", "max_fee", lambda x: x),
        ("dust_return_pubkey", "multisig_pubkey", lambda x: x),
        ("return_psbt", "verbose", lambda x: x),
        ("custom_inputs", "inputs_set", lambda x: x),
    ]:
        if deprecated_param in construct_params:
            if (
                construct_params.get(new_param) is None or not construct_params.get(new_param)
            ) and construct_params.get(deprecated_param) is not None:
                cleaned_construct_params[new_param] = copyer(construct_params[deprecated_param])
            cleaned_construct_params.pop(deprecated_param)
    # add warnings for deprecated parameters
    warnings = []
    for field in DEPRECATED_CONSTRUCT_PARAMS:
        if field in construct_params and construct_params[field] not in [None, False]:
            warnings.append(f"The `{field}` parameter is {CONSTRUCT_PARAMS[field][2].lower()}")

    return cleaned_construct_params, warnings


def compose_transaction(db, name, params, construct_parameters, final_validator=None):
    helpers.setup_bitcoinutils()

    construct_params, warnings = prepare_construct_params(construct_parameters)

    # prepare data
    skip_validation = not construct_params.get("validate", True)
    tx_info = compose_data(db, name, params, skip_validation=skip_validation)

    if construct_params.get("return_only_data", False):
        if final_validator is not None:
            refreshed_tx_info = final_validator(tx_info)
            if refreshed_tx_info is not None:
                tx_info = refreshed_tx_info
        data = tx_info[2]
        return {
            "data": config.PREFIX + data if data else None,
        }

    # construct transaction
    effective_tx_info = [tx_info]

    def refresh_tx_info(original_tx_info):
        refreshed_tx_info = final_validator(original_tx_info)
        if refreshed_tx_info is not None:
            effective_tx_info[0] = refreshed_tx_info
        return refreshed_tx_info

    result, unspent_list = construct(
        db,
        tx_info,
        construct_params,
        final_validator=refresh_tx_info if final_validator is not None else None,
    )
    tx_info = effective_tx_info[0]

    # sanity check
    try:
        check_transaction_sanity(tx_info, result, unspent_list, construct_params)
    except Exception as e:  # pylint: disable=broad-except
        raise exceptions.ComposeError(str(e)) from e

    # return result
    if construct_params.get("verbose", False):
        final_result = result | {
            "psbt": backend.bitcoind.convert_to_psbt(result["rawtransaction"]),
            "params": params,
            "name": name.split(".")[-1],
        }
    else:
        final_result = {}
        for key in REVEAL_RESULT_KEYS:
            if key in result:
                final_result[key] = result[key]
        final_result["rawtransaction"] = result["rawtransaction"]

    if len(warnings) > 0:
        final_result["warnings"] = warnings

    return final_result
