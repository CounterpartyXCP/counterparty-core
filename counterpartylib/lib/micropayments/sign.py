# coding: utf-8
# Copyright (c) 2016 Fabian Barkhau <fabian.barkhau@gmail.com>
# License: MIT (see LICENSE file)


import pycoin
from pycoin.tx.script import tools
from pycoin.encoding import hash160
from pycoin.tx.pay_to import SUBCLASSES
from pycoin.serialize import b2h, h2b
from pycoin.tx.pay_to.ScriptType import DEFAULT_PLACEHOLDER_SIGNATURE
from pycoin.tx.pay_to.ScriptType import ScriptType
from pycoin import encoding
from pycoin.tx.script.check_signature import parse_signature_blob
from pycoin.tx.script.der import UnexpectedDER
from pycoin import ecdsa
from . import util
from . import scripts


def deposit(btctxstore, payer_wif, rawtx):
    return btctxstore.sign_tx(rawtx, [payer_wif])


def created_commit(btctxstore, payer_wif, rawtx, deposit_script):
    tx = _load_tx(btctxstore, rawtx)
    script_bin = h2b(deposit_script)
    expire_time = scripts.get_deposit_expire_time(script_bin)
    hash160_lookup, p2sh_lookup = _make_lookups(payer_wif, script_bin)
    hash160_lookup, p2sh_lookup = _make_lookups(payer_wif, script_bin)
    with _DepositScriptHandler(expire_time):
        tx.sign(hash160_lookup, p2sh_lookup=p2sh_lookup,
                spend_type="create_commit", spend_secret=None)
    return tx.as_hex()


def finalize_commit(btctxstore, payee_wif, rawtx, deposit_script):
    tx = _load_tx(btctxstore, rawtx)
    script_bin = h2b(deposit_script)
    expire_time = scripts.get_deposit_expire_time(script_bin)
    hash160_lookup, p2sh_lookup = _make_lookups(payee_wif, script_bin)
    with _DepositScriptHandler(expire_time):
        tx.sign(hash160_lookup, p2sh_lookup=p2sh_lookup,
                spend_type="finalize_commit", spend_secret=None)
    assert(tx.bad_signature_count() == 0)
    return tx.as_hex()


def revoke_recover(btctxstore, payer_wif, rawtx, commit_script, revoke_secret):
    return _sign_commit_recover(btctxstore, payer_wif, rawtx, commit_script,
                                "revoke", None, revoke_secret)


def payout_recover(btctxstore, payee_wif, rawtx, commit_script, spend_secret):
    return _sign_commit_recover(btctxstore, payee_wif, rawtx, commit_script,
                                "payout", spend_secret, None)


def change_recover(btctxstore, payer_wif, rawtx, deposit_script, spend_secret):
    return _sign_deposit_recover(
        btctxstore, payer_wif, rawtx, deposit_script, "change", spend_secret
    )


def expire_recover(btctxstore, payer_wif, rawtx, deposit_script):
    return _sign_deposit_recover(
        btctxstore, payer_wif, rawtx, deposit_script, "expire", None
    )


def _load_tx(btctxstore, rawtx):
    # FIXME remove this so btctxstore is not required!
    tx = pycoin.tx.Tx.from_hex(rawtx)
    for txin in tx.txs_in:
        utxo_tx = btctxstore.service.get_tx(txin.previous_hash)
        tx.unspents.append(utxo_tx.txs_out[txin.previous_index])
    return tx


def _sign_deposit_recover(btctxstore, wif, rawtx, script_hex,
                          spend_type, spend_secret):
    tx = _load_tx(btctxstore, rawtx)
    script_bin = h2b(script_hex)
    expire_time = scripts.get_deposit_expire_time(script_bin)
    hash160_lookup, p2sh_lookup = _make_lookups(wif, script_bin)
    with _DepositScriptHandler(expire_time):
        tx.sign(hash160_lookup, p2sh_lookup=p2sh_lookup,
                spend_type=spend_type, spend_secret=spend_secret)
    assert(tx.bad_signature_count() == 0)
    return tx.as_hex()


def _sign_commit_recover(btctxstore, wif, rawtx, script_hex, spend_type,
                         spend_secret, revoke_secret):
    tx = _load_tx(btctxstore, rawtx)
    script_bin = h2b(script_hex)
    delay_time = scripts.get_commit_delay_time(script_bin)
    hash160_lookup, p2sh_lookup = _make_lookups(wif, script_bin)
    with _CommitScriptHandler(delay_time):
        tx.sign(hash160_lookup, p2sh_lookup=p2sh_lookup,
                spend_type=spend_type, spend_secret=spend_secret,
                revoke_secret=revoke_secret)
    assert(tx.bad_signature_count() == 0)
    return tx.as_hex()


def _make_lookups(wif, script_bin):
    hash160_lookup = pycoin.tx.pay_to.build_hash160_lookup(
        [util.wif2secretexponent(wif)]
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
        self.script = scripts.compile_commit_script(
            b2h(payer_sec), b2h(payee_sec), spend_secret_hash,
            revoke_secret_hash, delay_time
        )

    @classmethod
    def from_script(cls, script):
        r = cls.match(script)
        if r:
            delay_time = scripts.get_commit_delay_time(cls.TEMPLATE)
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
        return tools.compile(scripts.PAYOUT_SCRIPTSIG.format(
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
        return tools.compile(scripts.REVOKE_SCRIPTSIG.format(
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
        script_text = tools.disassemble(self.script)
        return "<CommitScript: {0}".format(script_text)


class _AbsDepositScript(ScriptType):

    def __init__(self, payer_sec, payee_sec, spend_secret_hash, expire_time):
        self.payer_sec = payer_sec
        self.payee_sec = payee_sec
        self.spend_secret_hash = spend_secret_hash
        self.expire_time = expire_time
        self.script = scripts.compile_deposit_script(
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
            expire_time = scripts.get_deposit_expire_time(cls.TEMPLATE)
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
        return tools.compile(scripts.EXPIRE_SCRIPTSIG.format(sig=b2h(sig)))

    def solve_change(self, **kwargs):
        hash160_lookup = kwargs["hash160_lookup"]
        spend_secret = kwargs["spend_secret"]
        private_key = hash160_lookup.get(encoding.hash160(self.payer_sec))
        secret_exponent, public_pair, compressed = private_key
        sig = self._create_script_signature(
            secret_exponent, kwargs["sign_value"], kwargs["signature_type"]
        )
        spend_secret_hash = scripts.get_deposit_spend_secret_hash(self.script)
        provided_spend_secret_hash = b2h(hash160(h2b(spend_secret)))
        assert(spend_secret_hash == provided_spend_secret_hash)
        script_text = scripts.CHANGE_SCRIPTSIG.format(
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
        script_text = scripts.COMMIT_SCRIPTSIG.format(
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

        script_text = scripts.COMMIT_SCRIPTSIG.format(
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
        script_text = tools.disassemble(self.script)
        return "<DepositScript: {0}".format(script_text)


class _CommitScriptHandler():

    def __init__(self, delay_time):
        class CommitScript(_AbsCommitScript):
            TEMPLATE = scripts.compile_commit_script(
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
            TEMPLATE = scripts.compile_deposit_script(
                "OP_PUBKEY", "OP_PUBKEY",
                "OP_PUBKEYHASH", expire_time
            )
        self.script_handler = DepositScript

    def __enter__(self):
        SUBCLASSES.insert(0, self.script_handler)

    def __exit__(self, type, value, traceback):
        SUBCLASSES.pop(0)
