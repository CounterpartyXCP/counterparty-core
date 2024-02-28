import logging
import os
import time
import platform
import signal
import shutil

import apsw

from counterpartylib import server
from counterpartylib.lib import config, blocks, ledger, backend, database
from counterpartylib.lib.kickstart.blocks_parser import BlockchainParser, ChainstateParser

logger = logging.getLogger(__name__)


def fetch_blocks(db, bitcoind_dir, last_known_hash):
    block_parser = BlockchainParser(bitcoind_dir)
    cursor = db.cursor()

    cursor.execute('''CREATE TABLE IF NOT EXISTS kickstart_blocks (
                      block_index INTEGER UNIQUE,
                      block_hash TEXT UNIQUE,
                      block_time INTEGER,
                      previous_block_hash TEXT UNIQUE,
                      difficulty INTEGER,
                      tx_count INTEGER,
                      PRIMARY KEY (block_index, block_hash))
                   ''')
    cursor.execute('''DELETE FROM kickstart_blocks''')
    
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
            bindings_lot += (
                block['block_index'],
                block['block_hash'],
                block['block_time'],
                block['hash_prev'],
                block['bits'],
                block['tx_count']
            )
            bindings_place.append('(?,?,?,?,?,?)')
            current_hash = block['hash_prev']
            block_count += 1
            if block['block_index'] == config.BLOCK_FIRST:
                break
        # insert blocks by lot
        cursor.execute(f'''INSERT INTO kickstart_blocks (block_index, block_hash, block_time, previous_block_hash, difficulty, tx_count)
                              VALUES {', '.join(bindings_place)}''',
                              bindings_lot)
        print(f"Block {bindings_lot[0]} to {bindings_lot[-6]} inserted.", end="\r")
        if block['block_index'] == config.BLOCK_FIRST:
            break
    block_parser.close()
    logger.info('Blocks indexed in: {:.3f}s'.format(time.time() - start_time_blocks_indexing))
    return block_count


def clean_kicstart_blocks(db):
    cursor = db.cursor()

    last_block_index_kickstart = cursor.execute('''
        SELECT block_index FROM kickstart_blocks ORDER BY block_index DESC LIMIT 1
    ''').fetchone()['block_index']

    last_block_index_parsed = cursor.execute('''
        SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1
    ''').fetchone()['block_index']

    if last_block_index_parsed >= last_block_index_kickstart:
        cursor.execute('''DROP TABLE kickstart_blocks''')


def prepare_db_for_resume(db):
    # get block count
    cursor = db.cursor()
    cursor.execute('''SELECT block_index FROM kickstart_blocks ORDER BY block_index DESC LIMIT 1''')
    last_block_index = cursor.fetchone()['block_index']

    # get last parsed transaction
    cursor.execute('''SELECT block_index, tx_index FROM transactions ORDER BY block_index DESC, tx_index DESC LIMIT 1''')
    last_transaction = cursor.fetchone()
    last_parsed_block = config.BLOCK_FIRST - 1
    tx_index = 0
    if last_transaction is not None:
        last_parsed_block = last_transaction['block_index']
        tx_index = last_transaction['tx_index'] + 1
    # clean tables from last parsed block
    for table in blocks.TABLES + ['transaction_outputs', 'transactions', 'blocks']:
        blocks.clean_table_from(cursor, table, last_parsed_block)

    block_count = last_block_index - last_parsed_block

    logger.info(f"Resuming from block {last_parsed_block}...")

    return block_count, tx_index, last_parsed_block


def run(bitcoind_dir, force=False, max_queue_size=None, debug_block=None):

    signal.signal(signal.SIGTERM, signal.SIG_DFL)
    signal.signal(signal.SIGINT, signal.default_int_handler)

    ledger.CURRENT_BLOCK_INDEX = 0
    backend.BACKEND()
    check_addrindexrs = {}
    while check_addrindexrs == {}:
        check_address = "tb1qurdetpdk8zg2thzx3g77qkgr7a89cp2m429t9c" if config.TESTNET else "34qkc2iac6RsyxZVfyE2S5U5WcRsbg2dpK"
        check_addrindexrs = backend.get_oldest_tx(check_address)
        if check_addrindexrs == {}:
            logger.warning('`addrindexrs` is not ready. Waiting one second.')
            time.sleep(1)

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

    default_queue_size = 100
    if config.TESTNET:
        bitcoind_dir = os.path.join(bitcoind_dir, 'testnet3')
        default_queue_size = 1000

    warnings = [
        '- Ensure `addrindexrs` is running and up to date.',
        '- Ensure that `bitcoind` is stopped.',
        '- The initialization may take a while.',
    ]
    message = "\n" + "\n".join(warnings)
    logger.warning(f'''Warning:{message}''')

    if not force and input('Proceed with the initialization? (y/N) : ') != 'y':
        return

    start_time_total = time.time()

    # Get hash of last known block.
    chain_parser = ChainstateParser(os.path.join(bitcoind_dir, 'chainstate'))
    last_known_hash = chain_parser.get_last_block_hash()
    chain_parser.close()
    logger.info('Last known block hash: {}'.format(last_known_hash))

    new_database = not os.path.exists(config.DATABASE)

    # check if we are resuming
    current_db = apsw.Connection(config.DATABASE)
    cursor = current_db.cursor()
    resuming = False
    if not new_database:
        query = "SELECT name FROM sqlite_master WHERE type='table' AND name='kickstart_blocks'"
        if len(list(cursor.execute(query))) == 1:
            resuming = True
    cursor.close()
    current_db.close()

    if not new_database and not resuming:
        logger.warning(f"New kickstart detected.")
        logger.warning(f"Old database will me moved to {config.DATABASE}.old and a new database will be created from scratch.")
        if not force and input('Continue? (y/N) : ') != 'y':
            return
        # move old database
        os.rename(config.DATABASE, config.DATABASE + '.old')
    else:
        # copy old database
        shutil.copy(config.DATABASE, config.DATABASE + '.old')

    kickstart_db = server.initialise_db()
    blocks.initialise(kickstart_db)

    if resuming:
        block_count, tx_index, last_parsed_block = prepare_db_for_resume(kickstart_db)
    else:
        database.update_version(kickstart_db)
        # fill `blocks`` table from bitcoind files
        block_count = fetch_blocks(kickstart_db, bitcoind_dir, last_known_hash)
        last_parsed_block = 0
        tx_index = 0

    cursor = kickstart_db.cursor()
    cursor.execute('PRAGMA auto_vacuum = 1')
    cursor.execute('PRAGMA journal_size_limit = 0')

    # Start block parser.
    queue_size = max_queue_size if max_queue_size is not None else default_queue_size
    block_parser = BlockchainParser(bitcoind_dir, config.DATABASE, last_parsed_block, queue_size)

    try:
        # save transactions for each blocks from first to last
        # then parse the block
        start_time_all_blocks_parse = time.time()
        block_parsed_count = 0
        block = block_parser.next_block()
        while block is not None:
            start_time_block_parse = time.time()
            ledger.CURRENT_BLOCK_INDEX = block['block_index']
            with kickstart_db: # ensure all the block or nothing
                # insert block
                cursor.execute(f'''
                    INSERT INTO blocks 
                        (block_index, block_hash, block_time, previous_block_hash, difficulty)
                    VALUES (?, ?, ?, ?, ?)
                ''', (
                    block['block_index'],
                    block['block_hash'],
                    block['block_time'],
                    block['hash_prev'],
                    block['bits']
                ))
                # save transactions
                for transaction in block['transactions']:
                    # Cache transaction. We do that here because the block is fetched by another process.
                    block_parser.put_in_cache(transaction)
                    tx_index = blocks.list_tx(kickstart_db,
                                            block['block_hash'],
                                            block['block_index'],
                                            block['block_time'],
                                            transaction['tx_hash'],
                                            tx_index,
                                            decoded_tx=transaction,
                                            block_parser=block_parser)
                # Parse the transactions in the block.
                blocks.parse_block(kickstart_db, block['block_index'], block['block_time'])
            last_parsed_block = block['block_index']
            if block['block_hash'] == last_known_hash:
                break
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
            # get next block
            block_parser.block_parsed()
            if debug_block is not None and block['block_index'] == int(debug_block):
                block = None
            else:
                block = block_parser.next_block()
        logger.info('All blocks parsed in: {:.3f}s'.format(time.time() - start_time_all_blocks_parse))
        # remove kickstart tables if all blocks have been parsed
        clean_kicstart_blocks(kickstart_db)
    except KeyboardInterrupt:
        logger.warning('Keyboard interrupt. Stopping...')
    finally:
        backend.stop()
        block_parser.close()
        logger.info("Last parsed block: {}".format(last_parsed_block))

    logger.info('Kickstart done in: {:.3f}s'.format(time.time() - start_time_total))
