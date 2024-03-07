import logging
import os
import time
import platform
import signal
import shutil
from queue import Empty

import apsw
from halo import Halo
from termcolor import colored

from counterpartylib import server
from counterpartylib.lib import config, blocks, ledger, backend, database, log
from counterpartylib.lib.kickstart.blocks_parser import BlockchainParser, ChainstateParser
from counterpartylib.lib.kickstart.utils import remove_shm_from_resource_tracker
from counterpartylib.lib.backend.addrindexrs import AddrindexrsSocket

logger = logging.getLogger(__name__)

OK_GREEN = colored("[OK]", "green")
SPINNER_STYLE = "bouncingBar"


def confirm_kickstart():
    warnings = [
        'Warnings:',
        '- Ensure `addrindexrs` is running and up to date.',
        '- Ensure that `bitcoind` is stopped.',
        '- The initialization may take a while.',
    ]
    warnings_message = colored("\n".join(warnings), "yellow")
    print(f'''{warnings_message}''')
    confirmation_message = colored('Proceed with the initialization? (y/N): ', "magenta")
    if input(confirmation_message) != 'y':
        exit()


def fetch_blocks(cursor, bitcoind_dir, last_known_hash, first_block, spinner):
    block_parser = BlockchainParser(bitcoind_dir)

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
            if block['block_index'] == first_block:
                break
        # insert blocks by lot. No sql injection here.
        cursor.execute(f'''INSERT INTO kickstart_blocks (block_index, block_hash, block_time, previous_block_hash, difficulty, tx_count)
                              VALUES {', '.join(bindings_place)}''', # nosec B608
                              bindings_lot)
        spinner.text = f"Initialising database: block {bindings_lot[0]} to {bindings_lot[-6]} inserted."
        if block['block_index'] == first_block:
            break
    block_parser.close()
    spinner.text = f'Blocks indexed in: {time.time() - start_time_blocks_indexing:.3f}s'
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


def prepare_db_for_resume(cursor):
    # get block count
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

    return block_count, tx_index, last_parsed_block


def get_bitcoind_dir(bitcoind_dir=None):
    if bitcoind_dir is None:
        if platform.system() == 'Darwin':
            bitcoind_dir = os.path.expanduser('~/Library/Application Support/Bitcoin/')
        elif platform.system() == 'Windows':
            bitcoind_dir = os.path.join(os.environ['APPDATA'], 'Bitcoin')
        else:
            bitcoind_dir = os.path.expanduser('~/.bitcoin')
    if not os.path.isdir(bitcoind_dir):
        raise Exception(f'Bitcoin Core data directory not found at {bitcoind_dir}. Use --bitcoind-dir parameter.')
    if config.TESTNET:
        bitcoind_dir = os.path.join(bitcoind_dir, 'testnet3')
    return bitcoind_dir


def get_last_known_block_hash(bitcoind_dir):
    step = 'Getting last known block hash...'
    with Halo(text=step, spinner=SPINNER_STYLE):
        chain_parser = ChainstateParser(os.path.join(bitcoind_dir, 'chainstate'))
        last_known_hash = chain_parser.get_last_block_hash()
        chain_parser.close()
        #print(f'Last known block hash: {last_known_hash}')
    print(f'{OK_GREEN} {step}')
    return last_known_hash


def intialize_kickstart_db(bitcoind_dir, last_known_hash, resuming, new_database, debug_block):
    step = 'Initialising database...'
    with Halo(text=step, spinner=SPINNER_STYLE) as spinner:
        kickstart_db = server.initialise_db()
        blocks.initialise(kickstart_db)
        database.update_version(kickstart_db)
        cursor = kickstart_db.cursor()

        if debug_block is not None:
            blocks.rollback(kickstart_db, int(debug_block) - 1)

        # create `kickstart_blocks` table if necessary
        if not resuming:
            first_block = config.BLOCK_FIRST
            if not new_database:
                first_block = cursor.execute('SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1').fetchone()['block_index']
            fetch_blocks(cursor, bitcoind_dir, last_known_hash, first_block, spinner)
        else:
            # check if kickstart_blocks is complete
            last_block = cursor.execute('SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1').fetchone()
            if last_block is not None:
                last_block_index = last_block['block_index']
                first_kickstart_block = cursor.execute('SELECT block_index FROM kickstart_blocks ORDER BY block_index LIMIT 1').fetchone()['block_index']
                if last_block_index < first_kickstart_block:
                    cursor.execute('DELETE FROM kickstart_blocks')
                    fetch_blocks(cursor, bitcoind_dir, last_known_hash, last_block_index + 1, spinner)
        # get last block index
        spinner.text = step
        block_count, tx_index, last_parsed_block = prepare_db_for_resume(cursor)
        cursor.close()
    print(f'{OK_GREEN} {step}')
    return kickstart_db, block_count, tx_index, last_parsed_block


def start_blocks_parser_process(bitcoind_dir, last_parsed_block, max_queue_size):
    step = f'Starting blocks parser from block {last_parsed_block}...'
    with Halo(text=step, spinner=SPINNER_STYLE):
        # determine queue size
        default_queue_size = 100
        if config.TESTNET:
            default_queue_size = 1000
        queue_size = max_queue_size if max_queue_size is not None else default_queue_size
        # Start block parser.
        block_parser = BlockchainParser(bitcoind_dir, config.DATABASE, last_parsed_block, queue_size)
    print(f'{OK_GREEN} {step}')
    return block_parser


def is_resuming(new_database):
    step = 'Checking database state...'
    with Halo(text=step, spinner=SPINNER_STYLE):
        current_db = apsw.Connection(config.DATABASE)
        cursor = current_db.cursor()
        resuming = False
        if not new_database:
            query = "SELECT name FROM sqlite_master WHERE type='table' AND name='kickstart_blocks'"
            if len(list(cursor.execute(query))) == 1:
                resuming = True
        cursor.close()
        current_db.close()
    print(f'{OK_GREEN} {step}')
    return resuming


def backup_db(move=False):
    step = 'Backing up database...'
    with Halo(text=step, spinner="bouncingBar"):
        if move:
            os.rename(config.DATABASE, config.DATABASE + '.old')
        else:
            shutil.copy(config.DATABASE, config.DATABASE + '.old')
    print(f'{OK_GREEN} {step}')


def backup_if_needed(new_database, resuming):
    if not new_database and not resuming:
        current_db = apsw.Connection(config.DATABASE)
        cursor = current_db.cursor()
        user_version = cursor.execute('PRAGMA user_version').fetchall()[0][0]
        version_major = user_version // 1000
        if version_major < 10:
            print(colored(f"Version lower than v10.0.0 detected. Kickstart must be done from the first block.", "yellow"))
            print(colored(f"Old database will me moved to {config.DATABASE}.old and a new database will be created from scratch.", "yellow"))
            if input(colored('Continue? (y/N): ', 'magenta')) != 'y':
                return
            # move old database
            backup_db(move=True)
            return True
        else:
            backup_db()
    elif not new_database:
        backup_db()
    return new_database


def parse_block(kickstart_db, cursor, block, block_parser, tx_index):
    ledger.CURRENT_BLOCK_INDEX = block['block_index']

    with kickstart_db: # ensure all the block or nothing
        # insert block
        cursor.execute('''
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

    return tx_index


def cleanup(kickstart_db, block_parser):
    remove_shm_from_resource_tracker()
    step = 'Cleaning up...'
    with Halo(text=step, spinner=SPINNER_STYLE):
        # empyt queue to clean shared memory
        try:
            block_parser.block_parsed()
            block_parser.close()
        except (Empty, FileNotFoundError):
            pass
        backend.stop()
        # remove kickstart tables if all blocks have been parsed
        clean_kicstart_blocks(kickstart_db)
    print(f'{OK_GREEN} {step}')


def run(bitcoind_dir, force=False, max_queue_size=None, debug_block=None):
    # default signal handlers
    signal.signal(signal.SIGTERM, signal.SIG_DFL)
    signal.signal(signal.SIGINT, signal.default_int_handler)

    # display warnings
    if not force:
        confirm_kickstart()

    # check addrindexrs
    server.connect_to_addrindexrs()

    # determine bitoincore data directory
    bitcoind_dir = get_bitcoind_dir(bitcoind_dir)

    # Get hash of last known block.
    last_known_hash = get_last_known_block_hash(bitcoind_dir)

    # check if database exists
    new_database = not os.path.exists(config.DATABASE)

    # check if we are resuming
    resuming = is_resuming(new_database)

    # backup old database
    if not force:
        new_database = backup_if_needed(new_database, resuming)

    # initialize main timer
    start_time_total = time.time()

    # initialise database
    kickstart_db, block_count, tx_index, last_parsed_block = intialize_kickstart_db(
        bitcoind_dir, last_known_hash, resuming, new_database, debug_block
    )

    # Start block parser.
    block_parser = start_blocks_parser_process(bitcoind_dir, last_parsed_block, max_queue_size)

    # intitialize message
    message = ""
    start_time_all_blocks_parse = time.time()
    block_parsed_count = 0
    spinner = Halo(text="Starting...", spinner=SPINNER_STYLE)
    spinner.start()

    # start parsing blocks
    try:
        cursor = kickstart_db.cursor()
        block = block_parser.next_block()
        while block is not None:
            # initialize block parsing timer
            start_time_block_parse = time.time()
            # parse block
            tx_index = parse_block(kickstart_db, cursor, block, block_parser, tx_index)
            # update last parsed block
            last_parsed_block = block['block_index']
            # update block parsed count
            block_parsed_count += 1
            # let's have a nice message
            message = blocks.generate_progression_message(
                block,
                start_time_block_parse, start_time_all_blocks_parse,
                block_parsed_count, block_count,
                tx_index
            )
            spinner.text = message
            # notify block parsed
            block_parser.block_parsed()
            # check if we are done
            if block['block_hash'] == last_known_hash:
                break
            if debug_block is not None and block['block_index'] == int(debug_block):
                break
            # get next block
            block = block_parser.next_block()

        spinner.stop()
    except FileNotFoundError:
        pass # block file not found on stopping
    except KeyboardInterrupt:
        spinner.stop()
        # re-print last message
        if message != "":
            ok_yellow = colored("[OK]", "yellow")
            print(f'{ok_yellow} {message}')
            message = ""
        print(colored('Keyboard interrupt. Stopping...', 'yellow'))
    finally:
        spinner.stop()
        # re-print last message
        if message != "":
            print(f'{OK_GREEN} {message}')
        # cleaning up
        cleanup(kickstart_db, block_parser)
        # end message
        print(f"Last parsed block: {last_parsed_block}")
        print(f'Kickstart done in: {time.time() - start_time_total:.3f}s')
