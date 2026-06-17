import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.messages import move
from counterpartycore.lib.utils import hashcodec

DUMMY_UTXO = 64 * "0" + ":0"


def get_utxo(ledger_db, address, asset="XCP"):
    # balances stores the compact asset_index and address_id; resolve both for
    # the filter. ``SELECT *`` lets the rowtracer reconstruct the ``utxo`` string
    # from the stored ``(utxo_tx_index, utxo_vout)`` pair.
    return ledger_db.execute(
        "SELECT * FROM balances "
        "WHERE utxo_address = (SELECT address_id FROM address_list WHERE address = ?) "
        "AND asset = (SELECT asset_index FROM assets WHERE asset_name = ?) AND quantity > 0",
        (
            address,
            asset,
        ),
    ).fetchone()["utxo"]


def test_move_assets_xcp(ledger_db, defaults, blockchain_mock, test_helpers, current_block_index):
    utxo = get_utxo(ledger_db, defaults["addresses"][0])
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], utxo_source=utxo, utxo_destination=DUMMY_UTXO
    )
    move.move_assets(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "debits",
                "values": {
                    "utxo": utxo,
                    "address": None,
                    "asset": "XCP",
                    "quantity": 100,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "action": "utxo move",
                },
            },
            {
                "table": "credits",
                "values": {
                    "utxo": DUMMY_UTXO,
                    "address": None,
                    "asset": "XCP",
                    "quantity": 100,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "calling_function": "utxo move",
                },
            },
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "status": "valid",
                    "source": utxo,
                    "source_address": defaults["addresses"][0],
                    "destination": DUMMY_UTXO,
                    "destination_address": defaults["addresses"][0],
                    "asset": "XCP",
                    "quantity": 100,
                    "fee_paid": 0,
                },
            },
            {
                "table": "transactions_status",
                "values": {
                    "tx_index": tx["tx_index"],
                    "valid": True,
                },
            },
        ],
    )


def test_move_assets_divisible(
    ledger_db, defaults, blockchain_mock, test_helpers, current_block_index
):
    utxo = get_utxo(ledger_db, defaults["addresses"][0], "DIVISIBLE")
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], utxo_source=utxo, utxo_destination=DUMMY_UTXO
    )
    move.move_assets(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "debits",
                "values": {
                    "utxo": utxo,
                    "address": None,
                    "asset": "DIVISIBLE",
                    "quantity": 1,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "action": "utxo move",
                },
            },
            {
                "table": "credits",
                "values": {
                    "utxo": DUMMY_UTXO,
                    "address": None,
                    "asset": "DIVISIBLE",
                    "quantity": 1,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "calling_function": "utxo move",
                },
            },
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "status": "valid",
                    "source": utxo,
                    "source_address": defaults["addresses"][0],
                    "destination": DUMMY_UTXO,
                    "destination_address": defaults["addresses"][0],
                    "asset": "DIVISIBLE",
                    "quantity": 1,
                    "fee_paid": 0,
                },
            },
            {
                "table": "transactions_status",
                "values": {
                    "tx_index": tx["tx_index"],
                    "valid": True,
                },
            },
        ],
    )


def test_move_assets_no_utxos_info(ledger_db, defaults, blockchain_mock):
    """Test move_assets returns False when tx has no utxos_info."""
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    # Remove utxos_info to test early return
    tx["utxos_info"] = None
    result = move.move_assets(ledger_db, tx)
    assert result is False

    # Also test with empty string
    tx["utxos_info"] = ""
    result = move.move_assets(ledger_db, tx)
    assert result is False

    # Also test with missing key
    del tx["utxos_info"]
    result = move.move_assets(ledger_db, tx)
    assert result is False


def test_move_assets_with_zero_balance(
    ledger_db, defaults, blockchain_mock, test_helpers, current_block_index
):
    """Test move_assets skips balances with quantity == 0."""
    utxo = get_utxo(ledger_db, defaults["addresses"][0])

    # Insert a balance with quantity 0 for the same utxo. ``utxo`` is stored as
    # the compact ``(utxo_tx_hash BLOB, utxo_vout)`` pair; ``utxo_address`` is
    # the ``address_id`` FK.
    ledger_db.execute(
        """
        INSERT INTO balances (address, asset, quantity, utxo_tx_hash, utxo_vout, utxo_address)
        VALUES (NULL, 'ZEROVAL', 0, ?, ?, (SELECT address_id FROM address_list WHERE address = ?))
        """,
        (
            hashcodec.hash_to_db(utxo.split(":")[0]),
            int(utxo.split(":")[1]),
            defaults["addresses"][0],
        ),
    )

    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], utxo_source=utxo, utxo_destination=DUMMY_UTXO
    )
    move.move_assets(ledger_db, tx)

    # The zero balance should not create a send record
    zero_sends = ledger_db.execute(
        "SELECT * FROM sends WHERE tx_hash = ? "
        "AND asset = (SELECT asset_index FROM assets WHERE asset_name = 'ZEROVAL')",
        (hashcodec.hash_to_db(tx["tx_hash"]),),
    ).fetchall()
    assert len(zero_sends) == 0

    # But XCP should still be moved
    xcp_sends = ledger_db.execute(
        "SELECT * FROM sends WHERE tx_hash = ? "
        "AND asset = (SELECT asset_index FROM assets WHERE asset_name = 'XCP')",
        (hashcodec.hash_to_db(tx["tx_hash"]),),
    ).fetchall()
    assert len(xcp_sends) == 1


def test_compose(ledger_db, defaults):
    utxo = get_utxo(ledger_db, defaults["addresses"][0])

    assert move.compose(ledger_db, utxo, defaults["addresses"][0]) == (
        utxo,
        [(defaults["addresses"][0], 546)],
        None,
    )

    assert move.compose(ledger_db, utxo, defaults["addresses"][0], 10000) == (
        utxo,
        [(defaults["addresses"][0], 10000)],
        None,
    )

    with pytest.raises(exceptions.ComposeError, match="Invalid source utxo format"):
        move.compose(ledger_db, "utxo", defaults["addresses"][0])

    with pytest.raises(exceptions.ComposeError, match="No assets attached to the source utxo"):
        move.compose(ledger_db, DUMMY_UTXO, defaults["addresses"][0])

    with pytest.raises(exceptions.ComposeError, match="destination must be an address"):
        move.compose(ledger_db, utxo, utxo)

    with pytest.raises(exceptions.ComposeError, match="utxo_value must be an integer"):
        move.compose(ledger_db, utxo, defaults["addresses"][0], utxo_value="string")

    with pytest.raises(
        exceptions.ComposeError, match="utxo_value must be a valid bitcoin output amount"
    ):
        move.compose(ledger_db, utxo, defaults["addresses"][0], utxo_value=-1)

    with pytest.raises(
        exceptions.ComposeError, match="utxo_value must be a valid bitcoin output amount"
    ):
        move.compose(
            ledger_db,
            utxo,
            defaults["addresses"][0],
            utxo_value=21_000_000 * config.UNIT + 1,
        )
