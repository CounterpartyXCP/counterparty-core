import pytest
from counterpartycore.lib import exceptions, ledger
from counterpartycore.lib.messages import cancel


def get_open_order(ledger_db):
    return ledger_db.execute(
        """
            SELECT * FROM
                (SELECT tx_hash, status, source, MAX(rowid) FROM orders GROUP BY tx_hash)
            WHERE status='open' ORDER BY tx_hash DESC LIMIT 1
        """
    ).fetchone()


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


def test_unpack_invalid_length():
    offer_hash, status = cancel.unpack(b"short")
    assert offer_hash is None
    assert status == "invalid: could not unpack"

    offer_hash, status = cancel.unpack(b"")
    assert offer_hash is None
    assert status == "invalid: could not unpack"


def test_unpack_cancel_all_flag():
    offer_hash, status = cancel.unpack(cancel.CANCEL_ALL_FLAG)
    assert offer_hash is None
    assert status == "valid"


def test_unpack_cancel_all_return_dict():
    result = cancel.unpack(cancel.CANCEL_ALL_FLAG, return_dict=True)
    assert result == {"offer_hash": None, "status": "valid"}


def test_unpack_return_dict():
    result = cancel.unpack(b"short", return_dict=True)
    assert result == {"offer_hash": None, "status": "invalid: could not unpack"}


def test_compose_cancel_all_roundtrip(ledger_db, defaults):
    """Compose cancel-all and verify unpack recovers the flag."""
    source, destinations, data = cancel.compose(ledger_db, defaults["addresses"][0])
    assert destinations == []
    # Strip type ID byte, unpack the remainder
    message = data[1:]
    offer_hash, status = cancel.unpack(message)
    assert offer_hash is None
    assert status == "valid"


def test_compose_cancel_all_format(ledger_db, defaults):
    """Cancel-all message is type ID + 1-byte flag."""
    _, _, data = cancel.compose(ledger_db, defaults["addresses"][0])
    assert len(data) == 2  # 1 byte type ID + 1 byte flag
    assert data[1:] == cancel.CANCEL_ALL_FLAG


def test_compose_cancel_all_no_offers(ledger_db, defaults):
    """Compose raises ComposeError when address has no open offers."""
    # Use an address with no open orders or bets
    source = defaults["addresses"][3]
    orders = ledger.markets.get_open_orders_by_source(ledger_db, source)
    bets = ledger.other.get_open_bets_by_source(ledger_db, source)
    assert not orders and not bets

    with pytest.raises(exceptions.ComposeError, match="no open offers"):
        cancel.compose(ledger_db, source)


def test_validate_cancel_all(ledger_db, defaults):
    """Validate returns empty problems when address has open offers."""
    source = defaults["addresses"][0]
    problems = cancel.validate(ledger_db, source, None)
    assert problems == []


def test_validate_cancel_all_no_offers(ledger_db, defaults):
    """Validate returns problem when address has no open offers."""
    source = defaults["addresses"][3]
    problems = cancel.validate(ledger_db, source, None)
    assert any("no open offers" in p for p in problems)


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


def test_parse_cancel_all(ledger_db, blockchain_mock, test_helpers):
    """Cancel-all cancels all open orders for the source."""
    open_order = get_open_order(ledger_db)
    source = open_order["source"]

    orders_before = ledger.markets.get_open_orders_by_source(ledger_db, source)
    assert len(orders_before) > 0

    tx = blockchain_mock.dummy_tx(ledger_db, source)
    cancel.parse(ledger_db, tx, cancel.CANCEL_ALL_FLAG)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "cancels",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "source": source,
                    "offer_hash": "cancel_all",
                    "status": "valid",
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

    orders_after = ledger.markets.get_open_orders_by_source(ledger_db, source)
    assert len(orders_after) == 0


def test_parse_cancel_all_no_offers(ledger_db, blockchain_mock):
    """Cancel-all with no open offers records invalid status."""
    source = "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj"
    tx = blockchain_mock.dummy_tx(ledger_db, source)

    # Verify this address has no open offers
    orders = ledger.markets.get_open_orders_by_source(ledger_db, source)
    bets = ledger.other.get_open_bets_by_source(ledger_db, source)
    assert not orders and not bets

    cancel.parse(ledger_db, tx, cancel.CANCEL_ALL_FLAG)

    record = ledger_db.execute(
        "SELECT * FROM cancels WHERE tx_hash = ? ORDER BY rowid DESC LIMIT 1",
        (tx["tx_hash"],),
    ).fetchone()
    assert record is not None
    assert record["status"] == "invalid: no open offers for this address"
    assert record["offer_hash"] == "cancel_all"


def test_parse_cancel_all_verifies_all_cancelled(ledger_db, blockchain_mock):
    """After cancel-all, every order for the source is cancelled."""
    source = get_open_order(ledger_db)["source"]

    # Count all orders (open and otherwise) for this source before
    all_orders_before = ledger_db.execute(
        """SELECT * FROM (
            SELECT *, MAX(rowid) FROM orders WHERE source = ? GROUP BY tx_hash
        )""",
        (source,),
    ).fetchall()
    open_before = [o for o in all_orders_before if o["status"] == "open"]
    assert len(open_before) > 0

    tx = blockchain_mock.dummy_tx(ledger_db, source)
    cancel.parse(ledger_db, tx, cancel.CANCEL_ALL_FLAG)

    # Every previously-open order should now be cancelled
    all_orders_after = ledger_db.execute(
        """SELECT * FROM (
            SELECT *, MAX(rowid) FROM orders WHERE source = ? GROUP BY tx_hash
        )""",
        (source,),
    ).fetchall()
    open_after = [o for o in all_orders_after if o["status"] == "open"]
    assert len(open_after) == 0


def test_parse_cancel_all_invalid_message_before_activation(
    ledger_db, blockchain_mock, test_helpers
):
    """Before protocol activation, the 1-byte flag is treated as invalid unpack."""
    from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled

    source = get_open_order(ledger_db)["source"]
    tx = blockchain_mock.dummy_tx(ledger_db, source)

    with ProtocolChangesDisabled(["cancel_all_offers"]):
        cancel.parse(ledger_db, tx, cancel.CANCEL_ALL_FLAG)

    record = ledger_db.execute(
        "SELECT * FROM cancels WHERE tx_hash = ? ORDER BY rowid DESC LIMIT 1",
        (tx["tx_hash"],),
    ).fetchone()
    assert record is not None
    assert "invalid" in record["status"]


def test_parse_cancel_all_wrong_flag(ledger_db, blockchain_mock):
    """A 1-byte message with wrong flag value is treated as invalid unpack."""
    source = get_open_order(ledger_db)["source"]
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    cancel.parse(ledger_db, tx, b"\x02")
    record = ledger_db.execute(
        "SELECT * FROM cancels WHERE tx_hash = ? ORDER BY rowid DESC LIMIT 1",
        (tx["tx_hash"],),
    ).fetchone()
    assert "invalid: could not unpack" in record["status"]
