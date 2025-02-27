from counterpartycore.lib.utils import helpers


def test_is_valid_tx_hash():
    assert not helpers.is_valid_tx_hash("foobar")
    assert helpers.is_valid_tx_hash(
        "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda1"
    )
    assert not helpers.is_valid_tx_hash(
        "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda11"
    )
    assert not helpers.is_valid_tx_hash(
        "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda"
    )
    assert not helpers.is_valid_tx_hash(
        "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42ddaG"
    )


def test_dhash():
    assert (
        helpers.dhash_string("foobar")
        == "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda1"
    )
