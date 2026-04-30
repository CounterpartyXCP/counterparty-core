"""
Targeted CBOR fuzz for parse paths reachable post-taproot_support.

Tests whether CBOR-encoded messages with non-int / non-bytes / None
fields trigger halts that byte-level fuzz missed. Covers the message
types whose parse() we hardened on this branch (issuance + subasset,
broadcast, enhanced send, sweep). Each test runs 100 Hypothesis
examples; default deadline=None so slow CBOR-decode paths don't
spuriously fail.

These tests are how we caught (and continue to guard against) the
CBOR-only halt-vector class -- the bugs that opened up when
taproot_support activated and message bodies stopped being struct-
typed. If a future change re-introduces an uncaught exception in any
of these parse paths, these tests fail loudly.

Run: hatch run pytest counterpartycore/test/units/messages/fuzz_cbor_test.py
"""

import apsw
import cbor2
import pytest
from hypothesis import HealthCheck, given, settings, strategies as st

from counterpartycore.lib.messages import (
    broadcast,
    dispense,
    issuance,
    sweep,
)
from counterpartycore.lib.messages.versions import enhancedsend, mpma


# Generate values with mixed valid / adversarial types. CBOR can carry any
# of these; struct format would have rejected most.
any_scalar = st.one_of(
    st.integers(min_value=0, max_value=2**64 - 1),
    st.integers(min_value=-(2**63), max_value=2**63),  # possibly-negative
    st.booleans(),
    st.text(max_size=32),
    st.binary(max_size=32),
    st.floats(allow_nan=False, allow_infinity=False, width=32),
    st.none(),
)


def issuance_cbor_tuple():
    # 7-tuple for standard issuance: (asset_id, quantity, divisible, lock,
    # reset, mime_type, description)
    return st.tuples(
        any_scalar,
        any_scalar,
        any_scalar,
        any_scalar,
        any_scalar,
        any_scalar,
        any_scalar,
    )


def subasset_cbor_tuple():
    # 9-tuple for subasset
    return st.tuples(
        any_scalar,
        any_scalar,
        any_scalar,
        any_scalar,
        any_scalar,
        st.integers(min_value=0, max_value=20),  # compacted_length
        st.binary(max_size=20),  # compacted_longname
        any_scalar,
        any_scalar,
    )


def broadcast_cbor_tuple():
    # 5-tuple: (timestamp, value, fee_fraction_int, mime_type, text_bytes)
    # This is the bug_009 attack surface that ultrareview caught.
    return st.tuples(
        any_scalar,
        any_scalar,
        any_scalar,
        any_scalar,
        any_scalar,
    )


def enhanced_send_cbor_tuple():
    # 4-tuple: (asset_id, quantity, short_address_bytes, memo_bytes)
    return st.tuples(any_scalar, any_scalar, any_scalar, any_scalar)


def sweep_cbor_tuple():
    # 3-tuple: (short_address_bytes, flags, memo_bytes)
    return st.tuples(any_scalar, any_scalar, any_scalar)


# Hypothesis settings — function-scoped fixtures (ledger_db, blockchain_mock)
# necessary because each example needs a fresh tx context.
fuzz_settings = settings(
    max_examples=100,
    deadline=None,
    suppress_health_check=[HealthCheck.function_scoped_fixture],
)


@fuzz_settings
@given(issuance_cbor_tuple())
def test_cbor_issuance_no_halt(ledger_db, blockchain_mock, defaults, tup):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    try:
        message = cbor2.dumps(tup)
    except Exception:
        return  # cbor2 encoding rejected; nothing to test
    try:
        issuance.parse(ledger_db, tx, message, issuance.ID)
    except apsw.ConstraintError:
        pass  # repeated tx_hash artifact across examples
    except Exception as exc:
        pytest.fail(f"issuance.parse raised {type(exc).__name__}: {exc}")


@fuzz_settings
@given(subasset_cbor_tuple())
def test_cbor_subasset_no_halt(ledger_db, blockchain_mock, defaults, tup):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    try:
        message = cbor2.dumps(tup)
    except Exception:
        return
    try:
        issuance.parse(ledger_db, tx, message, issuance.SUBASSET_ID)
    except apsw.ConstraintError:
        pass
    except Exception as exc:
        pytest.fail(f"issuance.parse(SUBASSET) raised {type(exc).__name__}: {exc}")


@fuzz_settings
@given(broadcast_cbor_tuple())
def test_cbor_broadcast_no_halt(ledger_db, blockchain_mock, defaults, tup):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    try:
        message = cbor2.dumps(tup)
    except Exception:
        return
    try:
        broadcast.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass
    except Exception as exc:
        pytest.fail(f"broadcast.parse raised {type(exc).__name__}: {exc}")


@fuzz_settings
@given(enhanced_send_cbor_tuple())
def test_cbor_enhanced_send_no_halt(ledger_db, blockchain_mock, defaults, tup):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    try:
        message = cbor2.dumps(tup)
    except Exception:
        return
    try:
        enhancedsend.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass
    except Exception as exc:
        pytest.fail(f"enhancedsend.parse raised {type(exc).__name__}: {exc}")


@fuzz_settings
@given(sweep_cbor_tuple())
def test_cbor_sweep_no_halt(ledger_db, blockchain_mock, defaults, tup):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    try:
        message = cbor2.dumps(tup)
    except Exception:
        return
    try:
        sweep.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass
    except Exception as exc:
        pytest.fail(f"sweep.parse raised {type(exc).__name__}: {exc}")
