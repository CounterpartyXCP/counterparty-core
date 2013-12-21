"""
Initialise database.

Sieve blockchain for Counterparty transactions, and add them to the database.
"""

import os
import time
import binascii
import struct
import sqlite3
import warnings

from . import (config, util, bitcoin)
from . import (send, order, btcpayment, issuance, broadcast, bet, dividend, burn)

def parse_block (db, cursor, block_index):
    """This is a separate function from follow() so that changing the parsing
    rules doesn’t require a full database rebuild. If parsing rules are changed
    (but not data identification), then just restart `counterparty.py follow`.

    """
    print('Block:', block_index) #

    # Parse transactions, sorting them by type.
    cursor.execute('''SELECT * FROM transactions \
                      WHERE block_index=? ORDER BY tx_index''',
                   (block_index,))
        
    for tx in cursor.fetchall():
        if tx['data'][:len(config.PREFIX)] == config.PREFIX:
            post_prefix = tx['data'][len(config.PREFIX):]
        else:
            continue
        message_type_id = struct.unpack(config.TXTYPE_FORMAT, post_prefix[:4])[0]
        message = post_prefix[4:]
        # TODO: Make sure that message lengths are correct. (struct.unpack is fragile.)
        # TODO: Re‐name parse_send, e.g., to parse, etc.
        if message_type_id == send.ID:
            db, cursor = send.parse_send(db, cursor, tx, message)
        elif message_type_id == order.ID:
            db, cursor = order.parse_order(db, cursor, tx, message)
        elif message_type_id == btcpayment.ID:
            db, cursor = btcpayment.parse_btcpayment(db, cursor, tx, message)
        elif message_type_id == issuance.ID:
            db, cursor = issuance.parse_issuance(db, cursor, tx, message)
        elif message_type_id == broadcast.ID:
            db, cursor = broadcast.parse(db, cursor, tx, message)
        elif message_type_id == bet.ID:
            db, cursor = bet.parse(db, cursor, tx, message)
        elif message_type_id == dividend.ID:
            db, cursor = dividend.parse(db, cursor, tx, message)
        elif message_type_id == burn.ID:
            db, cursor = burn.parse(db, cursor, tx, message)
        else:
            # Mark transaction as of unsupported type.
            cursor.execute('''UPDATE transactions \
                              SET supported=? \
                              WHERE tx_hash=?''',
                           ('False', tx['tx_hash']))
            print('Unsupported transaction:', message_type_id)
            print('Unsupported transaction:', tx['tx_hash'])
        db.commit()

    # TODO: Is it a problem that this comes after the parsing?! (inclusive vs. exclusive)
    db, cursor = order.expire(db, cursor, block_index)

    return db, cursor

def initialise(db, cursor):
    cursor.execute('''CREATE TABLE IF NOT EXISTS blocks(
                        block_index INTEGER PRIMARY KEY,
                        block_hash TEXT UNIQUE,
                        block_time INTEGER)
                   ''')

    cursor.execute('''CREATE TABLE IF NOT EXISTS transactions(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        block_time INTEGER,
                        source TEXT,
                        destination TEXT,
                        btc_amount INTEGER,
                        fee INTEGER,
                        data BLOB,
                        supported TEXT DEFAULT 'True')
                    ''')

    # Purge database of blocks, transactions from before BLOCK_FIRST.
    cursor.execute('''DELETE FROM blocks WHERE block_index<?''', (config.BLOCK_FIRST,))
    cursor.execute('''DELETE FROM transactions WHERE block_index<?''', (config.BLOCK_FIRST,))

    cursor.execute('''DROP TABLE IF EXISTS sends''')
    cursor.execute('''CREATE TABLE sends(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        destination TEXT,
                        asset_id INTEGER,
                        amount INTEGER,
                        validity TEXT)
                   ''')

    cursor.execute('''DROP TABLE IF EXISTS orders''')
    cursor.execute('''CREATE TABLE orders(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        give_id INTEGER,
                        give_amount INTEGER,
                        give_remaining INTEGER,
                        get_id INTEGER,
                        get_amount INTEGER,
                        ask_price REAL,
                        expiration INTEGER,
                        fee_required INTEGER,
                        fee_provided INTEGER,
                        validity TEXT)
                   ''')

    cursor.execute('''DROP TABLE IF EXISTS deals''')
    cursor.execute('''CREATE TABLE deals(
                        tx0_index INTEGER,
                        tx0_hash TEXT,
                        tx0_address TEXT,
                        tx1_index INTEGER,
                        tx1_hash TEXT,
                        tx1_address TEXT,
                        forward_id INTEGER,
                        forward_amount INTEGER,
                        backward_id INTEGER,
                        backward_amount INTEGER,
                        tx0_block_index INTEGER,
                        tx1_block_index INTEGER,
                        tx0_expiration INTEGER,
                        tx1_expiration INTEGER,
                        validity TEXT)
                   ''')

    cursor.execute('''DROP TABLE IF EXISTS issuances''')
    cursor.execute('''CREATE TABLE issuances(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        asset_id INTEGER,
                        amount INTEGER,
                        divisible BOOL,
                        issuer TEXT,
                        validity TEXT
                        )
                   ''')

    for asset_id in (0,1):
        cursor.execute('''INSERT INTO issuances(
                            tx_index,
                            tx_hash,
                            block_index,
                            asset_id,
                            amount,
                            divisible,
                            issuer,
                            validity) VALUES(?,?,?,?,?,?,?,?)''',
                            (None,
                            None,
                            None,
                            asset_id,
                            0,
                            True,
                            None,
                            'Valid')
                      )

    cursor.execute('''DROP TABLE IF EXISTS broadcasts''')
    cursor.execute('''CREATE TABLE broadcasts(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        timestamp INTEGER,
                        value REAL,
                        fee_multiplier INTEGER,
                        text TEXT,
                        validity TEXT)
                   ''')

    cursor.execute('''DROP TABLE IF EXISTS bets''')
    cursor.execute('''CREATE TABLE bets(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        feed_address TEXT,
                        bet_type INTEGER,
                        deadline INTEGER,
                        wager_amount INTEGER,
                        counterwager_amount INTEGER,
                        wager_remaining INTEGER,
                        odds REAL,
                        threshhold REAL,
                        leverage INTEGER,
                        expiration INTEGER,
                        validity TEXT)
                   ''')

    cursor.execute('''DROP TABLE IF EXISTS contracts''')
    cursor.execute('''CREATE TABLE contracts(
                        tx0_index INTEGER,
                        tx0_hash TEXT,
                        tx0_address TEXT,
                        tx1_index INTEGER,
                        tx1_hash TEXT,
                        tx1_address TEXT,
                        tx0_bet_type INTEGER,
                        tx1_bet_type INTEGER,
                        feed_address TEXT,
                        initial_value INTEGER,
                        deadline INTEGER,
                        threshold REAL,
                        leverage INTEGER,
                        forward_amount INTEGER,
                        backward_amount INTEGER,
                        tx0_block_index INTEGER,
                        tx1_block_index INTEGER,
                        tx0_expiration INTEGER,
                        tx1_expiration INTEGER,
                        validity TEXT)
                   ''')

    cursor.execute('''DROP TABLE IF EXISTS dividend_payments''')
    cursor.execute('''CREATE TABLE dividend_payments(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        share_id INTEGER,
                        amount_per_share INTEGER,
                        validity TEXT)
                   ''')

    cursor.execute('''DROP TABLE IF EXISTS burns''')
    cursor.execute('''CREATE TABLE burns(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        address TEXT,
                        burned INTEGER,
                        earned INTEGER,
                        validity TEXT)
                   ''')

    cursor.execute('''DROP TABLE IF EXISTS balances''')
    cursor.execute('''CREATE TABLE balances(
                        address TEXT,
                        asset_id INTEGER,
                        amount INTEGER)
                   ''')


    # Initialize XCP balances. TEMP
    for address in ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',
                    'mnkzHBHRkBWoP9aFtocDe5atxmRfSRHnjR',
                    'mz8qzVaH8RaVp2Rq6m8D2dTiSFirhFf4th'):
        db, cursor = util.credit(db, cursor, address, 1, 10000 * int(config.UNIT))
    db.commit()

    return db, cursor

def get_tx_info (tx):
    fee = 0

    # Collect all possible source addresses; ignore coinbase transactions.
    source_list = []
    for vin in tx['vin']:                                               # Loop through input transactions.
        if 'coinbase' in vin: return None, None, None, None, None
        vin_tx = bitcoin.rpc('getrawtransaction', [vin['txid'], 1])['result']   # Get the full transaction data for this input transaction.
        vout = vin_tx['vout'][vin['vout']]
        fee += vout['value'] * config.UNIT
        source_list.append(vout['scriptPubKey']['addresses'][0])        # Assume that the output was not not multi‐sig.

    # Require that all possible source addresses be the same.
    if all(x == source_list[0] for x in source_list): source = source_list[0]
    else: source = None

    # Destination is the first output with a valid address, (if it exists).
    destination, btc_amount = None, None
    for vout in tx['vout']:
        if 'addresses' in vout['scriptPubKey']:
            address = vout['scriptPubKey']['addresses'][0]
            if bitcoin.rpc('validateaddress', [address])['result']['isvalid']:
                destination, btc_amount = address, vout['value'] * config.UNIT
                break

    for vout in tx['vout']:
        fee -= vout['value'] * config.UNIT

    # Loop through outputs until you come upon OP_RETURN, then get the data.
    # NOTE: This assumes only one OP_RETURN output.
    data = None
    for vout in tx['vout']:
        asm = vout['scriptPubKey']['asm'].split(' ')
        if asm[0] == 'OP_RETURN' and len(asm) == 2:
            data = binascii.unhexlify(asm[1])

    return source, destination, btc_amount, fee, data

def follow ():

    # Find and delete old versions of the database.
    os.chdir(config.data_dir)
    for filename in os.listdir('.'):
        filename_array = filename.split('.')
        if len(filename_array) != 3:
            continue
        if 'ledger' == filename_array[0] and 'db' == filename_array[2]:
            if filename_array[1] != str(config.DB_VERSION):
                os.remove(filename)
                warnings.warn('New version of transaction table! Deleting old \
                               databases.')

    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    # TODO: db.execute('pragma foreign_keys=ON')
    cursor = db.cursor()

    # Always re‐parse from beginning on start‐up.
    db, cursor = initialise(db, cursor)
    cursor.execute('''SELECT * FROM blocks ORDER BY block_index''')
    for block in cursor.fetchall():
        db, cursor = parse_block(db, cursor, block['block_index'])

    tx_index = 0
    while True:

        # Get index of last block.
        try:
            cursor.execute('''SELECT * FROM blocks WHERE block_index = (SELECT MAX(block_index) from blocks)''')
            block_index = cursor.fetchone()['block_index'] + 1
            assert not cursor.fetchone()
        except Exception:
            block_index = config.BLOCK_FIRST

        # Get index of last transaction.
        try:    # Ugly
            cursor.execute('''SELECT * FROM transactions WHERE tx_index = (SELECT MAX(tx_index) from transactions)''')
            tx_index = cursor.fetchone()['tx_index'] + 1
            assert not cursor.fetchone()
        except Exception:
            pass

        # Get block.
        block_count = bitcoin.rpc('getblockcount', [])['result']
        while block_index <= block_count:
            # print('Fetching block:', block_index)

            block_hash = bitcoin.rpc('getblockhash', [block_index])['result']
            block = bitcoin.rpc('getblock', [block_hash])['result']
            block_time = block['time']
            tx_hash_list = block['tx']

            # Get the transaction list for each block.
            for tx_hash in tx_hash_list:
                # Skip duplicate transaction entries.
                cursor.execute('''SELECT * FROM transactions WHERE tx_hash=?''', (tx_hash,))
                if cursor.fetchone():
                    tx_index += 1
                    continue
                # Get the important details about each transaction.
                tx = bitcoin.rpc('getrawtransaction', [tx_hash, 1])['result']
                source, destination, btc_amount, fee, data = get_tx_info(tx)
                if data and source:
                    cursor.execute('''INSERT INTO transactions(
                                        tx_index,
                                        tx_hash,
                                        block_index,
                                        block_time,
                                        source,
                                        destination,
                                        btc_amount,
                                        fee,
                                        data) VALUES(?,?,?,?,?,?,?,?,?)''',
                                        (tx_index,
                                         tx_hash,
                                         block_index,
                                         block_time,
                                         source,
                                         destination,
                                         btc_amount,
                                         fee,
                                         data)
                                  )
                    tx_index += 1

            # List the block after all of the transactions in it.
            cursor.execute('''INSERT INTO blocks(
                                block_index,
                                block_hash,
                                block_time) VALUES(?,?,?)''',
                                (block_index,
                                block_hash,
                                block_time)
                          )
            db.commit() # Commit only at end of block.

            # Parse transactions in this block.
            db, cursor = parse_block(db, cursor, block_index)

            # Increment block index.
            block_count = bitcoin.rpc('getblockcount', [])['result'] # Get block count.
            block_index +=1

        while block_index > block_count: # DUPE
            block_count = bitcoin.rpc('getblockcount', [])['result']
            time.sleep(20)

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
