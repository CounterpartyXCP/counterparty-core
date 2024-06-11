import logging

from counterpartycore.lib import config, database

from . import rps

logger = logging.getLogger(config.LOGGER_NAME)

# move random rps_match_id
ID = 81


def initialise(db):
    cursor = db.cursor()

    # remove misnamed indexes
    database.drop_indexes(cursor, ["block_index_idx", "source_idx", "rps_match_id_idx"])

    cursor.execute("""CREATE TABLE IF NOT EXISTS rpsresolves(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      move INTEGER,
                      random TEXT,
                      rps_match_id TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   """)

    database.create_indexes(
        cursor,
        "rpsresolves",
        [
            ["block_index"],
            ["source"],
            ["rps_match_id"],
        ],
    )


def parse(db, tx, message):
    rps.parse(db, tx, message)
