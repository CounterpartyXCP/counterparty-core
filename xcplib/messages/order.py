#! /usr/bin/python3

def initialise(db):
    cursor = db.cursor()

    # Orders
    cursor.execute('''CREATE TABLE IF NOT EXISTS orders(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      give_asset TEXT,
                      give_quantity INTEGER,
                      give_remaining INTEGER,
                      get_asset TEXT,
                      get_quantity INTEGER,
                      get_remaining INTEGER,
                      expiration INTEGER,
                      expire_index INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      PRIMARY KEY (tx_index, tx_hash))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON orders (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      index_hash_idx ON orders (tx_index, tx_hash)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      expire_idx ON orders (expire_index, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      give_status_idx ON orders (give_asset, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_give_status_idx ON orders (source, give_asset, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      give_get_status_idx ON orders (get_asset, give_asset, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON orders (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      give_asset_idx ON orders (give_asset)
                   ''')

    # Order Matches
    cursor.execute('''CREATE TABLE IF NOT EXISTS order_matches(
                      id TEXT PRIMARY KEY,
                      tx0_index INTEGER,
                      tx0_hash TEXT,
                      tx0_address TEXT,
                      tx1_index INTEGER,
                      tx1_hash TEXT,
                      tx1_address TEXT,
                      forward_asset TEXT,
                      forward_quantity INTEGER,
                      backward_asset TEXT,
                      backward_quantity INTEGER,
                      tx0_block_index INTEGER,
                      tx1_block_index INTEGER,
                      block_index INTEGER,
                      tx0_expiration INTEGER,
                      tx1_expiration INTEGER,
                      match_expire_index INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx0_index, tx0_hash, tx0_block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      FOREIGN KEY (tx1_index, tx1_hash, tx1_block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      match_expire_idx ON order_matches (status, match_expire_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      forward_status_idx ON order_matches (forward_asset, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      backward_status_idx ON order_matches (backward_asset, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      id_idx ON order_matches (id)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx0_address_idx ON order_matches (tx0_address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx1_address_idx ON order_matches (tx1_address)
                   ''')

    # Order Expirations
    cursor.execute('''CREATE TABLE IF NOT EXISTS order_expirations(
                      order_index INTEGER PRIMARY KEY,
                      order_hash TEXT UNIQUE,
                      source TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index),
                      FOREIGN KEY (order_index, order_hash) REFERENCES orders(tx_index, tx_hash))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON order_expirations (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON order_expirations (source)
                   ''')

def validate (db, source, give_asset, give_quantity, get_asset, get_quantity, expiration, block_index):

def compose (db, source, give_asset, give_quantity, get_asset, get_quantity, expiration):

def parse (db, tx, message):