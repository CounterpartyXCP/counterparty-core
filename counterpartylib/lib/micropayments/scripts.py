# coding: utf-8
# Copyright (c) 2016 Fabian Barkhau <fabian.barkhau@gmail.com>
# License: MIT (see LICENSE file)


import pycoin
from pycoin.key import Key
from pycoin.tx import Tx
from pycoin.tx.script import tools
from pycoin.encoding import hash160
from pycoin.tx.pay_to import SUBCLASSES
from pycoin.serialize import b2h, h2b, b2h_rev
from pycoin.tx.pay_to.ScriptType import DEFAULT_PLACEHOLDER_SIGNATURE
from pycoin.tx.pay_to.ScriptType import ScriptType
from pycoin import encoding
from pycoin.tx.script.check_signature import parse_signature_blob
from pycoin.tx.script.der import UnexpectedDER
from pycoin import ecdsa
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


def compile_commit_scriptsig(payer_sig, payee_sig, deposit_script_hex):
    sig_asm = COMMIT_SCRIPTSIG.format(
        payer_sig=payer_sig, payee_sig=payee_sig
    )
    return tools.compile("{0} {1}".format(sig_asm, deposit_script_hex))


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


def sign_deposit(get_tx_func, payer_wif, rawtx):
    tx = _load_tx(get_tx_func, rawtx)
    key = Key.from_text(payer_wif)
    secret_exponents = [key.secret_exponent()]
    hash160_lookup = pycoin.tx.pay_to.build_hash160_lookup(secret_exponents)
    tx.sign(hash160_lookup)
    return tx.as_hex()


def sign_created_commit(get_tx_func, payer_wif, rawtx, deposit_script):
    tx = _load_tx(get_tx_func, rawtx)
    script_bin = h2b(deposit_script)
    expire_time = get_deposit_expire_time(script_bin)
    hash160_lookup, p2sh_lookup = _make_lookups(payer_wif, script_bin)
    hash160_lookup, p2sh_lookup = _make_lookups(payer_wif, script_bin)
    with _DepositScriptHandler(expire_time):
        tx.sign(hash160_lookup, p2sh_lookup=p2sh_lookup,
                spend_type="create_commit", spend_secret=None)
    return tx.as_hex()


def sign_finalize_commit(get_tx_func, payee_wif, rawtx, deposit_script):
    tx = _load_tx(get_tx_func, rawtx)
    script_bin = h2b(deposit_script)
    expire_time = get_deposit_expire_time(script_bin)
    hash160_lookup, p2sh_lookup = _make_lookups(payee_wif, script_bin)
    with _DepositScriptHandler(expire_time):
        tx.sign(hash160_lookup, p2sh_lookup=p2sh_lookup,
                spend_type="finalize_commit", spend_secret=None)
    assert(tx.bad_signature_count() == 0)
    return tx.as_hex()


def sign_revoke_recover(get_tx_func, payer_wif, rawtx,
                        commit_script, revoke_secret):
    return _sign_commit_recover(get_tx_func, payer_wif, rawtx, commit_script,
                                "revoke", None, revoke_secret)


def sign_payout_recover(get_tx_func, payee_wif, rawtx,
                        commit_script, spend_secret):
    return _sign_commit_recover(get_tx_func, payee_wif, rawtx, commit_script,
                                "payout", spend_secret, None)


def sign_change_recover(get_tx_func, payer_wif, rawtx,
                        deposit_script, spend_secret):
    return _sign_deposit_recover(
        get_tx_func, payer_wif, rawtx, deposit_script, "change", spend_secret
    )


def sign_expire_recover(get_tx_func, payer_wif, rawtx, deposit_script):
    return _sign_deposit_recover(
        get_tx_func, payer_wif, rawtx, deposit_script, "expire", None
    )


def _load_tx(get_tx_func, rawtx):
    tx = Tx.from_hex(rawtx)
    for txin in tx.txs_in:
        utxo_tx = Tx.from_hex(get_tx_func(b2h_rev(txin.previous_hash)))
        tx.unspents.append(utxo_tx.txs_out[txin.previous_index])
    return tx


def _sign_deposit_recover(get_tx_func, wif, rawtx, script_hex,
                          spend_type, spend_secret):
    tx = _load_tx(get_tx_func, rawtx)
    script_bin = h2b(script_hex)
    expire_time = get_deposit_expire_time(script_bin)
    hash160_lookup, p2sh_lookup = _make_lookups(wif, script_bin)
    with _DepositScriptHandler(expire_time):
        tx.sign(hash160_lookup, p2sh_lookup=p2sh_lookup,
                spend_type=spend_type, spend_secret=spend_secret)
    assert(tx.bad_signature_count() == 0)
    return tx.as_hex()


def _sign_commit_recover(get_tx_func, wif, rawtx, script_hex, spend_type,
                         spend_secret, revoke_secret):
    tx = _load_tx(get_tx_func, rawtx)
    script_bin = h2b(script_hex)
    delay_time = get_commit_delay_time(script_bin)
    hash160_lookup, p2sh_lookup = _make_lookups(wif, script_bin)
    with _CommitScriptHandler(delay_time):
        tx.sign(hash160_lookup, p2sh_lookup=p2sh_lookup,
                spend_type=spend_type, spend_secret=spend_secret,
                revoke_secret=revoke_secret)
    assert(tx.bad_signature_count() == 0)
    return tx.as_hex()


def _make_lookups(wif, script_bin):
    hash160_lookup = pycoin.tx.pay_to.build_hash160_lookup(
        [pycoin.key.Key.from_text(wif).secret_exponent()]
    )
    p2sh_lookup = pycoin.tx.pay_to.build_p2sh_lookup([script_bin])
    return hash160_lookup, p2sh_lookup


class _AbsCommitScript(ScriptType):

    def __init__(self, delay_time, spend_secret_hash,
                 payee_sec, payer_sec, revoke_secret_hash):
        self.delay_time = delay_time
        self.spend_secret_hash = spend_secret_hash
        self.payee_sec = payee_sec
        self.payer_sec = payer_sec
        self.revoke_secret_hash = revoke_secret_hash
        self.script = compile_commit_script(
            b2h(payer_sec), b2h(payee_sec), spend_secret_hash,
            revoke_secret_hash, delay_time
        )

    @classmethod
    def from_script(cls, script):
        r = cls.match(script)
        if r:
            delay_time = get_commit_delay_time(cls.TEMPLATE)
            spend_secret_hash = b2h(r["PUBKEYHASH_LIST"][0])
            payee_sec = r["PUBKEY_LIST"][0]
            revoke_secret_hash = b2h(r["PUBKEYHASH_LIST"][1])
            payer_sec = r["PUBKEY_LIST"][1]
            obj = cls(delay_time, spend_secret_hash,
                      payee_sec, payer_sec, revoke_secret_hash)
            assert(obj.script == script)
            return obj
        raise ValueError("bad script")

    def solve_payout(self, **kwargs):
        hash160_lookup = kwargs["hash160_lookup"]
        spend_secret = kwargs["spend_secret"]
        private_key = hash160_lookup.get(encoding.hash160(self.payee_sec))
        secret_exponent, public_pair, compressed = private_key
        sig = self._create_script_signature(
            secret_exponent, kwargs["sign_value"], kwargs["signature_type"]
        )
        return tools.compile(PAYOUT_SCRIPTSIG.format(
            sig=b2h(sig), spend_secret=spend_secret
        ))

    def solve_revoke(self, **kwargs):
        hash160_lookup = kwargs["hash160_lookup"]
        revoke_secret = kwargs["revoke_secret"]
        private_key = hash160_lookup.get(encoding.hash160(self.payer_sec))
        secret_exponent, public_pair, compressed = private_key
        sig = self._create_script_signature(
            secret_exponent, kwargs["sign_value"], kwargs["signature_type"]
        )
        return tools.compile(REVOKE_SCRIPTSIG.format(
            sig=b2h(sig), revoke_secret=revoke_secret
        ))

    def solve(self, **kwargs):
        solve_methods = {
            "payout": self.solve_payout,
            "revoke": self.solve_revoke,
        }
        solve_method = solve_methods[kwargs["spend_type"]]
        return solve_method(**kwargs)

    def __repr__(self):
        script_asm = tools.disassemble(self.script)
        return "<CommitScript: {0}".format(script_asm)


class _AbsDepositScript(ScriptType):

    def __init__(self, payer_sec, payee_sec, spend_secret_hash, expire_time):
        self.payer_sec = payer_sec
        self.payee_sec = payee_sec
        self.spend_secret_hash = spend_secret_hash
        self.expire_time = expire_time
        self.script = compile_deposit_script(
            b2h(payer_sec), b2h(payee_sec), spend_secret_hash, expire_time
        )

    @classmethod
    def from_script(cls, script):
        r = cls.match(script)
        if r:
            payer_sec = r["PUBKEY_LIST"][0]
            payee_sec = r["PUBKEY_LIST"][1]
            assert(payer_sec == r["PUBKEY_LIST"][2])
            assert(payer_sec == r["PUBKEY_LIST"][3])
            spend_secret_hash = b2h(r["PUBKEYHASH_LIST"][0])
            expire_time = get_deposit_expire_time(cls.TEMPLATE)
            obj = cls(payer_sec, payee_sec, spend_secret_hash, expire_time)
            assert(obj.script == script)
            return obj
        raise ValueError("bad script")

    def solve_expire(self, **kwargs):
        hash160_lookup = kwargs["hash160_lookup"]
        private_key = hash160_lookup.get(encoding.hash160(self.payer_sec))
        secret_exponent, public_pair, compressed = private_key
        sig = self._create_script_signature(
            secret_exponent, kwargs["sign_value"], kwargs["signature_type"]
        )
        return tools.compile(EXPIRE_SCRIPTSIG.format(sig=b2h(sig)))

    def solve_change(self, **kwargs):
        hash160_lookup = kwargs["hash160_lookup"]
        spend_secret = kwargs["spend_secret"]
        private_key = hash160_lookup.get(encoding.hash160(self.payer_sec))
        secret_exponent, public_pair, compressed = private_key
        sig = self._create_script_signature(
            secret_exponent, kwargs["sign_value"], kwargs["signature_type"]
        )
        spend_secret_hash = get_deposit_spend_secret_hash(self.script)
        provided_spend_secret_hash = b2h(hash160(h2b(spend_secret)))
        assert(spend_secret_hash == provided_spend_secret_hash)
        script_text = CHANGE_SCRIPTSIG.format(
            sig=b2h(sig), secret=spend_secret
        )
        return tools.compile(script_text)

    def solve_create_commit(self, **kwargs):
        hash160_lookup = kwargs["hash160_lookup"]
        private_key = hash160_lookup.get(encoding.hash160(self.payer_sec))
        secret_exponent, public_pair, compressed = private_key
        sig = self._create_script_signature(
            secret_exponent, kwargs["sign_value"], kwargs["signature_type"]
        )
        signature_placeholder = kwargs.get("signature_placeholder",
                                           DEFAULT_PLACEHOLDER_SIGNATURE)
        script_text = COMMIT_SCRIPTSIG.format(
            payer_sig=b2h(sig), payee_sig=b2h(signature_placeholder)
        )
        return tools.compile(script_text)

    def solve_finalize_commit(self, **kwargs):
        hash160_lookup = kwargs.get("hash160_lookup")
        sign_value = kwargs.get("sign_value")
        signature_type = kwargs.get("signature_type")
        existing_script = kwargs.get("existing_script")

        # validate payer sig
        opcode, data, pc = tools.get_opcode(existing_script, 0)  # OP_0
        opcode, payer_sig, pc = tools.get_opcode(existing_script, pc)
        sig_pair, actual_signature_type = parse_signature_blob(payer_sig)
        assert(signature_type == actual_signature_type)
        try:
            public_pair = encoding.sec_to_public_pair(self.payer_sec)
            sig_pair, signature_type = parse_signature_blob(payer_sig)
            valid = ecdsa.verify(ecdsa.generator_secp256k1, public_pair,
                                 sign_value, sig_pair)
            if not valid:
                raise Exception("Invalid payer public_pair!")
        except (encoding.EncodingError, UnexpectedDER):
            raise Exception("Invalid payer public_pair!")

        # sign
        private_key = hash160_lookup.get(encoding.hash160(self.payee_sec))
        secret_exponent, public_pair, compressed = private_key
        payee_sig = self._create_script_signature(
            secret_exponent, sign_value, signature_type
        )

        script_text = COMMIT_SCRIPTSIG.format(
            payer_sig=b2h(payer_sig), payee_sig=b2h(payee_sig)
        )
        return tools.compile(script_text)

    def solve(self, **kwargs):
        solve_methods = {
            "expire": self.solve_expire,
            "change": self.solve_change,
            "create_commit": self.solve_create_commit,
            "finalize_commit": self.solve_finalize_commit
        }
        solve_method = solve_methods[kwargs["spend_type"]]
        return solve_method(**kwargs)

    def __repr__(self):
        script_asm = tools.disassemble(self.script)
        return "<DepositScript: {0}".format(script_asm)


class _CommitScriptHandler():

    def __init__(self, delay_time):
        class CommitScript(_AbsCommitScript):
            TEMPLATE = compile_commit_script(
                "OP_PUBKEY", "OP_PUBKEY", "OP_PUBKEYHASH",
                "OP_PUBKEYHASH", delay_time
            )
        self.script_handler = CommitScript

    def __enter__(self):
        SUBCLASSES.insert(0, self.script_handler)

    def __exit__(self, type, value, traceback):
        SUBCLASSES.pop(0)


class _DepositScriptHandler():

    def __init__(self, expire_time):
        class DepositScript(_AbsDepositScript):
            TEMPLATE = compile_deposit_script(
                "OP_PUBKEY", "OP_PUBKEY",
                "OP_PUBKEYHASH", expire_time
            )
        self.script_handler = DepositScript

    def __enter__(self):
        SUBCLASSES.insert(0, self.script_handler)

    def __exit__(self, type, value, traceback):
        SUBCLASSES.pop(0)
