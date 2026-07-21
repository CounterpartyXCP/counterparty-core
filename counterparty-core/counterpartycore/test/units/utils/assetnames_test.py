import binascii
from unittest.mock import MagicMock

import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.utils import assetnames
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_parse_subasset_from_asset_name():
    with pytest.raises(
        exceptions.AssetNameError, match="parent asset name contains invalid character:"
    ):
        assetnames.parse_subasset_from_asset_name("BADASSETx.child1")

    with pytest.raises(exceptions.AssetNameError, match="parent asset name too long"):
        assetnames.parse_subasset_from_asset_name("TOOLONGASSETNAME.child1")

    with pytest.raises(exceptions.AssetNameError, match="parent asset name too short"):
        assetnames.parse_subasset_from_asset_name("BAD.child1")

    with pytest.raises(exceptions.AssetNameError, match="parent asset name starts with 'A'"):
        assetnames.parse_subasset_from_asset_name("ABADPARENT.child1")

    with pytest.raises(exceptions.AssetNameError, match="parent asset cannot be BTC"):
        assetnames.parse_subasset_from_asset_name("BTC.child1")

    with pytest.raises(exceptions.AssetNameError, match="parent asset cannot be XCP"):
        assetnames.parse_subasset_from_asset_name("XCP.child1")

    with pytest.raises(exceptions.AssetNameError, match="subasset name too short"):
        assetnames.parse_subasset_from_asset_name("PARENT.")

    with pytest.raises(exceptions.AssetNameError, match="subasset name too long"):
        assetnames.parse_subasset_from_asset_name("PARENT." + ("1234567890" * 24) + "12345")

    with pytest.raises(
        exceptions.AssetNameError, match="subasset name contains invalid character:"
    ):
        assetnames.parse_subasset_from_asset_name("PARENT.child1&")

    with pytest.raises(
        exceptions.AssetNameError, match="subasset name contains consecutive periods"
    ):
        assetnames.parse_subasset_from_asset_name("PARENT.child1..foo")

    with pytest.raises(exceptions.AssetNameError, match="parent asset name too long"):
        assetnames.parse_subasset_from_asset_name("A95428956661682177.subasset")

    with pytest.raises(exceptions.AssetNameError, match="parent asset name too long"):
        assetnames.parse_subasset_from_asset_name("A123456789012345678901.subasset")

    assert assetnames.parse_subasset_from_asset_name("A95428956661682177.subasset", True) == (
        "A95428956661682177",
        "A95428956661682177.subasset",
    )


def test_compact_subasset_longname():
    assert assetnames.compact_subasset_longname("a.very.long.name") == binascii.unhexlify(
        "132de2e856f9a630c2e2bc09"
    )
    assert assetnames.compact_subasset_longname("aaaa") == binascii.unhexlify("04de95")
    assert assetnames.compact_subasset_longname("a") == b"\x01"
    assert assetnames.compact_subasset_longname("b") == b"\x02"


def test_expand_subasset_longname():
    assert (
        assetnames.expand_subasset_longname(
            binascii.unhexlify("132de2e856f9a630c2e2bc09"),
        )
        == "a.very.long.name"
    )
    assert assetnames.expand_subasset_longname(binascii.unhexlify("04de95")) == "aaaa"
    assert assetnames.expand_subasset_longname(b"\x01") == "a"
    assert assetnames.expand_subasset_longname(b"\x02") == "b"
    assert (
        assetnames.expand_subasset_longname(binascii.unhexlify("8e90a57dba99d3a77b0a2470b1816edb"))
        == "PARENT.a-zA-Z0-9.-_@!"
    )


def test_validate_subasset_longname_no_dot():
    """Test validate_subasset_longname when subasset_longname has no dot (line 113)."""
    with pytest.raises(exceptions.AssetNameError, match="subasset name too short"):
        assetnames.validate_subasset_longname("NODOT")


def test_validate_subasset_longname_ends_with_period():
    """Test validate_subasset_longname when subasset_child ends with a period (line 129)."""
    with pytest.raises(exceptions.AssetNameError, match="subasset name ends with a period"):
        assetnames.validate_subasset_longname("PARENT.child.")


def test_validate_subasset_parent_name_with_allow_subassets_on_numerics():
    """Test validate_subasset_parent_name with allow_subassets_on_numerics=True (lines 171, 173, 175, 177)."""
    # Line 171: BTC is not allowed
    with pytest.raises(exceptions.AssetNameError, match="parent asset cannot be BTC"):
        assetnames.validate_subasset_parent_name("BTC", allow_subassets_on_numerics=True)

    # Line 173: XCP is not allowed
    with pytest.raises(exceptions.AssetNameError, match="parent asset cannot be XCP"):
        assetnames.validate_subasset_parent_name("XCP", allow_subassets_on_numerics=True)

    # Line 175: Asset name too short
    with pytest.raises(exceptions.AssetNameError, match="parent asset name too short"):
        assetnames.validate_subasset_parent_name("ABC", allow_subassets_on_numerics=True)

    # Line 177: Asset name too long (> 21 characters)
    with pytest.raises(exceptions.AssetNameError, match="parent asset name too long"):
        assetnames.validate_subasset_parent_name("A" * 22, allow_subassets_on_numerics=True)

    # Valid numeric asset
    assert (
        assetnames.validate_subasset_parent_name(
            "A95428956661682177", allow_subassets_on_numerics=True
        )
        is True
    )

    # Valid named asset
    assert (
        assetnames.validate_subasset_parent_name("VALIDASSET", allow_subassets_on_numerics=True)
        is True
    )

    # Invalid character in non-numeric asset
    with pytest.raises(
        exceptions.AssetNameError, match="parent asset name contains invalid character:"
    ):
        assetnames.validate_subasset_parent_name("INVALIDx", allow_subassets_on_numerics=True)


def test_expand_subasset_longname_empty_bytes():
    """Test expand_subasset_longname with empty bytes (line 201)."""
    assert assetnames.expand_subasset_longname(b"\x00") == ""
    assert assetnames.expand_subasset_longname(b"") == ""


def test_generate_random_asset_non_regtest():
    """Test generate_random_asset when not in regtest mode (line 216)."""
    original_regtest = config.REGTEST
    try:
        config.REGTEST = False
        asset = assetnames.generate_random_asset()
        assert asset.startswith("A")
        # The numeric part should be within valid range
        numeric_part = int(asset[1:])
        assert numeric_part >= 26**12 + 1
        assert numeric_part <= 2**64 - 1
    finally:
        config.REGTEST = original_regtest


def test_generate_random_asset_regtest_no_subasset():
    """Test generate_random_asset in regtest mode but without subasset_longname (line 216)."""
    original_regtest = config.REGTEST
    try:
        config.REGTEST = True
        asset = assetnames.generate_random_asset(subasset_longname=None)
        assert asset.startswith("A")
        # The numeric part should be within valid range
        numeric_part = int(asset[1:])
        assert numeric_part >= 26**12 + 1
        assert numeric_part <= 2**64 - 1
    finally:
        config.REGTEST = original_regtest


def test_gen_random_asset_name():
    """Test gen_random_asset_name function (lines 220-222)."""
    # Deterministic based on seed
    asset1 = assetnames.gen_random_asset_name("test_seed")
    asset2 = assetnames.gen_random_asset_name("test_seed")
    assert asset1 == asset2
    assert asset1.startswith("A")

    # Different seeds produce different assets
    asset3 = assetnames.gen_random_asset_name("different_seed")
    assert asset1 != asset3

    # Test with add parameter
    asset4 = assetnames.gen_random_asset_name("test_seed", add=1)
    assert asset4 != asset1
    # The difference should be exactly 1 in the numeric part
    assert int(asset4[1:]) == int(asset1[1:]) + 1


def test_asset_exists(ledger_db):
    """Test asset_exists function (lines 226-233)."""
    # DIVISIBLE should exist in the test database (created via issuance)
    assert assetnames.asset_exists(ledger_db, "DIVISIBLE") is True

    # Non-existent asset
    assert assetnames.asset_exists(ledger_db, "NONEXISTENTASSET123") is False


def test_deterministic_random_asset_name(ledger_db):
    """Test deterministic_random_asset_name function (lines 237-242)."""
    # Should return a deterministic asset name based on seed
    asset1 = assetnames.deterministic_random_asset_name(ledger_db, "unique_seed_12345")
    asset2 = assetnames.deterministic_random_asset_name(ledger_db, "unique_seed_12345")
    assert asset1 == asset2
    assert asset1.startswith("A")

    # Different seeds should produce different names
    asset3 = assetnames.deterministic_random_asset_name(ledger_db, "another_unique_seed_67890")
    assert asset1 != asset3


def test_deterministic_random_asset_name_collision():
    """Test deterministic_random_asset_name when there's a collision (lines 239-241)."""
    # Create a mock database that returns True for the first asset name
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor

    # First call returns existing asset, second call returns no results
    call_count = [0]

    def mock_fetchall():
        call_count[0] += 1
        if call_count[0] == 1:
            return [("some_result",)]  # Asset exists
        return []  # Asset doesn't exist

    mock_cursor.fetchall = mock_fetchall

    result = assetnames.deterministic_random_asset_name(mock_db, "collision_seed")
    assert result.startswith("A")
    # Should have tried at least twice
    assert call_count[0] >= 2


def test_expand_subasset_longname_rejects_oversized():
    """Regression: pre-fix, attacker-supplied compacted_subasset_longname
    via CBOR (taproot_support) was uncapped, and the O(n^2) expand loop
    consumed ~25s of CPU on a 100KB payload. The fix caps input at 200
    bytes (a 250-char base68 longname needs only 191 bytes).
    """
    # Gate off: oversized payload is not rejected at expand time (legacy replay).
    with ProtocolChangesDisabled(["subasset_compact_expand_cap"]):
        assetnames.expand_subasset_longname(b"\x01" * 30, block_index=999999)

    # Gate on: cap enforced.
    with pytest.raises(exceptions.AssetNameError, match="too long"):
        assetnames.expand_subasset_longname(b"\xff" * 1000, block_index=999999)
    assetnames.expand_subasset_longname(b"\x01" * 200, block_index=999999)
    with pytest.raises(exceptions.AssetNameError):
        assetnames.expand_subasset_longname(b"\x01" * 201, block_index=999999)
