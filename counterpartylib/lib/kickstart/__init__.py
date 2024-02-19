import logging
import os
import time
import shutil
import platform
import signal

import apsw

from counterpartylib import server
from counterpartylib.lib import config, blocks, ledger, backend
from counterpartylib.lib.kickstart.blocks_parser import BlockchainParser, ChainstateParser

logger = logging.getLogger(__name__)

def copy_memory_db_to_disk(local_base, memory_db):
    logger.info("Copying in memory database to disk...")
    start_time_copy_db = time.time()
    # backup old database
    if os.path.exists(local_base):
        shutil.copyfile(local_base, local_base + '.old')
        os.remove(local_base)
    # initialize new database
    config.DATABASE = local_base
    db = server.initialise_db()
    # copy memory database to new database
    with db.backup("main", memory_db, "main") as backup:
        backup.step()
    logger.info('Database copy duration: {:.3f}s'.format(time.time() - start_time_copy_db))


def fetch_blocks(db, bitcoind_dir, last_known_hash):
    block_parser = BlockchainParser(bitcoind_dir)
    cursor = db.cursor()
    start_time_blocks_indexing = time.time()
    # save blocks from last to first
    current_hash = last_known_hash
    lot_size = 100
    block_count = 0
    while True:
        bindings_lot = ()
        bindings_place = []
        # gather some blocks
        while len(bindings_lot) <= lot_size * 4:
            # read block from bitcoind files
            block = block_parser.read_raw_block(current_hash, only_header=True)
            # prepare bindings
            bindings_lot += (block['block_index'], block['block_hash'], block['block_time'], block['hash_prev'], block['bits'])
            bindings_place.append('(?,?,?,?,?)')
            current_hash = block['hash_prev']
            block_count += 1
            if block['block_index'] == config.BLOCK_FIRST:
                break
        # insert blocks by lot
        cursor.execute(f'''INSERT INTO blocks (block_index, block_hash, block_time, previous_block_hash, difficulty)
                              VALUES {', '.join(bindings_place)}''',
                              bindings_lot)
        print(f"Block {bindings_lot[0]} to {bindings_lot[-5]} inserted.", end="\r")
        if block['block_index'] == config.BLOCK_FIRST:
            break
    block_parser.close()
    logger.info('Blocks indexed in: {:.3f}s'.format(time.time() - start_time_blocks_indexing))
    return block_count


def copy_disk_db_to_memory(local_base, memory_db, resume_from):
    logger.info(f"Resuming from disk database {local_base}...")
    # copy disk database to memory database
    local_base_db = apsw.Connection(local_base)
    logger.info(f"Copying disk database to memory database...")
    with memory_db.backup("main", local_base_db, "main") as backup:
        backup.step()
    # get block count
    memory_cursor = memory_db.cursor()
    memory_cursor.execute('''SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1''')
    last_block_index = memory_cursor.fetchone()['block_index']
    # clean tables from resume block
    if resume_from != 'last':
        resume_block_index = int(resume_from)
        for table in blocks.TABLES + ['transaction_outputs', 'transactions']:
            blocks.clean_table_from(memory_cursor, table, resume_block_index)
    # get last parsed transaction
    memory_cursor.execute('''SELECT block_index, tx_index FROM transactions ORDER BY block_index DESC, tx_index DESC LIMIT 1''')
    last_transaction = memory_cursor.fetchone()
    last_parsed_block = last_transaction['block_index']
    # clean tables from last parsed block
    for table in blocks.TABLES:
        blocks.clean_table_from(memory_cursor, table, last_parsed_block)
    # clean hashes
    if resume_from != 'last':
        memory_cursor.execute('''UPDATE blocks
                                    SET txlist_hash = :txlist_hash, 
                                        ledger_hash = :ledger_hash,
                                        messages_hash = :messages_hash
                                    WHERE block_index > :block_index''', {
                                    'txlist_hash': None,
                                    'ledger_hash': None,
                                    'messages_hash': None,
                                    'block_index': last_parsed_block
                                })

    block_count = last_block_index - last_parsed_block
    tx_index = last_transaction['tx_index'] + 1
    logger.info(f"Resuming from block {last_parsed_block}...")

    return block_count, tx_index, last_parsed_block


# imitates the bitcoinlib class interface
# to be used directly by get_tx_info()
class COutPoint:
    def __init__(self, hash, n, coinbase):
        self.hash = hash
        self.n = n
        self.coinbase = coinbase

    def is_null(self):
        return self.coinbase

class CTxIn:
    def __init__(self, hash, n, scriptSig, nSequence, coinbase):
        self.prevout = COutPoint(hash, n)
        self.scriptSig = scriptSig
        self.nSequence = nSequence

class CTxOut:
    def __init__(self, nValue, scriptPubKey):
        self.nValue = nValue
        self.scriptPubKey = scriptPubKey

class CTxWitness:
    def __init__(self, vtxinwit=()):
        self.vtxinwit = vtxinwit

class CTxInWitness:
    def __init__(self, scriptWitness):
        self.scriptWitness = scriptWitness

class CTransaction:
    def __init__(self, nLockTime=0, nVersion=1, vin=(), vout=(), wit=CTxWitness(), coinbase=False):
        self.nVersion = nVersion
        self.vin = vin
        self.vout = vout
        self.nLockTime = nLockTime
        self.wit = wit
        self.coinbase = coinbase

    def is_coinbase(self):
        return self.coinbase

    def has_witness(self):
        return self.wit.vtxinwit != ()

def dict_to_class(tx):
    ct_vins = ()
    ct_vouts = ()
    for vin in tx['vin']:
        ct_vins += (CTxIn(
            vin['hash'],
            vin['n'],
            vin['scriptSig'],
            vin['nSequence'],
            vin['nSequence'],
            vin['coinbase']),
        )
    for vout in tx['vout']:
        ct_vouts += (CTxOut(
            vout['nValue'],
            vout['scriptPubKey']),
        )
    wit = CTxWitness(tuple(tx['vtxinwit']))

    return CTransaction(
        tx['lock_time'],
        tx['version'],
        ct_vins,
        ct_vouts,
        wit,
        tx['coinbase']
    )


def run(bitcoind_dir, force=False, last_hash=None, resume=True, resume_from=None):
    signal.signal(signal.SIGTERM, signal.SIG_DFL)
    signal.signal(signal.SIGINT, signal.default_int_handler)

    #ledger.CURRENT_BLOCK_INDEX = 0
    #backend.BACKEND()
    #check_addrindexrs = backend.get_oldest_tx("34qkc2iac6RsyxZVfyE2S5U5WcRsbg2dpK")
    #print("check_addrindexrs: ", check_addrindexrs)

    # determine bitoincore data directory
    if bitcoind_dir is None:
        if platform.system() == 'Darwin':
            bitcoind_dir = os.path.expanduser('~/Library/Application Support/Bitcoin/')
        elif platform.system() == 'Windows':
            bitcoind_dir = os.path.join(os.environ['APPDATA'], 'Bitcoin')
        else:
            bitcoind_dir = os.path.expanduser('~/.bitcoin')
    if not os.path.isdir(bitcoind_dir):
        raise Exception('Bitcoin Core data directory not found at {}. Use --bitcoind-dir parameter.'.format(bitcoind_dir))

    logger.warning(f'''Warning:
- `{config.DATABASE}` will be moved to `{config.DATABASE}.old` and recreated from scratch.
- Ensure `addrindexrs` is running and up to date.
- Ensure that `bitcoind` is stopped.
- The initialization may take a while.''')
    if not force and input('Proceed with the initialization? (y/N) : ') != 'y':
        return

    start_time_total = time.time()

    # Get hash of last known block.
    last_known_hash = last_hash
    if last_known_hash is None:
        chain_parser = ChainstateParser(os.path.join(bitcoind_dir, 'chainstate'))
        last_known_hash = chain_parser.get_last_block_hash()
        chain_parser.close()
    logger.info('Last known block hash: {}'.format(last_hash))

    # initialise in memory database
    local_base = config.DATABASE
    config.DATABASE = ':memory:'
    memory_db = server.initialise_db()

    if os.path.exists(local_base) and resume_from is not None:
        block_count, tx_index, last_parsed_block = copy_disk_db_to_memory(
            local_base, memory_db, resume_from
        )
    else:
        # intialize new database
        blocks.initialise(memory_db)
        # fill `blocks`` table from bitcoind files
        block_count = fetch_blocks(memory_db, bitcoind_dir, last_known_hash)
        last_parsed_block = 0
        tx_index = 0

    # Start block parser.
    block_parser = BlockchainParser(bitcoind_dir, memory_db, last_parsed_block)

    try:
        # save transactions for each blocks from first to last
        # then parse the block
        start_time_all_blocks_parse = time.time()
        block_parsed_count = 0
        block = block_parser.next_block()
        while block is not None:
            start_time_block_parse = time.time()
            ledger.CURRENT_BLOCK_INDEX = block['block_index']
            with memory_db: # ensure all the block or nothing
                # save transactions
                for transaction in block['transactions']:
                    # Cache transaction. We do that here because the block is fetched by another process.
                    block_parser.put_in_cache(transaction)
                    #decoded_tx = backend.deserialize(transaction['__data__'])
                    decoded_tx = dict_to_class(transaction)
                    tx_index = blocks.list_tx(memory_db,
                                            block['block_hash'],
                                            block['block_index'],
                                            block['block_time'],
                                            transaction['tx_hash'],
                                            tx_index,
                                            decoded_tx=decoded_tx,
                                            block_parser=block_parser)
                # Parse the transactions in the block.
                blocks.parse_block(memory_db, block['block_index'], block['block_time'])
            last_parsed_block = block['block_index']
            if block['block_hash'] == last_known_hash:
                break
            block = block_parser.next_block()
            # let's have a nice message
            block_parsed_count += 1
            block_parsing_duration = time.time() - start_time_block_parse
            message = f"Block {block['block_index']} parsed in {block_parsing_duration:.3f}s."
            message += f" {tx_index} transactions indexed."
            cumulated_duration = time.time() - start_time_all_blocks_parse
            message += f" Cumulated duration: {cumulated_duration:.3f}s."
            expected_duration = (cumulated_duration / block_parsed_count) * block_count
            message += f" Expected duration: {expected_duration:.3f}s."
            print(message, end="\r")
        logger.info('All blocks parsed in: {:.3f}s'.format(time.time() - start_time_all_blocks_parse))
    except KeyboardInterrupt:
        logger.warning('Keyboard interrupt. Stopping...')
    finally:
        backend.stop()
        block_parser.close()
        copy_memory_db_to_disk(local_base, memory_db)
        logger.info("Last parsed block: {}".format(last_parsed_block))

    logger.info('Kickstart done in: {:.3f}s'.format(time.time() - start_time_total))
