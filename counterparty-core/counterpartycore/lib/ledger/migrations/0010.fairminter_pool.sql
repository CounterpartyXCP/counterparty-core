-- Fairminter pool funding: tokens + collected XCP can seed an AMM pool at close
ALTER TABLE fairminters ADD COLUMN pool_quantity INTEGER DEFAULT 0;
