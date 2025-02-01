from counterpartycore.lib.parser import check


def test_dhash():
    assert (
        check.dhash_string("foobar")
        == "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda1"
    )
