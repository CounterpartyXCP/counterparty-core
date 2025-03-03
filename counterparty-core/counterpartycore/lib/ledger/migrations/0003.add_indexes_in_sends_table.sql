CREATE INDEX IF NOT EXISTS sends_send_type ON sends (send_type);
CREATE INDEX IF NOT EXISTS sends_source_address ON sends (source_address);
CREATE INDEX IF NOT EXISTS sends_destination_address ON sends (destination_address);