# Unreleased

## API

- Return MPMA decoding failures through the unpack endpoint's existing
  `message_data.error` response (HTTP 200), rather than a generic HTTP 503 and
  unexpected-error reports. Historical data still requires its original
  `block_index`; omitting it uses the current height's protocol rules. This does
  not change consensus decoding or accept legacy messages under current rules.

## Bootstrap

- Download signed bootstrap snapshots from `https://bootstrap.counterparty.io`
  so the storage backend can be migrated without another client URL change.
  Snapshot filenames, selected snapshot version, and signature verification
  are unchanged.
