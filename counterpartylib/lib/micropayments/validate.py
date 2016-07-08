# coding: utf-8
# Copyright (c) 2016 Fabian Barkhau <fabian.barkhau@gmail.com>
# License: MIT (see LICENSE file)


import six
import re
import pycoin
from pycoin.tx import Tx
from . import exceptions
from . import scripts
from . import util


def is_string(s):
    if not isinstance(s, six.string_types):
        raise exceptions.InvalidString(s)


def is_hex(data):
    is_string(data)
    if not re.match("^[0-9a-f]*$", data):
        raise exceptions.InvalidHexData(data)
    if not (len(data) % 2 == 0):
        raise exceptions.InvalidHexData(data)


def pubkey(pubkey_hex):
    is_hex(pubkey_hex)
    sec = pycoin.serialize.h2b(pubkey_hex)
    if len(sec) != 33:  # compressed only!
        raise exceptions.InvalidPubKey(pubkey_hex)


def hash160(hash_hex):
    is_hex(hash_hex)
    hash_bin = pycoin.serialize.h2b(hash_hex)
    if len(hash_bin) != 20:
        raise exceptions.InvalidHash160(hash_hex)


def is_integer(i):
    if not isinstance(i, six.integer_types):
        raise exceptions.InvalidInteger(i)


def is_list(l):
    if not isinstance(l, list):
        raise exceptions.InvalidList(l)


def is_unsigned(number):
    is_integer(number)
    if number < 0:
        raise exceptions.InvalidUnsigned(number)


def is_sequence(number):
    is_unsigned(number)
    if not (0 <= number <= scripts.MAX_SEQUENCE):
        raise exceptions.InvalidSequence(number)


def is_quantity(number):
    is_integer(number)
    if not (0 < number < 2100000000000000):
        raise exceptions.InvalidQuantity(number)


def deposit_script(deposit_script_hex, expected_payee_pubkey,
                   expected_spend_secret_hash):
    is_hex(deposit_script_hex)
    script_bin = util.h2b(deposit_script_hex)

    # is a deposit script
    reference_script = scripts.compile_deposit_script(
        "deadbeef", "deadbeef", "deadbeef", "deadbeef"
    )
    scripts.validate(reference_script, script_bin)

    # deposit spend secret hash matches expected spend secret hash
    found_hash = scripts.get_deposit_spend_secret_hash(script_bin)
    if found_hash != expected_spend_secret_hash:
        raise exceptions.IncorrectSpendSecretHash(
            found_hash, expected_spend_secret_hash
        )

    # deposit payee pubkey matches expected payee pubkey
    found_pubkey = scripts.get_deposit_payee_pubkey(script_bin)
    if found_pubkey != expected_payee_pubkey:
        raise exceptions.IncorrectPubKey(found_pubkey, expected_payee_pubkey)


def commit_script(commit_script_hex, deposit_script_hex):
    is_hex(commit_script_hex)
    is_hex(deposit_script_hex)

    _deposit_script = util.h2b(deposit_script_hex)
    _commit_script = util.h2b(commit_script_hex)

    # is a deposit script
    reference_script = scripts.compile_deposit_script(
        "deadbeef", "deadbeef", "deadbeef", "deadbeef"
    )
    scripts.validate(reference_script, _deposit_script)

    # is a commit script
    reference_script = scripts.compile_commit_script(
        "deadbeef", "deadbeef", "deadbeef", "deadbeef", "deadbeef"
    )
    scripts.validate(reference_script, _commit_script)

    # validate payee pubkey
    deposit_payee_pubkey = scripts.get_deposit_payee_pubkey(_deposit_script)
    commit_payee_pubkey = scripts.get_commit_payee_pubkey(_commit_script)
    if deposit_payee_pubkey != commit_payee_pubkey:
        raise exceptions.IncorrectPubKey(commit_payee_pubkey,
                                         deposit_payee_pubkey)

    # validate payer pubkey
    deposit_payer_pubkey = scripts.get_deposit_payer_pubkey(_deposit_script)
    commit_payer_pubkey = scripts.get_commit_payer_pubkey(_commit_script)
    if deposit_payer_pubkey != commit_payer_pubkey:
        raise exceptions.IncorrectPubKey(commit_payer_pubkey,
                                         deposit_payer_pubkey)

    # validate spend secret hash
    deposit_spend_hash = scripts.get_deposit_spend_secret_hash(_deposit_script)
    commit_spend_hash = scripts.get_commit_spend_secret_hash(_commit_script)
    if deposit_spend_hash != commit_spend_hash:
        raise exceptions.IncorrectSpendSecretHash(commit_spend_hash,
                                                  deposit_spend_hash)


def commit_rawtx(deposit_utxos, commit_rawtx_hex, expected_asset,
                 expected_deposit_script_hex, expected_commit_script, netcode):

    # is a bitcoin transaction
    tx = Tx.from_hex(commit_rawtx_hex)

    # validate sends to commit script
    commit_address = util.script2address(
        util.h2b(expected_commit_script), netcode=netcode
    )
    for txout in tx.txs_out:
        assert(txout.bitcoin_address(netcode=netcode) == commit_address)

    for txin in tx.txs_in:

        # must spend only deposit utxos
        found = False
        for utxo in deposit_utxos[:]:
            txid = util.b2h_rev(txin.previous_hash)
            if (utxo["txid"] == txid and utxo["vout"] == txin.previous_index):
                found = True
                deposit_utxos.remove(utxo)  # prevent reuse of utxo
                break
        if not found:
            assert(False)  # spends non deposit utxo

        # scriptsig is correct
        ref_scriptsig = scripts.compile_commit_scriptsig("deadbeef", "deadbeef")
        deposit_script = util.h2b(expected_deposit_script_hex)
        reference_script = ref_scriptsig + deposit_script
        scripts.validate(reference_script, txin.script)

        # FIXME validate signed by payer

    # FIXME validate rawtx asset correct


def state(state_data):
    pass  # FIXME implement
