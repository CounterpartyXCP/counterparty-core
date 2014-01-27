"""
Initialise database.

Sieve blockchain for Counterparty transactions, and add them to the database.
"""

import os
import time
import binascii
import struct
import decimal
D = decimal.Decimal
import logging

from . import (config, util, bitcoin)
from . import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel)

def parse_block (db, block_index):
    """This is a separate function from follow() so that changing the parsing
    rules doesn't require a full database rebuild. If parsing rules are changed
    (but not data identification), then just restart `counterparty.py follow`.

    """
    parse_block_cursor = db.cursor()

    # Expire orders and bets.
    order.expire(db, block_index)
    bet.expire(db, block_index)

    # Parse transactions, sorting them by type.
    parse_block_cursor.execute('''SELECT * FROM transactions \
                      WHERE block_index=? ORDER BY tx_index''',
                   (block_index,))
    transactions = parse_block_cursor.fetchall()   
    for tx in transactions:

        # Burns.
        if tx['destination'] == config.UNSPENDABLE:
            burn.parse(db, tx)
            continue

        # Everything else.
        message_type_id = struct.unpack(config.TXTYPE_FORMAT, tx['data'][:4])[0]
        message = tx['data'][4:]
        if message_type_id == send.ID and len(message) == send.LENGTH:
            send.parse(db, tx, message)
        elif message_type_id == order.ID and len(message) == order.LENGTH:
            order.parse(db, tx, message)
        elif message_type_id == btcpay.ID and len(message) == btcpay.LENGTH:
            btcpay.parse(db, tx, message)
        elif message_type_id == issuance.ID and len(message) == issuance.LENGTH:
            issuance.parse(db, tx, message)
        elif message_type_id == broadcast.ID and len(message) == broadcast.LENGTH:
            broadcast.parse(db, tx, message)
        elif message_type_id == bet.ID and len(message) == bet.LENGTH:
            bet.parse(db, tx, message)
        elif message_type_id == dividend.ID and len(message) == dividend.LENGTH:
            dividend.parse(db, tx, message)
        elif message_type_id == cancel.ID and len(message) == cancel.LENGTH:
            cancel.parse(db, tx, message)
        else:
            # Mark transaction as of unsupported type.
            parse_block_cursor.execute('''UPDATE transactions \
                              SET supported=? \
                              WHERE tx_hash=?''',
                           (False, tx['tx_hash']))
            logging.info('Unsupported: message type {}; transaction hash {}'.format(message_type_id, tx['tx_hash']))

    parse_block_cursor.close()

def initialise(db):
    initialise_cursor = db.cursor()
    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS blocks(
                        block_index INTEGER PRIMARY KEY,
                        block_hash TEXT UNIQUE,
                        block_time INTEGER)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        blocks_block_index_idx ON blocks (block_index)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS transactions(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        block_time INTEGER,
                        source TEXT,
                        destination TEXT,
                        btc_amount INTEGER,
                        fee INTEGER,
                        data BLOB,
                        supported BOOL DEFAULT 1)
                    ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        transactions_block_index_idx ON transactions (block_index)
                    ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        transactions_tx_index_idx ON transactions (tx_index)
                    ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        transactions_tx_hash_idx ON transactions (tx_hash)
                    ''')

    # Purge database of blocks, transactions from before BLOCK_FIRST.
    initialise_cursor.execute('''DELETE FROM blocks WHERE block_index<?''', (config.BLOCK_FIRST,))
    initialise_cursor.execute('''DELETE FROM transactions WHERE block_index<?''', (config.BLOCK_FIRST,))

    # NOTE: Only valid debits listed
    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS debits(
                        address TEXT,
                        asset TEXT,
                        amount INTEGER)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        debits_address_idx ON debits (address)
                    ''')

    # NOTE: Only valid credits listed
    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS credits(
                        address TEXT,
                        asset TEXT,
                        amount INTEGER)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        credits_address_idx ON credits (address)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS balances(
                        address TEXT,
                        asset TEXT,
                        amount INTEGER)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        balances_address_idx ON balances (address)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS sends(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        destination TEXT,
                        asset TEXT,
                        amount INTEGER,
                        validity TEXT)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        sends_block_index_idx ON sends (block_index)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS orders(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        give_asset TEXT,
                        give_amount INTEGER,
                        give_remaining INTEGER,
                        get_asset TEXT,
                        get_amount INTEGER,
                        price REAL,
                        expiration INTEGER,
                        fee_required INTEGER,
                        fee_provided INTEGER,
                        validity TEXT)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        orders_block_index_idx ON orders (block_index)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS order_matches(
                        tx0_index INTEGER,
                        tx0_hash TEXT,
                        tx0_address TEXT,
                        tx1_index INTEGER,
                        tx1_hash TEXT,
                        tx1_address TEXT,
                        forward_asset INTEGER,
                        forward_amount INTEGER,
                        backward_asset INTEGER,
                        backward_amount INTEGER,
                        tx0_block_index INTEGER,
                        tx1_block_index INTEGER,
                        tx0_expiration INTEGER,
                        tx1_expiration INTEGER,
                        validity TEXT)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        order_matches_block_index_idx ON order_matches (tx0_block_index, tx1_block_index)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS btcpays(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        order_match_id TEXT,
                        validity TEXT)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        btcpays_block_index_idx ON btcpays (block_index)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS issuances(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        asset TEXT,
                        amount INTEGER,
                        divisible BOOL,
                        issuer TEXT,
                        transfer BOOL,
                        validity TEXT
                        )
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        issuances_idx ON issuances (block_index)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS broadcasts(
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
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        broadcasts_block_index_idx ON broadcasts (block_index)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS bets(
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
                        target_value REAL,
                        leverage INTEGER,
                        expiration INTEGER,
                        fee_multiplier INTEGER,
                        validity TEXT)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        bets_block_index_idx ON bets (block_index)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS bet_matches(
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
                        target_value REAL,
                        leverage INTEGER,
                        forward_amount INTEGER,
                        backward_amount INTEGER,
                        tx0_block_index INTEGER,
                        tx1_block_index INTEGER,
                        tx0_expiration INTEGER,
                        tx1_expiration INTEGER,
                        fee_multiplier INTEGER,
                        validity TEXT)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        bet_matches_block_index_idx ON bet_matches (tx0_block_index, tx1_block_index)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS dividends(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        asset TEXT,
                        amount_per_share INTEGER,
                        validity TEXT)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        dividends_block_index_idx ON dividends (block_index)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS burns(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        address TEXT,
                        burned INTEGER,
                        earned INTEGER,
                        validity TEXT)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        burns_block_index_idx ON burns (block_index)
                    ''')

    initialise_cursor.execute('''CREATE TABLE IF NOT EXISTS cancels(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        offer_hash TEXT,
                        validity TEXT)
                   ''')
    initialise_cursor.execute('''CREATE INDEX IF NOT EXISTS
                        cancels_block_index_idx ON cancels (block_index)
                    ''')

    initialise_cursor.close()

def get_tx_info (tx):
    """
    The destination, if it exists, always comes before the data output; the
    change, if it exists, always comes after.
    """

    # Fee is the input values minus output values.
    fee = D(0)

    # Get destination output and data output.
    destination, btc_amount, data = None, None, b''
    for vout in tx['vout']:
        fee -= D(vout['value']) * config.UNIT

        # Sum data chunks to get data. (Can mix OP_RETURN and multi‐sig.)
        asm = vout['scriptPubKey']['asm'].split(' ')
        if len(asm) == 2 and asm[0] == 'OP_RETURN':                                                 # OP_RETURN
            try: data_chunk = binascii.unhexlify(bytes(asm[1], 'utf-8'))
            except binascii.Error: continue
            data += data_chunk
        elif len(asm) >= 5 and asm[0] == '1' and asm[3] == '2' and asm[4] == 'OP_CHECKMULTISIG':    # Multi‐sig
            try: data_pubkey = binascii.unhexlify(bytes(asm[2], 'utf-8'))
            except binascii.Error: continue
            data_chunk_length = data_pubkey[0]  # No ord() necessary.
            data_chunk = data_pubkey[1:data_chunk_length + 1]
            data += data_chunk

        # Destination is the first output before the data.
        if not destination and not btc_amount and not data:
            if 'addresses' in vout['scriptPubKey']:
                address = vout['scriptPubKey']['addresses'][0]
                try:  # If address is valid…
                    bitcoin.base58_decode(address, config.ADDRESSVERSION)
                    destination, btc_amount = address, round(D(vout['value']) * config.UNIT)
                    continue
                except:
                    pass

    # Check for, and strip away, prefix (except for burns).
    if destination == config.UNSPENDABLE:
        pass
    elif data[:len(config.PREFIX)] == config.PREFIX:
        data = data[len(config.PREFIX):]
    else:
        return b'', None, None, None, None

    # Only look for source if data were found (or destination is UNSPENDABLE), for speed.
    if not data and destination != config.UNSPENDABLE:
        return b'', None, None, None, None

    # Collect all possible source addresses; ignore coinbase transactions.
    source_list = []
    for vin in tx['vin']:                                               # Loop through input transactions.
        if 'coinbase' in vin: return b'', None, None, None, None
        vin_tx = bitcoin.rpc('getrawtransaction', [vin['txid'], 1])     # Get the full transaction data for this input transaction.
        vout = vin_tx['vout'][vin['vout']]
        fee += D(vout['value']) * config.UNIT
        source_list.append(vout['scriptPubKey']['addresses'][0])        # Assume that the output was not not multi-sig.
    # Require that all possible source addresses be the same.
    if all(x == source_list[0] for x in source_list): source = source_list[0]
    else: source = None

    return source, destination, btc_amount, round(fee), data

def purge (db, quiet=False):
    # TODO: This is not thread‐safe!
    purge_cursor = db.cursor()

    # Delete all of the results of parsing from the database.
    # TODO: This is more than is necessary for reorgs. Rather, in that case, have every table have a block index column, and only delete the stuff required.
        # (What about table balances?)
            # Have ‘balance‐as‐of‐block‐N’?!
    # NOTE: dropping a table will also delete any indicies and triggers associated with it
    purge_cursor.execute('''DROP TABLE IF EXISTS debits''')
    purge_cursor.execute('''DROP TABLE IF EXISTS credits''')
    purge_cursor.execute('''DROP TABLE IF EXISTS balances''')
    purge_cursor.execute('''DROP TABLE IF EXISTS sends''')
    purge_cursor.execute('''DROP TABLE IF EXISTS orders''')
    purge_cursor.execute('''DROP TABLE IF EXISTS order_matches''')
    purge_cursor.execute('''DROP TABLE IF EXISTS btcpays''')
    purge_cursor.execute('''DROP TABLE IF EXISTS issuances''')
    purge_cursor.execute('''DROP TABLE IF EXISTS broadcasts''')
    purge_cursor.execute('''DROP TABLE IF EXISTS bets''')
    purge_cursor.execute('''DROP TABLE IF EXISTS bet_matches''')
    purge_cursor.execute('''DROP TABLE IF EXISTS dividends''')
    purge_cursor.execute('''DROP TABLE IF EXISTS burns''')
    purge_cursor.execute('''DROP TABLE IF EXISTS cancels''')

    # Reparse everything up to the deleted blocks, transactions.
    # TODO: Also more than necessary for reorgs.
    if quiet:
        log = logging.getLogger('')
        log.setLevel(logging.WARNING)
    initialise(db)
    purge_cursor.execute('''SELECT * FROM blocks ORDER BY block_index''')
    for block in purge_cursor.fetchall():
        logging.info('Block (re‐parse): {}'.format(str(block['block_index'])))
        parse_block(db, block['block_index'])
    if quiet:
        log.setLevel(logging.INFO)

    purge_cursor.close()
    return

def reorg (db):
    # Detect blockchain reorganisation.
    reorg_cursor = db.cursor()
    reorg_cursor.execute('''SELECT * FROM blocks WHERE block_index = (SELECT MAX(block_index) from blocks)''')
    last_block_index = reorg_cursor.fetchall()[0]['block_index']
    reorg_necessary = False
    for block_index in range(last_block_index - 6, last_block_index + 1):
        block_hash_see = bitcoin.rpc('getblockhash', [block_index])
        reorg_cursor.execute('''SELECT * FROM blocks WHERE block_index=?''', (block_index,))
        block_hash_have = reorg_cursor.fetchall()[0]['block_hash']
        if block_hash_see != block_hash_have:
            reorg_necessary = True
            logging.warning('Status: Blockchain reorganisation at block {}.'.format(block_index))
            break

    if not reorg_necessary: return last_block_index + 1

    # Delete blocks and transactions back as far as necessary.
    reorg_cursor.execute('''DELETE FROM blocks WHERE block_index>=?''', (block_index,))
    reorg_cursor.execute('''DELETE FROM transactions WHERE block_index>=?''', (block_index,))

    # Re-parse all transactions that are still there.
    purge(db, quiet=True)

    reorg_cursor.close()
    return block_index

def follow (db):
    # TODO: This is not thread‐safe!
    follow_cursor = db.cursor()

    logging.info('Status: RESTART')
    initialise(db)

    while True:

        # TODO: Check DB_VERSION
        # purge if old

        # Get index of last block.
        try:
            follow_cursor.execute('''SELECT * FROM blocks WHERE block_index = (SELECT MAX(block_index) from blocks)''')
            block_index = follow_cursor.fetchall()[0]['block_index'] + 1
        except Exception:
            logging.warning('Status: NEW DATABASE')
            block_index = config.BLOCK_FIRST

        # Get index of last transaction.
        try:
            follow_cursor.execute('''SELECT * FROM transactions WHERE tx_index = (SELECT MAX(tx_index) from transactions)''')
            tx_index = follow_cursor.fetchall()[0]['tx_index'] + 1
        except Exception:
            tx_index = 0

        # Get new blocks.
        block_count = bitcoin.rpc('getblockcount', [])
        while block_index <= block_count:
            logging.info('Block: {}'.format(str(block_index)))
            block_hash = bitcoin.rpc('getblockhash', [block_index])
            block = bitcoin.rpc('getblock', [block_hash])
            block_time = block['time']
            tx_hash_list = block['tx']

            # Get and parse transactions in this block, atomically.
            with db:
                # List the block.
                follow_cursor.execute('''INSERT INTO blocks(
                                    block_index,
                                    block_hash,
                                    block_time) VALUES(?,?,?)''',
                                    (block_index,
                                    block_hash,
                                    block_time)
                              )

                # List the transactions in the block.
                for tx_hash in tx_hash_list:
                    # Skip duplicate transaction entries.
                    follow_cursor.execute('''SELECT * FROM transactions WHERE tx_hash=?''', (tx_hash,))
                    blocks = follow_cursor.fetchall()
                    if blocks:
                        tx_index += 1
                        continue
                    # Get the important details about each transaction.
                    tx = bitcoin.rpc('getrawtransaction', [tx_hash, 1])
                    source, destination, btc_amount, fee, data = get_tx_info(tx)
                    if source and (data or destination == config.UNSPENDABLE):
                        follow_cursor.execute('''INSERT INTO transactions(
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

                # Parse the transactions in the block.
                parse_block(db, block_index)

            # Increment block index.
            block_count = bitcoin.rpc('getblockcount', [])
            block_index +=1

        while block_index > block_count: # DUPE
            # Handle blockchain reorganisations, as necessary, atomically.
            with db:
                block_index = reorg(db)

            block_count = bitcoin.rpc('getblockcount', [])
            time.sleep(2)

    follow_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
