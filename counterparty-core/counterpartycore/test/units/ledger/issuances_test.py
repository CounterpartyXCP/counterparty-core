import re
from fractions import Fraction

import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.ledger import issuances


def test_issuances_functions(ledger_db, defaults, current_block_index):
    assert issuances.generate_asset_id("BTC", current_block_index) == 0
    assert issuances.generate_asset_id("XCP", current_block_index) == 1

    with pytest.raises(exceptions.AssetNameError, match="too short"):
        issuances.generate_asset_id("BCD", 308000)

    with pytest.raises(exceptions.AssetNameError, match="non‐numeric asset name starts with ‘A’"):
        issuances.generate_asset_id("ABCD", 308000)

    with pytest.raises(exceptions.AssetNameError, match="numeric asset name not in range"):
        issuances.generate_asset_id(f"A{26**12}", 308000)

    with pytest.raises(exceptions.AssetNameError, match="numeric asset name not in range"):
        issuances.generate_asset_id(f"A{2**64}", 308000)

    assert issuances.generate_asset_id(f"A{26**12 + 1}", 308000) == 26**12 + 1
    assert issuances.generate_asset_id(f"A{2**64 - 1}", 308000) == 2**64 - 1

    with pytest.raises(exceptions.AssetNameError, match="long asset names must be numeric"):
        issuances.generate_asset_id("LONGASSETNAMES", 308000)

    with pytest.raises(exceptions.AssetNameError, match=re.escape("invalid character:")):
        issuances.generate_asset_id("BCDE_F", 308000)

    assert issuances.generate_asset_id("BAAA", 308000) == 26**3
    assert issuances.generate_asset_id("ZZZZZZZZZZZZ", 308000) == 26**12 - 1

    assert issuances.generate_asset_name(0, current_block_index) == "BTC"
    assert issuances.generate_asset_name(1, current_block_index) == "XCP"
    assert issuances.generate_asset_name(26**12 - 1, 308000) == "ZZZZZZZZZZZZ"
    assert issuances.generate_asset_name(26**3, 308000) == "BAAA"
    assert issuances.generate_asset_name(2**64 - 1, 308000) == f"A{2**64 - 1}"
    assert issuances.generate_asset_name(26**12 + 1, 308000) == f"A{26**12 + 1}"

    with pytest.raises(exceptions.AssetIDError, match="too low"):
        issuances.generate_asset_name(26**3 - 1, 308000)
    with pytest.raises(exceptions.AssetIDError, match="too high"):
        issuances.generate_asset_name(2**64, 308000)

    assert issuances.price(1, 10) == Fraction(1, 10)

    assert issuances.get_asset_id(ledger_db, "XCP", current_block_index) == 1
    assert issuances.get_asset_id(ledger_db, "BTC", current_block_index) == 0

    with pytest.raises(exceptions.AssetError, match="No such asset: foobar"):
        issuances.get_asset_id(ledger_db, "foobar", current_block_index)

    assert issuances.resolve_subasset_longname(ledger_db, "XCP") == "XCP"
    assert issuances.resolve_subasset_longname(ledger_db, "PARENT") == "PARENT"
    assert (
        issuances.resolve_subasset_longname(ledger_db, "PARENT.nonexistent.subasset")
        == "PARENT.nonexistent.subasset"
    )
    assert issuances.resolve_subasset_longname(ledger_db, "PARENT.ILEGAL^^^") == "PARENT.ILEGAL^^^"
    assert (
        issuances.resolve_subasset_longname(ledger_db, "PARENT.already.issued")
        == "A95428959342453541"
    )

    assert issuances.is_divisible(ledger_db, "XCP")
    assert issuances.is_divisible(ledger_db, "BTC")
    assert issuances.is_divisible(ledger_db, "DIVISIBLE")
    assert not issuances.is_divisible(ledger_db, "NODIVISIBLE")

    with pytest.raises(exceptions.AssetError, match="No such asset: foobar"):
        issuances.is_divisible(ledger_db, "foobar")

    assert (
        issuances.value_in(
            ledger_db,
            1.1,
            "leverage",
        )
        == 1
    )
    assert (
        issuances.value_in(
            ledger_db,
            1 / 10,
            "fraction",
        )
        == 0.1
    )
    assert (
        issuances.value_in(
            ledger_db,
            1,
            "NODIVISIBLE",
        )
        == 1
    )
    with pytest.raises(
        exceptions.QuantityError,
        match="Divisible assets have only eight decimal places of precision.",
    ):
        issuances.value_in(
            ledger_db,
            1.111111111111,
            "DIVISIBLE",
        )
    with pytest.raises(
        exceptions.QuantityError, match="Fractional quantities of indivisible assets."
    ):
        issuances.value_in(
            ledger_db,
            1.1,
            "NODIVISIBLE",
        )

    assert (
        issuances.value_out(
            ledger_db,
            1.1,
            "leverage",
        )
        == "1.1"
    )
    assert (
        issuances.value_out(
            ledger_db,
            1 / 10,
            "fraction",
        )
        == "10.0%"
    )
    assert (
        issuances.value_out(
            ledger_db,
            1,
            "NODIVISIBLE",
        )
        == 1
    )
    with pytest.raises(
        exceptions.QuantityError, match="Fractional quantities of indivisible assets."
    ):
        issuances.value_out(
            ledger_db,
            1.1,
            "NODIVISIBLE",
        )

    assert issuances.get_asset_name(ledger_db, 1, current_block_index) == "XCP"
    assert issuances.get_asset_name(ledger_db, 0, current_block_index) == "BTC"
    assert issuances.get_asset_name(ledger_db, 453, current_block_index) == 0


def test_get_assets_last_issuance(state_db):
    assert issuances.get_assets_last_issuance(
        state_db,
        [
            "DIVISIBLE",
            "NODIVISIBLE",
            "CALLABLE",
            "LOCKED",
            "LOCKEDPREV",
            "PARENT.already.issued",
        ],
    ) == {
        "A95428959342453541": {
            "asset": "A95428959342453541",
            "asset_longname": "PARENT.already.issued",
            "description": "Child of parent",
            "divisible": True,
            "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "locked": False,
        },
        "BTC": {
            "divisible": True,
            "asset_longname": None,
            "description": "The Bitcoin cryptocurrency",
            "locked": False,
            "issuer": None,
        },
        "XCP": {
            "divisible": True,
            "asset_longname": None,
            "description": "The Counterparty protocol native currency",
            "locked": True,
            "issuer": None,
        },
        "CALLABLE": {
            "asset_longname": None,
            "description": "Callable asset",
            "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "divisible": True,
            "locked": False,
        },
        "DIVISIBLE": {
            "asset_longname": None,
            "description": "Divisible asset",
            "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "divisible": True,
            "locked": False,
        },
        "LOCKED": {
            "asset_longname": None,
            "description": "Locked asset",
            "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "divisible": True,
            "locked": True,
        },
        "LOCKEDPREV": {
            "asset_longname": None,
            "description": "changed",
            "issuer": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            "divisible": True,
            "locked": True,
        },
        "PARENT.already.issued": {
            "asset": "A95428959342453541",
            "asset_longname": "PARENT.already.issued",
            "description": "Child of parent",
            "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "divisible": True,
            "locked": False,
        },
        "NODIVISIBLE": {
            "asset_longname": None,
            "description": "No divisible asset",
            "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "divisible": False,
            "locked": False,
        },
    }
