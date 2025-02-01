import binascii

import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.utils import assetnames


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
