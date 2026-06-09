from counterpartycore.lib.parser import utxosinfo

TXID = "0" * 64


def test_is_utxo_format_rejects_vout_above_uint32():
    assert utxosinfo.is_utxo_format(f"{TXID}:0")
    assert utxosinfo.is_utxo_format(f"{TXID}:4294967295")
    assert not utxosinfo.is_utxo_format(f"{TXID}:4294967296")
    assert not utxosinfo.is_utxo_format(f"{TXID}:999999999999999999999")
