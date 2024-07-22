-- depends: 0005.add_addresses_field_in_mempool
ALTER TABLE assets_info ADD COLUMN confirmed BOOLEAN DEFAULT TRUE;