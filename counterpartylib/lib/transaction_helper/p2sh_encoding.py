"""
This module contains p2sh data encoding functions
"""

import binascii
import math

import logging
logger = logging.getLogger(__name__)

import bitcoin as bitcoinlib
from bitcoin.core.script import CScript

from counterpartylib.lib import config
from counterpartylib.lib import script
from counterpartylib.lib import exceptions

def maximum_data_chunk_size():
    return bitcoinlib.core.script.MAX_SCRIPT_ELEMENT_SIZE - len(config.PREFIX)

def calculate_outputs(destination_outputs, data_array, fee_per_kb):
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
    data_value = math.ceil(datatx_necessary_fee / len(data_array))

    # adjust the data output with the new value and recalculate data_btc_out
    data_output = (data_array, data_value)
    data_btc_out = data_value * len(data_array)

    logger.getChild('p2shdebug').debug('datatx size: %d fee: %d' % (datatx_size, datatx_necessary_fee))
    logger.getChild('p2shdebug').debug('pretx output size: %d' % (pretx_output_size, ))
    logger.getChild('p2shdebug').debug('size_for_fee: %d' % (size_for_fee, ))

    return size_for_fee, datatx_necessary_fee, data_value, data_btc_out

def decode_p2sh_input(asm):
    ''' Looks at the scriptSig for the input of the p2sh-encoded data transaction
        [signature] [data] [OP_HASH160 ... OP_EQUAL]
    '''
    pubkey, source, redeem_script_is_valid = decode_data_redeem_script(asm[-1])
    if redeem_script_is_valid and len(asm) >= 3:
        # this is a signed transaction, so we got {sig[,sig]} {datachunk} {redeemScript}
        datachunk, redeemScript = asm[-2:]
    else:
        pubkey, source, redeem_script_is_valid = decode_data_redeem_script(asm[-2])
        if not redeem_script_is_valid or len(asm) != 3:
            return None, None, None

        # this is an unsigned transaction (last is outputScript), so we got [datachunk] [redeemScript] [temporaryOutputScript]
        datachunk, redeemScript, _substituteScript = asm

    data = datachunk
    if data[:len(config.PREFIX)] == config.PREFIX:
        data = data[len(config.PREFIX):]
    else:
        raise exceptions.DecodeError('unrecognised P2SH output')

    return source, None, data

def decode_data_redeem_script(redeemScript):
    script_len = len(redeemScript)

    if script_len == 41 and \
        redeemScript[0] == bitcoinlib.core.script.OP_DROP and \
        redeemScript[35] == bitcoinlib.core.script.OP_CHECKSIGVERIFY and \
        redeemScript[37] == bitcoinlib.core.script.OP_DROP and \
        redeemScript[38] == bitcoinlib.core.script.OP_DEPTH and \
        redeemScript[39] == bitcoinlib.core.script.OP_0 and \
        redeemScript[40] == bitcoinlib.core.script.OP_EQUAL:
            # - OP_DROP [push] [33-byte pubkey] OP_CHECKSIGVERIFY [n] OP_DROP OP_DEPTH 0 OP_EQUAL
            pubkey = redeemScript[2:35]
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

    return pubkey, source, redeem_script_is_valid

def make_p2sh_encoding_redeemscript(datachunk, n, pubKey=None, multisig_pubkeys=None, multisig_pubkeys_required=None):
    _logger = logger.getChild('p2sh_encoding')
    assert len(datachunk) <= bitcoinlib.core.script.MAX_SCRIPT_ELEMENT_SIZE

    dataDropScript = [bitcoinlib.core.script.OP_DROP] # just drop the data chunk
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

    redeemScript = CScript(datachunk) + CScript(dataDropScript + verifyOwnerScript + cleanupScript)

    _logger.debug('datachunk %s' % (binascii.hexlify(datachunk)))
    _logger.debug('dataDropScript %s (%s)' % (repr(CScript(dataDropScript)), binascii.hexlify(CScript(dataDropScript))))
    _logger.debug('verifyOwnerScript %s (%s)' % (repr(CScript(verifyOwnerScript)), binascii.hexlify(CScript(verifyOwnerScript))))
    _logger.debug('entire redeemScript %s (%s)' % (repr(redeemScript), binascii.hexlify(redeemScript)))

    outputScript = redeemScript.to_p2sh_scriptPubKey()

    #scriptSig = b''.join([CScript([datachunk, redeemScript]), outputScript])
    scriptSig = b''.join([CScript([datachunk])])
    print('redeemScript: ', binascii.hexlify(redeemScript))
    print('outputScript: ', binascii.hexlify(outputScript))
    #scriptSig = CScript([datachunk]) + redeemScript

    _logger.debug('scriptSig %s (%s)' % (repr(scriptSig), binascii.hexlify(scriptSig)))
    _logger.debug('outputScript %s (%s)' % (repr(outputScript), binascii.hexlify(outputScript)))

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
