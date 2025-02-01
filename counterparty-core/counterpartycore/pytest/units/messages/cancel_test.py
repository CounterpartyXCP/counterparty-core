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
        ],
    )
