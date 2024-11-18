-- depends: 0005.populate_consolidated_tables

UPDATE fairminters SET 
    earned_quantity = (
        SELECT SUM(earn_quantity) 
        FROM fairmints 
        WHERE fairmints.fairminter_tx_hash = fairminters.tx_hash
    ),
    paid_quantity = (
        SELECT SUM(paid_quantity) 
        FROM fairmints 
        WHERE fairmints.fairminter_tx_hash = fairminters.tx_hash
    ),
    commission = (
        SELECT SUM(commission) 
        FROM fairmints 
        WHERE fairmints.fairminter_tx_hash = fairminters.tx_hash
    );