"""
This module contains p2sh data encoding functions
"""

import binascii
import math
import struct
import logging
import traceback # not needed if not printing exceptions on p2sh decoding

logger = logging.getLogger(__name__)

import bitcoin as bitcoinlib
from bitcoin.core.script import CScript

from counterpartylib.lib import config
from counterpartylib.lib import script
from counterpartylib.lib import exceptions

def maximum_data_chunk_size(pubkeylength):
    if pubkeylength >= 0:
        return bitcoinlib.core.script.MAX_SCRIPT_ELEMENT_SIZE - len(config.PREFIX) - pubkeylength - 12 #Two bytes are for unique offset. This will work for a little more than 1000 outputs
    else:
        return bitcoinlib.core.script.MAX_SCRIPT_ELEMENT_SIZE - len(config.PREFIX) - 44 # Redeemscript size for p2pkh addresses, multisig won't work here

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
            #if the dust isn't enough to reach the exact_fee, data value will be an array with only the last fee bumped
            data_value = [data_value for i in range(len(data_array))]
            data_value[len(data_array)-1] = data_value[len(data_array)-1] + remain_fee
            data_btc_out = exact_fee
    
    data_output = (data_array, data_value)          

    logger.getChild('p2shdebug').debug('datatx size: %d fee: %d' % (datatx_size, datatx_necessary_fee))
    logger.getChild('p2shdebug').debug('pretx output size: %d' % (pretx_output_size, ))
    logger.getChild('p2shdebug').debug('size_for_fee: %d' % (size_for_fee, ))

    return size_for_fee, datatx_necessary_fee, data_value, data_btc_out

def decode_p2sh_input(asm, p2sh_is_segwit=False):
    ''' Looks at the scriptSig for the input of the p2sh-encoded data transaction
        [signature] [data] [OP_HASH160 ... OP_EQUAL]
    '''
    pubkey, source, redeem_script_is_valid, found_data = decode_data_redeem_script(asm[-1], p2sh_is_segwit)
    if redeem_script_is_valid:
        # this is a signed transaction, so we got {sig[,sig]} {datachunk} {redeemScript}
        datachunk = found_data
        redeemScript = asm[-1] #asm[-2:]
    else:
        #print('ASM:', len(asm))
        pubkey, source, redeem_script_is_valid, found_data = decode_data_redeem_script(asm[-1], p2sh_is_segwit)
        if not redeem_script_is_valid or len(asm) != 3:
            return None, None, None

        # this is an unsigned transaction (last is outputScript), so we got [datachunk] [redeemScript] [temporaryOutputScript]
        datachunk, redeemScript, _substituteScript = asm

    data = datachunk
    if data[:len(config.PREFIX)] == config.PREFIX:
        data = data[len(config.PREFIX):]
    else:
        if data == b'':
            return source, None, None
        raise exceptions.DecodeError('unrecognised P2SH output')

    return source, None, data

def decode_data_push(arr, pos):
    pushlen = 0
    data = b''
    opcode = bitcoinlib.core.script.CScriptOp(arr[pos])
    if opcode > 0 and opcode < bitcoinlib.core.script.OP_PUSHDATA1:
        pushlen = arr[pos]
        pos += 1
    elif opcode == bitcoinlib.core.script.OP_PUSHDATA1:
        pushlen = arr[pos + 1]
        pos += 2
    elif opcode == bitcoinlib.core.script.OP_PUSHDATA2:
        (pushlen, ) = struct.unpack('<H', arr[pos + 1:pos + 3])
        pos += 3
    elif opcode == bitcoinlib.core.script.OP_PUSHDATA4:
        (pushlen, ) = struct.unpack('<L', arr[pos + 1:pos + 5])
        pos += 5

    return pos + pushlen, arr[pos:pos + pushlen]

def decode_data_redeem_script(redeemScript, p2sh_is_segwit=False):
    script_len = len(redeemScript)
    found_data = b''

    if script_len == 41 and \
        redeemScript[0] == bitcoinlib.core.script.OP_DROP and \
        redeemScript[35] == bitcoinlib.core.script.OP_CHECKSIGVERIFY and \
        redeemScript[37] == bitcoinlib.core.script.OP_DROP and \
        redeemScript[38] == bitcoinlib.core.script.OP_DEPTH and \
        redeemScript[39] == bitcoinlib.core.script.OP_0 and \
        redeemScript[40] == bitcoinlib.core.script.OP_EQUAL:
            # - OP_DROP [push] [33-byte pubkey] OP_CHECKSIGVERIFY [n] OP_DROP OP_DEPTH 0 OP_EQUAL
            pubkey = redeemScript[2:35]
            if p2sh_is_segwit:
                source = script.pubkey_to_p2whash(pubkey)
            else:
                source = script.pubkey_to_pubkeyhash(pubkey)
            redeem_script_is_valid = True
    elif script_len > 41 and \
        redeemScript[0] == bitcoinlib.core.script.OP_DROP and \
        redeemScript[script_len-4] == bitcoinlib.core.script.OP_DROP and \
        redeemScript[script_len-3] == bitcoinlib.core.script.OP_DEPTH and \
        redeemScript[script_len-2] == bitcoinlib.core.script.OP_0 and \
        redeemScript[script_len-1] == bitcoinlib.core.script.OP_EQUAL:
            # - OP_DROP {arbitrary multisig script} [n] OP_DROP OP_DEPTH 0 OP_EQUAL
            pubkey = None
            source = None
            redeem_script_is_valid = True
    else:
        pubkey = None
        source = None
        redeem_script_is_valid = False

        try:
            opcode = bitcoinlib.core.script.CScriptOp(redeemScript[0])
            if opcode > bitcoinlib.core.script.OP_0 and opcode < bitcoinlib.core.script.OP_PUSHDATA1 or \
                opcode in (bitcoinlib.core.script.OP_PUSHDATA1, bitcoinlib.core.script.OP_PUSHDATA2, bitcoinlib.core.script.OP_PUSHDATA4):

                pos = 0
                pos, found_data = decode_data_push(redeemScript, 0)

                if redeemScript[pos] == bitcoinlib.core.script.OP_DROP:
                    pos += 1
                    valid_sig = False
                    opcode = redeemScript[pos]
                    if type(opcode) != type(''):
                        if opcode >= bitcoinlib.core.script.OP_2 and opcode <= bitcoinlib.core.script.OP_15:
                            # it's multisig
                            req_sigs = opcode - bitcoinlib.core.script.OP_1 + 1
                            pos += 1
                            pubkey = None
                            num_sigs = 0
                            found_sigs = False
                            while not found_sigs:
                                pos, npubkey = decode_data_push(redeemScript, pos)
                                num_sigs += 1
                                if redeemScript[pos] - bitcoinlib.core.script.OP_1 + 1 == num_sigs:
                                    found_sigs = True

                            pos += 1
                            valid_sig = redeemScript[pos] == bitcoinlib.core.script.OP_CHECKMULTISIGVERIFY
                        else:
                            # it's p2pkh
                            pos, pubkey = decode_data_push(redeemScript, pos)

                            if p2sh_is_segwit:
                                source = script.pubkey_to_p2whash(pubkey)
                            else:
                                source = script.pubkey_to_pubkeyhash(pubkey)

                            valid_sig = redeemScript[pos] == bitcoinlib.core.script.OP_CHECKSIGVERIFY
                        pos += 1

                        if valid_sig:
                            uniqueOffsetLength = 0

                            for i in range(pos+1, len(redeemScript)):
                                if redeemScript[i] == bitcoinlib.core.script.OP_DROP:
                                    uniqueOffsetLength = i-pos-1
                                    break

                            redeem_script_is_valid = redeemScript[pos + 1 + uniqueOffsetLength] == bitcoinlib.core.script.OP_DROP and \
                                redeemScript[pos + 2 + uniqueOffsetLength] == bitcoinlib.core.script.OP_DEPTH and \
                                redeemScript[pos + 3 + uniqueOffsetLength] == 0 and \
                                redeemScript[pos + 4 + uniqueOffsetLength] == bitcoinlib.core.script.OP_EQUAL
        except Exception as e:
            return None, None, False, None

    return pubkey, source, redeem_script_is_valid, found_data

def make_p2sh_encoding_redeemscript(datachunk, n, pubKey=None, multisig_pubkeys=None, multisig_pubkeys_required=None):
    _logger = logger.getChild('p2sh_encoding')
    assert len(datachunk) <= bitcoinlib.core.script.MAX_SCRIPT_ELEMENT_SIZE

    dataDropScript = [datachunk, bitcoinlib.core.script.OP_DROP] # just drop the data chunk
    cleanupScript = [n, bitcoinlib.core.script.OP_DROP, bitcoinlib.core.script.OP_DEPTH, 0, bitcoinlib.core.script.OP_EQUAL] # unique offset + prevent scriptSig malleability

    if pubKey is not None:
        # a p2pkh script looks like this: {pubkey} OP_CHECKSIGVERIFY
        verifyOwnerScript = [pubKey, bitcoinlib.core.script.OP_CHECKSIGVERIFY]
    elif multisig_pubkeys_required is not None and multisig_pubkeys:
        # a 2-of-3 multisig looks like this:
        #   2 {pubkey1} {pubkey2} {pubkey3} 3 OP_CHECKMULTISIGVERIFY
        multisig_pubkeys_required = int(multisig_pubkeys_required)
        if multisig_pubkeys_required < 2 or multisig_pubkeys_required > 15:
            raise exceptions.TransactionError('invalid multisig pubkeys value')
        verifyOwnerScript = [multisig_pubkeys_required]
        for multisig_pubkey in multisig_pubkeys:
            verifyOwnerScript.append(multisig_pubkey)
        verifyOwnerScript = verifyOwnerScript + [len(multisig_pubkeys), bitcoinlib.core.script.OP_CHECKMULTISIGVERIFY]
    else:
        raise exceptions.TransactionError('Either pubKey or multisig pubKeys must be provided')

    #redeemScript = CScript(datachunk) + CScript(dataDropScript + verifyOwnerScript + cleanupScript)
    redeemScript = CScript(dataDropScript + verifyOwnerScript + cleanupScript)

    _logger.debug(f'datachunk {binascii.hexlify(datachunk)}')
    _logger.debug(f'dataDropScript {repr(CScript(dataDropScript))} ({binascii.hexlify(CScript(dataDropScript))})')
    _logger.debug(f'verifyOwnerScript {repr(CScript(verifyOwnerScript))} ({binascii.hexlify(CScript(verifyOwnerScript))})')
    _logger.debug(f'entire redeemScript {repr(redeemScript)} ({binascii.hexlify(redeemScript)})')

    #scriptSig = CScript([]) + redeemScript  # PUSH(datachunk) + redeemScript
    scriptSig = CScript([redeemScript])
    outputScript = redeemScript.to_p2sh_scriptPubKey()

    _logger.debug(f'scriptSig {repr(scriptSig)} ({binascii.hexlify(scriptSig)})')
    _logger.debug(f'outputScript {repr(outputScript)} ({binascii.hexlify(outputScript)})')

    # outputScript looks like OP_HASH160 {{ hash160([redeemScript]) }} OP_EQUALVERIFY
    # redeemScript looks like OP_DROP {{ pubkey }} OP_CHECKSIGVERIFY {{ n }} OP_DROP OP_DEPTH 0 OP_EQUAL
    # scriptSig is {{ datachunk }} OP_DROP {{ pubkey }} OP_CHECKSIGVERIFY {{ n }} OP_DROP OP_DEPTH 0 OP_EQUAL
    return scriptSig, redeemScript, outputScript

def make_standard_p2sh_multisig_script(multisig_pubkeys, multisig_pubkeys_required):
    # a 2-of-3 multisig looks like this:
    #   2 {pubkey1} {pubkey2} {pubkey3} 3 OP_CHECKMULTISIG
    multisig_pubkeys_required = int(multisig_pubkeys_required)
    multisig_script = [multisig_pubkeys_required]
    for multisig_pubkey in multisig_pubkeys:
        multisig_script.append(multisig_pubkey)
    multisig_script = multisig_script + [len(multisig_pubkeys), bitcoinlib.core.script.OP_CHECKMULTISIG]
    return multisig_script
