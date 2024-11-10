-- depends: 0013.fix_fairminters_table

CREATE INDEX IF NOT EXISTS blocks_ledger_hash_idx ON blocks (ledger_hash);