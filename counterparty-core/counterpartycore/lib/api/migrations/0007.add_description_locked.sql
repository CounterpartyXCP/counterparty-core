-- depends: 0006.add_confirmed_field_in_assets_info
ALTER TABLE issuances ADD COLUMN description_locked BOOL;