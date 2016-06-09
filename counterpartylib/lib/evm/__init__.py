

def initialise(db):
    cursor = db.cursor()

    # Contracts
    cursor.execute('''CREATE TABLE IF NOT EXISTS contracts(
                      contract_id TEXT PRIMARY KEY,
                      tx_index INTEGER,
                      tx_hash TEXT,
                      block_index INTEGER,
                      source TEXT,
                      code BLOB,
                      nonce INTEGER,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                  ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON contracts (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx_hash_idx ON contracts (tx_hash)
                   ''')

    # Contract Storage
    cursor.execute('''CREATE TABLE IF NOT EXISTS storage(
                      contract_id TEXT,
                      key BLOB,
                      value BLOB,
                      PRIMARY KEY(contract_id, `key`),
                      FOREIGN KEY (contract_id) REFERENCES contracts(contract_id))
                  ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      contract_id_idx ON contracts(contract_id)
                   ''')

    # Suicides
    cursor.execute('''CREATE TABLE IF NOT EXISTS suicides(
                      contract_id TEXT PRIMARY KEY,
                      FOREIGN KEY (contract_id) REFERENCES contracts(contract_id))
                  ''')

    # Nonces
    cursor.execute('''CREATE TABLE IF NOT EXISTS nonces(
                      address TEXT PRIMARY KEY,
                      nonce INTEGER)
                  ''')

    # Executions
    cursor.execute('''CREATE TABLE IF NOT EXISTS executions(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      contract_id TEXT,
                      gas_price INTEGER,
                      gas_start INTEGER,
                      gas_cost INTEGER,
                      gas_remained INTEGER,
                      value INTEGER,
                      data BLOB,
                      output BLOB,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                  ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON executions(source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx_hash_idx ON executions(tx_hash)
                   ''')

    cursor.close()
