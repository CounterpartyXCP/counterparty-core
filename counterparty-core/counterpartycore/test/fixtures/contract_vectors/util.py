import binascii

from counterpartycore.lib import exceptions

UTIL_VECTOR = {
    "parser.protocol": {
        "enabled": [
            {"in": ("numeric_asset_names",), "out": True},
            {"in": ("foobar",), "error": (KeyError, "foobar")},
            {
                "mock_protocol_changes": {"numeric_asset_names": False},
                "in": ("numeric_asset_names",),
                "out": False,
            },
        ],
    },
    "utils.assetnames": {
        "parse_subasset_from_asset_name": [
            {
                "in": ("BADASSETx.child1",),
                "error": (
                    exceptions.AssetNameError,
                    "parent asset name contains invalid character:",
                ),
            },
            {
                "in": ("TOOLONGASSETNAME.child1",),
                "error": (exceptions.AssetNameError, "parent asset name too long"),
            },
            {
                "in": ("BAD.child1",),
                "error": (exceptions.AssetNameError, "parent asset name too short"),
            },
            {
                "in": ("ABADPARENT.child1",),
                "error": (exceptions.AssetNameError, "parent asset name starts with 'A'"),
            },
            {
                "in": ("BTC.child1",),
                "error": (exceptions.AssetNameError, "parent asset cannot be BTC"),
            },
            {
                "in": ("XCP.child1",),
                "error": (exceptions.AssetNameError, "parent asset cannot be XCP"),
            },
            {
                "in": ("PARENT.",),
                "error": (exceptions.AssetNameError, "subasset name too short"),
            },
            {
                "in": ("PARENT." + ("1234567890" * 24) + "12345",),
                "error": (exceptions.AssetNameError, "subasset name too long"),
            },
            {
                "in": ("PARENT.child1&",),
                "error": (
                    exceptions.AssetNameError,
                    "subasset name contains invalid character:",
                ),
            },
            {
                "in": ("PARENT.child1..foo",),
                "error": (
                    exceptions.AssetNameError,
                    "subasset name contains consecutive periods",
                ),
            },
            {
                "comment": "numerics disallowed",
                "in": ("A95428956661682177.subasset",),
                "error": (
                    exceptions.AssetNameError,
                    "parent asset name too long",
                ),
            },
            {
                "comment": "numerics allowed",
                "in": ("A95428956661682177.subasset", True),
                "out": ("A95428956661682177", "A95428956661682177.subasset"),
            },
            {
                "comment": "numerics allowed but too long",
                "in": ("A123456789012345678901.subasset", True),
                "error": (
                    exceptions.AssetNameError,
                    "parent asset name too long",
                ),
            },
        ],
        "compact_subasset_longname": [
            {
                "in": ("a.very.long.name",),
                "out": binascii.unhexlify("132de2e856f9a630c2e2bc09"),
            },
            {"in": ("aaaa",), "out": binascii.unhexlify("04de95")},
            {"in": ("a",), "out": b"\x01"},
            {"in": ("b",), "out": b"\x02"},
        ],
        "expand_subasset_longname": [
            {
                "in": (binascii.unhexlify("132de2e856f9a630c2e2bc09"),),
                "out": "a.very.long.name",
            },
            {"in": (binascii.unhexlify("04de95"),), "out": "aaaa"},
            {"in": (b"\x01",), "out": "a"},
            {"in": (b"\x02",), "out": "b"},
            {
                "in": (binascii.unhexlify("8e90a57dba99d3a77b0a2470b1816edb"),),
                "out": "PARENT.a-zA-Z0-9.-_@!",
            },
        ],
    },
    "parser.check": {
        "dhash_string": [
            {
                "in": ("foobar",),
                "out": "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda1",
            }
        ],
    },
    "utils.helpers": {
        "is_valid_tx_hash": [
            {
                "in": ("foobar",),
                "out": False,
            },
            {
                "in": ("3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda1",),
                "out": True,
            },
            {
                "in": ("3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda11",),
                "out": False,
            },
            {
                "in": ("3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda",),
                "out": False,
            },
            {
                "in": ("3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42ddaG",),
                "out": False,
            },
        ],
    },
}
