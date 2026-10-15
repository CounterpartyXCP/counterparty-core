# Unreleased

## Protocol

- Record XCP destruction when a nonzero pool deposit, pool withdrawal, or
  fairminter pool-creation fee is charged. This keeps XCP supply and asset
  conservation consistent with the debited balances, including the API's supply
  projection. Trading fees retained in pool reserves are unaffected.

## Bootstrap

- Download signed bootstrap snapshots from `https://bootstrap.counterparty.io`
  so the storage backend can be migrated without another client URL change.
  Snapshot filenames, selected snapshot version, and signature verification
  are unchanged.
