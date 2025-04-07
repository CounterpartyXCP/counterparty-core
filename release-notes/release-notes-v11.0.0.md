# Release Notes - Counterparty Core v11.0.0 (2025-03-??)


# Upgrading

**Upgrade Instructions:**
To upgrade, download the latest version of `counterparty-core` and restart `counterparty-server`.

With Docker Compose:

```bash
cd counterparty-core
git pull
docker compose stop counterparty-core
docker compose --profile mainnet up -d
```

or use `ctrl-c` to interrupt the server:

```bash
cd counterparty-core
git pull
cd counterparty-rs
pip install -e .
cd ../counterparty-core
pip install -e .
counterparty-server start
```

# ChangeLog

## Bugfixes

- Fix verbose mode when unpack fails
- Handle correctly `DatabaseError` on API calls
- Fix verbose mode in get transactions endpoints
- Fix `script_to_address` function, handle correctly taproot addresses
- Prevent taproot address for MPMA sends and dispenser Oracle
- Fix Testnet4 bootsrap with custom url
- Fix Composer for taproot address
- Fix `address.pack` and `address.unpack` functions, handle correctly taproot addresses
- Make `APSWConnectionPool` thread safe
- Fix typo in composer paramerters: `mutlisig_pubkey` -> `multisig_pubkey`
- Fix `price_normalized` in Fairminters endpoints
- Fix event name: `BET_MATCH_RESOLUTON` => `BET_MATCH_RESOLUTION`
- Fix `is_segwit` value in `get_vin_info`
- Fix `apsw.ThreadingViolationError` with `APSWConnectionPool`
- Optimize `APSWConnectionPool`
- Fix `ledger_state` field in API root endpoint

## Codebase

- Use a new data encoding format for Sweep, Enhanced Send, Fairminter and Fairmint with variable length for every data field
- Update ledger hashes checkpoints using truncated addresses
- Use asset ID instead asset name in Fairminter and Fairmint messages
- Allow `soft_cap` to be equal to `hard_cap` in Fairminter
- Add `max_mint_per_address` parameter
- Clean up hard-coded protocol changes distributed throughout codebase
- Add Taproot envelope data encoding support
- Remove P2SH data encoding support
- Ensure fairminters' hard cap is a multiple of lot size

## API

- Adds `asset` as optional param to Get Balances by Addresses endpoint
- The `encoding` parameter now accepts the `taproot` value
- Ensure that Fairminter's `start_block` and `end_block` are greater than the current block
- In Compose Fairminter, rename `price` to `lot_price` and `quantity_by_price` to `lot_size`
- In Composer Fairmint, ensure that `quantity` is a multiple of `lot_size`
- Ensure that Fairminter's `hard_cap` is greater than the sum of `premint_quantity` and `soft_cap`
- The POST URL encoded parameters are now accepted to compose a transaction

## CLI

- Adds support for the `SLACK_HOOK` environment variable containing a webhook URL called after a rebuild
- The `--profile` flag now generates a report every 15 minutes instead of just one at shutdown
- Add `URGENT` log level displayed even with `--quiet` flag
- Add `--enable-all-protocol-changes` flag for testing purposes

# Credits

- Ouziel Slama
- Adam Krellenstein
