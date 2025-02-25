import re
from decimal import Decimal as D
from fractions import Fraction

import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.ledger import issuances
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_issuances_functions(ledger_db, defaults, current_block_index):
    assert issuances.generate_asset_id("BTC") == 0
    assert issuances.generate_asset_id("XCP") == 1

    with pytest.raises(exceptions.AssetNameError, match="too short"):
        issuances.generate_asset_id("BCD")

    with pytest.raises(exceptions.AssetNameError, match="non‐numeric asset name starts with ‘A’"):
        issuances.generate_asset_id("ABCD")

    with pytest.raises(exceptions.AssetNameError, match="numeric asset name not in range"):
        issuances.generate_asset_id(f"A{26**12}")

    with pytest.raises(exceptions.AssetNameError, match="numeric asset name not in range"):
        issuances.generate_asset_id(f"A{2**64}")

    assert issuances.generate_asset_id(f"A{26**12 + 1}") == 26**12 + 1
    assert issuances.generate_asset_id(f"A{2**64 - 1}") == 2**64 - 1

    with pytest.raises(exceptions.AssetNameError, match="long asset names must be numeric"):
        issuances.generate_asset_id("LONGASSETNAMES")

    with pytest.raises(exceptions.AssetNameError, match=re.escape("invalid character:")):
        issuances.generate_asset_id("BCDE_F")

    assert issuances.generate_asset_id("BAAA") == 26**3
    assert issuances.generate_asset_id("ZZZZZZZZZZZZ") == 26**12 - 1

    assert issuances.generate_asset_name(0) == "BTC"
    assert issuances.generate_asset_name(1) == "XCP"
    assert issuances.generate_asset_name(26**12 - 1) == "ZZZZZZZZZZZZ"
    assert issuances.generate_asset_name(26**3) == "BAAA"
    assert issuances.generate_asset_name(2**64 - 1) == f"A{2**64 - 1}"
    assert issuances.generate_asset_name(26**12 + 1) == f"A{26**12 + 1}"

    with pytest.raises(exceptions.AssetIDError, match="too low"):
        issuances.generate_asset_name(26**3 - 1)
    with pytest.raises(exceptions.AssetIDError, match="too high"):
        issuances.generate_asset_name(2**64)

    assert issuances.price(1, 10) == Fraction(1, 10)

    assert issuances.get_asset_id(ledger_db, "XCP") == 1
    assert issuances.get_asset_id(ledger_db, "BTC") == 0

    with pytest.raises(exceptions.AssetError, match="No such asset: foobar"):
        issuances.get_asset_id(ledger_db, "foobar")

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

    assert issuances.get_asset_name(ledger_db, 1) == "XCP"
    assert issuances.get_asset_name(ledger_db, 0) == "BTC"
    assert issuances.get_asset_name(ledger_db, 453) == 0


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
            "owner": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
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
            "owner": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "divisible": True,
            "locked": False,
        },
        "DIVISIBLE": {
            "asset_longname": None,
            "description": "Divisible asset",
            "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "owner": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "divisible": True,
            "locked": False,
        },
        "LOCKED": {
            "asset_longname": None,
            "description": "Locked asset",
            "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "owner": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "divisible": True,
            "locked": True,
        },
        "LOCKEDPREV": {
            "asset_longname": None,
            "description": "changed",
            "issuer": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            "owner": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            "divisible": True,
            "locked": True,
        },
        "PARENT.already.issued": {
            "asset": "A95428959342453541",
            "asset_longname": "PARENT.already.issued",
            "description": "Child of parent",
            "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "owner": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "divisible": True,
            "locked": False,
        },
        "NODIVISIBLE": {
            "asset_longname": None,
            "description": "No divisible asset",
            "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "owner": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "divisible": False,
            "locked": False,
        },
    }


def test_edge_cases_and_errors(ledger_db, current_block_index, monkeypatch):
    with ProtocolChangesDisabled(["numeric_asset_names"]):
        with pytest.raises(
            exceptions.AssetNameError, match="non‐numeric asset name starts with ‘A’"
        ):
            asset_id_1 = issuances.generate_asset_id("ABCDE")
            asset_id_2 = issuances.get_asset_id(ledger_db, "ABCDE")
            assert asset_id_1 == asset_id_2

    with ProtocolChangesDisabled(["hotfix_numeric_assets"]):
        assert issuances.get_asset_id(ledger_db, "BAAA") == issuances.generate_asset_id("BAAA")
        assert issuances.get_asset_name(ledger_db, 26**3) == issuances.generate_asset_name(
            26**3, 308000
        )

    assert issuances.get_asset_name(ledger_db, "01234") == 0

    with pytest.raises(
        exceptions.QuantityError,
        match="Divisible assets have only eight decimal places of precision.",
    ):
        issuances.value_input(D("1.12345678912345"), "DIVISIBLE", True)

    assert issuances.value_input(12, "foobar", True) == 1200000000

    assert issuances.value_output(D("1.12345678912345"), "DIVISIBLE", True) == "0.00000001"

    assert issuances.value_output(1200000000, "foobar", True) == "12.0"

    monkeypatch.setattr(
        "counterpartycore.lib.parser.protocol.after_block_or_test_network", lambda x, y: False
    )
    assert issuances.price(10, 3) == D(D(10) / D(3))

    with pytest.raises(exceptions.AssetError, match="No such asset: foobaz"):
        issuances.get_asset_issuer(ledger_db, "foobaz")

    assert issuances.get_asset_description(ledger_db, "XCP") == ""
    assert issuances.get_asset_description(ledger_db, "BTC") == ""
    assert issuances.get_asset_description(ledger_db, "NODIVISIBLE") == "No divisible asset"

    assert len(issuances.get_issuances(ledger_db, locked=True)) == 3
    assert issuances.get_issuances(ledger_db, block_index=current_block_index) == []

    with ProtocolChangesDisabled(["fix_get_issuances"]):
        assert len(issuances.get_issuances(ledger_db, locked=True, last=True)) == 3

    assert issuances.get_last_issuance_no_cache(ledger_db, "NODIVISIBLE") == {
        "asset": "NODIVISIBLE",
        "asset_events": "creation",
        "asset_longname": None,
        "block_index": 104,
        "call_date": 0,
        "call_price": 0.0,
        "callable": False,
        "description": "No divisible asset",
        "description_locked": False,
        "divisible": False,
        "fair_minting": False,
        "fee_paid": 50000000,
        "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "locked": False,
        "msg_index": 0,
        "quantity": 1000,
        "reset": False,
        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "status": "valid",
        "transfer": False,
        "tx_hash": "58d9b2b8eda2b46f478078a31939d919da185010bc6e110e2c97c7c351592857",
        "tx_index": 2,
    }

    assert issuances.get_fairmint_quantities(ledger_db, "dummmy_hash") == (0, 0)
