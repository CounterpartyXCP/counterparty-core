from counterpartycore.lib.ledger import currentstate, markets


def test_markets(ledger_db, defaults):
    assert len(markets.get_pending_btc_order_matches(ledger_db, defaults["addresses"][0])) == 0
    assert len(markets.get_open_btc_orders(ledger_db, defaults["addresses"][0])) == 1

    original_state = currentstate.CurrentState().block_parser_status()
    currentstate.CurrentState().set_block_parser_status("catching up")
    assert len(markets.get_matching_orders(ledger_db, "tx_hash", "BTC", "XCP")) == 2
    currentstate.CurrentState().set_block_parser_status(original_state)

    open_orders = ledger_db.execute(
        """SELECT rowid FROM (
            SELECT *, MAX(rowid) as rowid
            FROM orders
            GROUP BY tx_hash
        )"""
    ).fetchall()
    ledger_db.execute("DROP TRIGGER block_update_orders")

    ledger_db.execute(
        "UPDATE orders SET give_remaining = 0 WHERE rowid = ?", (open_orders[0]["rowid"],)
    )
    ledger_db.execute(
        "UPDATE orders SET get_remaining = 0 WHERE rowid = ?", (open_orders[1]["rowid"],)
    )

    open_orders = ledger_db.execute(
        """SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM orders
            GROUP BY tx_hash
        ) WHERE give_remaining = 0 OR get_remaining = 0"""
    ).fetchall()

    order_filled_count_before = ledger_db.execute(
        "SELECT COUNT(*) AS count FROM orders WHERE status = ?", ("filled",)
    ).fetchone()["count"]

    markets.mark_order_as_filled(ledger_db, open_orders[0]["tx_hash"], open_orders[1]["tx_hash"])

    order_filled_count_after = ledger_db.execute(
        "SELECT COUNT(*) AS count FROM orders WHERE status = ?", ("filled",)
    ).fetchone()["count"]

    assert order_filled_count_before + 2 == order_filled_count_after

    dispensers = ledger_db.execute(
        "SELECT * FROM dispensers ORDER BY rowid DESC LIMIT 1"
    ).fetchall()

    assert markets.get_dispenser_info(ledger_db) == [dispensers[0]]
    assert markets.get_dispenser_info(ledger_db, tx_hash=dispensers[0]["tx_hash"]) == [
        dispensers[0]
    ]
    assert markets.get_dispenser_info(ledger_db, tx_index=dispensers[0]["tx_index"]) == [
        dispensers[0]
    ]
    assert markets.get_dispenser_info(
        ledger_db, tx_hash=dispensers[0]["tx_hash"], tx_index=dispensers[0]["tx_index"]
    ) == [dispensers[0]]

    result = markets.get_dispensers_info(ledger_db, [dispensers[0]["tx_hash"]])
    assert isinstance(result[dispensers[0]["tx_hash"]], dict)
    assert result[dispensers[0]["tx_hash"]]["tx_index"] == dispensers[0]["tx_index"]
