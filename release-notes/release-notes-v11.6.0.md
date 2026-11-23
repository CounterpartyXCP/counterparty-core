# Release Notes - Counterparty Core v11.6.0 (2026-10-31)

This release fixes a mainnet `txlist_hash` and `messages_hash` divergence between nodes that restarted and nodes that kept running, and fixes XCP supply accounting for AMM pool usage fees, which introduces one protocol change. It also makes nodes check for mandatory upgrades continuously and report their protocol compatibility through the API and health checks, returns structured MPMA decoding errors from the API, stops the server from hanging when the API process exits unexpectedly, and updates dependencies for security advisories.

**All node operators must upgrade before mainnet block 980,400, expected around 2026-12-16.** No pool fee has ever been charged on mainnet, testnet4 or signet, so the change is not expected to affect any block, but nodes that have not upgraded by then are no longer guaranteed to agree with the network.

# Upgrading

To upgrade, download the latest version of `counterparty-core` and restart `counterparty-server`.

**Mainnet nodes roll back to block 973,417 on first start and re-parse the blocks since.** This also rebuilds the State DB: approximately 30 minutes on mainnet, during which the API is unavailable. For Kubernetes deployments, the dedicated health listener (`/healthz/live` and `/healthz/ready`, port `4002` by default on mainnet) reports that rebuild as in v11.5.0: liveness returns `200` and readiness returns `503 rebuilding`. No balance changes: the re-parse only restores the `utxomove` transactions that a node which restarted in the middle of a chain of them failed to record (see [Consensus Determinism](#consensus-determinism)), so that every node converges on the same `txlist_hash` and `messages_hash`.

**On testnet3, testnet4 and signet, no reparse, rollback or State DB rebuild is required, and the API stays available throughout.** The protocol change activates ahead of every chain tip.

**Nodes still running v11.4.0 or earlier must roll back before starting v11.6.0.** Database upgrade actions only run for the version being installed, so skipping v11.5.0 also skips its rollback to the `require_reveal_source_signature` activation height. A running v11.4.0 node only checked minimum versions at startup, so it may have kept parsing past that height with the old rule. Run `counterparty-server rollback 969320` (testnet3: 5151805, testnet4: 154564, signet: 324359) once with v11.6.0 installed, then start the server. This rolls back both the Ledger DB and the State DB, and also covers the v11.6.0 rollback to block 973,417 on mainnet. Alternatively, bootstrap again.

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

The v11.4.0 bootstrap snapshots remain valid and are selected automatically by `counterparty-server bootstrap`. They are now downloaded from `https://bootstrap.counterparty.io`.

The protocol change activates at the following block heights, the blocks each chain is expected to reach around 2026-12-16:

| Network | `fix_pool_fee_destruction` |
| --- | ---: |
| Mainnet | 980,400 |
| Testnet3 | 5,414,600 |
| Testnet4 | 167,700 |
| Signet | 335,500 |

Testnet3 block times are too erratic for this estimate to be reliable. The change is enabled from block 0 on regtest.

# ChangeLog

## Consensus Determinism

- Rebuild the UTXO balances cache by replaying the recorded `utxos_info` of every parsed transaction, instead of loading the `balances` table plus special cases (`KNOWN_SOURCES` descendants and invalid attaches). While parsing, the first non-OP_RETURN output of every `attach`, and of every transaction spending a cached UTXO, is added to the cache even when no asset reaches that output, and a later spend of such a "phantom" UTXO is recorded as a `utxomove` transaction that moves nothing. A node that restarted, rolled back or handled a reorg in the middle of such a chain rebuilt the cache without the phantom entry and silently stopped recording the chain, so its `txlist_hash` and `messages_hash` diverged from nodes that kept running. On mainnet, the valid `attach` `86a3d0a5…085482` at block 973,405 attached to its third output while its first output entered the cache; its first output was spent at block 973,417 and started a chain of ten `utxomove` transactions, seven of which are missing on nodes that restarted after block 973,422. The cache rebuild is now a deterministic function of the Ledger DB, and an automatic rollback to block 973,417 (mainnet only) re-parses the chain so that every node converges on the freshly synced history. No protocol rule changes and no balance is affected.

## Protocol

- Record XCP destruction when a nonzero pool deposit, pool withdrawal, or fairminter pool-creation fee is charged (`fix_pool_fee_destruction`). This keeps XCP supply and asset conservation consistent with the debited balances, including the API's supply projection. Before the fix, the first such fee would have failed the asset conservation check and stopped the node. Trading fees retained in pool reserves are unaffected. No such fee has been charged on mainnet, testnet4 or signet, so no historical block is affected.

## Upgrade Compatibility

- Refresh published minimum-version requirements in a background thread every five minutes, including in API-only mode. Previously they were only checked when the server started.
- Expose cached protocol compatibility in the API root, response headers and health readiness. Before activation, report a pending upgrade without blocking service. At a known unsupported activation height, stop parsing before writing the block and return `503 protocol_upgrade_required` for ordinary API requests. Diagnostic endpoints remain available and liveness stays separate. See [Protocol upgrade signals](../README.md#protocol-upgrade-signals).
- Retain known upgrade requirements during metadata outages and report stale or unknown verification explicitly. `--force` remains an explicit, advertised unsafe bypass. This mechanism changes no protocol rule, activation height or ledger format.
- Verify upgrade metadata at startup before any `UPGRADE_ACTIONS` reparse, so reparsed blocks are checked against the published requirements.

## API

- Return MPMA decoding failures, including malformed address tables and recipient indexes past the end of the table, through the existing `message_data.error` response (HTTP 200) of `/v2/transactions/unpack` and `/v2/transactions/info`, rather than a generic HTTP 503 and unexpected-error reports. Verbose `unpacked_data` reports the specific error instead of the generic "Could not unpack data". Historical data still requires its original `block_index`; omitting it uses the current height's protocol rules. This does not change consensus decoding or accept legacy messages under current rules.
- Report Waitress connection admission (accepted connections, socket-map occupancy against the connection limit, overflow state and per-minute peaks) in `/healthz/metrics` and the `WORKER_STATS` log, to tell admission pressure apart from busy workers. Diagnostics only: readiness and liveness are unchanged.

## Mempool

- Compact the unsupported-transaction cache to 900,000 entries at its 1,000,000-entry limit, including when restoring a full cache. New hashes append between compactions instead of triggering a full-file rewrite on every mempool batch. Snapshots are written to a temporary file and atomically replaced, preserving the previous file if writing or replacement fails. The cache format and transaction validation rules are unchanged.

## Reliability

- Shut down instead of hanging forever when the API process stops unexpectedly, for example on `Address already in use` at startup. The main process blocked on a `multiprocessing.Event` that the exited API process could no longer acknowledge; the API stop signal is now a lock-free shared flag.

## Bootstrap

- Download signed bootstrap snapshots from `https://bootstrap.counterparty.io` so the storage backend can be migrated without another client URL change. Snapshot filenames, selected snapshot version, and signature verification are unchanged.

## Codebase

- Bump `pyo3` to 0.29.3 (RUSTSEC-2026-0176, RUSTSEC-2026-0177), `rustls` to 0.23.46 and `rustls-webpki` to 0.103.16 (RUSTSEC-2026-0049, -0098, -0099, -0104, -0285, -0346, -0348, -0349) in `counterparty-rs`.
- Bump `quinn-proto` to 0.11.19, `rustls` to 0.23.46, `rustls-webpki` to 0.103.16 and `webpki-root-certs` to 1.0.10 in `counterparty-client` (RUSTSEC-2026-0338 to -0342, RUSTSEC-2026-0346 to -0349, RUSTSEC-2026-0382, RUSTSEC-2026-0383), and triage the unmaintained `unsafe-libyaml` and standalone `zbus` crates in the audit configuration.
- Bump `quinn-udp` to 0.5.16 (RUSTSEC-2026-0538) and `rustix` to 1.1.6 (RUSTSEC-2026-0486) in `counterparty-client`, and `libz-sys` to 1.1.33 (RUSTSEC-2026-0544) in `counterparty-rs`.
- Bump `url` to 2.5.9 (RUSTSEC-2026-0592) in `counterparty-client`.
- Bump `tokio` to 1.53.3 in `counterparty-rs` and `counterparty-client` (RUSTSEC-2026-0386), and replace the client's yanked `async-executor` 1.14.0 with 1.14.1.
- Remove the native extension's unused `bip32` dependency and update the locked `libz-sys`, `zstd-sys` and `anyhow` dependencies to their advisory-fixed versions.
- Bump `Werkzeug` to 3.1.9 (GHSA-g6x2-hccm-hh4m). The advisory only affects nodes running on Windows.

# Credits

- Ouziel Slama
- Adam Krellenstein
- Dan Anderson
