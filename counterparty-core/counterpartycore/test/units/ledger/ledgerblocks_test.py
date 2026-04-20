import apsw
from counterpartycore.lib.ledger import blocks


def test_blocks_functions(ledger_db, current_block_index):
    last_block = blocks.get_block(ledger_db, current_block_index)
    assert (
        last_block["block_hash"]
        == "d478c438aec59c5a9c2079f7320d41363f1c7702b8975e47204ff2865340cfb3"
    )
    assert last_block["block_index"] == current_block_index
    assert (
        last_block["ledger_hash"]
        == "9f547b55042d971e96c2b89993c1bc535e105865a2a423a95e7720e7fe8efc32"
    )
    assert (
        last_block["txlist_hash"]
        == "ea512abeff736ecc252eecbbbbbc7070cabb6b8cc0430450b3716ec2e7f050bb"
    )

    assert blocks.last_db_index(ledger_db) == current_block_index

    last_block = blocks.get_block_by_hash(ledger_db, last_block["block_hash"])
    assert (
        last_block["block_hash"]
        == "d478c438aec59c5a9c2079f7320d41363f1c7702b8975e47204ff2865340cfb3"
    )
    assert last_block["block_index"] == current_block_index
    assert (
        last_block["ledger_hash"]
        == "9f547b55042d971e96c2b89993c1bc535e105865a2a423a95e7720e7fe8efc32"
    )
    assert (
        last_block["txlist_hash"]
        == "ea512abeff736ecc252eecbbbbbc7070cabb6b8cc0430450b3716ec2e7f050bb"
    )

    assert (
        blocks.get_block_hash(ledger_db, current_block_index)
        == "d478c438aec59c5a9c2079f7320d41363f1c7702b8975e47204ff2865340cfb3"
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
