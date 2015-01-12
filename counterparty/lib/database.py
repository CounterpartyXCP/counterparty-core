import apsw
import logging
logger = logging.getLogger(__name__)
import time


from counterparty.lib import config
from counterparty.lib import util
from counterparty.lib import exceptions
from counterparty.lib import log

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
        return True

    db = cursor.getconnection()
    dictionary = {'command': command, 'category': category, 'bindings': bindings}

    # Skip blocks, transactions.
    if 'blocks' in sql or 'transactions' in sql: return True

    # Record alteration in database.
    if category not in ('balances', 'messages', 'mempool', 'assets'):
        if category not in ('suicides', 'postqueue'):  # These tables are ephemeral.
            if category not in ('nonces', 'storage'):  # List message manually.
                if not (command in ('update') and category in ('orders', 'bets', 'rps', 'order_matches', 'bet_matches', 'rps_matches', 'contracts')):    # List message manually.
                    # try:
                        log.message(db, command, category, bindings)
                    # except:
                        # raise TypeError('SQLite3 statements must used named arguments.')

    return True

class DatabaseIntegrityError(exceptions.DatabaseError):
    pass
def get_connection(read_only=True, foreign_keys=True, integrity_check=True):
    """Connects to the SQLite database, returning a db `Connection` object"""
    logger.debug('Creating connection to `{}`.'.format(config.DATABASE.split('/').pop()))

    if read_only:
        db = apsw.Connection(config.DATABASE, flags=0x00000001)
    else:
        db = apsw.Connection(config.DATABASE)
    cursor = db.cursor()

    # For integrity, security.
    if foreign_keys and not read_only:
        cursor.execute('''PRAGMA foreign_keys = ON''')
        cursor.execute('''PRAGMA defer_foreign_keys = ON''')
        rows = list(cursor.execute('''PRAGMA foreign_key_check'''))
        if rows: raise exceptions.DatabaseError('Foreign key check failed.')

        # So that writers don’t block readers.
        cursor.execute('''PRAGMA journal_mode = WAL''')

    # Make case sensitive the `LIKE` operator.
    # For insensitive queries use 'UPPER(fieldname) LIKE value.upper()''
    cursor.execute('''PRAGMA case_sensitive_like = ON''')

    if integrity_check:
        # Integrity check
        integral = False
        for i in range(10): # DUPE
            try:
                logger.debug('Checking database integrity.')
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

    db.setrowtrace(rowtracer)
    db.setexectrace(exectracer)

    cursor.close()
    return db

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
