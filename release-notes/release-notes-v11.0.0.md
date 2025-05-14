# Release Notes - Counterparty Core v11.0.0 (2025-05-14)

Counterparty Core v11.0.0 is a large release with numerous protocol upgrades and many miscellaneous improvements to the API, CLI and codebase, including significantly increased test coverage.

**Protocol Upgrades:**
- Fix Bech32 address handling—now support P2WSH and P2TR
- Support for Taproot envelope data encoding, which will significantly reduce transaction fees for larger transactions (and removal of support for P2SH data encoding, which is strictly worse than Taproot)
- Support for Ordinals Inscription creation when composing an Issuance, Fairminter or Broadcast (API parameters: `inscription`, `mime_type`)
- Allow `soft_cap` to be equal to `hard_cap` with Fairminters
- Add `max_mint_per_address` parameter to Fairminters (API parameter: `max_mint_per_address`)

# Upgrading

**This release is a protocol upgrade. All nodes must upgrade by block 898800.**

**Important** A bug in Bech32 and Taproot address handling introduced in 2018 caused these addresses to be stored in the database incorrectly. As part of fixing this, and adding proper support for P2WSH and P2TR address types, a full database reparse is required. This operation takes approximately 7 hours on an M3 Mac. As a consequence, Counterparty Core >= v11.0.0 will have all consensus hashes and checkpoints updated retroactively.

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

## Protocol

- Fix Bech32 address support
- Use CBOR encoding format for Sweep, Enhanced Send, Fairminter, Fairmint, Issuance and Broadcast
- Allow `soft_cap` to be equal to `hard_cap` with Fairminters
- Add `max_mint_per_address` parameter to Fairminters
- Ensure Fairminter hard cap is a multiple of the lot size
- Use asset ID instead of asset name in Fairminter and Fairmint messages
- Add Taproot envelope data encoding support (disabled for transactions with a destination output and `detach`)
- Add support for Taproot change address
- Remove P2SH data encoding support
- Use an envelope script compatible with Ordinals when the description/text of a Fairminter, Issuance or Broadcast is not empty


## Bugfixes

- Fix API verbose flag when unpacking fails
- Fix API verbose flag for the Get Transactions endpoints
- Handle `DatabaseError` correctly in API calls
- Fix `is_cachable()` function in API v2
- Fix `ledger_state` field in API root endpoint
- Disable Taproot addresses for MPMA sends and dispenser oracles
- Fix composer for Taproot addresses
- Fix `script_to_address` function's handling of taproot addresses
- Fix `testnet4` bootstrap with custom URL
- Fix `address.pack` and `address.unpack` functions' handling of Taproot addresses
- Make `APSWConnectionPool` thread-safe
- Fix typo in composer parameters: `mutlisig_pubkey` -> `multisig_pubkey`
- Fix `price_normalized` in Fairminters endpoints
- Fix event name: `BET_MATCH_RESOLUTON` -> `BET_MATCH_RESOLUTION`
- Fix `is_segwit` value in `get_vin_info`
- Fix `apsw.IOError` when using `--rebuild-state-db` flag
- Fix round error in inputs values when composing transaction
- Fix Fairminter validation
- Fix SIGHASH collecting
- Fix create dispenser using subasset name

## Codebase

- Improve test coverage by 10% (from ~78% to ~88%)
- Update ledger-hash checkpoints using truncated addresses
- Clean up hard-coded protocol changes throughout codebase
- Optimize `APSWConnectionPool`
- Add `mime_type` to `issuances`, `fairminters` and `broadcasts` tables

## API

- When using an Ordinals envelope script, add a dust output for the source address
- Add `asset` as an optional parameter to the Get Balances by Addresses endpoint
- The `encoding` parameter now accepts a `taproot` value
- Ensure that Fairminter's `start_block` and `end_block` are greater than the current block
- In Compose Fairminter, rename `price` -> `lot_price` and `quantity_by_price` -> `lot_size`
- In Compose Fairmint, ensure that `quantity` is a multiple of `lot_size`
- Ensure that Fairminter's `hard_cap` is greater than the sum of `premint_quantity` and `soft_cap`
- `POST` URL-encoded parameters are now accepted when composing a transaction
- Add `mime_type` parameter to `compose_issuance`, `compose_fairminter` and `compose_broadcast` endpoints
- Remove mandatory fields for broadcast: `fee_fraction`, `value`, `timestamp`
- Add `inscription` parameter to the compose API
- Add `category` field to functions and arguments in `/v2/routes` endpoint response

## CLI

- Add support for the `SLACK_HOOK` environment variable containing a webhook URL called after a rebuild
- The `--profile` flag now generates a report every 15 minutes instead of just once at shutdown
- Add `URGENT` log level displayed even with `--quiet` flag
- Add `--enable-all-protocol-changes` flag for testing purposes
- Remove `mempoolfullrbf=1` from `docker-compose.yml`

# Credits

- Ouziel Slama
- Adam Krellenstein
