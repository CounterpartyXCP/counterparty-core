import apsw
from counterpartycore.lib.ledger import blocks


def test_blocks_functions(ledger_db, current_block_index):
    last_block = blocks.get_block(ledger_db, current_block_index)
    assert (
        last_block["block_hash"]
        == "5f0d5c07accb0f04a59deb15b8e92524668c087f4678f11fe99bf29befc3a29d"
    )
    assert last_block["block_index"] == current_block_index
    assert (
        last_block["ledger_hash"]
        == "084d9a93dea77718d67f44e5bb34a63539f4d5437132d8af2b1abfb1e8ddf848"
    )
    assert (
        last_block["txlist_hash"]
        == "46a70e84023ed477615c80ac6acad01afc0765b3f8084d293efa15a8c5cdd750"
    )

    assert blocks.last_db_index(ledger_db) == current_block_index

    last_block = blocks.get_block_by_hash(ledger_db, last_block["block_hash"])
    assert (
        last_block["block_hash"]
        == "5f0d5c07accb0f04a59deb15b8e92524668c087f4678f11fe99bf29befc3a29d"
    )
    assert last_block["block_index"] == current_block_index
    assert (
        last_block["ledger_hash"]
        == "084d9a93dea77718d67f44e5bb34a63539f4d5437132d8af2b1abfb1e8ddf848"
    )
    assert (
        last_block["txlist_hash"]
        == "46a70e84023ed477615c80ac6acad01afc0765b3f8084d293efa15a8c5cdd750"
    )

    assert (
        blocks.get_block_hash(ledger_db, current_block_index)
        == "5f0d5c07accb0f04a59deb15b8e92524668c087f4678f11fe99bf29befc3a29d"
    )
    assert blocks.get_block_hash(ledger_db, 999999999999999) is None
    assert blocks.get_vouts(ledger_db, "hash") == []

    all_txs = blocks.get_transactions(ledger_db)
    print(all_txs[0]["tx_hash"], all_txs[0]["tx_index"])
    assert len(all_txs) == 64
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
