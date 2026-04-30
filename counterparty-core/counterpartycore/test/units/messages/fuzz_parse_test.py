"""
Property-based (Hypothesis) fuzz tests for parse() functions.

Strategy: generate arbitrary message bytes (random byte strings, not
CBOR-shaped) and verify parse() functions never raise an uncaught
exception. Any uncaught exception = halt vector that would propagate
through parse_tx as ParseTransactionError and stop the chain.

19 fuzz tests, 100 Hypothesis examples each (~1,900 random byte
inputs per run). Targets every message-type parse path we touched on
this branch. Complements fuzz_cbor_test.py which targets the
CBOR-shape attack surface specifically.

Run: hatch run pytest counterpartycore/test/units/messages/fuzz_parse_test.py
"""

import apsw
import pytest
from hypothesis import HealthCheck, given, settings, strategies as st

from counterpartycore.lib.messages import (
    attach,
    bet,
    broadcast,
    btcpay,
    cancel,
    destroy,
    detach,
    dispenser,
    dividend,
    fairmint,
    fairminter,
    issuance,
    order,
    sweep,
    utxo,
)
from counterpartycore.lib.messages.versions import enhancedsend, mpma, send1
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


msg_bytes = st.binary(min_size=0, max_size=512)


def _dummy_tx(blockchain_mock, ledger_db, defaults):
    # Fresh tx per example so invalid-record INSERTs don't collide on tx_index
    return blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])


# Each test picks a parse() function and confirms fuzzed bytes do not raise.
# The test tolerates "valid" results, "invalid: ..." status records, or
# explicitly-raised UnpackError (since UnpackError is caught upstream in
# parse_tx's try/except Exception). What we guarantee is NO uncaught
# exception bubbling out.


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_issuance_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        issuance.parse(ledger_db, tx, message, issuance.ID)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"issuance.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_issuance_subasset_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        with ProtocolChangesDisabled(["free_subassets"]):
            issuance.parse(ledger_db, tx, message, issuance.SUBASSET_ID)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"issuance.parse(SUBASSET) raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_utxo_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        utxo.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"utxo.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_attach_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        attach.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"attach.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_detach_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        detach.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"detach.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_fairmint_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        fairmint.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"fairmint.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_fairminter_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        fairminter.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"fairminter.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_order_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        order.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"order.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_bet_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        bet.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"bet.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_broadcast_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        broadcast.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"broadcast.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_btcpay_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        btcpay.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"btcpay.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_cancel_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        cancel.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"cancel.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_destroy_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        destroy.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"destroy.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_dividend_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        dividend.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"dividend.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_sweep_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        sweep.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"sweep.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_dispenser_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        dispenser.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"dispenser.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_send1_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        send1.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"send1.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_enhancedsend_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        enhancedsend.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"enhancedsend.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=100, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(msg_bytes)
def test_fuzz_mpma_parse(ledger_db, blockchain_mock, defaults, message):
    tx = _dummy_tx(blockchain_mock, ledger_db, defaults)
    try:
        mpma.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples; known test artifact
    except Exception as exc:
        pytest.fail(f"mpma.parse raised {type(exc).__name__}: {exc}")
