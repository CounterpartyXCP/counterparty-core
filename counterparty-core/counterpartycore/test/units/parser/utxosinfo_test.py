from counterpartycore.lib.parser import utxosinfo

TXID = "0" * 64


def test_is_utxo_format_rejects_vout_above_uint32(monkeypatch):
    # Base format checks: valid vouts are accepted regardless of the gate.
    assert utxosinfo.is_utxo_format(f"{TXID}:0")
    assert utxosinfo.is_utxo_format(f"{TXID}:4294967295")

    # Once `enforce_utxo_vout_max` is active, out-of-range vouts are rejected.
    monkeypatch.setattr(
        "counterpartycore.lib.parser.protocol.enabled", lambda change, block_index=None: True
    )
    assert not utxosinfo.is_utxo_format(f"{TXID}:4294967296")
    assert not utxosinfo.is_utxo_format(f"{TXID}:999999999999999999999")

    # Before activation the legacy behaviour is preserved (no consensus change):
    # any non-negative integer vout that round-trips through str(int()) is accepted.
    monkeypatch.setattr(
        "counterpartycore.lib.parser.protocol.enabled", lambda change, block_index=None: False
    )
    assert utxosinfo.is_utxo_format(f"{TXID}:4294967296")
    assert utxosinfo.is_utxo_format(f"{TXID}:999999999999999999999")
