import apsw
import logging
logger = logging.getLogger(__name__)
import time
import collections
import copy

from counterpartylib.lib import config
from counterpartylib.lib import util
from counterpartylib.lib import exceptions
from counterpartylib.lib import log

BLOCK_MESSAGES = []

def rowtracer(cursor, sql):
    """Converts fetched SQL data into dict-style"""
    dictionary = {}
    for index, (name, type_) in enumerate(cursor.getdescription()):
        dictionary[name] = sql[index]
    return dictionary

def exectracer(cursor, sql, bindings):
    # This means that all changes to database must use a very simple syntax.
    # TODO: Need sanity checks here.
    sql = sql.lower()

    if sql.startswith('create trigger'):
        #CREATE TRIGGER stmts may include an "insert" or "update" as part of them
        return True 

    # Parse SQL.
    array = sql.split('(')[0].split(' ')
    command = array[0]
    if 'insert' in sql:
        category = array[2]
    elif 'update' in sql:
        category = array[1]
    else:
        #CREATE TABLE, etc
        return True

    db = cursor.getconnection()
    dictionary = {'command': command, 'category': category, 'bindings': bindings}

    skip_tables = [
        'blocks', 'transactions',
        'balances', 'messages', 'mempool', 'assets', 
        'suicides', 'postqueue', # These tables are ephemeral.
        'nonces', 'storage' # List message manually.
    ]
    skip_tables_block_messages = copy.copy(skip_tables)
    if command == 'update':
        # List message manually.
        skip_tables += ['orders', 'bets', 'rps', 'order_matches', 'bet_matches', 'rps_matches', 'contracts']

    # Record alteration in database.
    if category not in skip_tables:
        log.message(db, bindings['block_index'], command, category, bindings)
    # Record alteration in computation of message feed hash for the block
    if category not in skip_tables_block_messages:
        sorted_bindings = sorted(bindings.items()) if isinstance(bindings, dict) else [bindings,] 
        BLOCK_MESSAGES.append('{}{}{}'.format(command, category, sorted_bindings))

    return True

class DatabaseIntegrityError(exceptions.DatabaseError):
    pass
def get_connection(read_only=True, foreign_keys=True, integrity_check=True):
    """Connects to the SQLite database, returning a db `Connection` object"""
    logger.debug('Creating connection to `{}`.'.format(config.DATABASE))

    if read_only:
        db = apsw.Connection(config.DATABASE, flags=0x00000001)
    else:
        db = apsw.Connection(config.DATABASE)
    cursor = db.cursor()

    # For integrity, security.
    if foreign_keys and not read_only:
        # logger.debug('Checking database foreign keys.')
        cursor.execute('''PRAGMA foreign_keys = ON''')
        cursor.execute('''PRAGMA defer_foreign_keys = ON''')
        rows = list(cursor.execute('''PRAGMA foreign_key_check'''))
        if rows:
            for row in rows:
                logger.debug('Foreign Key Error: {}'.format(row))
            raise exceptions.DatabaseError('Foreign key check failed.')

        # So that writers don’t block readers.
        cursor.execute('''PRAGMA journal_mode = WAL''')
        # logger.debug('Foreign key check completed.')

    # Make case sensitive the `LIKE` operator.
    # For insensitive queries use 'UPPER(fieldname) LIKE value.upper()''
    cursor.execute('''PRAGMA case_sensitive_like = ON''')

    if integrity_check:
        logger.debug('Checking database integrity.')
        integral = False
        for i in range(10): # DUPE
            try:
                cursor.execute('''PRAGMA integrity_check''')
                rows = cursor.fetchall()
                if not (len(rows) == 1 and rows[0][0] == 'ok'):
                    raise exceptions.DatabaseError('Integrity check failed.')
                integral = True
                break
            except DatabaseIntegrityError:
                time.sleep(1)
                continue
        if not integral:
            raise exceptions.DatabaseError('Could not perform integrity check.')
        # logger.debug('Integrity check completed.')

    db.setrowtrace(rowtracer)
    db.setexectrace(exectracer)

    cursor.close()
    return db

def version(db):
    cursor = db.cursor()
    user_version = cursor.execute('PRAGMA user_version').fetchall()[0]['user_version']
    # manage old user_version
    if user_version == config.VERSION_MINOR:
        version_minor = user_version
        version_major = config.VERSION_MAJOR
        user_version = (config.VERSION_MAJOR * 1000) + version_minor
        cursor.execute('PRAGMA user_version = {}'.format(user_version))
    else:
        version_minor = user_version % 1000
        version_major = user_version // 1000
    return version_major, version_minor

def update_version(db):
    cursor = db.cursor()
    user_version = (config.VERSION_MAJOR * 1000) + config.VERSION_MINOR
    cursor.execute('PRAGMA user_version = {}'.format(user_version)) # Syntax?!
    logger.info('Database version number updated.')

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
