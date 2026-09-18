# Release Notes - Counterparty Core v11.4.0 (2026-09-18)

This is a security release that fixes vulnerabilities which could halt the network or cause nodes to disagree on ledger state. It also improves reorganization handling, API performance and startup and shutdown times.

**All node operators should upgrade immediately. This release includes protocol changes that activate at mainnet block 971,700 (approximately October 17, 2026).**

# Upgrading

To upgrade, download the latest version of `counterparty-core` and restart `counterparty-server`.

**The first start automatically refreshes the State DB. Allow approximately 30 minutes on mainnet, during which the API will be unavailable. No ledger reparse is required when upgrading from v11.3.0.**

For Kubernetes deployments, point liveness and readiness probes at the dedicated health listener before upgrading: `/healthz/live` and `/healthz/ready`, on port `4002` by default on mainnet. During the refresh, liveness returns `200` and readiness returns `503 rebuilding`.

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

Bootstrap snapshots for v11.4.0 include the State DB refresh and are selected automatically by `counterparty-server bootstrap` on mainnet, testnet4 and signet. Existing nodes do not need to bootstrap again.

The protocol changes activate at the following block heights:

| Network | Broadcast validation and MPMA changes | Ordinals metadata support |
| --- | ---: | ---: |
| Mainnet | 971,700 | 971,700 |
| Testnet3 | 5,166,000 | 5,166,000 |
| Testnet4 | 155,500 | 155,500 |
| Signet | 325,500 | Already active |

All changes are enabled on regtest. The activation heights for `correct_transaction_fee`, released in v11.3.0, are unchanged. The other security fixes take effect immediately on upgrade.

# ChangeLog

## Security

- Fix remotely triggerable chain halts in transaction decoding, broadcasts, bets, dispensers, fairminters, issuances and AMM pool operations ([GHSA-pmfx-7qj5-fx6c](https://github.com/CounterpartyXCP/counterparty-core/security/advisories/GHSA-pmfx-7qj5-fx6c)).
- Fix inconsistent inscription reveal source and fee calculations when Bitcoin RPC lookups fail.
- Handle malformed backend responses as RPC errors to prevent valid transactions from being silently skipped.
- Make SegWit detection consistent between the Rust parser and Python fallback.
- Fix Rust deserializer panics caused by empty encryption keys and RPC client initialization failures.
- Enforce minimum software versions at the correct activation heights on testnet and signet.

## Protocol

These four changes take effect at the activation heights listed above:

- Reject broadcasts whose timestamp, value or fee fraction is NaN, infinite or a decimal value that cannot be stored in the ledger (`reject_non_finite_broadcast`).
- Reject broadcasts with negative fee fractions (`reject_negative_fee_fraction`).
- Enable Counterparty messages in the `xcp` field of an Ordinals inscription metadata map (`ordinals_metadata_support`) on mainnet, testnet3 and testnet4. This format was previously documented but not activated on those networks (#3502).
- Allow an MPMA send to pay Taproot and P2WSH destinations (`mpma_taproot_support`). The address table switches from the fixed 21-byte legacy packing to a length byte followed by the self-describing address packing already used by enhanced sends and sweeps. Before activation, tables are written and read exactly as before. Wallets that decode MPMA sends must support the new table by the activation height (#3208).

## API

- Speed up address history queries for credits, debits and sends (#3489).
- Limit `offset` to 0–10,000 on `/v2/addresses/<address>/credits`, `/debits`, `/sends` and `/sends/<asset>`. Use `cursor` for deeper pagination. These routes return `result_count: null` on cursor pages; initial and offset pages retain the count.
- Remove `sort` from the address `/sends` and `/sends/<asset>` endpoints. Requests supplying it now return `400`.
- Deduplicate repeated `send_type` values and reject unknown values.
- Return `409 Conflict` when composing an issuance or fairminter that conflicts with an asset operation in Counterparty's parsed mempool. Retry after the pending transaction confirms or leaves the mempool. `validate=false` bypasses this check (#3490).
- Add readiness reasons `rebuilding`, `starting` and `watcher_stopped`. Readiness returns `503` while rebuilding, before the API can serve requests or after the watcher fails, including in `--api-only` mode (#3485, #3493, #3504).
- Include `openapi.json` in wheels and source distributions, fixing `/v2/openapi.json` in the official container. Document the pagination changes and composition conflicts (#3495, #3505, #3507).
- Return all recipients, quantities, and memos when unpacking MPMA transactions, rather than only the first recipient for each asset.

## Performance

- Use incremental State DB rollback for reorganizations up to 1,000 blocks, with a full rebuild as fallback. Reorganizations may change default listing order; restart active pagination cursors after a reorganization (#3485).
- Speed up API watcher startup and reorganization checks by using indexed event lookups (#3486).
- Avoid multi-minute API startup delays by disabling automatic SQLite optimization during database connection creation. Existing indexes, query statistics and explicit optimization calls are preserved (#3517).
- Bound API shutdown to a shared eight-second budget and interrupt pending database reads. Gunicorn requests still running when its drain deadline expires may be dropped (#3486, #3513).
- Report State DB rebuild progress, migration timings and shutdown failures in logs.

## Bugfixes

- Fix source resolution for inscription reveals spending coinbase outputs.
- Detect reorganizations at the chain tip, during catch-up and while partially through a block (#3493).
- Restore missing address history after State DB refreshes and full rollbacks, including gaps left by earlier releases (#3503).
- Keep balance block indexes, transaction indexes, subasset names and zero-quantity updates consistent between rebuilt and streamed State DBs (#3485).
- Fix Gunicorn worker retirement hanging on health-listener shutdown.
- Clean up temporary GnuPG directories and agents after snapshot signature verification (#3492).
- Update the Docker Compose image to v11.4.0 and verify the version in integration tests (#3506).
- Fix `destination_vout` on `compose/attach`, which rejected every value because the parameter was declared as a string. It is now an integer, so an attach can target a specific output (#3519).

## Codebase

- Share State DB projection, address-event and replay-cursor logic between build, rollback and watcher code.
- Add rollback indexes on `addresses`, `rps` and `rps_matches`.
- Expand parser fuzzing and add security, rollback, lifecycle and packaging regression tests.
- Update `h2` to 0.4.19 for RUSTSEC-2026-0258 and `chacha20` to 0.10.2.

# Credits

- Ouziel Slama
- Dan Anderson
- Adam Krellenstein
- John A. Zoidburg (vulnerability report)
