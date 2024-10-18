-- depends: 0012.add_index_on_event_index

CREATE INDEX IF NOT EXISTS issuances_status_asset_longname_tx_index_idx ON issuances (status, asset_longname, tx_index DESC);
