# coding: utf-8
# Copyright (c) 2016 Fabian Barkhau <fabian.barkhau@gmail.com>
# License: MIT (see LICENSE file)


from pycoin.serialize import b2h
from pycoin.tx.script import tools
from pycoin.tx import Tx
from . import exceptions


MAX_SEQUENCE = 0x0000FFFF
DEPOSIT_SCRIPT = """
    OP_IF
        2 {payer_pubkey} {payee_pubkey} 2 OP_CHECKMULTISIG
    OP_ELSE
        OP_IF
            OP_HASH160 {spend_secret_hash} OP_EQUALVERIFY
            {payer_pubkey} OP_CHECKSIG
        OP_ELSE
            {expire_time} OP_NOP3 OP_DROP
            {payer_pubkey} OP_CHECKSIG
        OP_ENDIF
    OP_ENDIF
"""
COMMIT_SCRIPT = """
    OP_IF
        {delay_time} OP_NOP3 OP_DROP
        OP_HASH160 {spend_secret_hash} OP_EQUALVERIFY
        {payee_pubkey} OP_CHECKSIG
    OP_ELSE
        OP_HASH160 {revoke_secret_hash} OP_EQUALVERIFY
        {payer_pubkey} OP_CHECKSIG
    OP_ENDIF
"""
EXPIRE_SCRIPTSIG = "{sig} OP_0 OP_0"
CHANGE_SCRIPTSIG = "{sig} {secret} OP_1 OP_0"
COMMIT_SCRIPTSIG = "OP_0 {payer_sig} {payee_sig} OP_1"
PAYOUT_SCRIPTSIG = "{sig} {spend_secret} OP_1"
REVOKE_SCRIPTSIG = "{sig} {revoke_secret} OP_0"


def get_word(script, index):
    pc = 0
    i = 0
    while pc < len(script) and i <= index:
        opcode, data, pc = tools.get_opcode(script, pc)
        i += 1
    if i != index + 1:
        raise ValueError(index)
    return opcode, data, tools.disassemble_for_opcode_data(opcode, data)


def validate(reference_script, untrusted_script):
    r_pc = 0
    u_pc = 0
    while r_pc < len(reference_script) and u_pc < len(untrusted_script):
        r_opcode, r_data, r_pc = tools.get_opcode(reference_script, r_pc)
        u_opcode, u_data, u_pc = tools.get_opcode(untrusted_script, u_pc)
        if r_data is not None and b2h(r_data) == "deadbeef":
            continue  # placeholder for expected variable
        if r_opcode != u_opcode or r_data != u_data:
            raise exceptions.InvalidScript(b2h(untrusted_script))
    if r_pc != len(reference_script) or u_pc != len(untrusted_script):
        raise exceptions.InvalidScript(b2h(untrusted_script))


def get_spend_secret(payout_rawtx, commit_script):
    tx = Tx.from_hex(payout_rawtx)
    spend_script = tx.txs_in[0].script
    try:
        opcode, data, disassembled = get_word(spend_script, 3)
        if data == commit_script:  # is payout tx
            opcode, spend_secret, disassembled = get_word(spend_script, 1)
            return b2h(spend_secret)
    except ValueError:
        return None


def parse_sequence_value(opcode, data, disassembled):
    value = None
    if opcode == 0:
        value = 0
    elif 0 < opcode < 76:  # get from data bytes
        value = tools.int_from_script_bytes(data)
    elif 80 < opcode < 97:  # OP_1 - OP_16
        value = opcode - 80
    else:
        raise ValueError("Invalid expire time: {0}".format(disassembled))
    if value > MAX_SEQUENCE:
        msg = "Max expire time exceeded: {0} > {1}"
        raise ValueError(msg.format(value, MAX_SEQUENCE))
    return value


def get_commit_payer_pubkey(script):
    opcode, data, disassembled = get_word(script, 13)
    return b2h(data)


def get_commit_payee_pubkey(script):
    opcode, data, disassembled = get_word(script, 7)
    return b2h(data)


def get_commit_delay_time(script):
    opcode, data, disassembled = get_word(script, 1)
    return parse_sequence_value(opcode, data, disassembled)


def get_commit_spend_secret_hash(script):
    opcode, data, disassembled = get_word(script, 5)
    return b2h(data)


def get_commit_revoke_secret_hash(script):
    opcode, data, disassembled = get_word(script, 11)
    return b2h(data)


def get_deposit_payer_pubkey(script):
    opcode, data, disassembled = get_word(script, 2)
    return b2h(data)


def get_deposit_payee_pubkey(script):
    opcode, data, disassembled = get_word(script, 3)
    return b2h(data)


def get_deposit_expire_time(script):
    opcode, data, disassembled = get_word(script, 14)
    return parse_sequence_value(opcode, data, disassembled)


def get_deposit_spend_secret_hash(script):
    opcode, data, disassembled = get_word(script, 9)
    return b2h(data)


def compile_deposit_script(payer_pubkey, payee_pubkey,
                           spend_secret_hash, expire_time):
    """Compile deposit transaction pay ot script.

    Args:
        payer_pubkey (str): Hex encoded public key in sec format.
        payee_pubkey (str): Hex encoded public key in sec format.
        spend_secret_hash (str): Hex encoded hash160 of spend secret.
        expire_time (int): Channel expire time in blocks given as int.

    Return:
        Compiled bitcoin script.
    """
    script_text = DEPOSIT_SCRIPT.format(
        payer_pubkey=payer_pubkey,
        payee_pubkey=payee_pubkey,
        spend_secret_hash=spend_secret_hash,
        expire_time=str(expire_time)
    )
    return tools.compile(script_text)


def compile_commit_script(payer_pubkey, payee_pubkey, spend_secret_hash,
                          revoke_secret_hash, delay_time):
    script_text = COMMIT_SCRIPT.format(
        payer_pubkey=payer_pubkey,
        payee_pubkey=payee_pubkey,
        spend_secret_hash=spend_secret_hash,
        revoke_secret_hash=revoke_secret_hash,
        delay_time=str(delay_time)
    )
    return tools.compile(script_text)
