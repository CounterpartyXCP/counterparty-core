from counterpartycore.lib import config, exceptions
from counterpartycore.lib.ledger.events import insert_update

#####################
#    BROADCASTS     #
#####################


def get_oracle_last_price(db, oracle_address, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM broadcasts
        WHERE source = :source AND status = :status AND block_index < :block_index
        ORDER by tx_index DESC LIMIT 1
    """
    bindings = {"source": oracle_address, "status": "valid", "block_index": block_index}
    cursor.execute(query, bindings)
    broadcasts = cursor.fetchall()
    cursor.close()

    if len(broadcasts) == 0:
        return None, None, None, None

    oracle_broadcast = broadcasts[0]
    oracle_label = oracle_broadcast["text"].split("-")
    if len(oracle_label) == 2:
        fiat_label = oracle_label[1]
    else:
        fiat_label = ""

    return (
        oracle_broadcast["value"],
        oracle_broadcast["fee_fraction_int"],
        fiat_label,
        oracle_broadcast["block_index"],
    )


def get_broadcasts_by_source(db, address: str, status: str = "valid", order_by: str = "DESC"):
    """
    Returns the broadcasts of a source
    :param str address: The address to return (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param str status: The status of the broadcasts to return (e.g. valid)
    :param str order_by: The order of the broadcasts to return (e.g. ASC)
    """
    if order_by not in ["ASC", "DESC"]:
        raise exceptions.InvalidArgument("Invalid order_by parameter")
    cursor = db.cursor()
    query = f"""
        SELECT * FROM broadcasts
        WHERE (status = ? AND source = ?)
        ORDER BY tx_index {order_by}
    """  # nosec B608  # noqa: S608 # nosec B608
    bindings = (status, address)
    cursor.execute(query, bindings)
    return cursor.fetchall()


#####################
#       BURNS       #
#####################


def get_burns(db, address: str = None, status: str = "valid"):
    """
    Returns the burns of an address
    :param str address: The address to return
    :param str status: The status of the burns to return
    """
    cursor = db.cursor()
    where = []
    bindings = []
    if status is not None:
        where.append("status = ?")
        bindings.append(status)
    if address is not None:
        where.append("source = ?")
        bindings.append(address)
    # no sql injection here
    query = f"""SELECT * FROM burns WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608 # nosec B608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


######################################
#       BLOCKS AND TRANSACTIONS      #
######################################


def get_addresses(db, address=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if address is not None:
        where.append("address = ?")
        bindings.append(address)
    # no sql injection here
    query = f"""SELECT *, MAX(rowid) AS rowid FROM addresses WHERE ({" AND ".join(where)}) GROUP BY address"""  # nosec B608  # noqa: S608 # nosec B608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_send_msg_index(db, tx_hash):
    cursor = db.cursor()
    last_msg_index = cursor.execute(
        """
        SELECT MAX(msg_index) as msg_index FROM sends WHERE tx_hash = ?
    """,
        (tx_hash,),
    ).fetchone()
    if last_msg_index and last_msg_index["msg_index"] is not None:
        msg_index = last_msg_index["msg_index"] + 1
    else:
        msg_index = 0
    return msg_index


#####################
#       BETS        #
#####################

### SELECTS ###


def get_pending_bet_matches(db, feed_address, order_by=None):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM bet_matches
            WHERE feed_address = ?
            GROUP BY id
        ) WHERE status = ?
    """
    if order_by is not None:
        query += f""" ORDER BY {order_by}"""
    else:
        query += f""" ORDER BY rowid"""  # noqa: F541
    bindings = (feed_address, "pending")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bet_matches_to_expire(db, block_time):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM bet_matches
            WHERE deadline < ? AND deadline > ?
            GROUP BY id
        ) WHERE status = ?
        ORDER BY rowid
    """
    bindings = (
        block_time - config.TWO_WEEKS,
        block_time
        - 2 * config.TWO_WEEKS,  # optimize query: assuming before that we have already expired
        "pending",
    )
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bet(db, bet_hash: str):
    """
    Returns the information of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 5d097b4729cb74d927b4458d365beb811a26fcee7f8712f049ecbe780eb496ed)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM bets
        WHERE tx_hash = ?
        ORDER BY rowid DESC LIMIT 1
    """
    bindings = (bet_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bets_to_expire(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bets
            WHERE expire_index = ? - 1
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (block_index, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_matching_bets(db, feed_address, bet_type):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bets
            WHERE (feed_address = ? AND bet_type = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (feed_address, bet_type, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bet_by_feed(db, address: str, status: str = "open"):
    """
    Returns the bets of a feed
    :param str address: The address of the feed (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param str status: The status of the bet (e.g. filled)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bets
            WHERE feed_address = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (address, status)
    cursor.execute(query, bindings)
    return cursor.fetchall()


### UPDATES ###


def update_bet(db, tx_hash, update_data):
    insert_update(db, "bets", "tx_hash", tx_hash, update_data, "BET_UPDATE")


def update_bet_match_status(db, bet_match_id, status):
    update_data = {"status": status}
    insert_update(db, "bet_matches", "id", bet_match_id, update_data, "BET_MATCH_UPDATE")
