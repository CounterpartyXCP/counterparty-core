CREATE TABLE all_expirations(
    type TEXT,
    object_id TEXT,
    block_index INTEGER);
CREATE INDEX all_expirations_type_idx ON all_expirations (type);
CREATE INDEX all_expirations_block_index_idx ON all_expirations (block_index);

INSERT INTO all_expirations (object_id, block_index, type)
SELECT order_hash AS object_id, block_index, 'order' AS type
FROM order_expirations;
INSERT INTO all_expirations (object_id, block_index, type)
SELECT order_match_id AS object_id, block_index, 'order_match' AS type
FROM order_match_expirations;
INSERT INTO all_expirations (object_id, block_index, type)
SELECT bet_hash AS object_id, block_index, 'bet' AS type
FROM bet_expirations;
INSERT INTO all_expirations (object_id, block_index, type)
SELECT bet_match_id AS object_id, block_index, 'bet_match' AS type
FROM bet_match_expirations;
INSERT INTO all_expirations (object_id, block_index, type)
SELECT rps_hash AS object_id, block_index, 'rps' AS type
FROM rps_expirations;
INSERT INTO all_expirations (object_id, block_index, type)
SELECT rps_match_id AS object_id, block_index, 'rps_match' AS type
FROM rps_match_expirations;