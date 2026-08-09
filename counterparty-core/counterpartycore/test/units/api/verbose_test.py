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


def test_inject_normalized_quantities_normalizes_all_fairminter_quantities():
    """Every asset-denominated quantity on a fairminter row must get a
    `_normalized` companion. `max_mint_per_address` and `pool_quantity` were
    missing from `quantity_fields` while all their neighbours were present."""
    result = verbose.inject_normalized_quantities(
        [
            {
                "asset": "DIVISIBLE",
                "hard_cap": 1000000000,
                "soft_cap": 400000000,
                "max_mint_per_tx": 100000000,
                "max_mint_per_address": 500000000,
                "premint_quantity": 200000000,
                "pool_quantity": 300000000,
                "asset_info": {"divisible": True},
            }
        ]
    )[0]

    assert result["max_mint_per_tx_normalized"] == decimal.Decimal("1")
    assert result["max_mint_per_address_normalized"] == decimal.Decimal("5")
    assert result["premint_quantity_normalized"] == decimal.Decimal("2")
    assert result["pool_quantity_normalized"] == decimal.Decimal("3")


def test_inject_normalized_quantities_fairminter_quantities_indivisible():
    """Divisibility comes from the fairminter's own `asset_info`: an
    indivisible asset is returned as-is, not divided by 1e8."""
    result = verbose.inject_normalized_quantities(
        [
            {
                "asset": "INDIVISIBLE",
                "max_mint_per_address": 5,
                "pool_quantity": 3,
                "asset_info": {"divisible": False},
            }
        ]
    )[0]

    assert result["max_mint_per_address_normalized"] == "5"
    assert result["pool_quantity_normalized"] == "3"


def test_inject_normalized_quantities_skips_null_max_mint_per_address():
    """`max_mint_per_address` is nullable (no DEFAULT on the column), so the
    `_normalized` key is absent rather than null on fairminters that don't
    set it. Clients must not assume the key is always present."""
    result = verbose.inject_normalized_quantities(
        [
            {
                "asset": "DIVISIBLE",
                "max_mint_per_address": None,
                "pool_quantity": 0,
                "asset_info": {"divisible": True},
            }
        ]
    )[0]

    assert "max_mint_per_address_normalized" not in result
    assert result["pool_quantity_normalized"] == decimal.Decimal("0")


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
