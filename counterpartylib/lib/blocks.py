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
logger = logging.getLogger(__name__)
import collections
import platform
from Crypto.Cipher import ARC4
import apsw
import csv
import http

import bitcoin as bitcoinlib
from bitcoin.core.script import CScriptInvalidError

from counterpartylib.lib import config
from counterpartylib.lib import exceptions
from counterpartylib.lib import util
from counterpartylib.lib import check
from counterpartylib.lib import script
from counterpartylib.lib import backend
from counterpartylib.lib import log
from counterpartylib.lib import database
from .messages import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, rps, rpsresolve, publish, execute, destroy)

from .kickstart.blocks_parser import BlockchainParser, ChainstateParser
from .kickstart.utils import ib2h

from .exceptions import DecodeError, BTCOnlyError

# Order matters for FOREIGN KEY constraints.
TABLES = ['credits', 'debits', 'messages'] + \
         ['bet_match_resolutions', 'order_match_expirations', 'order_matches',
         'order_expirations', 'orders', 'bet_match_expirations', 'bet_matches',
         'bet_expirations', 'bets', 'broadcasts', 'btcpays', 'burns',
         'cancels', 'dividends', 'issuances', 'sends',
         'rps_match_expirations', 'rps_expirations', 'rpsresolves',
         'rps_matches', 'rps', 'executions', 'storage', 'suicides', 'nonces',
         'postqueue', 'contracts', 'destructions', 'assets']

CURR_DIR = os.path.dirname(os.path.realpath(__file__))
with open(CURR_DIR + '/../mainnet_burns.csv', 'r') as f:
    mainnet_burns_reader = csv.DictReader(f)
    MAINNET_BURNS = {}
    for line in mainnet_burns_reader:
        MAINNET_BURNS[line['tx_hash']] = line

def parse_tx(db, tx):
    """Parse the transaction, return True for success."""
    cursor = db.cursor()

    # Only one source and one destination allowed for now.
    if len(tx['source'].split('-')) > 1:
        return
    if tx['destination']:
        if len(tx['destination'].split('-')) > 1:
            return

    # Burns.
    if tx['destination'] == config.UNSPENDABLE:
        burn.parse(db, tx, MAINNET_BURNS)
        return

    if len(tx['data']) > 4:
        try:
            message_type_id = struct.unpack(config.TXTYPE_FORMAT, tx['data'][:4])[0]
        except struct.error:    # Deterministically raised.
            message_type_id = None
    else:
        message_type_id = None

    # Protocol change.
    rps_enabled = tx['block_index'] >= 308500 or config.TESTNET

    message = tx['data'][4:]
    if message_type_id == send.ID:
        send.parse(db, tx, message)
    elif message_type_id == order.ID:
        order.parse(db, tx, message)
    elif message_type_id == btcpay.ID:
        btcpay.parse(db, tx, message)
    elif message_type_id == issuance.ID:
        issuance.parse(db, tx, message)
    elif message_type_id == broadcast.ID:
        broadcast.parse(db, tx, message)
    elif message_type_id == bet.ID:
        bet.parse(db, tx, message)
    elif message_type_id == dividend.ID:
        dividend.parse(db, tx, message)
    elif message_type_id == cancel.ID:
        cancel.parse(db, tx, message)
    elif message_type_id == rps.ID and rps_enabled:
        rps.parse(db, tx, message)
    elif message_type_id == rpsresolve.ID and rps_enabled:
        rpsresolve.parse(db, tx, message)
    elif message_type_id == publish.ID and tx['block_index'] != config.MEMPOOL_BLOCK_INDEX:
        publish.parse(db, tx, message)
    elif message_type_id == execute.ID and tx['block_index'] != config.MEMPOOL_BLOCK_INDEX:
        execute.parse(db, tx, message)
    elif message_type_id == destroy.ID:
        destroy.parse(db, tx, message)
    else:
        cursor.execute('''UPDATE transactions \
                                   SET supported=? \
                                   WHERE tx_hash=?''',
                                (False, tx['tx_hash']))
        if tx['block_index'] != config.MEMPOOL_BLOCK_INDEX:
            logger.info('Unsupported transaction: hash {}; data {}'.format(tx['tx_hash'], tx['data']))
        cursor.close()
        return False

    # NOTE: for debugging (check asset conservation after every `N` transactions).
    # if not tx['tx_index'] % N:
    #     check.asset_conservation(db)

    cursor.close()
    return True


def parse_block(db, block_index, block_time, previous_ledger_hash=None,
                ledger_hash=None, previous_txlist_hash=None, txlist_hash=None):
    """Parse the block, return hash of new ledger and txlist.

    The unused arguments `ledger_hash` and `txlist_hash` are for the test suite.
    """
    cursor = db.cursor()

    util.BLOCK_LEDGER = []

    assert block_index == util.CURRENT_BLOCK_INDEX

    # Expire orders, bets and rps.
    order.expire(db, block_index)
    bet.expire(db, block_index, block_time)
    rps.expire(db, block_index)

    # Parse transactions, sorting them by type.
    cursor.execute('''SELECT * FROM transactions \
                      WHERE block_index=? ORDER BY tx_index''',
                   (block_index,))
    txlist = []
    for tx in list(cursor):
        parse_tx(db, tx)
        txlist.append('{}{}{}{}{}{}'.format(tx['tx_hash'], tx['source'], tx['destination'],
                                            tx['btc_amount'], tx['fee'],
                                            binascii.hexlify(tx['data']).decode('UTF-8')))

    cursor.close()

    # Consensus hashes.
    new_txlist_hash = check.consensus_hash(db, 'txlist_hash', previous_txlist_hash, txlist)
    new_ledger_hash = check.consensus_hash(db, 'ledger_hash', previous_ledger_hash, util.BLOCK_LEDGER)

    return new_ledger_hash, new_txlist_hash


def initialise(db):
    """Initialise data, create and populate the database."""
    cursor = db.cursor()

    # Blocks
    cursor.execute('''CREATE TABLE IF NOT EXISTS blocks(
                      block_index INTEGER UNIQUE,
                      block_hash TEXT UNIQUE,
                      block_time INTEGER,
                      previous_block_hash TEXT UNIQUE,
                      difficulty INTEGER,
                      PRIMARY KEY (block_index, block_hash))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON blocks (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      index_hash_idx ON blocks (block_index, block_hash)
                   ''')

    # SQLite can’t do `ALTER TABLE IF COLUMN NOT EXISTS`.
    columns = [column['name'] for column in cursor.execute('''PRAGMA table_info(blocks)''')]
    if 'ledger_hash' not in columns:
        cursor.execute('''ALTER TABLE blocks ADD COLUMN ledger_hash TEXT''')
    if 'txlist_hash' not in columns:
        cursor.execute('''ALTER TABLE blocks ADD COLUMN txlist_hash TEXT''')
    if 'previous_block_hash' not in columns:
        cursor.execute('''ALTER TABLE blocks ADD COLUMN previous_block_hash TEXT''')
    if 'difficulty' not in columns:
        cursor.execute('''ALTER TABLE blocks ADD COLUMN difficulty TEXT''')


    # Check that first block in DB is BLOCK_FIRST.
    cursor.execute('''SELECT * from blocks ORDER BY block_index''')
    blocks = list(cursor)
    if len(blocks):
        if blocks[0]['block_index'] != config.BLOCK_FIRST:
            raise exceptions.DatabaseError('First block in database is not block {}.'.format(config.BLOCK_FIRST))

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

    # Purge database of blocks, transactions from before BLOCK_FIRST.
    cursor.execute('''DELETE FROM blocks WHERE block_index < ?''', (config.BLOCK_FIRST,))
    cursor.execute('''DELETE FROM transactions WHERE block_index < ?''', (config.BLOCK_FIRST,))


    # (Valid) debits
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

    # (Valid) credits
    cursor.execute('''CREATE TABLE IF NOT EXISTS credits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      calling_function TEXT,
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
    # TODO: Store more asset info here?!
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
    cursor.execute('''SELECT * FROM assets WHERE asset_name = ?''', ('BTC',))
    if not list(cursor):
        cursor.execute('''INSERT INTO assets VALUES (?,?,?)''', ('0', 'BTC', None))
        cursor.execute('''INSERT INTO assets VALUES (?,?,?)''', ('1', 'XCP', None))

    # Consolidated
    send.initialise(db)
    destroy.initialise(db)
    order.initialise(db)
    btcpay.initialise(db)
    issuance.initialise(db)
    broadcast.initialise(db)
    bet.initialise(db)
    publish.initialise(db)
    execute.initialise(db)
    dividend.initialise(db)
    burn.initialise(db)
    cancel.initialise(db)
    rps.initialise(db)
    rpsresolve.initialise(db)

    # Messages
    cursor.execute('''CREATE TABLE IF NOT EXISTS messages(
                      message_index INTEGER PRIMARY KEY,
                      block_index INTEGER,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER)
                  ''')
                      # TODO: FOREIGN KEY (block_index) REFERENCES blocks(block_index) DEFERRABLE INITIALLY DEFERRED)
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON messages (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_message_index_idx ON messages (block_index, message_index)
                   ''')

    # Mempool messages
    # NOTE: `status`, 'block_index` are removed from bindings.
    cursor.execute('''DROP TABLE IF EXISTS mempool''')
    cursor.execute('''CREATE TABLE mempool(
                      tx_hash TEXT,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER)
                  ''')

    cursor.close()

def get_tx_info(tx_hex, block_parser=None, block_index=None):
    """Get the transaction info. Calls one of two subfunctions depending on signature type."""
    if not block_index:
        block_index = util.CURRENT_BLOCK_INDEX
    try:
        if util.enabled('multisig_addresses', block_index=block_index):   # Protocol change.
            tx_info = get_tx_info2(tx_hex, block_parser=block_parser)
        else:
            tx_info = get_tx_info1(tx_hex, block_index, block_parser=block_parser)
    except (DecodeError, BTCOnlyError) as e:
        # NOTE: For debugging, logger.debug('Could not decode: ' + str(e))
        tx_info = b'', None, None, None, None

    return tx_info

def get_tx_info1(tx_hex, block_index, block_parser=None):
    """Get singlesig transaction info.
    The destination, if it exists, always comes before the data output; the
    change, if it exists, always comes after.
    """
    ctx = backend.deserialize(tx_hex)

    def get_pubkeyhash(scriptpubkey):
        asm = script.get_asm(scriptpubkey)
        if len(asm) != 5 or asm[0] != 'OP_DUP' or asm[1] != 'OP_HASH160' or asm[3] != 'OP_EQUALVERIFY' or asm[4] != 'OP_CHECKSIG':
            return False
        return asm[2]

    def get_address(scriptpubkey):
        pubkeyhash = get_pubkeyhash(scriptpubkey)
        if not pubkeyhash:
            return False
        pubkeyhash = binascii.hexlify(pubkeyhash).decode('utf-8')
        address = script.base58_check_encode(pubkeyhash, config.ADDRESSVERSION)
        # Test decoding of address.
        if address != config.UNSPENDABLE and binascii.unhexlify(bytes(pubkeyhash, 'utf-8')) != script.base58_check_decode(address, config.ADDRESSVERSION):
            return False

        return address

    # Fee is the input values minus output values.
    fee = 0

    # Get destination output and data output.
    destination, btc_amount, data = None, None, b''
    pubkeyhash_encoding = False
    for vout in ctx.vout:
        fee -= vout.nValue

        # Sum data chunks to get data. (Can mix OP_RETURN and multi-sig.)
        asm = script.get_asm(vout.scriptPubKey)
        if len(asm) == 2 and asm[0] == 'OP_RETURN':                                             # OP_RETURN
            if type(asm[1]) != bytes:
                continue
            data_chunk = asm[1]
            data += data_chunk
        elif len(asm) == 5 and asm[0] == 1 and asm[3] == 2 and asm[4] == 'OP_CHECKMULTISIG':    # Multi-sig
            if type(asm[2]) != bytes:
                continue
            data_pubkey = asm[2]
            data_chunk_length = data_pubkey[0]  # No ord() necessary.
            data_chunk = data_pubkey[1:data_chunk_length + 1]
            data += data_chunk
        elif len(asm) == 5 and (block_index >= 293000 or config.TESTNET):    # Protocol change.
            # Be strict.
            pubkeyhash = get_pubkeyhash(vout.scriptPubKey)
            if not pubkeyhash:
                continue

            if ctx.is_coinbase():
                raise DecodeError('coinbase transaction')
            obj1 = ARC4.new(ctx.vin[0].prevout.hash[::-1])
            data_pubkey = obj1.decrypt(pubkeyhash)
            if data_pubkey[1:9] == config.PREFIX or pubkeyhash_encoding:
                pubkeyhash_encoding = True
                data_chunk_length = data_pubkey[0]  # No ord() necessary.
                data_chunk = data_pubkey[1:data_chunk_length + 1]
                if data_chunk[-8:] == config.PREFIX:
                    data += data_chunk[:-8]
                    break
                else:
                    data += data_chunk

        # Destination is the first output before the data.
        if not destination and not btc_amount and not data:
            address = get_address(vout.scriptPubKey)
            if address:
                destination = address
                btc_amount = vout.nValue

    # Check for, and strip away, prefix (except for burns).
    if destination == config.UNSPENDABLE:
        pass
    elif data[:len(config.PREFIX)] == config.PREFIX:
        data = data[len(config.PREFIX):]
    else:
        raise DecodeError('no prefix')

    # Only look for source if data were found or destination is UNSPENDABLE, for speed.
    if not data and destination != config.UNSPENDABLE:
        raise BTCOnlyError('no data and not unspendable')

    # Collect all possible source addresses; ignore coinbase transactions and anything but the simplest Pay‐to‐PubkeyHash inputs.
    source_list = []
    for vin in ctx.vin[:]:                                               # Loop through input transactions.
        if vin.prevout.is_null():
            raise DecodeError('coinbase transaction')
         # Get the full transaction data for this input transaction.
        if block_parser:
            vin_tx = block_parser.read_raw_transaction(ib2h(vin.prevout.hash))
            vin_ctx = backend.deserialize(vin_tx['__data__'])
        else:
            vin_tx = backend.getrawtransaction(ib2h(vin.prevout.hash))
            vin_ctx = backend.deserialize(vin_tx)
        vout = vin_ctx.vout[vin.prevout.n]
        fee += vout.nValue

        address = get_address(vout.scriptPubKey)
        if not address:
            raise DecodeError('invalid scriptpubkey')
        else:
            source_list.append(address)

    # Require that all possible source addresses be the same.
    if all(x == source_list[0] for x in source_list):
        source = source_list[0]
    else:
        source = None

    return source, destination, btc_amount, fee, data

def get_tx_info2(tx_hex, block_parser=None):
    """Get multisig transaction info.
    The destinations, if they exists, always comes before the data output; the
    change, if it exists, always comes after.
    """
    # Decode transaction binary.
    ctx = backend.deserialize(tx_hex)

    def arc4_decrypt(cyphertext):
        '''Un‐obfuscate. Initialise key once per attempt.'''
        key = ARC4.new(ctx.vin[0].prevout.hash[::-1])
        return key.decrypt(cyphertext)

    def get_opreturn(asm):
        if len(asm) == 2 and asm[0] == 'OP_RETURN':
            pubkeyhash = asm[1]
            if type(pubkeyhash) == bytes:
                return pubkeyhash
        raise DecodeError('invalid OP_RETURN')

    def decode_opreturn(asm):
        chunk = get_opreturn(asm)
        chunk = arc4_decrypt(chunk)
        if chunk[:len(config.PREFIX)] == config.PREFIX:             # Data
            destination, data = None, chunk[len(config.PREFIX):]
        else:
            raise DecodeError('unrecognised OP_RETURN output')

        return destination, data

    def decode_checksig(asm):
        pubkeyhash = script.get_checksig(asm)
        chunk = arc4_decrypt(pubkeyhash)
        if chunk[1:len(config.PREFIX) + 1] == config.PREFIX:        # Data
            # Padding byte in each output (instead of just in the last one) so that encoding methods may be mixed. Also, it’s just not very much data.
            chunk_length = chunk[0]
            chunk = chunk[1:chunk_length + 1]
            destination, data = None, chunk[len(config.PREFIX):]
        else:                                                       # Destination
            pubkeyhash = binascii.hexlify(pubkeyhash).decode('utf-8')
            destination, data = script.base58_check_encode(pubkeyhash, config.ADDRESSVERSION), None

        return destination, data

    def decode_checkmultisig(asm):
        pubkeys, signatures_required = script.get_checkmultisig(asm)
        chunk = b''
        for pubkey in pubkeys[:-1]:     # (No data in last pubkey.)
            chunk += pubkey[1:-1]       # Skip sign byte and nonce byte.
        chunk = arc4_decrypt(chunk)
        if chunk[1:len(config.PREFIX) + 1] == config.PREFIX:        # Data
            # Padding byte in each output (instead of just in the last one) so that encoding methods may be mixed. Also, it’s just not very much data.
            chunk_length = chunk[0]
            chunk = chunk[1:chunk_length + 1]
            destination, data = None, chunk[len(config.PREFIX):]
        else:                                                       # Destination
            pubkeyhashes = [script.pubkey_to_pubkeyhash(pubkey) for pubkey in pubkeys]
            destination, data = script.construct_array(signatures_required, pubkeyhashes, len(pubkeyhashes)), None

        return destination, data

    # Ignore coinbase transactions.
    if ctx.is_coinbase():
        raise DecodeError('coinbase transaction')

    # Get destinations and data outputs.
    destinations, btc_amount, fee, data = [], 0, 0, b''
    for vout in ctx.vout:
        # Fee is the input values minus output values.
        output_value = vout.nValue
        fee -= output_value

        # Ignore transactions with invalid script.
        try:
          asm = script.get_asm(vout.scriptPubKey)
        except CScriptInvalidError as e:
          raise DecodeError(e)

        if asm[0] == 'OP_RETURN':
            new_destination, new_data = decode_opreturn(asm)
        elif asm[-1] == 'OP_CHECKSIG':
            new_destination, new_data = decode_checksig(asm)
        elif asm[-1] == 'OP_CHECKMULTISIG':
            new_destination, new_data = decode_checkmultisig(asm)
        else:
            raise DecodeError('unrecognised output type')
        assert not (new_destination and new_data)
        assert new_destination != None or new_data != None  # `decode_*()` should never return `None, None`.

        if util.enabled('null_data_check'):
            if new_data == []:
                raise DecodeError('new destination is `None`')

        # All destinations come before all data.
        if not data and not new_data and destinations != [config.UNSPENDABLE,]:
            destinations.append(new_destination)
            btc_amount += output_value
        else:
            if new_destination:     # Change.
                break
            else:                   # Data.
                data += new_data

    # Only look for source if data were found or destination is `UNSPENDABLE`,
    # for speed.
    if not data and destinations != [config.UNSPENDABLE,]:
        raise BTCOnlyError('no data and not unspendable')

    # Collect all (unique) source addresses.
    sources = []
    for vin in ctx.vin[:]:                   # Loop through inputs.
        # Get the full transaction data for this input transaction.
        if block_parser:
            vin_tx = block_parser.read_raw_transaction(ib2h(vin.prevout.hash))
            vin_ctx = backend.deserialize(vin_tx['__data__'])
        else:
            vin_tx = backend.getrawtransaction(ib2h(vin.prevout.hash))
            vin_ctx = backend.deserialize(vin_tx)
        vout = vin_ctx.vout[vin.prevout.n]
        fee += vout.nValue

        asm = script.get_asm(vout.scriptPubKey)
        if asm[-1] == 'OP_CHECKSIG':
            new_source, new_data = decode_checksig(asm)
            if new_data or not new_source:
                raise DecodeError('data in source')
        elif asm[-1] == 'OP_CHECKMULTISIG':
            new_source, new_data = decode_checkmultisig(asm)
            if new_data or not new_source:
                raise DecodeError('data in source')
        else:
            raise DecodeError('unrecognised source type')

        # Collect unique sources.
        if new_source not in sources:
            sources.append(new_source)

    sources = '-'.join(sources)
    destinations = '-'.join(destinations)
    return sources, destinations, btc_amount, round(fee), data

def reinitialise(db, block_index=None):
    """Drop all predefined tables and initialise the database once again."""
    cursor = db.cursor()

    # Delete all of the results of parsing.
    for table in TABLES + ['balances']:
        cursor.execute('''DROP TABLE IF EXISTS {}'''.format(table))

    # Create missing tables
    initialise(db)

    # clean consensus hashes if first block hash don't match with checkpoint.
    checkpoints = check.CHECKPOINTS_TESTNET if config.TESTNET else check.CHECKPOINTS_MAINNET
    columns = [column['name'] for column in cursor.execute('''PRAGMA table_info(blocks)''')]
    for field in ['ledger_hash', 'txlist_hash']:
        if field in columns:
            sql = '''SELECT {} FROM blocks  WHERE block_index = ?'''.format(field)
            first_block = list(cursor.execute(sql, (config.BLOCK_FIRST,)))
            if first_block:
                first_hash = first_block[0][field]
                if first_hash != checkpoints[config.BLOCK_FIRST][field]:
                    logger.info('First hash changed. Cleaning {}.'.format(field))
                    cursor.execute('''UPDATE blocks SET {} = NULL'''.format(field))

    # For rollbacks, just delete new blocks and then reparse what’s left.
    if block_index:
        cursor.execute('''DELETE FROM transactions WHERE block_index > ?''', (block_index,))
        cursor.execute('''DELETE FROM blocks WHERE block_index > ?''', (block_index,))

    cursor.close()

def reparse(db, block_index=None, quiet=False):
    """Reparse all transactions (atomically). If block_index is set, rollback
    to the end of that block.
    """
    logger.info('Reparsing all transactions.')

    check.software_version()

    cursor = db.cursor()
    if quiet:
        root_logger = logging.getLogger()
        root_level = logger.getEffectiveLevel()

    with db:
        reinitialise(db, block_index)

        # Reparse all blocks, transactions.
        if quiet:
            root_logger.setLevel(logging.WARNING)

        previous_ledger_hash, previous_txlist_hash = None, None
        cursor.execute('''SELECT * FROM blocks ORDER BY block_index''')
        for block in cursor.fetchall():
            logger.info('Block (re‐parse): {}'.format(str(block['block_index'])))
            util.CURRENT_BLOCK_INDEX = block['block_index']
            previous_ledger_hash, previous_txlist_hash = parse_block(db, block['block_index'], block['block_time'],
                                                                     previous_ledger_hash, previous_txlist_hash)

        if quiet:
            root_logger.setLevel(root_level)

        # Check for conservation of assets.
        check.asset_conservation(db)

        # Update minor version number.
        cursor.execute('PRAGMA user_version = {}'.format(int(config.VERSION_MINOR))) # Syntax?!
        logger.info('Database minor version number updated.')

    cursor.close()
    return

def list_tx(db, block_hash, block_index, block_time, tx_hash, tx_index, tx_hex=None):
    assert type(tx_hash) == str
    cursor = db.cursor()

    # Edge case: confirmed tx_hash also in mempool
    cursor.execute('''SELECT * FROM transactions WHERE tx_hash = ?''', (tx_hash,))
    transactions = list(cursor)
    if transactions:
        return tx_index

    # Get the important details about each transaction.
    if tx_hex is None:
        tx_hex = backend.getrawtransaction(tx_hash)
    source, destination, btc_amount, fee, data = get_tx_info(tx_hex)

    # For mempool
    if block_hash == None:
        block_hash = config.MEMPOOL_BLOCK_HASH
        block_index = config.MEMPOOL_BLOCK_INDEX
        backend.extract_addresses([tx_hash,]) # prepare cache for backend.unconfirmed_transactions().
    else:
        assert block_index == util.CURRENT_BLOCK_INDEX

    if source and (data or destination == config.UNSPENDABLE):
        logger.debug('Saving transaction: {}'.format(tx_hash))
        cursor.execute('''INSERT INTO transactions(
                            tx_index,
                            tx_hash,
                            block_index,
                            block_hash,
                            block_time,
                            source,
                            destination,
                            btc_amount,
                            fee,
                            data) VALUES(?,?,?,?,?,?,?,?,?,?)''',
                            (tx_index,
                             tx_hash,
                             block_index,
                             block_hash,
                             block_time,
                             source,
                             destination,
                             btc_amount,
                             fee,
                             data)
                      )
        cursor.close()
        return tx_index + 1
    else:
        logger.debug('Skipping transaction: {}'.format(tx_hash))

    return tx_index

def kickstart(db, bitcoind_dir):
    if bitcoind_dir is None:
        if platform.system() == 'Darwin':
            bitcoind_dir = os.path.expanduser('~/Library/Application Support/Bitcoin/')
        elif platform.system() == 'Windows':
            bitcoind_dir = os.path.join(os.environ['APPDATA'], 'Bitcoin')
        else:
            bitcoind_dir = os.path.expanduser('~/.bitcoin')
    if not os.path.isdir(bitcoind_dir):
        raise Exception('Bitcoin Core data directory not found at {}. Use --bitcoind-dir parameter.'.format(bitcoind_dir))

    cursor = db.cursor()

    logger.warning('''Warning:
- Ensure that bitcoind is stopped.
- You must reindex bitcoind after the initialization is complete (restart with `-reindex=1`)
- The initialization may take a while.''')
    if input('Proceed with the initialization? (y/N) : ') != 'y':
        return

    first_hash = config.BLOCK_FIRST_TESTNET_HASH if config.TESTNET else config.BLOCK_FIRST_MAINNET_HASH
    start_time_total = time.time()

    # Get hash of last known block.
    chain_parser = ChainstateParser(os.path.join(bitcoind_dir, 'chainstate'))
    last_hash = chain_parser.get_last_block_hash()
    chain_parser.close()

    # Start block parser.
    block_parser = BlockchainParser(os.path.join(bitcoind_dir, 'blocks'), os.path.join(bitcoind_dir, 'blocks/index'))

    current_hash = last_hash
    tx_index = 0
    with db:

        # Prepare SQLite database. # TODO: Be more specific!
        logger.info('Preparing database.')
        start_time = time.time()
        reinitialise(db, block_index=config.BLOCK_FIRST - 1)
        logger.info('Prepared database in {:.3f}s'.format(time.time() - start_time))

        # Get blocks and transactions, moving backwards in time.
        while current_hash != None:
            start_time = time.time()
            transactions = []

            # Get `tx_info`s for transactions in this block.
            block = block_parser.read_raw_block(current_hash)
            for tx in block['transactions']:
                source, destination, btc_amount, fee, data = get_tx_info(tx['__data__'], block_parser=block_parser, block_index=block['block_index'])
                if source and (data or destination == config.UNSPENDABLE):
                    transactions.append((
                        tx['tx_hash'], block['block_index'], block['block_hash'], block['block_time'],
                        source, destination, btc_amount, fee, data
                    ))
                    logger.info('Valid transaction: {}'.format(tx['tx_hash']))

            # Insert block and transactions into database.
            cursor.execute('''INSERT INTO blocks(
                                    block_index,
                                    block_hash,
                                    block_time) VALUES(?,?,?)''',
                                    (block['block_index'],
                                    block['block_hash'],
                                    block['block_time']))
            if len(transactions):
                transactions = list(reversed(transactions))
                tx_chunks = [transactions[i:i+90] for i in range(0, len(transactions), 90)]
                for tx_chunk in tx_chunks:
                    sql = '''INSERT INTO transactions
                                (tx_index, tx_hash, block_index, block_hash, block_time, source, destination, btc_amount, fee, data) 
                             VALUES '''
                    bindings = ()
                    bindings_place = []
                    # negative tx_index from -1 and inverse order for fast reordering   # TODO: Can this be clearer?
                    for tx in tx_chunk:
                        bindings += (-(tx_index + 1),) + tx
                        bindings_place.append('''(?,?,?,?,?,?,?,?,?,?)''')
                        tx_index += 1
                    sql += ', '.join(bindings_place)
                    cursor.execute(sql, bindings)

            logger.info('Block {} ({}): {}/{} saved in {:.3f}s'.format(
                          block['block_index'], block['block_hash'],
                          len(transactions), len(block['transactions']),
                          time.time() - start_time))

            # Get hash of next block.
            current_hash = block['hash_prev'] if current_hash != first_hash else None

        block_parser.close()

        # Reorder all transactions in database.
        logger.info('Reordering transactions.')
        start_time = time.time()
        cursor.execute('''UPDATE transactions SET tx_index = tx_index + ?''', (tx_index,))
        logger.info('Reordered transactions in {:.3f}s.'.format(time.time() - start_time))

    # Parse all transactions in database.
    reparse(db)

    cursor.close()
    logger.info('Total duration: {:.3f}s'.format(time.time() - start_time_total))

def last_db_index(db):
    cursor = db.cursor()
    try:
        blocks = list(cursor.execute('''SELECT * FROM blocks WHERE block_index = (SELECT MAX(block_index) from blocks)'''))
        try:
            return blocks[0]['block_index']
        except IndexError:
            return 0
    except apsw.SQLError:
        return 0

def get_next_tx_index(db):
    """Return index of next transaction."""
    cursor = db.cursor()
    txes = list(cursor.execute('''SELECT * FROM transactions WHERE tx_index = (SELECT MAX(tx_index) from transactions)'''))
    if txes:
        assert len(txes) == 1
        tx_index = txes[0]['tx_index'] + 1
    else:
        tx_index = 0
    cursor.close()
    return tx_index



class MempoolError(Exception):
    pass
def follow(db):
    # Check software version.
    check.software_version()

    # Initialise.
    initialise(db)

    # Get index of last block.
    if util.CURRENT_BLOCK_INDEX == 0:
        logger.warning('New database.')
        block_index = config.BLOCK_FIRST
    else:
        block_index = util.CURRENT_BLOCK_INDEX + 1

        # Check database version.
        try:
            check.database_version(db)
        except check.DatabaseVersionError as e:
            logger.info(str(e))
            # no need to reparse or rollback a new database
            if block_index != config.BLOCK_FIRST:
                reparse(db, block_index=e.reparse_block_index, quiet=False)
            database.update_version(db)

    logger.info('Resuming parsing.')

    # Get index of last transaction.
    tx_index = get_next_tx_index(db)

    not_supported = {}   # No false positives. Use a dict to allow for O(1) lookups
    not_supported_sorted = collections.deque()
    # ^ Entries in form of (block_index, tx_hash), oldest first. Allows for easy removal of past, unncessary entries
    cursor = db.cursor()
    # a reorg can happen without the block count increasing, or even for that
    # matter, with the block count decreasing. This should only delay
    # processing of the new blocks a bit.
    while True:
        start_time = time.time()

        # Get block count.
        # If the backend is unreachable and `config.FORCE` is set, just sleep
        # and try again repeatedly.
        try:
            block_count = backend.getblockcount()
        except (ConnectionRefusedError, http.client.CannotSendRequest, backend.addrindex.BackendRPCError) as e:
            if config.FORCE:
                time.sleep(config.BACKEND_POLL_INTERVAL)
                continue
            else:
                raise e
            
        # Get new blocks.
        if block_index <= block_count:

            # Backwards check for incorrect blocks due to chain reorganisation, and stop when a common parent is found.
            current_index = block_index
            requires_rollback = False
            while True:
                if current_index == config.BLOCK_FIRST:
                    break

                logger.debug('Checking that block {} is not an orphan.'.format(current_index))

                # Backend parent hash.
                current_hash = backend.getblockhash(current_index)
                current_cblock = backend.getblock(current_hash)
                backend_parent = bitcoinlib.core.b2lx(current_cblock.hashPrevBlock)

                # DB parent hash.
                blocks = list(cursor.execute('''SELECT * FROM blocks
                                                WHERE block_index = ?''', (current_index - 1,)))
                if len(blocks) != 1:  # For empty DB.
                    break
                db_parent = blocks[0]['block_hash']

                # Compare.
                assert type(db_parent) == str
                assert type(backend_parent) == str
                if db_parent == backend_parent:
                    break
                else:
                    current_index -= 1
                    requires_rollback = True

            # Rollback for reorganisation.
            if requires_rollback:
                # Record reorganisation.
                logger.warning('Blockchain reorganisation at block {}.'.format(current_index))
                log.message(db, block_index, 'reorg', None, {'block_index': current_index})

                # Rollback the DB.
                reparse(db, block_index=current_index-1, quiet=True)
                block_index = current_index
                tx_index = get_next_tx_index(db)
                continue

            # Check version. (Don’t add any blocks to the database while
            # running an out‐of‐date client!)
            check.software_version()

            # Get and parse transactions in this block (atomically).
            block_hash = backend.getblockhash(current_index)
            block = backend.getblock(block_hash)
            previous_block_hash = bitcoinlib.core.b2lx(block.hashPrevBlock)
            block_time = block.nTime
            txhash_list = backend.get_txhash_list(block)
            raw_transactions = backend.getrawtransaction_batch(txhash_list)
            with db:
                util.CURRENT_BLOCK_INDEX = block_index

                # List the block.
                cursor.execute('''INSERT INTO blocks(
                                    block_index,
                                    block_hash,
                                    block_time,
                                    previous_block_hash,
                                    difficulty) VALUES(?,?,?,?,?)''',
                                    (block_index,
                                    block_hash,
                                    block_time,
                                    previous_block_hash,
                                    block.difficulty)
                              )

                # List the transactions in the block.
                for tx_hash in txhash_list:
                    tx_hex = raw_transactions[tx_hash]
                    tx_index = list_tx(db, block_hash, block_index, block_time, tx_hash, tx_index, tx_hex)

                # Parse the transactions in the block.
                parse_block(db, block_index, block_time)

            # When newly caught up, check for conservation of assets.
            if block_index == block_count:
                if config.CHECK_ASSET_CONSERVATION:
                    check.asset_conservation(db)

            # Remove any non‐supported transactions older than ten blocks.
            while len(not_supported_sorted) and not_supported_sorted[0][0] <= block_index - 10:
                tx_h = not_supported_sorted.popleft()[1]
                del not_supported[tx_h]

            logger.info('Block: %s (%ss)'%(str(block_index), "{:.2f}".format(time.time() - start_time, 3)))
            # Increment block index.
            block_count = backend.getblockcount()
            block_index += 1

        else:
            # Get old mempool.
            old_mempool = list(cursor.execute('''SELECT * FROM mempool'''))
            old_mempool_hashes = [message['tx_hash'] for message in old_mempool]

            if backend.MEMPOOL_CACHE_INITIALIZED is False:
                backend.init_mempool_cache()
                backend.refresh_unconfirmed_transactions_cache(old_mempool_hashes)
                logger.info("Ready for queries.")

            # Fake values for fake block.
            curr_time = int(time.time())
            mempool_tx_index = tx_index

            # For each transaction in Bitcoin Core mempool, if it’s new, create
            # a fake block, a fake transaction, capture the generated messages,
            # and then save those messages.
            # Every transaction in mempool is parsed independently. (DB is rolled back after each one.)
            mempool = []
            raw_mempool = backend.getrawmempool()
            for tx_hash in raw_mempool:
                # If already in mempool, copy to new one.
                if tx_hash in old_mempool_hashes:
                    for message in old_mempool:
                        if message['tx_hash'] == tx_hash:
                            mempool.append((tx_hash, message))

                # If already skipped, skip it again.
                elif tx_hash not in not_supported:

                    # Else: list, parse and save it.
                    try:
                        with db:
                            # List the fake block.
                            cursor.execute('''INSERT INTO blocks(
                                                block_index,
                                                block_hash,
                                                block_time) VALUES(?,?,?)''',
                                                (config.MEMPOOL_BLOCK_INDEX,
                                                 config.MEMPOOL_BLOCK_HASH,
                                                 curr_time)
                                          )

                            # List transaction.
                            try:    # Sometimes the transactions can’t be found: `{'code': -5, 'message': 'No information available about transaction'} Is txindex enabled in Bitcoind?`
                                mempool_tx_index = list_tx(db, None, block_index, curr_time, tx_hash, mempool_tx_index)
                            except backend.addrindex.BackendRPCError:
                                raise MempoolError

                            # Parse transaction.
                            cursor.execute('''SELECT * FROM transactions \
                                              WHERE tx_hash = ?''',
                                           (tx_hash,))
                            transactions = list(cursor)
                            if transactions:
                                assert len(transactions) == 1
                                transaction = transactions[0]
                                supported = parse_tx(db, transaction)
                                if not supported:
                                    not_supported[tx_hash] = ''
                                    not_supported_sorted.append((block_index, tx_hash))
                            else:
                                # If a transaction hasn’t been added to the
                                # table `transactions`, then it’s not a
                                # Counterparty transaction.
                                not_supported[tx_hash] = ''
                                not_supported_sorted.append((block_index, tx_hash))
                                raise MempoolError

                            # Save transaction and side‐effects in memory.
                            cursor.execute('''SELECT * FROM messages WHERE block_index = ?''', (config.MEMPOOL_BLOCK_INDEX,))
                            for message in list(cursor):
                                mempool.append((tx_hash, message))

                            # Rollback.
                            raise MempoolError
                    except MempoolError:
                        pass

            # Re‐write mempool messages to database.
            with db:
                cursor.execute('''DELETE FROM mempool''')
                for message in mempool:
                    tx_hash, new_message = message
                    new_message['tx_hash'] = tx_hash
                    cursor.execute('''INSERT INTO mempool VALUES(:tx_hash, :command, :category, :bindings, :timestamp)''', (new_message))
                    
            backend.refresh_unconfirmed_transactions_cache([tx_hash for tx_hash, message in mempool])

            elapsed_time = time.time() - start_time
            sleep_time = config.BACKEND_POLL_INTERVAL - elapsed_time if elapsed_time <= config.BACKEND_POLL_INTERVAL else 0

            logger.debug('Refresh mempool: %s CP txs seen, out of %s total entries (took %ss, next refresh in %ss)' % (
                len(mempool), len(raw_mempool), "{:.2f}".format(elapsed_time, 3), "{:.2f}".format(sleep_time, 3)))

            # Wait
            db.wal_checkpoint(mode=apsw.SQLITE_CHECKPOINT_PASSIVE)
            time.sleep(sleep_time)

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
