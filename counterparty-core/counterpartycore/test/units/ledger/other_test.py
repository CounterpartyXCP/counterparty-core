import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.ledger import other


def test_get_oracle_price(ledger_db):
    broadcasts = ledger_db.execute("SELECT * FROM broadcasts WHERE status = 'valid'").fetchall()

    assert other.get_oracle_last_price(
        ledger_db, broadcasts[0]["source"], broadcasts[0]["block_index"] + 1
    ) == (
        broadcasts[0]["value"],
        broadcasts[0]["fee_fraction_int"],
        "",
        broadcasts[0]["block_index"],
    )
    with pytest.raises(exceptions.InvalidArgument, match="Invalid order_by parameter"):
        other.get_broadcasts_by_source(ledger_db, broadcasts[0]["source"], order_by="DEC")

    assert len(other.get_pending_bet_matches(ledger_db, broadcasts[0]["source"])) == 0

    assert other.get_oracle_last_price(
        ledger_db, broadcasts[0]["source"], broadcasts[0]["block_index"]
    ) == (None, None, None, None)

    ledger_db.execute("DROP TRIGGER block_update_broadcasts")
    ledger_db.execute(
        "UPDATE broadcasts SET text = 'part1-part2' WHERE tx_index = ?",
        (broadcasts[0]["tx_index"],),
    )
    assert other.get_oracle_last_price(
        ledger_db, broadcasts[0]["source"], broadcasts[0]["block_index"] + 1
    ) == (
        broadcasts[0]["value"],
        broadcasts[0]["fee_fraction_int"],
        "part2",
        broadcasts[0]["block_index"],
    )
