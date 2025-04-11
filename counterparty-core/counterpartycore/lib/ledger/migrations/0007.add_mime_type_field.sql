ALTER TABLE fairminters ADD COLUMN mime_type TEXT DEFAULT "text/plain";
ALTER TABLE issuances ADD COLUMN mime_type TEXT DEFAULT "text/plain";
