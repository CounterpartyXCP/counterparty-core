-- depends: 0001.api_db_to_state_db

DELETE FROM events_count;

INSERT INTO events_count (event, count)
    SELECT event, COUNT(*) AS counter
    FROM messages
    GROUP BY event;