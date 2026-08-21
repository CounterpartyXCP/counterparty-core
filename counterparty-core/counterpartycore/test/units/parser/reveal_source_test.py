"""
An inscription reveal transaction resolves its source one hop further back than
an ordinary input: to the output that funded the *commit* transaction, not to
the commit output the reveal spends.

The Rust deserializer normally performs that rewrite and returns the result as
`vin["info"]`. When its batch RPC call fails it returns no `info`, and the Python
fallback used to resolve `vin["hash"]:vin["n"]` as if it were an ordinary input
-- giving that node a different `source` and a different `fee` than every node
whose RPC succeeded, with nothing downstream able to notice. These tests pin the
wiring that keeps both paths in agreement.

The commit-parent lookup itself is covered in
`test/units/backend/bitcoind_test.py`; here we check that `gettxinfo` asks for it
when (and only when) it is needed, and threads the answer into every input.
"""

from counterpartycore.lib import backend
from counterpartycore.lib.parser import gettxinfo

COMMIT_TXID = "aa" * 32
FUNDING_TXID = "bb" * 32
OTHER_TXID = "cc" * 32
RESOLVED_INFO = {"value": 1, "script_pub_key": "0011", "is_segwit": False}


def decoded_tx(vins, is_reveal_tx=True):
    # parsed_vouts = (destinations, btc_amount, fee, data, potential_dispensers, is_reveal_tx)
    return {"vin": vins, "parsed_vouts": ([], 0, 0, b"data", [], is_reveal_tx)}


def test_no_override_for_an_ordinary_transaction(monkeypatch):
    monkeypatch.setattr(
        backend.bitcoind,
        "get_reveal_prevouts",
        lambda *args, **kwargs: pytest_fail_unexpected_lookup(),
    )
    tx = decoded_tx([{"hash": COMMIT_TXID, "n": 0, "info": None}], is_reveal_tx=False)
    assert gettxinfo.get_vin_prevout_overrides(tx) is None


def pytest_fail_unexpected_lookup():
    raise AssertionError("the commit parent must not be looked up here")


def test_no_override_when_the_deserializer_resolved_every_input(monkeypatch):
    """The Rust rewrite already applied; asking the backend again would be a
    redundant RPC round-trip on every reveal transaction."""
    monkeypatch.setattr(
        backend.bitcoind,
        "get_reveal_prevouts",
        lambda *args, **kwargs: pytest_fail_unexpected_lookup(),
    )
    tx = decoded_tx([{"hash": COMMIT_TXID, "n": 0, "info": RESOLVED_INFO}])
    assert gettxinfo.get_vin_prevout_overrides(tx) is None


def test_override_when_an_input_is_unresolved(monkeypatch):
    monkeypatch.setattr(
        backend.bitcoind, "get_reveal_prevouts", lambda *args, **kwargs: [(FUNDING_TXID, 3)]
    )
    tx = decoded_tx([{"hash": COMMIT_TXID, "n": 0, "info": None}])
    assert gettxinfo.get_vin_prevout_overrides(tx) == [(FUNDING_TXID, 3)]


def test_get_transaction_sources_resolves_the_commit_parent(monkeypatch):
    """The prevout override must reach get_vin_info() for every input, so the
    source and the summed input value match the RPC-success path."""
    requested = []

    def fake_get_vin_info(vin, no_retry=False, prevout=None):
        requested.append(prevout or (vin["hash"], vin["n"]))
        # P2PKH script for a known address; the value differs per input so that
        # a wrong prevout would show up in `outputs_value` too.
        return (
            100 if prevout else 1,
            "76a914412463039be25be1bef6e6dbc5eb8eb18cf9569488ac",
            False,
        )

    monkeypatch.setattr(
        backend.bitcoind,
        "get_reveal_prevouts",
        lambda *args, **kwargs: [(FUNDING_TXID, 3), (OTHER_TXID, 1)],
    )
    monkeypatch.setattr(backend.bitcoind, "get_vin_info", fake_get_vin_info)

    tx = decoded_tx(
        [
            {"hash": COMMIT_TXID, "n": 0, "info": None},
            {"hash": OTHER_TXID, "n": 1, "info": None},
        ]
    )
    sources, outputs_value = gettxinfo.get_transaction_sources(tx)

    assert requested == [(FUNDING_TXID, 3), (OTHER_TXID, 1)]
    assert COMMIT_TXID not in [txid for txid, _n in requested]
    assert outputs_value == 200
    assert sources == "mmTPoijZbv5sLkCpbG6JkjFkWR89WCJL7G"
