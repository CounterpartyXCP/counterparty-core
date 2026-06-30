-- Fairminter pool funding: tokens + collected XCP can seed an AMM pool at close
ALTER TABLE fairminters ADD COLUMN pool_quantity INTEGER DEFAULT 0;
ALTER TABLE fairminters ADD COLUMN lp_asset TEXT;
CREATE INDEX IF NOT EXISTS fairminters_lp_asset_idx ON fairminters (lp_asset);
