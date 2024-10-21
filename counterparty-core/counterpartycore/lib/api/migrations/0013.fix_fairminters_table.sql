-- depends: 0012.add_index_on_event_index

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
