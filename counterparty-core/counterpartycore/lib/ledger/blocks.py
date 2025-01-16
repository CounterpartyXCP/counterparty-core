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
