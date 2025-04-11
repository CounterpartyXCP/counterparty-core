import apsw
from counterpartycore.lib.ledger import blocks


def test_blocks_functions(ledger_db, current_block_index):
    last_block = blocks.get_block(ledger_db, current_block_index)
    assert (
        last_block["block_hash"]
        == "4b77f641741ee30f3d9b517b30e0c59b7622b6a4a6b4342348b6ceae2d351da6"
    )
    assert last_block["block_index"] == current_block_index
    assert (
        last_block["ledger_hash"]
        == "f6b2b412e0d3eeba5e7b700dded887912563055c19ba89b77b24bfbefca4da28"
    )
    assert (
        last_block["txlist_hash"]
        == "faf80adaea98671f728c0ec9435ea889aaf843fb89118db09990584dcbe55a44"
    )

    assert blocks.last_db_index(ledger_db) == current_block_index

    last_block = blocks.get_block_by_hash(ledger_db, last_block["block_hash"])
    assert (
        last_block["block_hash"]
        == "4b77f641741ee30f3d9b517b30e0c59b7622b6a4a6b4342348b6ceae2d351da6"
    )
    assert last_block["block_index"] == current_block_index
    assert (
        last_block["ledger_hash"]
        == "f6b2b412e0d3eeba5e7b700dded887912563055c19ba89b77b24bfbefca4da28"
    )
    assert (
        last_block["txlist_hash"]
        == "faf80adaea98671f728c0ec9435ea889aaf843fb89118db09990584dcbe55a44"
    )

    assert (
        blocks.get_block_hash(ledger_db, current_block_index)
        == "4b77f641741ee30f3d9b517b30e0c59b7622b6a4a6b4342348b6ceae2d351da6"
    )
    assert blocks.get_block_hash(ledger_db, 999999999999999) is None
    assert blocks.get_vouts(ledger_db, "hash") == []

    all_txs = blocks.get_transactions(ledger_db)
    print(all_txs[0]["tx_hash"], all_txs[0]["tx_index"])
    assert len(all_txs) == 67
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
