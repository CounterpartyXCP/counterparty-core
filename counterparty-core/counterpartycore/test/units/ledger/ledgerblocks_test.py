import apsw
from counterpartycore.lib.ledger import blocks


def test_blocks_functions(ledger_db, current_block_index):
    last_block = blocks.get_block(ledger_db, current_block_index)
    assert (
        last_block["block_hash"]
        == "8bb22b9d86a16dc8231d3da9e1279cf75824876af6bcb26394b8d9bb67e35937"
    )
    assert last_block["block_index"] == current_block_index
    assert (
        last_block["ledger_hash"]
        == "5e9a6d091e2e6d81b669f32eb1b8bcab1ab5cbe416dd7ddf1b19e4352181204a"
    )
    assert (
        last_block["txlist_hash"]
        == "c9ae2c34029a5d4ae2e4574cc3617c3f5d2fa0c24710ea525386936e70f1511d"
    )

    assert blocks.last_db_index(ledger_db) == current_block_index

    last_block = blocks.get_block_by_hash(ledger_db, last_block["block_hash"])
    assert (
        last_block["block_hash"]
        == "8bb22b9d86a16dc8231d3da9e1279cf75824876af6bcb26394b8d9bb67e35937"
    )
    assert last_block["block_index"] == current_block_index
    assert (
        last_block["ledger_hash"]
        == "5e9a6d091e2e6d81b669f32eb1b8bcab1ab5cbe416dd7ddf1b19e4352181204a"
    )
    assert (
        last_block["txlist_hash"]
        == "c9ae2c34029a5d4ae2e4574cc3617c3f5d2fa0c24710ea525386936e70f1511d"
    )

    assert (
        blocks.get_block_hash(ledger_db, current_block_index)
        == "8bb22b9d86a16dc8231d3da9e1279cf75824876af6bcb26394b8d9bb67e35937"
    )
    assert blocks.get_block_hash(ledger_db, 999999999999999) is None
    assert blocks.get_vouts(ledger_db, "hash") == []

    all_txs = blocks.get_transactions(ledger_db)
    print(all_txs[0]["tx_hash"], all_txs[0]["tx_index"])
    assert len(all_txs) == 68
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
