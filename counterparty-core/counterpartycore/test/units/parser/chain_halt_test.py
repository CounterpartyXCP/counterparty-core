"""
Regression suite for the "uncaught exception halts the chain" vulnerability class.

Two architectural facts make an uncaught exception fatal for the whole network:

1. `blocks.parse_tx()` wraps any exception raised by a message handler into
   `exceptions.ParseTransactionError`, and `blocks.parse_block()` deliberately
   re-raises it (note the commented-out `# pass`). So *any* unexpected raise
   inside any `parse()` stops block ingestion.
2. `gettxinfo.get_tx_info()` historically caught only `DecodeError` and
   `BTCOnlyError`, and `blocks.list_tx()` has no try/except at all, so a parse
   level exception of any other type escaped raw.

Both mean the same outcome: every node halts at the same block, restarts, halts
again. A single cheap, consensus-valid transaction is enough. The cases below
were reported privately (GHSA-pmfx-7qj5-fx6c) and each one is checked here
against the *fixed* behaviour: the crafted transaction must be parsed as
invalid / non-Counterparty, never raise.

All fixtures are synthetic (regtest, mocked bitcoind); nothing touches a
network.
"""

import binascii
import struct

import cbor2
import pytest
from arc4 import ARC4
from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages import bet, broadcast, dispenser, fairminter
from counterpartycore.lib.parser import blocks, deserialize, gettxinfo
from counterpartycore.lib.utils import address as address_utils
from counterpartycore.test.mocks.bitcoind import mine_block
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled

# Prevout txid of vin[0]; doubles as the ARC4 key of every output.
PREV_TXID = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
ARC4_KEY = binascii.unhexlify(PREV_TXID)

# `\x0d` == dispenser.DISPENSE_ID; the trailing byte is required because
# messagetype.unpack() only reads a short message-type id when len(data) > 1.
DISPENSE_PREFIX_PAYLOAD = b"\x0d\x00"


def prefix():
    assert len(config.PREFIX) == 8
    return config.PREFIX


def sig_script_sig():
    """scriptSig carrying one 72-byte mock-DER signature, so that
    check_signatures_sighash_flag() finds a SIGHASH_ALL flag."""
    sig = b"\x30" * 71 + b"\x01"
    return bytes([len(sig)]) + sig


def build_raw_tx(script_sig, outputs):
    """1-input raw transaction with the given scriptSig and (value, spk) outputs."""
    tx = struct.pack("<I", 1)
    tx += b"\x01"
    tx += binascii.unhexlify(PREV_TXID)[::-1]
    tx += struct.pack("<I", 0)
    tx += bytes([len(script_sig)]) + script_sig
    tx += b"\xff\xff\xff\xff"
    tx += bytes([len(outputs)])
    for value, spk in outputs:
        tx += struct.pack("<Q", value)
        tx += bytes([len(spk)]) + spk
    tx += struct.pack("<I", 0)
    return binascii.hexlify(tx).decode()


def op_return_output(message_bytes):
    payload = ARC4(ARC4_KEY).encrypt(prefix() + message_bytes)
    return 0, b"\x6a" + bytes([len(payload)]) + payload


def deserialize_crafted_tx(current_block_index, blockchain_mock, defaults, raw_tx):
    deserialize.Deserializer.reset_instance()
    blockchain_mock.source_by_txid[PREV_TXID] = defaults["addresses"][0]
    decoded_tx = deserialize.deserialize_tx(
        raw_tx, parse_vouts=True, block_index=current_block_index
    )
    assert not isinstance(decoded_tx["parsed_vouts"], Exception), decoded_tx["parsed_vouts"]
    return decoded_tx


def oracle_broadcast(
    ledger_db,
    blockchain_mock,
    oracle,
    timestamp,
    value,
    fee_fraction_int,
    text=b"XCP-USD",
    use_first_tx=False,
):
    """Run the production broadcast.parse() with a CBOR (post-taproot) message and
    return the stored row. `use_first_tx` picks a different carrier transaction so
    that two broadcasts from the same source do not collide on `tx_index`."""
    tx = blockchain_mock.dummy_tx(ledger_db, oracle, use_first_tx=use_first_tx)
    message = cbor2.dumps([timestamp, value, fee_fraction_int, "text/plain", text])
    broadcast.parse(ledger_db, tx, message)
    return (
        ledger_db.cursor()
        .execute("SELECT * FROM broadcasts ORDER BY rowid DESC LIMIT 1")
        .fetchone()
    )


def count_dispensers(ledger_db):
    return ledger_db.cursor().execute("SELECT COUNT(*) AS n FROM dispensers").fetchone()["n"]


def open_oracle_dispenser_message(oracle):
    asset_id = ledger.issuances.generate_asset_id(config.XCP)
    return struct.pack(">QQQQB", asset_id, 100, 100, 10_000, 0) + address_utils.pack_legacy(oracle)


# ---------------------------------------------------------------------------
# C1 -- `None` element in potential_dispensers (Rust `Option<PotentialDispenser>`
# crossing the PyO3 boundary) subscripted by the Python consumers.
# ---------------------------------------------------------------------------
def poison_pubkeyhash():
    """20-byte pubkeyhash whose ARC4 plaintext is `\\x00` + CNTRPRTY + junk: the
    prefix is present at bytes 1..=8 but the length byte is < len(prefix), which
    takes the short-data early return of parse_vout()."""
    plaintext = b"\x00" + prefix() + b"JUNKJUNKJUN"
    assert len(plaintext) == 20
    return ARC4(ARC4_KEY).encrypt(plaintext)


def test_c1_none_dispenser_element_is_skipped():
    """get_dispensers_tx_info() must skip a None element instead of subscripting it."""
    assert gettxinfo.get_dispensers_tx_info("some_source", [None]) == (
        b"",
        None,
        None,
        None,
        None,
        [],
    )


def test_c1_none_dispenser_output_is_skipped(ledger_db):
    """get_dispensers_outputs() must skip a None element instead of unpacking it."""
    assert gettxinfo.get_dispensers_outputs(ledger_db, [None, (None, None)]) == []


def test_c1_rust_never_emits_a_none_dispenser_slot(
    ledger_db, current_block_index, blockchain_mock, defaults
):
    """End-to-end: the deserializer must not put a bare None in potential_dispensers,
    and the transaction must parse as a plain non-Counterparty transaction."""
    spk = b"\x76\xa9\x14" + poison_pubkeyhash() + b"\x88\xac"
    raw_tx = build_raw_tx(
        sig_script_sig(),
        [(546, spk), op_return_output(DISPENSE_PREFIX_PAYLOAD)],
    )
    decoded_tx = deserialize_crafted_tx(current_block_index, blockchain_mock, defaults, raw_tx)

    _destinations, _btc_amount, _fee, data, potential_dispensers, _is_reveal = decoded_tx[
        "parsed_vouts"
    ]
    assert data == DISPENSE_PREFIX_PAYLOAD, data
    assert None not in potential_dispensers, potential_dispensers

    source, _destination, _btc_amount, _fee, _data, _outs, _utxos_info = gettxinfo.get_tx_info(
        ledger_db, decoded_tx, current_block_index
    )
    assert source == b""
    mine_block(ledger_db, [decoded_tx])


# ---------------------------------------------------------------------------
# C2 -- ZeroDivisionError opening an oracle dispenser on a zero-price oracle
# (dispenser.py `oracle_mainchainrate / last_price`).
# ---------------------------------------------------------------------------
def test_c2_zero_price_oracle_dispenser(ledger_db, blockchain_mock, defaults):
    oracle = defaults["addresses"][1]
    row = oracle_broadcast(ledger_db, blockchain_mock, oracle, 1_700_000_000, 0, 0)
    assert row["status"] == "valid"
    assert row["value"] == 0  # a zero-price broadcast is, and stays, valid

    before = count_dispensers(ledger_db)
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], destination=oracle, btc_amount=10**8
    )
    dispenser.parse(ledger_db, tx, open_oracle_dispenser_message(oracle))
    # No price at all -> the dispenser is rejected, not a crash.
    assert count_dispensers(ledger_db) == before
    assert count_dispensers(ledger_db) == before


# ---------------------------------------------------------------------------
# C3 -- TypeError from a NULL `fee_fraction_int` (NaN float bound as NULL by
# sqlite3) in calculate_oracle_fee().
# ---------------------------------------------------------------------------
def test_c3_nan_fee_fraction_broadcast_is_rejected(ledger_db, blockchain_mock, defaults):
    """Root cause: after `reject_non_finite_broadcast` a NaN field never reaches
    the database at all."""
    row = oracle_broadcast(
        ledger_db, blockchain_mock, defaults["addresses"][1], 1_700_000_000, 1.0, float("nan")
    )
    assert row["status"] == "invalid: non-finite numeric value", row["status"]


def test_c3_null_fee_fraction_oracle_dispenser(ledger_db, blockchain_mock, defaults):
    oracle = defaults["addresses"][1]
    # Before the activation height a NaN `fee_fraction_int` validates as "valid"
    # (every comparison against NaN is False) and sqlite3 binds it as NULL. Such
    # rows can already be on chain, so the consumer must cope on its own.
    with ProtocolChangesDisabled(["reject_non_finite_broadcast"]):
        row = oracle_broadcast(ledger_db, blockchain_mock, oracle, 1_700_000_000, 1.0, float("nan"))
    assert row["status"] == "valid", row["status"]
    assert row["fee_fraction_int"] is None

    before = count_dispensers(ledger_db)
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], destination=oracle, btc_amount=10**8
    )
    dispenser.parse(ledger_db, tx, open_oracle_dispenser_message(oracle))
    # The dispenser opens with no oracle fee instead of halting the chain.
    assert count_dispensers(ledger_db) == before + 1


# ---------------------------------------------------------------------------
# C4 -- decimal.InvalidOperation comparing a NaN `minted_asset_commission`.
# ---------------------------------------------------------------------------
def nan_fairminter_message():
    asset_id = ledger.issuances.generate_asset_id("NANCRASH")
    return cbor2.dumps(
        [
            asset_id,
            0,  # asset_parent_id
            0,  # price
            1,  # quantity_by_price
            0,  # max_mint_per_tx
            0,  # max_mint_per_address
            0,  # hard_cap
            0,  # premint_quantity
            0,  # start_block
            0,  # end_block
            0,  # soft_cap
            0,  # soft_cap_deadline_block
            float("nan"),  # minted_asset_commission_int  <-- the poison
            False,  # burn_payment
            False,  # lock_description
            False,  # lock_quantity
            True,  # divisible
        ]
    )


def test_c4_fairminter_nan_commission_handler(ledger_db, blockchain_mock, defaults):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    fairminter.parse(ledger_db, tx, nan_fairminter_message())

    row = (
        ledger_db.cursor()
        .execute("SELECT status FROM fairminters ORDER BY rowid DESC LIMIT 1")
        .fetchone()
    )
    assert row is not None
    assert "must be a number" in row["status"], row["status"]


def test_c4_fairminter_nan_commission_block_ingestion(
    ledger_db, current_block_index, blockchain_mock, defaults
):
    raw_tx = build_raw_tx(
        sig_script_sig(),
        [op_return_output(b"\x5a" + nan_fairminter_message())],  # 0x5a == fairminter.ID
    )
    decoded_tx = deserialize_crafted_tx(current_block_index, blockchain_mock, defaults, raw_tx)
    assert decoded_tx["parsed_vouts"][3][0] == fairminter.ID
    mine_block(ledger_db, [decoded_tx])


def test_c4_fairminter_infinite_commission_status_unchanged(ledger_db, blockchain_mock, defaults):
    """+/-inf must keep its historical status string: it compares fine, never
    crashed, and so may exist in a parsed block."""
    message = cbor2.loads(nan_fairminter_message())
    message[12] = float("inf")
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    fairminter.parse(ledger_db, tx, cbor2.dumps(message))

    row = (
        ledger_db.cursor()
        .execute("SELECT status FROM fairminters ORDER BY rowid DESC LIMIT 1")
        .fetchone()
    )
    assert "must be less than 0 or greater than or equal to 1" in row["status"], row["status"]


# ---------------------------------------------------------------------------
# C5 -- TypeError comparing a NULL broadcast timestamp in bet.validate().
# ---------------------------------------------------------------------------
def test_c5_null_timestamp_bet(ledger_db, blockchain_mock, defaults):
    oracle = defaults["addresses"][1]
    with ProtocolChangesDisabled(["reject_non_finite_broadcast"]):
        row = oracle_broadcast(ledger_db, blockchain_mock, oracle, float("nan"), 1.0, 5_000_000)
    assert row["status"] == "valid", row["status"]
    assert row["timestamp"] is None
    assert row["text"]  # not a "lock" broadcast: bet.validate() reaches the deadline check

    # bet_type=2 (Equal), FORMAT ">HIQQdII"
    message = struct.pack(">HIQQdII", 2, 1_800_000_000, 1000, 1000, 1.0, 5040, 100)
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], destination=oracle)
    bet.parse(ledger_db, tx, message)

    bet_row = (
        ledger_db.cursor().execute("SELECT status FROM bets ORDER BY rowid DESC LIMIT 1").fetchone()
    )
    assert bet_row is not None
    assert "no usable timestamp" in bet_row["status"], bet_row["status"]


# ---------------------------------------------------------------------------
# C6 -- TypeError in collect_sighash_flags(): script.script_to_asm() rewrites
# asm[0] and asm[-2] into ints whenever the last element is b"\xae", and the Rust
# renderer emits a *pushed* 0xae byte identically to the OP_CHECKMULTISIG opcode.
# ---------------------------------------------------------------------------
def test_c6_int_typed_asm_element(ledger_db, current_block_index, blockchain_mock, defaults):
    # scriptSig = OP_0 OP_0 <push 0xae>: push-only, relay-standard when spending
    # a bare OP_TRUE or a 0-of-0 P2SH-CHECKMULTISIG output.
    raw_tx = build_raw_tx(b"\x00\x00\x01\xae", [op_return_output(DISPENSE_PREFIX_PAYLOAD)])
    decoded_tx = deserialize_crafted_tx(current_block_index, blockchain_mock, defaults, raw_tx)

    source, _destination, _btc_amount, _fee, _data, _outs, _utxos_info = gettxinfo.get_tx_info(
        ledger_db, decoded_tx, current_block_index
    )
    assert source == b""
    mine_block(ledger_db, [decoded_tx])


def test_c6_der_sighash_flag_rejects_non_bytes():
    assert gettxinfo.get_der_signature_sighash_flag(0xAE) is None


# ---------------------------------------------------------------------------
# H4 -- MultiSigAddressError (an AddressError, *not* a DecodeError) escaping
# get_tx_info() for a bare-multisig prevout with m outside 1..3.
# ---------------------------------------------------------------------------
def test_h4_bare_multisig_m0_prevout(
    ledger_db, current_block_index, blockchain_mock, defaults, monkeypatch
):
    assert not issubclass(exceptions.MultiSigAddressError, exceptions.DecodeError)

    pk1 = b"\x02" + b"\x11" * 32
    pk2 = b"\x02" + b"\x22" * 32
    # The ARC4-decrypted detection chunk must NOT carry the prefix, so that
    # decode_checkmultisig() takes the destination branch and builds an address.
    chunk = ARC4(ARC4_KEY).decrypt(pk1[1:-1])
    assert chunk[1 : len(prefix()) + 1] != prefix()

    # OP_0 <33B pk1> <33B pk2> OP_2 OP_CHECKMULTISIG -> signatures_required = 0
    prevout_spk = (b"\x00" + b"\x21" + pk1 + b"\x21" + pk2 + b"\x52\xae").hex()
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.get_vin_info",
        lambda vin, no_retry=False, prevout=None: (int(10 * config.UNIT), prevout_spk, False),
    )

    raw_tx = build_raw_tx(sig_script_sig(), [op_return_output(DISPENSE_PREFIX_PAYLOAD)])
    decoded_tx = deserialize_crafted_tx(current_block_index, blockchain_mock, defaults, raw_tx)

    source, _destination, _btc_amount, _fee, _data, _outs, _utxos_info = gettxinfo.get_tx_info(
        ledger_db, decoded_tx, current_block_index
    )
    assert source == b""
    mine_block(ledger_db, [decoded_tx])


# ---------------------------------------------------------------------------
# The safety net itself: data errors are absorbed, infrastructure errors are not.
# ---------------------------------------------------------------------------
def test_malformed_transaction_errors_are_absorbed(
    ledger_db, current_block_index, blockchain_mock, defaults, monkeypatch
):
    raw_tx = build_raw_tx(sig_script_sig(), [op_return_output(b"\x0a" + b"\x00" * 32)])
    decoded_tx = deserialize_crafted_tx(current_block_index, blockchain_mock, defaults, raw_tx)

    def boom(*_args, **_kwargs):
        raise ZeroDivisionError("crafted")

    monkeypatch.setattr(gettxinfo, "_get_tx_info", boom)
    source, *_rest = gettxinfo.get_tx_info(ledger_db, decoded_tx, current_block_index)
    assert source == b""


def test_backend_errors_still_propagate(
    ledger_db, current_block_index, blockchain_mock, defaults, monkeypatch
):
    """A failed prevout lookup must NEVER be mistaken for "not a Counterparty
    transaction": silently dropping a confirmed transaction forks the ledger
    permanently (block 510556)."""
    raw_tx = build_raw_tx(sig_script_sig(), [op_return_output(b"\x0a" + b"\x00" * 32)])
    decoded_tx = deserialize_crafted_tx(current_block_index, blockchain_mock, defaults, raw_tx)

    def boom(*_args, **_kwargs):
        raise exceptions.BitcoindRPCError("backend down")

    monkeypatch.setattr(gettxinfo, "_get_tx_info", boom)
    with pytest.raises(exceptions.BitcoindRPCError):
        gettxinfo.get_tx_info(ledger_db, decoded_tx, current_block_index)


# ---------------------------------------------------------------------------
# Locked feeds: broadcast.parse() blanks `text`, `value` and `fee_fraction_int`
# while keeping status "valid", so every oracle reader must tolerate NULLs.
# ---------------------------------------------------------------------------
def test_locked_oracle_feed_does_not_halt(ledger_db, blockchain_mock, defaults):
    oracle = defaults["addresses"][1]
    oracle_broadcast(ledger_db, blockchain_mock, oracle, 1_700_000_000, 1.0, 0, use_first_tx=True)
    row = oracle_broadcast(ledger_db, blockchain_mock, oracle, 1_700_000_001, 1.0, 0, text=b"lock")
    assert row["status"] == "valid"
    assert row["text"] is None and row["value"] is None

    # get_oracle_last_price() used to call .split() on the NULL text.
    assert ledger.other.get_oracle_last_price(
        ledger_db, oracle, blocks.CurrentState().current_block_index()
    ) == (None, None, "", row["block_index"])

    before = count_dispensers(ledger_db)
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], destination=oracle, btc_amount=10**8
    )
    dispenser.parse(ledger_db, tx, open_oracle_dispenser_message(oracle))
    # No price at all -> the dispenser is rejected, not a crash.
    assert count_dispensers(ledger_db) == before
