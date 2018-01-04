#! /usr/bin/python3

from counterpartylib.lib.messages.versions import send1
from counterpartylib.lib.messages.versions import enhanced_send
from counterpartylib.lib.messages.versions import mpma
from counterpartylib.lib import util
from counterpartylib.lib import exceptions

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
    columns = [column['name'] for column in cursor.execute('''PRAGMA table_info(sends)''')]

    # If CIP10 activated, Create Sends copy, copy old data, drop old table, rename new table, recreate indexes
    #   SQLite can’t do `ALTER TABLE IF COLUMN NOT EXISTS` nor can drop UNIQUE constraints
    if 'msg_index' not in columns:
        if 'memo' not in columns:
            cursor.execute('''CREATE TABLE new_sends(
                              tx_index INTEGER,
                              tx_hash TEXT,
                              block_index INTEGER,
                              source TEXT,
                              destination TEXT,
                              asset TEXT,
                              quantity INTEGER,
                              status TEXT,
                              msg_index INTEGER DEFAULT 0,
                              PRIMARY KEY (tx_index, msg_index),
                              FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                              UNIQUE (tx_hash, msg_index) ON CONFLICT FAIL)
                           ''')
            cursor.execute('''INSERT INTO new_sends(tx_index, tx_hash, block_index, source, destination, asset, quantity, status)
                SELECT tx_index, tx_hash, block_index, source, destination, asset, quantity, status
                FROM sends''', {})
        else:
            cursor.execute('''CREATE TABLE new_sends(
                  tx_index INTEGER,
                  tx_hash TEXT,
                  block_index INTEGER,
                  source TEXT,
                  destination TEXT,
                  asset TEXT,
                  quantity INTEGER,
                  status TEXT,
                  memo BLOB,
                  msg_index INTEGER DEFAULT 0,
                  PRIMARY KEY (tx_index, msg_index),
                  FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                  UNIQUE (tx_hash, msg_index) ON CONFLICT FAIL)
               ''')
            cursor.execute('''INSERT INTO new_sends (tx_index, tx_hash, block_index, source, destination, asset, quantity, status, memo)
                SELECT tx_index, tx_hash, block_index, source, destination, asset, quantity, status, memo
                FROM sends''', {})

        cursor.execute('DROP TABLE sends')
        cursor.execute('ALTER TABLE new_sends RENAME TO sends')

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

    if 'memo' not in columns:
        cursor.execute('''ALTER TABLE sends ADD COLUMN memo BLOB''')

    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      memo_idx ON sends (memo)
                   ''')

def unpack(db, message, block_index):
    return send1.unpack(db, message, block_index)

def validate (db, source, destination, asset, quantity, block_index):
    return send1.validate(db, source, destination, asset, quantity, block_index)

def compose (db, source, destination, asset, quantity, memo=None, memo_is_hex=False, use_enhanced_send=None):
    # special case - enhanced_send replaces send by default when it is enabled
    #   but it can be explicitly disabled with an API parameter
    if util.enabled('enhanced_sends'):
        # Another special case, if destination, asset and quantity are arrays, it's an MPMA send
        if util.enabled('mpma_sends') and isinstance(destination, list) and isinstance(asset, list) and isinstance(quantity, list):
            return mpma.compose(db, source, zip(asset, destination, quantity))
        elif use_enhanced_send is None or use_enhanced_send == True:
            return enhanced_send.compose(db, source, destination, asset, quantity, memo, memo_is_hex)
    elif memo is not None or use_enhanced_send == True:
        raise exceptions.ComposeError('enhanced sends are not enabled')


    return send1.compose(db, source, destination, asset, quantity)

def parse (db, tx, message):    # TODO: *args
    return send1.parse(db, tx, message)


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
