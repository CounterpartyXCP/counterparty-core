import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.ledger import events


def test_events_functions(ledger_db, defaults):
    result = events.last_message(ledger_db)
    assert result["block_index"] == 1929
    assert result["message_index"] == 3995
    assert result["event"] == "BLOCK_PARSED"

    assert events.debit(ledger_db, defaults["addresses"][0], "XCP", 1, 0) is None

    with pytest.raises(exceptions.DebitError, match="Cannot debit bitcoins."):
        events.debit(ledger_db, defaults["addresses"][0], "BTC", defaults["quantity"], 0)

    with pytest.raises(exceptions.DebitError, match="Negative quantity."):
        events.debit(ledger_db, defaults["addresses"][0], "BTC", -1 * defaults["quantity"], 0)

    with pytest.raises(exceptions.DebitError, match="Quantity must be an integer."):
        events.debit(ledger_db, defaults["addresses"][0], "BTC", 1.1 * defaults["quantity"], 0)

    with pytest.raises(exceptions.DebitError, match="Insufficient funds."):
        events.debit(ledger_db, defaults["addresses"][0], "XCP", 2**40, 0)

    assert events.credit(ledger_db, defaults["addresses"][0], "XCP", 1, 0) is None

    with pytest.raises(exceptions.CreditError, match="Cannot debit bitcoins."):
        events.credit(ledger_db, defaults["addresses"][0], "BTC", defaults["quantity"], 0)

    with pytest.raises(exceptions.CreditError, match="Negative quantity."):
        events.credit(ledger_db, defaults["addresses"][0], "BTC", -1 * defaults["quantity"], 0)

    with pytest.raises(exceptions.CreditError, match="Quantity must be an integer."):
        events.credit(ledger_db, defaults["addresses"][0], "BTC", 1.1 * defaults["quantity"], 0)
