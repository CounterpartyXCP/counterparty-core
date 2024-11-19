-- depends: 0016.fix2_asset_longname_field
CREATE TABLE IF NOT EXISTS events_count(
        event TEXT PRIMARY KEY,
        count INTEGER);
CREATE INDEX IF NOT EXISTS events_count_count_idx ON events_count (count);

INSERT INTO events_count (event, count)
    SELECT event, COUNT(*) AS counter
    FROM messages
    GROUP BY event;
