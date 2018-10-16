#! /usr/bin/python3

from .messages import (burn, cancel, dividend, issuance, order, send)

def initialise(db):
    cursor = db.cursor()

    # Blocks
    cursor.execute('''CREATE TABLE IF NOT EXISTS blocks(
                      block_index INTEGER UNIQUE,
                      block_hash TEXT UNIQUE,
                      previous_block_hash TEXT UNIQUE,
                      ledger_hash TEXT,
                      txlist_hash TEXT,
                      messages_hash TEXT,
                      block_time INTEGER,
                      difficulty INTEGER,
                      PRIMARY KEY (block_index, block_hash))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON blocks (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      index_hash_idx ON blocks (block_index, block_hash)
                   ''')

    # Transactions
    cursor.execute('''CREATE TABLE IF NOT EXISTS transactions(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      block_hash TEXT,
                      block_time INTEGER,
                      source TEXT,
                      destination TEXT,
                      btc_amount INTEGER,
                      fee INTEGER,
                      data BLOB,
                      supported BOOL DEFAULT 1,
                      FOREIGN KEY (block_index, block_hash) REFERENCES blocks(block_index, block_hash),
                      PRIMARY KEY (tx_index, tx_hash, block_index))
                    ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON transactions (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx_index_idx ON transactions (tx_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx_hash_idx ON transactions (tx_hash)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      index_index_idx ON transactions (block_index, tx_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      index_hash_index_idx ON transactions (tx_index, tx_hash, block_index)
                   ''')

    # Messages
    cursor.execute('''CREATE TABLE IF NOT EXISTS messages(
                      message_index INTEGER PRIMARY KEY,
                      block_index INTEGER,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER)
                  ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON messages (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_message_index_idx ON messages (block_index, message_index)
                   ''')

    # Debits
    cursor.execute('''CREATE TABLE IF NOT EXISTS debits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      action TEXT,
                      event TEXT,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      address_idx ON debits (address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_idx ON debits (asset)
                   ''')

    # Credits
    cursor.execute('''CREATE TABLE IF NOT EXISTS credits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      action TEXT,
                      event TEXT,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      address_idx ON credits (address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_idx ON credits (asset)
                   ''')

    # Balances
    cursor.execute('''CREATE TABLE IF NOT EXISTS balances(
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      address_asset_idx ON balances (address, asset)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      address_idx ON balances (address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_idx ON balances (asset)
                   ''')

    # Assets
    cursor.execute('''CREATE TABLE IF NOT EXISTS assets(
                      asset_id TEXT UNIQUE,
                      asset_name TEXT UNIQUE,
                      block_index INTEGER)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      name_idx ON assets (asset_name)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      id_idx ON assets (asset_id)
                   ''')

    # Addresses
    cursor.execute('''CREATE TABLE IF NOT EXISTS addresses(
                      address TEXT UNIQUE,
                      options INTEGER,
                      block_index INTEGER)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      addresses_idx ON addresses (address)
                   ''')

    # Consolidated
    burn.initialise(db)
    cancel.initialise(db)
    dividend.initialise(db)
    issuance.initialise(db)
    order.initialise(db)
    send.initialise(db)
