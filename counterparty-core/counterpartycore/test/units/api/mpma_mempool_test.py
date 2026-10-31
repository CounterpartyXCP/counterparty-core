"""API coverage for pending MPMA wire-format selection."""

import pytest
from bitstring import BitArray
from counterparty_rs import utils as rs_utils
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.api import apiserver
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


def test_unpack_legacy_mpma_requires_historical_height(
    apiv2_client, ledger_db, monkeypatch, mpma_activation
):
    """Omitted height uses current rules, not a fallback to the legacy decoder."""
    _set_mpma_ledger_tip(ledger_db, monkeypatch, mpma_activation + 10)
    data, expected = _mpma_activation_payload(ledger_db, mpma_activation - 1)
    captured = []
    monkeypatch.setattr(apiserver, "capture_exception", captured.append)

    response = apiv2_client.get(
        "/v2/transactions/unpack", query_string={"datahex": (config.PREFIX + data).hex()}
    )
    assert response.status_code == 200, response.json
    # On mainnet, the legacy P2PKH version byte is read as a zero length;
    # test networks instead reject a truncated or invalid packed address.
    assert "error" in response.json["result"]["message_data"]
    assert captured == []

    response = apiv2_client.get(
        "/v2/transactions/unpack",
        query_string={"datahex": data.hex(), "block_index": mpma_activation - 1},
    )
    assert response.status_code == 200, response.json
    assert response.json["result"]["message_data"] == expected

    data, expected = _mpma_activation_payload(ledger_db, mpma_activation + 9, taproot=True)
    response = apiv2_client.get("/v2/transactions/unpack", query_string={"datahex": data.hex()})
    assert response.status_code == 200, response.json
    assert response.json["result"]["message_data"] == expected


@pytest.mark.parametrize(
    "message,error",
    [
        (b"\x00\x00", "address list can't be empty"),
        (b"\x00\x01\x00", "address can't be empty"),
        (b"\x00\x01\x02\x01", "truncated address list"),
        (b"\x00\x01\x01\xff", "invalid address:"),
    ],
    ids=["empty-list", "empty-address", "truncated-address", "invalid-address"],
)
def test_unpack_mpma_decode_error_is_structured(
    apiv2_client, ledger_db, monkeypatch, mpma_activation, message, error
):
    _set_mpma_ledger_tip(ledger_db, monkeypatch, mpma_activation + 10)
    # Only the API handles these failures; consensus decoding still rejects them.
    with pytest.raises(exceptions.DecodeError, match=error):
        mpma.unpack(message, block_index=mpma_activation)
    captured = []
    monkeypatch.setattr(apiserver, "capture_exception", captured.append)

    response = apiv2_client.get(
        "/v2/transactions/unpack",
        query_string={
            "datahex": (messagetype.pack(mpma.ID) + message).hex(),
            "block_index": mpma_activation,
            "verbose": "true",
        },
    )
    assert response.status_code == 200, response.json
    result = response.json["result"]
    assert result["message_type"] == "mpma_send"
    assert result["message_type_id"] == mpma.ID
    assert result["message_data"]["error"].startswith(error)
    assert captured == []


def _mpma_out_of_range_index_message():
    """A three-address table with a recipient index of 3."""
    lut = b"\x00\x03" + b"".join(b"\x15\x01" + bytes([byte]) * 20 for byte in (0x11, 0x22, 0x33))
    sends = BitArray()
    sends.append("0b0")  # no message memo
    sends.append("0b1")  # one asset follows
    sends.append("uintbe:64=1")  # XCP
    sends.append("uint:2=0")  # a single recipient
    sends.append("uint:2=3")  # recipient index
    sends.append("uintbe:64=17")
    sends.append("0b0")  # no send memo
    sends.append("0b0")  # no more assets
    return lut + sends.bytes


def test_unpack_mpma_out_of_range_index_is_structured(
    apiv2_client, ledger_db, monkeypatch, mpma_activation
):
    _set_mpma_ledger_tip(ledger_db, monkeypatch, mpma_activation + 10)
    message = _mpma_out_of_range_index_message()
    # Consensus decoding is unchanged; mpma.parse() records this as invalid.
    with pytest.raises(IndexError):
        mpma.unpack(message, block_index=mpma_activation)
    captured = []
    monkeypatch.setattr(apiserver, "capture_exception", captured.append)

    response = apiv2_client.get(
        "/v2/transactions/unpack",
        query_string={
            "datahex": (messagetype.pack(mpma.ID) + message).hex(),
            "block_index": mpma_activation,
        },
    )
    assert response.status_code == 200, response.json
    assert response.json["result"] == {
        "message_type": "mpma_send",
        "message_type_id": mpma.ID,
        "message_data": {"error": "address index out of range"},
    }
    assert captured == []
