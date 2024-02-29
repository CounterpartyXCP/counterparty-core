import apsw
import apsw.bestpractice
apsw.bestpractice.apply(apsw.bestpractice.recommended)  # includes WAL mode
import logging
logger = logging.getLogger(__name__)
import time
import collections
import copy

from counterpartylib.lib import config
from counterpartylib.lib import ledger
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
        'blocks', 'transactions', 'transaction_outputs',
        'balances', 'messages', 'mempool', 'assets',
        'new_sends', 'new_issuances' # interim table for CIP10 activation
    ]
    skip_tables_block_messages = copy.copy(skip_tables)
    if command == 'update':
        # List message manually.
        skip_tables += ['orders', 'bets', 'rps', 'order_matches', 'bet_matches', 'rps_matches', 'dispensers']

    # Record alteration in database.
    if category not in skip_tables:
        if bindings is not None:
            if isinstance(bindings, dict):
                log.message(db, bindings['block_index'], command, category, bindings)
            # tx_index < 0 => kickstart
            elif bindings[0] < 0 and sql.startswith('insert into transaction values (tx_index, tx_hash, block_index, '):
                log.message(db, bindings[2], command, category, bindings[2])
            else:
                #raise exceptions.DatabaseError('Unknown bindings type.')
                pass # just pass until we remove this function

    # Record alteration in computation of message feed hash for the block
    if category not in skip_tables_block_messages:
        # don't include asset_longname as part of the messages hash
        #   until subassets are enabled
        if category == 'issuances' and not ledger.enabled('subassets'):
            if isinstance(bindings, dict) and 'asset_longname' in bindings: del bindings['asset_longname']

        # don't include memo as part of the messages hash
        #   until enhanced_sends are enabled
        if category == 'sends' and not ledger.enabled('enhanced_sends'):
            if isinstance(bindings, dict) and 'memo' in bindings: del bindings['memo']

        sorted_bindings = sorted(bindings.items()) if isinstance(bindings, dict) else [bindings,]
        BLOCK_MESSAGES.append('{}{}{}'.format(command, category, sorted_bindings))

    return True


class DatabaseIntegrityError(exceptions.DatabaseError):
    pass
def get_connection(read_only=True, foreign_keys=True, integrity_check=True):
    """Connects to the SQLite database, returning a db `Connection` object"""
    logger.debug('Creating connection to `{}`.'.format(config.DATABASE))

    if read_only:
        db = apsw.Connection(config.DATABASE, flags=apsw.SQLITE_OPEN_READONLY)
    else:
        db = apsw.Connection(config.DATABASE)
    cursor = db.cursor()

    # For integrity, security.
    if foreign_keys and not read_only:
        logger.info('Checking database foreign keys...')
        cursor.execute('''PRAGMA foreign_keys = ON''')
        cursor.execute('''PRAGMA defer_foreign_keys = ON''')
        rows = list(cursor.execute('''PRAGMA foreign_key_check'''))
        if rows:
            for row in rows:
                logger.debug('Foreign Key Error: {}'.format(row))
            raise exceptions.DatabaseError('Foreign key check failed.')

        logger.info('Foreign key check completed.')

    # Make case sensitive the `LIKE` operator.
    # For insensitive queries use 'UPPER(fieldname) LIKE value.upper()''
    cursor.execute('''PRAGMA case_sensitive_like = ON''')

    if integrity_check:
        logger.info('Checking database integrity...')
        integral = False

        # Try up to 10 times.
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
        logger.info('Integrity check completed.')

    cursor.execute('PRAGMA auto_vacuum = 1')
    cursor.execute('PRAGMA synchronous = normal')
    cursor.execute('PRAGMA journal_size_limit = 6144000')

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


def vacuum(db):
    logger.info('Starting database VACUUM. This may take awhile...')
    cursor = db.cursor()
    cursor.execute('VACUUM')
    logger.info('Database VACUUM completed.')


def field_is_pk(cursor, table, field):
    cursor.execute(f"PRAGMA table_info({table})")
    for row in cursor:
        if row["name"] == field and row["pk"] == 1:
            return True
    return False


def has_fk_on(cursor, table, foreign_key):
    cursor.execute(f"PRAGMA foreign_key_list ({table})")
    for row in cursor:
        if f"{row['table']}.{row['to']}" == foreign_key:
            return True
    return False


def create_indexes(cursor, table, indexes, unique=False):
    for index in indexes:
        field_names = [field.split(' ')[0] for field in index]
        index_name = f"{table}_{'_'.join(field_names)}_idx"
        fields = ', '.join(index)
        unique_clause = 'UNIQUE' if unique else ''
        query = f'''
            CREATE {unique_clause} INDEX IF NOT EXISTS {index_name} ON {table} ({fields})
        '''
        cursor.execute(query)


def drop_indexes(cursor, indexes):
    for index_name in [indexes]:
        cursor.execute(f'''DROP INDEX IF EXISTS {index_name}''')


def copy_old_table(cursor, table_name, new_create_query):
    cursor.execute(f'''ALTER TABLE {table_name} RENAME TO old_{table_name}''')
    cursor.execute(new_create_query)
    cursor.execute(f'''INSERT INTO {table_name} SELECT * FROM old_{table_name}''')
    cursor.execute(f'''DROP TABLE old_{table_name}''')