"""
This module contains p2sh data encoding functions
"""

import binascii
import io
import logging
import struct

import bitcoin as bitcoinlib
from bitcoin.core import CTransaction
from bitcoin.core.script import CScript

from counterpartycore.lib import arc4, backend, config, exceptions, script
from counterpartycore.lib.transaction_helper import transaction_outputs
from counterpartycore.lib.transaction_helper.common_serializer import (
    OP_RETURN,
    get_script,
    op_push,
    var_int,
)
from counterpartycore.lib.transaction_helper.transaction_inputs import (
    UTXOLocks,
    sort_unspent_txouts,
)

logger = logging.getLogger(config.LOGGER_NAME)


def maximum_data_chunk_size(pubkeylength):
    if pubkeylength >= 0:
        return (
            bitcoinlib.core.script.MAX_SCRIPT_ELEMENT_SIZE - len(config.PREFIX) - pubkeylength - 12
        )  # Two bytes are for unique offset. This will work for a little more than 1000 outputs
    else:
        return (
            bitcoinlib.core.script.MAX_SCRIPT_ELEMENT_SIZE - len(config.PREFIX) - 44
        )  # Redeemscript size for p2pkh addresses, multisig won't work here


def calculate_outputs(destination_outputs, data_array, fee_per_kb, exact_fee=None):
    datatx_size = 10  # 10 base
    datatx_size += 181  # 181 for source input
    datatx_size += (25 + 9) * len(destination_outputs)  # destination outputs
    datatx_size += 13  # opreturn that signals P2SH encoding
    datatx_size += len(data_array) * (9 + 181)  # size of p2sh inputs, excl data
    datatx_size += sum([len(data_chunk) for data_chunk in data_array])  # data in scriptSig
    datatx_necessary_fee = int(datatx_size / 1000 * fee_per_kb)

    pretx_output_size = 10  # 10 base
    pretx_output_size += len(data_array) * 29  # size of P2SH output

    size_for_fee = pretx_output_size

    # split the tx fee evenly between all datatx outputs
    # data_value = math.ceil(datatx_necessary_fee / len(data_array))
    data_value = config.DEFAULT_REGULAR_DUST_SIZE

    # adjust the data output with the new value and recalculate data_btc_out
    data_btc_out = data_value * len(data_array)

    if exact_fee:
        remain_fee = exact_fee - data_value * len(data_array)
        if remain_fee > 0:
            # if the dust isn't enough to reach the exact_fee, data value will be an array with only the last fee bumped
            data_value = [data_value for i in range(len(data_array))]
            data_value[len(data_array) - 1] = data_value[len(data_array) - 1] + remain_fee
            data_btc_out = exact_fee

    data_output = (data_array, data_value)  # noqa: F841

    logger.debug(f"datatx size: {datatx_size} fee: {datatx_necessary_fee}")
    logger.debug(f"pretx output size: {pretx_output_size}")
    logger.debug(f"size_for_fee: {size_for_fee}")

    return size_for_fee, datatx_necessary_fee, data_value, data_btc_out


def decode_p2sh_input(asm, p2sh_is_segwit=False):
    """Looks at the scriptSig for the input of the p2sh-encoded data transaction
    [signature] [data] [OP_HASH160 ... OP_EQUAL]
    """
    pubkey, source, redeem_script_is_valid, found_data = decode_data_redeem_script(
        asm[-1], p2sh_is_segwit
    )
    if redeem_script_is_valid:
        # this is a signed transaction, so we got {sig[,sig]} {datachunk} {redeem_script}
        datachunk = found_data
        redeem_script = asm[-1]  # asm[-2:]
    else:
        # print('ASM:', len(asm))
        pubkey, source, redeem_script_is_valid, found_data = decode_data_redeem_script(
            asm[-1], p2sh_is_segwit
        )
        if not redeem_script_is_valid or len(asm) != 3:
            return None, None, None

        # this is an unsigned transaction (last is outputScript), so we got [datachunk] [redeem_script] [temporaryOutputScript]
        datachunk, redeem_script, _substitute_script = asm

    data = datachunk
    if data[: len(config.PREFIX)] == config.PREFIX:
        data = data[len(config.PREFIX) :]
    else:
        if data == b"":
            return source, None, None
        raise exceptions.DecodeError("unrecognised P2SH output")

    return source, None, data


def decode_data_push(arr, pos):
    pushlen = 0
    data = b""  # noqa: F841
    opcode = bitcoinlib.core.script.CScriptOp(arr[pos])
    if opcode > 0 and opcode < bitcoinlib.core.script.OP_PUSHDATA1:
        pushlen = arr[pos]
        pos += 1
    elif opcode == bitcoinlib.core.script.OP_PUSHDATA1:
        pushlen = arr[pos + 1]
        pos += 2
    elif opcode == bitcoinlib.core.script.OP_PUSHDATA2:
        (pushlen,) = struct.unpack("<H", arr[pos + 1 : pos + 3])
        pos += 3
    elif opcode == bitcoinlib.core.script.OP_PUSHDATA4:
        (pushlen,) = struct.unpack("<L", arr[pos + 1 : pos + 5])
        pos += 5

    return pos + pushlen, arr[pos : pos + pushlen]


def decode_data_redeem_script(redeem_script, p2sh_is_segwit=False):
    script_len = len(redeem_script)
    found_data = b""

    if (
        script_len == 41
        and redeem_script[0] == bitcoinlib.core.script.OP_DROP
        and redeem_script[35] == bitcoinlib.core.script.OP_CHECKSIGVERIFY
        and redeem_script[37] == bitcoinlib.core.script.OP_DROP
        and redeem_script[38] == bitcoinlib.core.script.OP_DEPTH
        and redeem_script[39] == bitcoinlib.core.script.OP_0
        and redeem_script[40] == bitcoinlib.core.script.OP_EQUAL
    ):
        # - OP_DROP [push] [33-byte pubkey] OP_CHECKSIGVERIFY [n] OP_DROP OP_DEPTH 0 OP_EQUAL
        pubkey = redeem_script[2:35]
        if p2sh_is_segwit:
            source = script.pubkey_to_p2whash(pubkey)
        else:
            source = script.pubkey_to_pubkeyhash(pubkey)
        redeem_script_is_valid = True
    elif (
        script_len > 41
        and redeem_script[0] == bitcoinlib.core.script.OP_DROP
        and redeem_script[script_len - 4] == bitcoinlib.core.script.OP_DROP
        and redeem_script[script_len - 3] == bitcoinlib.core.script.OP_DEPTH
        and redeem_script[script_len - 2] == bitcoinlib.core.script.OP_0
        and redeem_script[script_len - 1] == bitcoinlib.core.script.OP_EQUAL
    ):
        # - OP_DROP {arbitrary multisig script} [n] OP_DROP OP_DEPTH 0 OP_EQUAL
        pubkey = None
        source = None
        redeem_script_is_valid = True
    else:
        pubkey = None
        source = None
        redeem_script_is_valid = False

        try:
            opcode = bitcoinlib.core.script.CScriptOp(redeem_script[0])
            if (
                opcode > bitcoinlib.core.script.OP_0
                and opcode < bitcoinlib.core.script.OP_PUSHDATA1
                or opcode
                in (
                    bitcoinlib.core.script.OP_PUSHDATA1,
                    bitcoinlib.core.script.OP_PUSHDATA2,
                    bitcoinlib.core.script.OP_PUSHDATA4,
                )
            ):
                pos = 0
                pos, found_data = decode_data_push(redeem_script, 0)

                if redeem_script[pos] == bitcoinlib.core.script.OP_DROP:
                    pos += 1
                    valid_sig = False
                    opcode = redeem_script[pos]
                    if type(opcode) != type(""):  # noqa: E721
                        if (
                            opcode >= bitcoinlib.core.script.OP_2
                            and opcode <= bitcoinlib.core.script.OP_15
                        ):
                            # it's multisig
                            req_sigs = opcode - bitcoinlib.core.script.OP_1 + 1  # noqa: F841
                            pos += 1
                            pubkey = None
                            num_sigs = 0
                            found_sigs = False
                            while not found_sigs:
                                pos, npubkey = decode_data_push(redeem_script, pos)
                                num_sigs += 1
                                if redeem_script[pos] - bitcoinlib.core.script.OP_1 + 1 == num_sigs:
                                    found_sigs = True

                            pos += 1
                            valid_sig = (
                                redeem_script[pos] == bitcoinlib.core.script.OP_CHECKMULTISIGVERIFY
                            )
                        else:
                            # it's p2pkh
                            pos, pubkey = decode_data_push(redeem_script, pos)

                            if p2sh_is_segwit:
                                source = script.pubkey_to_p2whash(pubkey)
                            else:
                                source = script.pubkey_to_pubkeyhash(pubkey)

                            valid_sig = (
                                redeem_script[pos] == bitcoinlib.core.script.OP_CHECKSIGVERIFY
                            )
                        pos += 1

                        if valid_sig:
                            unique_offfset_length = 0

                            for i in range(pos + 1, len(redeem_script)):
                                if redeem_script[i] == bitcoinlib.core.script.OP_DROP:
                                    unique_offfset_length = i - pos - 1
                                    break

                            redeem_script_is_valid = (
                                redeem_script[pos + 1 + unique_offfset_length]
                                == bitcoinlib.core.script.OP_DROP
                                and redeem_script[pos + 2 + unique_offfset_length]
                                == bitcoinlib.core.script.OP_DEPTH
                                and redeem_script[pos + 3 + unique_offfset_length] == 0
                                and redeem_script[pos + 4 + unique_offfset_length]
                                == bitcoinlib.core.script.OP_EQUAL
                            )
        except Exception as e:  # noqa: F841
            return None, None, False, None

    return pubkey, source, redeem_script_is_valid, found_data


def make_p2sh_encoding_redeemscript(
    datachunk, n, pub_key=None, multisig_pubkeys=None, multisig_pubkeys_required=None
):
    _logger = logger
    assert len(datachunk) <= bitcoinlib.core.script.MAX_SCRIPT_ELEMENT_SIZE

    data_drop_script = [datachunk, bitcoinlib.core.script.OP_DROP]  # just drop the data chunk
    cleanup_script = [
        n,
        bitcoinlib.core.script.OP_DROP,
        bitcoinlib.core.script.OP_DEPTH,
        0,
        bitcoinlib.core.script.OP_EQUAL,
    ]  # unique offset + prevent scriptSig malleability

    if pub_key is not None:
        # a p2pkh script looks like this: {pubkey} OP_CHECKSIGVERIFY
        verify_owner_script = [pub_key, bitcoinlib.core.script.OP_CHECKSIGVERIFY]
    elif multisig_pubkeys_required is not None and multisig_pubkeys:
        # a 2-of-3 multisig looks like this:
        #   2 {pubkey1} {pubkey2} {pubkey3} 3 OP_CHECKMULTISIGVERIFY
        multisig_pubkeys_required = int(multisig_pubkeys_required)
        if multisig_pubkeys_required < 2 or multisig_pubkeys_required > 15:
            raise exceptions.TransactionError("invalid multisig pubkeys value")
        verify_owner_script = [multisig_pubkeys_required]
        for multisig_pubkey in multisig_pubkeys:
            verify_owner_script.append(multisig_pubkey)
        verify_owner_script = verify_owner_script + [
            len(multisig_pubkeys),
            bitcoinlib.core.script.OP_CHECKMULTISIGVERIFY,
        ]
    else:
        raise exceptions.TransactionError("Either pub_key or multisig pub_keys must be provided")

    # redeem_script = CScript(datachunk) + CScript(data_drop_script + verify_owner_script + cleanup_script)
    redeem_script = CScript(data_drop_script + verify_owner_script + cleanup_script)

    _logger.debug(f"datachunk {binascii.hexlify(datachunk)}")
    _logger.debug(
        f"data_drop_script {repr(CScript(data_drop_script))} ({binascii.hexlify(CScript(data_drop_script))})"
    )
    _logger.debug(
        f"verifyOwnerScript {repr(CScript(verify_owner_script))} ({binascii.hexlify(CScript(verify_owner_script))})"
    )
    _logger.debug(f"entire redeem_script {repr(redeem_script)} ({binascii.hexlify(redeem_script)})")

    # script_sig = CScript([]) + redeem_script  # PUSH(datachunk) + redeem_script
    script_sig = CScript([redeem_script])
    output_script = redeem_script.to_p2sh_scriptPubKey()

    _logger.debug(f"scriptSig {repr(script_sig)} ({binascii.hexlify(script_sig)})")
    _logger.debug(f"outputScript {repr(output_script)} ({binascii.hexlify(output_script)})")

    # outputScript looks like OP_HASH160 {{ hash160([redeem_script]) }} OP_EQUALVERIFY
    # redeem_script looks like OP_DROP {{ pubkey }} OP_CHECKSIGVERIFY {{ n }} OP_DROP OP_DEPTH 0 OP_EQUAL
    # script_sig is {{ datachunk }} OP_DROP {{ pubkey }} OP_CHECKSIGVERIFY {{ n }} OP_DROP OP_DEPTH 0 OP_EQUAL
    return script_sig, redeem_script, output_script


def make_standard_p2sh_multisig_script(multisig_pubkeys, multisig_pubkeys_required):
    # a 2-of-3 multisig looks like this:
    #   2 {pubkey1} {pubkey2} {pubkey3} 3 OP_CHECKMULTISIG
    multisig_pubkeys_required = int(multisig_pubkeys_required)
    multisig_script = [multisig_pubkeys_required]
    for multisig_pubkey in multisig_pubkeys:
        multisig_script.append(multisig_pubkey)
    multisig_script = multisig_script + [
        len(multisig_pubkeys),
        bitcoinlib.core.script.OP_CHECKMULTISIG,
    ]
    return multisig_script


def select_any_coin_from_source(
    source,
    allow_unconfirmed_inputs=True,
    disable_utxo_locks=False,
    exclude_utxos=None,
):
    """Get the first (biggest) input from the source address"""

    # Array of UTXOs, as retrieved by listunspent function from bitcoind
    unspent = backend.addrindexrs.get_unspent_txouts(source, unconfirmed=allow_unconfirmed_inputs)

    unspent = UTXOLocks().filter_unspents(source, unspent, exclude_utxos)

    # sort
    unspent = sort_unspent_txouts(unspent, dust_size=config.DEFAULT_REGULAR_DUST_SIZE)

    # use the first input
    tx_input = unspent[0]
    if tx_input is None:
        return None

    if not disable_utxo_locks:
        UTXOLocks().lock_utxos(source, [tx_input])

    return tx_input


def serialise_p2sh_pretx(
    inputs,
    source,
    source_value,
    data_output,
    change_output=None,
    pubkey=None,
    multisig_pubkeys=None,
    multisig_pubkeys_required=None,
):
    assert data_output  # we don't do this unless there's data

    data_array, data_value = data_output

    s = (1).to_bytes(4, byteorder="little")  # Version

    # Number of inputs.
    s += var_int(int(len(inputs)))

    # List of Inputs.
    for txin in inputs:
        s += binascii.unhexlify(bytes(txin["txid"], "utf-8"))[::-1]  # TxOutHash
        s += txin["vout"].to_bytes(4, byteorder="little")  # TxOutIndex

        tx_script = binascii.unhexlify(bytes(txin["script_pub_key"], "utf-8"))
        s += var_int(int(len(tx_script)))  # Script length
        s += tx_script  # Script
        s += b"\xff" * 4  # Sequence

    # Number of outputs.
    n = len(data_array)
    if change_output:
        n += 1

    # encode number of outputs
    s += var_int(n)

    # P2SH for data encodeded inputs
    for n, data_chunk in enumerate(data_array):
        data_chunk = config.PREFIX + data_chunk  # prefix the data_chunk  # noqa: PLW2901

        # get the scripts
        script_sig, redeem_script, output_script = make_p2sh_encoding_redeemscript(
            data_chunk, n, pubkey, multisig_pubkeys, multisig_pubkeys_required
        )

        # if data_value is an array, then every output fee is specified in it
        if isinstance(data_value, list):  # noqa: E721
            s += data_value[n].to_bytes(8, byteorder="little")  # Value
        else:
            s += data_value.to_bytes(8, byteorder="little")  # Value
        s += var_int(int(len(output_script)))  # Script length
        s += output_script  # Script

    # Change output.
    if change_output:
        change_address, change_value = change_output
        tx_script, witness_script = get_script(change_address)

        s += change_value.to_bytes(8, byteorder="little")  # Value
        s += var_int(int(len(tx_script)))  # Script length
        s += tx_script  # Script

    s += (0).to_bytes(4, byteorder="little")  # LockTime

    return s


def serialize_p2sh(
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
):
    pretx_txid = None
    unsigned_pretx_hex = None
    unsigned_tx_hex = None

    # Normalize source
    if script.is_multisig(source):
        source_address = transaction_outputs.multisig_pubkeyhashes_to_pubkeys(
            source, provided_pubkeys
        )
    else:
        source_address = source

    if p2sh_source_multisig_pubkeys:
        p2sh_source_multisig_pubkeys = [binascii.unhexlify(p) for p in p2sh_source_multisig_pubkeys]

    assert not (segwit and p2sh_pretx_txid)  # shouldn't do old style with segwit enabled

    if p2sh_pretx_txid:
        pretx_txid = (
            p2sh_pretx_txid
            if isinstance(p2sh_pretx_txid, bytes)
            else binascii.unhexlify(p2sh_pretx_txid)
        )
        unsigned_pretx = None
    else:
        destination_value_sum = sum([value for (_destination, value) in destination_outputs])
        source_value = destination_value_sum

        if change_output:
            # add the difference between source and destination to the change
            change_value = change_output[1] + (destination_value_sum - source_value)
            change_output = (change_output[0], change_value)

        unsigned_pretx = serialise_p2sh_pretx(
            inputs,
            source=source_address,
            source_value=source_value,
            data_output=data_output,
            change_output=change_output,
            pubkey=dust_return_pubkey,
            multisig_pubkeys=p2sh_source_multisig_pubkeys,
            multisig_pubkeys_required=p2sh_source_multisig_pubkeys_required,
        )
        unsigned_pretx_hex = binascii.hexlify(unsigned_pretx).decode("utf-8")

    # with segwit we already know the txid and can return both
    if segwit:
        # pretx_txid = hashlib.sha256(unsigned_pretx).digest()  # this should be segwit txid
        ptx = CTransaction.stream_deserialize(
            io.BytesIO(unsigned_pretx)
        )  # could be a non-segwit tx anyways
        txid_ba = bytearray(ptx.GetTxid())
        txid_ba.reverse()
        pretx_txid = bytes(txid_ba)  # gonna leave the malleability problem to upstream
        logger.debug(f"pretx_txid {pretx_txid}")

    if unsigned_pretx:
        # we set a long lock on this, don't want other TXs to spend from it
        UTXOLocks().lock_p2sh_utxos(unsigned_pretx)

    # only generate the data TX if we have the pretx txId
    if pretx_txid:
        source_input = None
        if script.is_p2sh(source):
            source_input = select_any_coin_from_source(source, exclude_utxos=exclude_utxos)
            if not source_input:
                raise exceptions.TransactionError(
                    "Unable to select source input for p2sh source address"
                )

        unsigned_datatx = serialise_p2sh_datatx(
            pretx_txid,
            source=source_address,
            source_input=source_input,
            destination_outputs=destination_outputs,
            data_output=data_output,
            pubkey=dust_return_pubkey,
            multisig_pubkeys=p2sh_source_multisig_pubkeys,
            multisig_pubkeys_required=p2sh_source_multisig_pubkeys_required,
        )
        unsigned_datatx_hex = binascii.hexlify(unsigned_datatx).decode("utf-8")

        # let the rest of the code work it's magic on the data tx
        unsigned_tx_hex = unsigned_datatx_hex
        return pretx_txid, unsigned_pretx_hex, unsigned_tx_hex
    else:
        # we're just gonna return the pretx, it doesn't require any of the further checks
        return pretx_txid, unsigned_pretx_hex, None


def serialise_p2sh_datatx(
    txid,
    source,
    source_input,
    destination_outputs,
    data_output,
    pubkey=None,
    multisig_pubkeys=None,
    multisig_pubkeys_required=None,
):
    assert data_output  # we don't do this unless there's data

    txhash = bitcoinlib.core.lx(bitcoinlib.core.b2x(txid))  # reverse txId
    data_array, value = data_output

    # version
    s = (1).to_bytes(4, byteorder="little")

    # number of inputs is the length of data_array (+1 if a source_input exists)
    number_of_inputs = len(data_array)
    if source_input is not None:
        number_of_inputs += 1
    s += var_int(number_of_inputs)

    # Handle a source input here for a P2SH source
    if source_input is not None:
        s += binascii.unhexlify(bytes(source_input["txid"], "utf-8"))[::-1]  # TxOutHash
        s += source_input["vout"].to_bytes(4, byteorder="little")  # TxOutIndex

        # since pubkey is not returned from indexd, add it from bitcoind
        source_inputs = script.ensure_script_pub_key_for_inputs([source_input])
        source_input = source_inputs[0]
        tx_script = binascii.unhexlify(bytes(source_input["script_pub_key"], "utf-8"))
        s += var_int(int(len(tx_script)))  # Script length
        s += tx_script  # Script
        s += b"\xff" * 4  # Sequence

    # list of inputs
    for n, data_chunk in enumerate(data_array):
        data_chunk = config.PREFIX + data_chunk  # prefix the data_chunk  # noqa: PLW2901

        # get the scripts
        script_sig, redeem_script, output_script = make_p2sh_encoding_redeemscript(
            data_chunk, n, pubkey, multisig_pubkeys, multisig_pubkeys_required
        )

        s += txhash  # TxOutHash
        s += (n).to_bytes(4, byteorder="little")  # TxOutIndex (assumes 0-based)

        s += var_int(len(script_sig))  # + len(output_script))                      # Script length
        s += script_sig  # Script

        s += b"\xff" * 4  # Sequence

    # number of outputs, always 1 for the opreturn
    n = 1
    n += len(destination_outputs)

    # encode output length
    s += var_int(n)

    # destination outputs
    for destination, value in destination_outputs:
        tx_script, witness_script = get_script(destination)

        s += value.to_bytes(8, byteorder="little")  # Value
        s += var_int(int(len(tx_script)))  # Script length
        s += tx_script  # Script

    # opreturn to signal P2SH encoding
    key = arc4.init_arc4(txid)
    data_chunk = config.PREFIX + b"P2SH"
    data_chunk = key.encrypt(data_chunk)
    tx_script = OP_RETURN  # OP_RETURN
    tx_script += op_push(len(data_chunk))  # Push bytes of data chunk
    tx_script += data_chunk  # Data

    # add opreturn
    s += (0).to_bytes(8, byteorder="little")  # Value
    s += var_int(int(len(tx_script)))  # Script length
    s += tx_script  # Script

    s += (0).to_bytes(4, byteorder="little")  # LockTime

    return s
