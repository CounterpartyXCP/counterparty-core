"""
This module contains p2sh data encoding functions
"""

import binascii

import logging
logger = logging.getLogger(__name__)

import bitcoin as bitcoinlib
from bitcoin.core.script import CScript

from counterpartylib.lib import config
from counterpartylib.lib import script
from counterpartylib.lib import exceptions

def decode_p2sh_input(asm):
    ''' Looks at the scriptSig for the input of the p2sh-encoded data transaction 
        [signature] [data] [OP_HASH160 ... OP_EQUAL]
    '''
    assert len(asm) == 3

    source = None
    last_chunk = asm[2]
    last_is_p2sh = len(last_chunk) == 23 and \
                    last_chunk[0] == bitcoinlib.core.script.OP_HASH160 and \
                    last_chunk[22] == bitcoinlib.core.script.OP_EQUAL
    unsigned = last_is_p2sh

    # this is an unsigned transaction (last is outputScript), so we got [datachunk] [redeemScript] [outputScript]
    if unsigned:
        datachunk = asm[0]
        redeemScript = asm[1]
    # this is a signed transaction (last is not outputScript), so we got [sig] [datachunk] [redeemScript]
    else:
        datachunk = asm[1]
        redeemScript = asm[2]

    # extract the source from the redeemScript
    redeem_script_is_valid = False
    script_len = len(redeemScript)
    if script_len == 63 and \
        redeemScript[0] == bitcoinlib.core.script.OP_HASH160 and \
        redeemScript[22] == bitcoinlib.core.script.OP_EQUALVERIFY and \
        redeemScript[57] == bitcoinlib.core.script.OP_CHECKSIGVERIFY and \
        redeemScript[59] == bitcoinlib.core.script.OP_DROP and \
        redeemScript[60] == bitcoinlib.core.script.OP_DEPTH and \
        redeemScript[61] == bitcoinlib.core.script.OP_0 and \
        redeemScript[62] == bitcoinlib.core.script.OP_EQUAL:
            # - OP_HASH160 [push] [20bytehash] OP_EQUALVERIFY [push] [33-byte pubkey] OP_CHECKSIGVERIFY [n] OP_DROP OP_DEPTH 0 OP_EQUAL
            pubkey = redeemScript[24:57]
            source = script.pubkey_to_pubkeyhash(pubkey)
            redeem_script_is_valid = True
    elif script_len > 63 and \
        redeemScript[0] == bitcoinlib.core.script.OP_HASH160 and \
        redeemScript[22] == bitcoinlib.core.script.OP_EQUALVERIFY and \
        redeemScript[script_len-4] == bitcoinlib.core.script.OP_DROP and \
        redeemScript[script_len-3] == bitcoinlib.core.script.OP_DEPTH and \
        redeemScript[script_len-2] == bitcoinlib.core.script.OP_0 and \
        redeemScript[script_len-1] == bitcoinlib.core.script.OP_EQUAL:
            # - OP_HASH160 [push] [20bytehash] OP_EQUALVERIFY {arbitrary multisig script} [n] OP_DROP OP_DEPTH 0 OP_EQUAL
            source = None
            redeem_script_is_valid = True
    else:
      redeem_script_is_valid = False

    if not redeem_script_is_valid:
        raise exceptions.DecodeError('unrecognised redeemScript in P2SH output')

    data = datachunk

    if data[:len(config.PREFIX)] == config.PREFIX:
        data = data[len(config.PREFIX):]
    else:
        raise exceptions.DecodeError('unrecognised P2SH output')

    return source, None, data


def make_p2sh_encoding_redeemscript(datachunk, n, pubKey=None, multisig_pubkeys=None, multisig_pubkeys_required=None):
    _logger = logger.getChild('p2sh_encoding')
    assert len(datachunk) <= bitcoinlib.core.script.MAX_SCRIPT_ELEMENT_SIZE

    dataRedeemScript = [bitcoinlib.core.script.OP_HASH160, bitcoinlib.core.Hash160(datachunk), bitcoinlib.core.script.OP_EQUALVERIFY]

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

    redeemScript = CScript(dataRedeemScript + verifyOwnerScript +
                           [n, bitcoinlib.core.script.OP_DROP,  # deduplicate push dropped to meet BIP62 rules
                            bitcoinlib.core.script.OP_DEPTH, 0, bitcoinlib.core.script.OP_EQUAL])  # prevent scriptSig malleability

    _logger.debug('datachunk %s' % (binascii.hexlify(datachunk)))
    _logger.debug('dataRedeemScript %s (%s)' % (repr(CScript(dataRedeemScript)), binascii.hexlify(CScript(dataRedeemScript))))

    _logger.debug('redeemScript %s (%s)' % (repr(redeemScript), binascii.hexlify(redeemScript)))

    outputScript = redeemScript.to_p2sh_scriptPubKey()
    scriptSig = CScript([datachunk]) + redeemScript  # PUSH(datachunk) + redeemScript

    _logger.debug('scriptSig %s (%s)' % (repr(scriptSig), binascii.hexlify(scriptSig)))
    _logger.debug('outputScript %s (%s)' % (repr(outputScript), binascii.hexlify(outputScript)))

    return scriptSig, redeemScript, outputScript


