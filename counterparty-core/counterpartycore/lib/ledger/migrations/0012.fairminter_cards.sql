-- Fairminter cards: a fairminter may distribute a set of numbered card
-- subassets (`<asset>.1` .. `<asset>.N`) instead of one asset. One row per
-- card, written when the fairminter is parsed; a card's minted count is its
-- asset supply (every draw is an issuance of the card asset).
CREATE TABLE IF NOT EXISTS fairminter_cards(
    fairminter_tx_index INTEGER,
    block_index INTEGER,
    card_index INTEGER,
    asset INTEGER,
    asset_longname TEXT,
    weight INTEGER,
    max_supply INTEGER
);
CREATE INDEX IF NOT EXISTS fairminter_cards_fairminter_tx_index_idx ON fairminter_cards (fairminter_tx_index);
CREATE INDEX IF NOT EXISTS fairminter_cards_block_index_idx ON fairminter_cards (block_index);
CREATE INDEX IF NOT EXISTS fairminter_cards_asset_idx ON fairminter_cards (asset);

-- Whether the issuer may still add cards (`addcards` message).
ALTER TABLE fairminters ADD COLUMN lock_cards BOOL DEFAULT 0;
