import apsw
from counterpartycore.lib.ledger import blocks


def test_blocks_functions(ledger_db, current_block_index):
    last_block = blocks.get_block(ledger_db, current_block_index)
    assert (
        last_block["block_hash"]
        == "7dd8c57f20e51f94dccfb1dfdd5388321590eaa5814de7d39d9746df68fd6c7c"
    )
    assert last_block["block_index"] == current_block_index
    assert (
        last_block["ledger_hash"]
        == "c2baeb3caea2b1af2be5c98d7b7147e7e42ad4360a4da0d9e5d9191f9d7e4024"
    )
    assert (
        last_block["txlist_hash"]
        == "dc76d30ab05b9b1ff31bf391583a37303bed5a1c91de4d089161c3c447aa6758"
    )

    assert blocks.last_db_index(ledger_db) == current_block_index

    last_block = blocks.get_block_by_hash(ledger_db, last_block["block_hash"])
    assert (
        last_block["block_hash"]
        == "7dd8c57f20e51f94dccfb1dfdd5388321590eaa5814de7d39d9746df68fd6c7c"
    )
    assert last_block["block_index"] == current_block_index
    assert (
        last_block["ledger_hash"]
        == "c2baeb3caea2b1af2be5c98d7b7147e7e42ad4360a4da0d9e5d9191f9d7e4024"
    )
    assert (
        last_block["txlist_hash"]
        == "dc76d30ab05b9b1ff31bf391583a37303bed5a1c91de4d089161c3c447aa6758"
    )

    assert (
        blocks.get_block_hash(ledger_db, current_block_index)
        == "7dd8c57f20e51f94dccfb1dfdd5388321590eaa5814de7d39d9746df68fd6c7c"
    )
    assert blocks.get_block_hash(ledger_db, 999999999999999) is None
    assert blocks.get_vouts(ledger_db, "hash") == []

    all_txs = blocks.get_transactions(ledger_db)
    assert len(all_txs) == 72
    assert (
        all_txs[0]["tx_hash"] == "5adde02c200e7959a453c2fc362e9baf20fe4ef3c8a37b9ce601be238ad4e6fa"
    )
    assert all_txs[0]["tx_index"] == 0
    assert blocks.get_transactions(ledger_db, tx_hash=all_txs[0]["tx_hash"]) == [all_txs[0]]
    assert blocks.get_transactions(ledger_db, tx_index=all_txs[0]["tx_index"]) == [all_txs[0]]
    assert blocks.get_transactions(
        ledger_db, tx_hash=all_txs[0]["tx_hash"], tx_index=all_txs[0]["tx_index"]
    ) == [all_txs[0]]

    assert blocks.get_transaction(ledger_db, all_txs[0]["tx_hash"]) == all_txs[0]
    assert blocks.get_transaction(ledger_db, "foobar") is None


def test_no_blocks_table(empty_ledger_db):
    dummy_db = apsw.Connection(":memory:")
    assert blocks.last_db_index(dummy_db) == 0

    empty_ledger_db.execute("""PRAGMA foreign_keys=OFF""")
    empty_ledger_db.execute("""DELETE FROM blocks""")
    assert blocks.last_db_index(empty_ledger_db) == 0
