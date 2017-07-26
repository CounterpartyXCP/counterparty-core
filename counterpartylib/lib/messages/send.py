#! /usr/bin/python3

from counterpartylib.lib.messages.versions import send1
from counterpartylib.lib.messages.versions import enhanced_send
from counterpartylib.lib import util

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

    # Adds a memo to sends
    #   SQLite can’t do `ALTER TABLE IF COLUMN NOT EXISTS`.
    columns = [column['name'] for column in cursor.execute('''PRAGMA table_info(sends)''')]
    if 'memo' not in columns:
        cursor.execute('''ALTER TABLE sends ADD COLUMN memo BLOB''')

    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      memo_idx ON sends (memo)
                   ''')

def unpack(db, message, block_index):
    return send1.unpack(db, message, block_index)

def validate (db, source, destination, asset, quantity, block_index):
    return send1.validate(db, source, destination, asset, quantity, block_index)

def compose (db, source, destination, asset, quantity, use_enhanced_send=None, memo=None, memo_is_hex=False):
    # special case - enhanced_send replaces send by default when it is enabled
    #   but it can be explicitly disabled with an API parameter
    if util.enabled('enhanced_sends'):
        if use_enhanced_send is None or use_enhanced_send == True:
            return enhanced_send.compose(db, source, destination, asset, quantity, memo, memo_is_hex)

    return send1.compose(db, source, destination, asset, quantity)

def parse (db, tx, message):    # TODO: *args
    return send1.parse(db, tx, message)


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4

