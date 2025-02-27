from counterpartycore.lib import config


def get_block(db, block_index: int):
    """
    Return the information of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    query = """
        SELECT * FROM blocks
        WHERE block_index = ?
    """
    bindings = (block_index,)
    cursor = db.cursor()
    cursor.execute(query, bindings)
    return cursor.fetchone()


def last_db_index(db):
    cursor = db.cursor()
    query = "SELECT name FROM sqlite_master WHERE type='table' AND name='blocks'"
    if len(list(cursor.execute(query))) == 0:
        return 0

    query = "SELECT block_index FROM blocks WHERE ledger_hash IS NOT NULL ORDER BY block_index DESC LIMIT 1"
    blocks = list(cursor.execute(query))
    if len(blocks) == 0:
        return 0

    return blocks[0]["block_index"]


def get_block_by_hash(db, block_hash: str):
    """
    Return the information of a block
    :param int block_hash: The hash of the block to return (e.g. 00000000000000000001158f52eae43aa7fede1bb675736f105ccb545edcf5dd)
    """
    query = """
        SELECT * FROM blocks
        WHERE block_hash = ?
    """
    bindings = (block_hash,)
    cursor = db.cursor()
    cursor.execute(query, bindings)
    return cursor.fetchone()


def get_last_block(db):
    cursor = db.cursor()
    query = "SELECT * FROM blocks WHERE block_index != ? ORDER BY block_index DESC LIMIT 1"
    cursor.execute(query, (config.MEMPOOL_BLOCK_INDEX,))
    block = cursor.fetchone()
    return block


def get_block_hash(db, block_index):
    query = """
        SELECT block_hash FROM blocks
        WHERE block_index = ?
    """
    bindings = (block_index,)
    cursor = db.cursor()
    cursor.execute(query, bindings)
    block = cursor.fetchone()
    if block is None:
        return None
    return block["block_hash"]


def get_blocks_time(db, block_indexes):
    cursor = db.cursor()
    query = f"""
        SELECT block_index, block_time
        FROM blocks
        WHERE block_index IN ({",".join(["?" for e in range(0, len(block_indexes))])})
    """  # nosec B608  # noqa: S608 # nosec B608
    cursor.execute(query, block_indexes)
    blocks = cursor.fetchall()
    result = {}
    for block in blocks:
        result[block["block_index"]] = block["block_time"]
    return result


def get_vouts(db, tx_hash):
    cursor = db.cursor()
    query = """
        SELECT txs.source AS source, txs_outs.*
        FROM transaction_outputs txs_outs
        LEFT JOIN transactions txs ON txs.tx_hash = txs_outs.tx_hash
        WHERE txs_outs.tx_hash=:tx_hash
        ORDER BY txs_outs.out_index
    """
    bindings = {"tx_hash": tx_hash}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_transactions(db, tx_hash=None, tx_index=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if tx_hash is not None:
        where.append("tx_hash = ?")
        bindings.append(tx_hash)
    if tx_index is not None:
        where.append("tx_index = ?")
        bindings.append(tx_index)
    # no sql injection here
    if len(where) > 0:
        query = f"""SELECT * FROM transactions WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608 # nosec B608
    else:
        query = "SELECT * FROM transactions"
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_transaction(db, tx_hash: str):
    """
    Returns the information of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 876a6cfbd4aa22ba4fa85c2e1953a1c66649468a43a961ad16ea4d5329e3e4c5)
    """
    transactions = get_transactions(db, tx_hash)
    if transactions:
        return transactions[0]
    return None
