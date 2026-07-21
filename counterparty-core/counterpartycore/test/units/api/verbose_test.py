"""Tests for counterpartycore.lib.api.verbose helpers.

Focuses on PR-touched helpers:
- normalize_price now uses decimal.localcontext() so prec doesn't leak
  to the calling thread (consensus-split footgun if anyone imports
  helpers.divide into a parse path).
- clean_api_result branch coverage (dict / list / primitive).
"""

import decimal
import threading

from counterpartycore.lib.api import verbose


def test_normalize_price_basic():
    assert verbose.normalize_price(1) == "1.0000000000000000"
    assert verbose.normalize_price("0.5") == "0.5000000000000000"


def test_normalize_price_custom_precision():
    assert verbose.normalize_price("0.5", precision=4) == "0.5000"
    assert verbose.normalize_price("1.234567", precision=2) == "1.23"


def test_inject_normalized_quantities_adds_market_price_normalized():
    result = verbose.inject_normalized_quantities(
        [
            {
                "give_quantity": 100000000,
                "get_quantity": 50000000,
                "give_asset_info": {"divisible": True},
                "get_asset_info": {"divisible": True},
                "market_dir": "SELL",
            }
        ]
    )[0]

    assert result["give_quantity_normalized"] == decimal.Decimal("1")
    assert result["get_quantity_normalized"] == decimal.Decimal("0.5")
    assert result["market_price_normalized"] == decimal.Decimal("0.5")
    assert result["market_price"] == result["market_price_normalized"]


def test_inject_normalized_quantities_adds_order_match_market_price_normalized():
    result = verbose.inject_normalized_quantities(
        [
            {
                "forward_quantity": 100000000,
                "backward_quantity": 150,
                "forward_asset_info": {"divisible": True},
                "backward_asset_info": {"divisible": False},
                "market_dir": "SELL",
            }
        ]
    )[0]

    assert result["forward_quantity_normalized"] == decimal.Decimal("1")
    assert result["backward_quantity_normalized"] == "150"
    assert result["market_price_normalized"] == decimal.Decimal("150")
    assert result["market_price"] == result["market_price_normalized"]


def test_normalize_price_does_not_leak_prec_to_caller_thread():
    """normalize_price must NOT mutate the thread-local Decimal precision
    of the caller; previously it called `decimal.getcontext().prec = 32`
    which permanently bumped the precision for every Decimal op on that
    thread for the rest of its lifetime -- a latent consensus-split
    footgun if anyone imports helpers.divide into a parse path.

    Pin the post-call precision to whatever it was before. The default is
    28, but other tests may have mutated it; we only assert that the
    *change* is zero."""
    prec_before = decimal.getcontext().prec
    verbose.normalize_price("3.14159265358979323846264338327950288")
    prec_after = decimal.getcontext().prec
    assert prec_after == prec_before


def test_normalize_price_thread_isolation():
    """Two threads calling normalize_price concurrently must each see
    their own thread-local context untouched."""
    initial_prec = decimal.getcontext().prec
    results_per_thread = {}

    def worker(thread_id):
        local_prec = decimal.getcontext().prec
        for _ in range(20):
            verbose.normalize_price("1.5")
        results_per_thread[thread_id] = (
            local_prec,
            decimal.getcontext().prec,
        )

    threads = [threading.Thread(target=worker, args=(i,)) for i in range(4)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert decimal.getcontext().prec == initial_prec
    for thread_id, (before, after) in results_per_thread.items():
        assert before == after, f"thread {thread_id} prec drifted from {before} to {after}"


def test_clean_api_result_passes_primitive_through():
    """Primitive types must be returned as-is."""
    assert verbose.clean_api_result(42) == 42
    assert verbose.clean_api_result("hello") == "hello"
    assert verbose.clean_api_result(None) is None
    assert verbose.clean_api_result(3.14) == 3.14
    assert verbose.clean_api_result(True) is True


def test_clean_api_result_recurses_into_list():
    """Lists must be cleaned element-wise (recursive)."""
    result = verbose.clean_api_result([1, 2, "x", None])
    assert result == [1, 2, "x", None]


def test_clean_api_result_recurses_into_nested_list_of_dicts():
    """Lists of dicts must be cleaned recursively."""
    result = verbose.clean_api_result([{"a": 1}, {"b": 2}])
    assert isinstance(result, list)
    assert len(result) == 2


def test_clean_api_result_handles_dict():
    """Dicts go through clean_dictionary which strips internal keys."""
    result = verbose.clean_api_result({"asset": "XCP", "quantity": 10})
    assert isinstance(result, dict)
    assert "asset" in result
