#! /usr/bin/python3

from counterpartylib.lib.messages.versions import send1

ID = send1.ID

def initialise (db):
    cursor = db.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS sends(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      destination TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON sends (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON sends (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      destination_idx ON sends (destination)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_idx ON sends (asset)
                   ''')

def unpack(db, message, block_index):
    return send1.unpack(db, message, block_index)

def validate (db, source, destination, asset, quantity, block_index):
    return send1.validate(db, source, destination, asset, quantity, block_index)

def compose (db, source, destination, asset, quantity):
    return send1.compose(db, source, destination, asset, quantity)

def parse (db, tx, message):    # TODO: *args
    return send1.parse(db, tx, message)


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4

