-- depends: 0007.create_fairminters_tables
ALTER TABLE balances ADD COLUMN utxo TEXT;
ALTER TABLE credits ADD COLUMN utxo TEXT;
ALTER TABLE debits ADD COLUMN utxo TEXT;
ALTER TABLE transactions ADD COLUMN utxos_info TEXT;
CREATE INDEX IF NOT EXISTS balances_utxo_idx ON balances (utxo);
CREATE INDEX IF NOT EXISTS credits_utxo_idx ON credits (utxo);
CREATE INDEX IF NOT EXISTS debits_utxo_idx ON debits (utxo);