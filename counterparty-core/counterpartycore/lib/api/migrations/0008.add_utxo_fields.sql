-- depends: 0007.create_fairminters_tables
ALTER TABLE balances ADD COLUMN utxo TEXT;
ALTER TABLE balances ADD COLUMN utxo_address TEXT;
ALTER TABLE credits ADD COLUMN utxo TEXT;
ALTER TABLE credits ADD COLUMN utxo_address TEXT;
ALTER TABLE debits ADD COLUMN utxo TEXT;
ALTER TABLE debits ADD COLUMN utxo_address TEXT;
ALTER TABLE transactions ADD COLUMN utxos_info TEXT;
ALTER TABLE sends ADD COLUMN fee_paid INTEGER DEFAULT 0;
CREATE INDEX IF NOT EXISTS balances_utxo_idx ON balances (utxo);
CREATE INDEX IF NOT EXISTS credits_utxo_idx ON credits (utxo);
CREATE INDEX IF NOT EXISTS debits_utxo_idx ON debits (utxo);
CREATE INDEX IF NOT EXISTS balances_utxo_address_idx ON balances (utxo_address);
CREATE INDEX IF NOT EXISTS credits_utxo_address_idx ON credits (utxo_address);
CREATE INDEX IF NOT EXISTS debits_utxo_address_idx ON debits (utxo_address);