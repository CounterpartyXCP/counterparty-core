"""
`require_reveal_source_signature` (GHSA-q27c-r246-f6qw).

An inscription reveal is recognised by shape alone and attributed to the address
that funded its commit. Until this change nothing tied that address to the
envelope: an attacker could publish a P2TR address whose hidden leaf carried a
`sweep`, have a victim pay plain BTC to it, and spend the payment in a reveal
that the parser attributed to the victim. A P2WSH output with a three-element
witness worked the same way, without any real signature.

The rule itself lives in `counterparty-rs/src/reveal.rs` and is exhaustively
unit-tested there. These tests build genuine commit/reveal pairs with
`bitcoinutils` and check the Python wiring: the wrapper, the gate, where the
commit output comes from, and that `get_transaction_sources` refuses to name a
source for an unauthorised reveal.
"""

import binascii
import hashlib

import pytest
from bitcoinutils.keys import PrivateKey, PublicKey
from bitcoinutils.script import Script
from bitcoinutils.utils import ControlBlock
from counterpartycore.lib import backend, exceptions
from counterpartycore.lib.parser import gettxinfo, protocol
from counterpartycore.lib.utils import script as script_utils

COMMIT_TXID = "aa" * 32
FUNDING_TXID = "bb" * 32
FAKE_SIGNATURE = "01" * 64
MESSAGE = binascii.hexlify(b"\x04sweep message").decode()


def envelope(leaf_pubkey: PublicKey) -> Script:
    return Script(
        ["OP_FALSE", "OP_IF", MESSAGE, "OP_ENDIF", leaf_pubkey.to_x_only_hex(), "OP_CHECKSIG"]
    )


def commit(internal_pubkey: PublicKey, leaf: Script):
    """(commit scriptPubKey, control block) of the single-leaf tree
    `P2TR(internal_pubkey, [leaf])`."""
    address = internal_pubkey.get_taproot_address([[leaf]])
    control_block = ControlBlock(internal_pubkey, scripts=[leaf], index=0, is_odd=address.is_odd())
    return address.to_script_pub_key().to_hex(), control_block.to_hex()


def p2wpkh(pubkey: PublicKey) -> str:
    return pubkey.get_segwit_address().to_script_pub_key().to_hex()


def p2tr(pubkey: PublicKey) -> str:
    return pubkey.get_taproot_address().to_script_pub_key().to_hex()


def reveal_tx(source_script_pubkey, leaf: Script, control_block: str, is_reveal=True):
    """A decoded reveal transaction whose input 0 already resolves to the
    commit's funder (the Rust rewrite applied), as `gettxinfo` sees it."""
    return {
        "tx_id": "cc" * 32,
        "segwit": True,
        "vtxinwit": [[FAKE_SIGNATURE, leaf.to_hex(), control_block]],
        "vin": [
            {
                "hash": COMMIT_TXID,
                "n": 0,
                "info": {
                    "value": 100000,
                    "script_pub_key": binascii.unhexlify(source_script_pubkey),
                    "is_segwit": True,
                },
            }
        ],
        # (destinations, btc_amount, fee, data, potential_dispensers, is_reveal_tx)
        "parsed_vouts": ([], 0, 0, b"data", [], is_reveal),
    }


@pytest.fixture
def commit_output(monkeypatch):
    """Makes `get_reveal_commit_script_pubkey` return the given commit output
    and records that it was asked."""
    calls = []

    def install(script_pub_key):
        def fake(decoded_tx, no_retry=False):
            calls.append((decoded_tx["vin"][0]["hash"], no_retry))
            return binascii.unhexlify(script_pub_key)

        monkeypatch.setattr(backend.bitcoind, "get_reveal_commit_script_pubkey", fake)
        return calls

    return install


def test_honest_reveal_from_a_p2wpkh_source_is_accepted(commit_output):
    source = PrivateKey(secret_exponent=1).get_public_key()
    leaf = envelope(source)
    commit_spk, control_block = commit(source, leaf)
    calls = commit_output(commit_spk)

    tx = reveal_tx(p2wpkh(source), leaf, control_block)
    gettxinfo.check_reveal_source_signature(tx, tx["vin"][0]["info"]["script_pub_key"])
    assert len(calls) == 1
    assert calls[0][0] == COMMIT_TXID
    assert not calls[0][1]  # not parsing the mempool: retries allowed


def test_honest_reveal_from_a_p2tr_source_is_accepted(commit_output):
    source = PrivateKey(secret_exponent=2).get_public_key()
    # internal key in the envelope, as `composer.get_reveal_source_pubkey`
    # returns it when the wallet provides its key
    leaf = envelope(source)
    commit_spk, control_block = commit(source, leaf)
    commit_output(commit_spk)
    tx = reveal_tx(p2tr(source), leaf, control_block)
    gettxinfo.check_reveal_source_signature(tx, tx["vin"][0]["info"]["script_pub_key"])

    # output key in the envelope, the composer's fallback for an unknown key
    output_key = source.get_taproot_address().to_witness_program()
    output_pubkey = PublicKey.from_hex("02" + output_key)
    leaf = envelope(output_pubkey)
    commit_spk, control_block = commit(output_pubkey, leaf)
    commit_output(commit_spk)
    tx = reveal_tx(p2tr(source), leaf, control_block)
    gettxinfo.check_reveal_source_signature(tx, tx["vin"][0]["info"]["script_pub_key"])


def test_the_reported_p2tr_attack_is_rejected(commit_output):
    """Case A of the advisory: the attacker's key closes the envelope, the
    victim merely paid the commit address."""
    victim = PrivateKey(secret_exponent=3).get_public_key()
    attacker = PrivateKey(secret_exponent=4).get_public_key()
    leaf = envelope(attacker)
    commit_spk, control_block = commit(attacker, leaf)
    commit_output(commit_spk)

    for victim_script_pubkey in (p2wpkh(victim), p2tr(victim)):
        tx = reveal_tx(victim_script_pubkey, leaf, control_block)
        with pytest.raises(exceptions.DecodeError, match="not signed by its source"):
            gettxinfo.check_reveal_source_signature(tx, tx["vin"][0]["info"]["script_pub_key"])


def test_the_reported_p2wsh_attack_is_rejected(commit_output):
    """Case B of the advisory: a P2WSH commit whose witness script is
    `OP_2DROP OP_1`, revealed with a fixed 64-byte first witness element."""
    victim = PrivateKey(secret_exponent=5).get_public_key()
    witness_script = Script(["OP_2DROP", "OP_1"])
    commit_spk = "0020" + hashlib.sha256(witness_script.to_bytes()).hexdigest()
    commit_output(commit_spk)

    tx = reveal_tx(p2wpkh(victim), envelope(victim), witness_script.to_hex())
    with pytest.raises(exceptions.DecodeError, match="not P2TR"):
        gettxinfo.check_reveal_source_signature(tx, tx["vin"][0]["info"]["script_pub_key"])


def test_nothing_is_checked_for_an_ordinary_transaction(monkeypatch):
    def unexpected(*args, **kwargs):
        raise AssertionError("the commit output must not be fetched for a non-reveal")

    monkeypatch.setattr(backend.bitcoind, "get_reveal_commit_script_pubkey", unexpected)
    source = PrivateKey(secret_exponent=6).get_public_key()
    leaf = envelope(source)
    _commit_spk, control_block = commit(source, leaf)
    tx = reveal_tx(p2wpkh(source), leaf, control_block, is_reveal=False)
    gettxinfo.check_reveal_source_signature(tx, tx["vin"][0]["info"]["script_pub_key"])

    # and for a transaction the deserializer could not parse at all
    tx["parsed_vouts"] = "DecodeError"
    gettxinfo.check_reveal_source_signature(tx, tx["vin"][0]["info"]["script_pub_key"])


def test_nothing_is_checked_before_activation(monkeypatch):
    def unexpected(*args, **kwargs):
        raise AssertionError("the commit output must not be fetched before activation")

    monkeypatch.setattr(backend.bitcoind, "get_reveal_commit_script_pubkey", unexpected)
    original_enabled = protocol.enabled
    asked = []

    def gated(change_name, block_index=None):
        if change_name == "require_reveal_source_signature":
            asked.append(block_index)
            return False
        return original_enabled(change_name, block_index)

    monkeypatch.setattr(gettxinfo.protocol, "enabled", gated)
    victim = PrivateKey(secret_exponent=7).get_public_key()
    attacker = PrivateKey(secret_exponent=8).get_public_key()
    leaf = envelope(attacker)
    _commit_spk, control_block = commit(attacker, leaf)
    tx = reveal_tx(p2wpkh(victim), leaf, control_block)
    gettxinfo.check_reveal_source_signature(
        tx, tx["vin"][0]["info"]["script_pub_key"], block_index=971699
    )
    assert asked == [971699]


def test_commit_output_lookup_follows_the_mempool_policy(monkeypatch):
    seen = []

    def fake(decoded_tx, no_retry=False):
        seen.append(no_retry)
        raise exceptions.DecodeError("vin not found")

    monkeypatch.setattr(backend.bitcoind, "get_reveal_commit_script_pubkey", fake)
    monkeypatch.setattr(gettxinfo.CurrentState, "parsing_mempool", lambda self: True)
    source = PrivateKey(secret_exponent=9).get_public_key()
    leaf = envelope(source)
    _commit_spk, control_block = commit(source, leaf)
    tx = reveal_tx(p2wpkh(source), leaf, control_block)
    with pytest.raises(exceptions.DecodeError):
        gettxinfo.check_reveal_source_signature(tx, tx["vin"][0]["info"]["script_pub_key"])
    assert seen == [True]


def test_get_transaction_sources_refuses_an_unauthorised_reveal(commit_output, monkeypatch):
    """The check runs on the *resolved* first input -- the commit's funder --
    before any source is returned, and is skipped while composing (unsigned)."""
    victim = PrivateKey(secret_exponent=10).get_public_key()
    attacker = PrivateKey(secret_exponent=11).get_public_key()
    leaf = envelope(attacker)
    commit_spk, control_block = commit(attacker, leaf)
    commit_output(commit_spk)
    monkeypatch.setattr(
        backend.bitcoind,
        "get_vin_info",
        lambda vin, no_retry=False, prevout=None: (
            vin["info"]["value"],
            vin["info"]["script_pub_key"],
            vin["info"]["is_segwit"],
        ),
    )

    tx = reveal_tx(p2wpkh(victim), leaf, control_block)
    with pytest.raises(exceptions.DecodeError, match="not signed by its source"):
        gettxinfo.get_transaction_sources(tx)
    assert gettxinfo.get_transaction_sources(tx, composing=True) == (
        victim.get_segwit_address().to_string(),
        100000,
    )

    # the honest pair goes through and names the funder
    honest_leaf = envelope(victim)
    honest_commit_spk, honest_control_block = commit(victim, honest_leaf)
    commit_output(honest_commit_spk)
    tx = reveal_tx(p2wpkh(victim), honest_leaf, honest_control_block)
    assert gettxinfo.get_transaction_sources(tx) == (
        victim.get_segwit_address().to_string(),
        100000,
    )


def test_wrapper_accepts_hex_and_bytes():
    source = PrivateKey(secret_exponent=12).get_public_key()
    leaf = envelope(source)
    commit_spk, control_block = commit(source, leaf)
    witness_hex = [FAKE_SIGNATURE, leaf.to_hex(), control_block]
    witness_bytes = [binascii.unhexlify(item) for item in witness_hex]

    assert (
        script_utils.reveal_source_signature_error(commit_spk, p2wpkh(source), witness_hex) is None
    )
    assert (
        script_utils.reveal_source_signature_error(
            binascii.unhexlify(commit_spk), binascii.unhexlify(p2wpkh(source)), witness_bytes
        )
        is None
    )
    other = PrivateKey(secret_exponent=13).get_public_key()
    assert (
        script_utils.reveal_source_signature_error(commit_spk, p2wpkh(other), witness_hex)
        == "envelope key does not belong to the source address"
    )
    assert script_utils.reveal_source_signature_error(commit_spk, p2wpkh(source), []) == (
        "witness has 0 elements, a tapscript reveal has exactly 3"
    )
