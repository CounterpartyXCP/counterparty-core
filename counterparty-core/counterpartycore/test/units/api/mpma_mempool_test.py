"""API coverage for pending MPMA wire-format selection."""

import pytest
from counterparty_rs import utils as rs_utils
from counterpartycore.lib import config
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages.versions import mpma
from counterpartycore.lib.parser import messagetype, protocol
from counterpartycore.lib.utils import hashcodec
from counterpartycore.lib.utils.mpmaencoding import _encode_mpma_send


@pytest.fixture(params=["mainnet", "testnet3", "testnet4", "signet"])
def mpma_activation(request, apiv2_client, monkeypatch):
    """Apply real network activation heights after building the regtest API fixtures."""
    network = request.param
    monkeypatch.setattr(config, "REGTEST", False)
    monkeypatch.setattr(config, "NETWORK_NAME", network)
    for flag in ("TESTNET3", "TESTNET4", "SIGNET"):
        monkeypatch.setattr(config, flag, network == flag.lower())
    return protocol.get_change_block_index("mpma_taproot_support")


def _set_mpma_ledger_tip(ledger_db, monkeypatch, height):
    ledger_db.execute(
        "INSERT INTO blocks (block_index, block_hash, ledger_hash, block_time) VALUES (?, ?, ?, 0)",
        (height, hashcodec.hash_to_db("ab" * 32), hashcodec.hash_to_db("cd" * 32)),
    )
    # The API's cached State DB height can lag the confirmed Ledger DB tip.
    monkeypatch.setitem(CurrentState().state, "CURRENT_BLOCK_INDEX", height - 1)


def _mpma_activation_payload(ledger_db, block_index, taproot=False):
    destination = rs_utils.unpack_address(b"\x01" + b"\x11" * 20, config.NETWORK_NAME)
    packed_other = b"\x03\x01" + b"\x22" * 32 if taproot else b"\x01" + b"\x22" * 20
    other = rs_utils.unpack_address(packed_other, config.NETWORK_NAME)
    # One recipient per asset keeps activation coverage independent of how the
    # API flattens multiple recipients of the same asset.
    sends = [("DIVISIBLE", other, 29), ("XCP", destination, 17)]
    data = messagetype.pack(mpma.ID) + _encode_mpma_send(ledger_db, sends, block_index=block_index)
    expected = [
        {
            "asset": asset,
            "destination": recipient,
            "quantity": quantity,
            "memo": None,
            "memo_is_hex": None,
        }
        for asset, recipient, quantity in sends
    ]
    return data, expected


@pytest.mark.parametrize("tip_offset", [-2, -1, 0], ids=["before", "activation-next", "after"])
@pytest.mark.parametrize("endpoint", ["unpack", "verbose-transactions"])
def test_unpack_mpma_mempool_uses_next_block(
    apiv2_client, ledger_db, monkeypatch, mpma_activation, tip_offset, endpoint
):
    """Pending MPMA data uses the next confirmed block's format on both API paths."""
    tip = mpma_activation + tip_offset
    _set_mpma_ledger_tip(ledger_db, monkeypatch, tip)
    # A mempool parsing block has no ledger hash and must not become the tip.
    ledger_db.execute(
        "INSERT INTO blocks (block_index, block_hash, block_time) VALUES (?, ?, 0)",
        (config.MEMPOOL_BLOCK_INDEX, config.MEMPOOL_BLOCK_HASH),
    )
    data, expected = _mpma_activation_payload(
        ledger_db, tip + 1, taproot=tip + 1 >= mpma_activation
    )

    if endpoint == "unpack":
        response = apiv2_client.get(
            "/v2/transactions/unpack",
            query_string={"datahex": data.hex(), "block_index": config.MEMPOOL_BLOCK_INDEX},
        )
        assert response.status_code == 200, response.json
        unpacked = response.json["result"]
    else:
        tx_hash = "ef" * 32
        tx_index = ledger_db.execute(
            "SELECT MAX(tx_index) + 1 AS tx_index FROM transactions"
        ).fetchone()["tx_index"]
        ledger_db.execute(
            """INSERT INTO mempool_transactions (
                   tx_index, tx_hash, block_index, block_hash, block_time,
                   source, destination, btc_amount, fee, data, supported,
                   utxos_info, transaction_type
               ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                tx_index,
                hashcodec.hash_to_db(tx_hash),
                config.MEMPOOL_BLOCK_INDEX,
                config.MEMPOOL_BLOCK_HASH,
                0,
                expected[0]["destination"],
                None,
                0,
                0,
                data,
                1,
                "",
                "mpma_send",
            ),
        )
        response = apiv2_client.get(
            "/v2/transactions",
            query_string={"show_unconfirmed": "true", "verbose": "true", "limit": 1},
        )
        assert response.status_code == 200, response.json
        transaction = response.json["result"][0]
        assert transaction["tx_hash"] == tx_hash
        assert transaction["confirmed"] is False
        unpacked = transaction["unpacked_data"]

    assert unpacked["message_type"] == "mpma_send"
    assert unpacked["message_type_id"] == mpma.ID
    # Verbose responses add asset metadata and normalized quantities.
    assert [
        {key: send[key] for key in expected[0]} for send in unpacked["message_data"]
    ] == expected


def test_unpack_mpma_preserves_confirmed_height(
    apiv2_client, ledger_db, monkeypatch, mpma_activation
):
    """Historical legacy messages remain readable after the format activates."""
    _set_mpma_ledger_tip(ledger_db, monkeypatch, mpma_activation + 10)
    block_index = mpma_activation - 1
    data, expected = _mpma_activation_payload(ledger_db, block_index)
    response = apiv2_client.get(
        "/v2/transactions/unpack",
        query_string={"datahex": data.hex(), "block_index": block_index},
    )

    assert response.status_code == 200
    assert response.json["result"] == {
        "message_type": "mpma_send",
        "message_type_id": mpma.ID,
        "message_data": expected,
    }
