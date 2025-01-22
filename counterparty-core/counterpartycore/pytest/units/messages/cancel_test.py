import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.messages import cancel


def test_compose(ledger_db, defaults):
    open_order = ledger_db.execute(
        """
            SELECT * FROM 
                (SELECT tx_hash, status, source, MAX(rowid) FROM orders GROUP BY tx_hash) 
            WHERE status='open' ORDER BY tx_hash DESC LIMIT 1
        """
    ).fetchone()

    assert cancel.compose(ledger_db, open_order["source"], open_order["tx_hash"]) == (
        open_order["source"],
        [],
        b"F\xe1\xba\xf7\xedl\x87\xc1\x99\xd3\xff\x8e\xb9\x00@\x03\xf0\xf6H\x1a\x1ePV+\x16<P\x08\xa4\xd7]7}",
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
