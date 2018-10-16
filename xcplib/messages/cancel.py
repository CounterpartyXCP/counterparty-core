#! /usr/bin/python3

def initialise (db):
    cursor = db.cursor()

    # Cancels
    cursor.execute('''CREATE TABLE IF NOT EXISTS cancels(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      offer_hash TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
                      # Offer hash is not a foreign key. (And it cannot be, because of some invalid cancels.)
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      cancels_block_index_idx ON cancels (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON cancels (source)
                   ''')

def validate (db, source, offer_hash):

def compose (db, source, offer_hash):

def parse (db, tx, message):
