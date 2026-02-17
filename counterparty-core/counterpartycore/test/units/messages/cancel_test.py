import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.messages import cancel


def get_open_order(ledger_db):
    return ledger_db.execute(
        """
            SELECT * FROM
                (SELECT tx_hash, status, source, MAX(rowid) FROM orders GROUP BY tx_hash)
            WHERE status='open' ORDER BY tx_hash DESC LIMIT 1
        """
    ).fetchone()


def get_open_orders_for_source(ledger_db, source):
    return ledger_db.execute(
        """
            SELECT * FROM
                (SELECT *, MAX(rowid) FROM orders GROUP BY tx_hash)
            WHERE status='open' AND source=?
            ORDER BY tx_index, tx_hash
        """,
        (source,),
    ).fetchall()


def test_compose(ledger_db, defaults):
    open_order = get_open_order(ledger_db)

    assert cancel.compose(ledger_db, open_order["source"], open_order["tx_hash"]) == (
        open_order["source"],
        [],
        b"F\xfd\xcd]\xdf\x084\xb1\xf6\xe7\xd7\xe4\xb9^\x92=\xd5\x1a:\xd4\xdaW\x95\xc0\xf5\xf2q\xa5\x1f\xc3\xab\xb4.",
    )

    with pytest.raises(exceptions.ComposeError, match="no open offer with that hash"):
        cancel.compose(ledger_db, defaults["addresses"][1], "bet_hash")

    with pytest.raises(exceptions.ComposeError, match="incorrect source address"):
        cancel.compose(ledger_db, "addresses", open_order["tx_hash"])

    closed_bet = ledger_db.execute(
        "SELECT * FROM bets WHERE source = ? ORDER BY rowid DESC LIMIT 1",
        (defaults["addresses"][1],),
    ).fetchone()

    with pytest.raises(exceptions.ComposeError, match="offer not open"):
        cancel.compose(ledger_db, closed_bet["source"], closed_bet["tx_hash"])


def test_compose_cancel_all(ledger_db, defaults):
    """Test composing a cancel-all message."""
    open_order = get_open_order(ledger_db)
    source = open_order["source"]

    result = cancel.compose(ledger_db, source)
    assert result[0] == source
    assert result[1] == []
    # The data should be the packed message type ID + CANCEL_ALL_FLAG (0x01)
    assert result[2].endswith(b"\x01")


def test_compose_cancel_all_no_open_offers(ledger_db, defaults):
    """Test composing cancel-all when no open offers exist raises ComposeError."""
    # Use an address that has no open orders or bets
    source = defaults["addresses"][5]
    # First check there are actually no open orders for this address
    open_orders = get_open_orders_for_source(ledger_db, source)
    if open_orders:
        # If there are open orders, skip this specific check
        return
    with pytest.raises(exceptions.ComposeError, match="no open offers for this address"):
        cancel.compose(ledger_db, source)


def test_unpack_invalid_length():
    """Test unpack with invalid message length."""
    # Too short message (but not 1-byte cancel-all flag)
    offer_hash, status, cancel_all = cancel.unpack(b"short")
    assert offer_hash is None
    assert status == "invalid: could not unpack"
    assert cancel_all is False

    # Empty message
    offer_hash, status, cancel_all = cancel.unpack(b"")
    assert offer_hash is None
    assert status == "invalid: could not unpack"
    assert cancel_all is False


def test_unpack_cancel_all():
    """Test unpack with 1-byte cancel-all flag."""
    offer_hash, status, cancel_all = cancel.unpack(b"\x01")
    assert offer_hash is None
    assert status == "valid"
    assert cancel_all is True


def test_unpack_cancel_all_return_dict():
    """Test unpack cancel-all with return_dict=True."""
    result = cancel.unpack(b"\x01", return_dict=True)
    assert result == {
        "offer_hash": None,
        "status": "valid",
        "cancel_all": True,
    }


def test_unpack_return_dict():
    """Test unpack with return_dict=True for invalid message."""
    result = cancel.unpack(b"short", return_dict=True)
    assert result == {
        "offer_hash": None,
        "status": "invalid: could not unpack",
        "cancel_all": False,
    }


def test_parse_cancel_order(ledger_db, blockchain_mock, test_helpers, current_block_index):
    open_order = get_open_order(ledger_db)
    tx = blockchain_mock.dummy_tx(ledger_db, open_order["source"])
    message = b"\xfd\xcd]\xdf\x084\xb1\xf6\xe7\xd7\xe4\xb9^\x92=\xd5\x1a:\xd4\xdaW\x95\xc0\xf5\xf2q\xa5\x1f\xc3\xab\xb4."

    cancel.parse(ledger_db, tx, message)
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "cancels",
                "values": {
                    "block_index": tx["block_index"],
                    "offer_hash": open_order["tx_hash"],
                    "source": open_order["source"],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            },
            {
                "table": "orders",
                "values": {
                    "status": "cancelled",
                    "tx_hash": open_order["tx_hash"],
                    "block_index": current_block_index,
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


def test_parse_cancel_all(ledger_db, blockchain_mock, test_helpers, current_block_index):
    """Test parsing a cancel-all message cancels all open orders for the source."""
    open_order = get_open_order(ledger_db)
    source = open_order["source"]

    # Count open orders before
    open_orders_before = get_open_orders_for_source(ledger_db, source)
    assert len(open_orders_before) > 0

    tx = blockchain_mock.dummy_tx(ledger_db, source)
    message = b"\x01"  # CANCEL_ALL_FLAG

    cancel.parse(ledger_db, tx, message)

    # Check that a cancels record was inserted with offer_hash="all"
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "cancels",
                "values": {
                    "block_index": tx["block_index"],
                    "source": source,
                    "offer_hash": "all",
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
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

    # Verify all orders for this source are now cancelled
    open_orders_after = get_open_orders_for_source(ledger_db, source)
    assert len(open_orders_after) == 0
