# Release Notes - Counterparty Core v11.6.0 (2026-10-31)

This release fixes XCP supply accounting for AMM pool usage fees, which introduces one protocol change. It also makes nodes check for mandatory upgrades continuously and report their protocol compatibility through the API and health checks, returns structured MPMA decoding errors from the API, and updates dependencies for security advisories.

**All node operators must upgrade before mainnet block 978,500, expected around 2026-11-30.** No pool fee has ever been charged on mainnet, testnet4 or signet, so the change is not expected to affect any block, but nodes that have not upgraded by then are no longer guaranteed to agree with the network.

# Upgrading

To upgrade, download the latest version of `counterparty-core` and restart `counterparty-server`.

**No reparse, rollback or State DB rebuild is required when upgrading from v11.5.0, and the API stays available throughout.** The protocol change activates ahead of every chain tip.

**Nodes still running v11.4.0 or earlier must roll back before starting v11.6.0.** Database upgrade actions only run for the version being installed, so skipping v11.5.0 also skips its rollback to the `require_reveal_source_signature` activation height. A running v11.4.0 node only checked minimum versions at startup, so it may have kept parsing past that height with the old rule. Run `counterparty-server rollback 969320` (testnet3: 5151805, testnet4: 154564, signet: 324359) once with v11.6.0 installed, then start the server. This rolls back both the Ledger DB and the State DB. Alternatively, bootstrap again.

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

The protocol change activates at the following block heights, the blocks each chain is expected to reach around 2026-11-30:

| Network | `fix_pool_fee_destruction` |
| --- | ---: |
| Mainnet | 978,500 |
| Testnet3 | 5,410,000 |
| Testnet4 | 161,900 |
| Signet | 333,100 |

Testnet3 block times are too erratic for this estimate to be reliable. The change is enabled from block 0 on regtest.

# ChangeLog

## Protocol

- Record XCP destruction when a nonzero pool deposit, pool withdrawal, or fairminter pool-creation fee is charged (`fix_pool_fee_destruction`). This keeps XCP supply and asset conservation consistent with the debited balances, including the API's supply projection. Before the fix, the first such fee would have failed the asset conservation check and stopped the node. Trading fees retained in pool reserves are unaffected. No such fee has been charged on mainnet, testnet4 or signet, so no historical block is affected.

## Upgrade Compatibility

- Refresh published minimum-version requirements in a background thread every five minutes, including in API-only mode. Previously they were only checked when the server started.
- Expose cached protocol compatibility in the API root, response headers and health readiness. Before activation, report a pending upgrade without blocking service. At a known unsupported activation height, stop parsing before writing the block and return `503 protocol_upgrade_required` for ordinary API requests. Diagnostic endpoints remain available and liveness stays separate. See [Protocol upgrade signals](../README.md#protocol-upgrade-signals).
- Retain known upgrade requirements during metadata outages and report stale or unknown verification explicitly. `--force` remains an explicit, advertised unsafe bypass. This mechanism changes no protocol rule, activation height or ledger format.
- Verify upgrade metadata at startup before any `UPGRADE_ACTIONS` reparse, so reparsed blocks are checked against the published requirements.

## API

- Return MPMA decoding failures, including malformed address tables and recipient indexes past the end of the table, through the existing `message_data.error` response (HTTP 200) of `/v2/transactions/unpack` and `/v2/transactions/info`, rather than a generic HTTP 503 and unexpected-error reports. Verbose `unpacked_data` reports the specific error instead of the generic "Could not unpack data". Historical data still requires its original `block_index`; omitting it uses the current height's protocol rules. This does not change consensus decoding or accept legacy messages under current rules.

## Bootstrap

- Download signed bootstrap snapshots from `https://bootstrap.counterparty.io` so the storage backend can be migrated without another client URL change. Snapshot filenames, selected snapshot version, and signature verification are unchanged.

## Codebase

- Bump `pyo3` to 0.29.3 (RUSTSEC-2026-0176, RUSTSEC-2026-0177), `rustls` to 0.23.46 and `rustls-webpki` to 0.103.16 (RUSTSEC-2026-0049, -0098, -0099, -0104, -0285, -0346, -0348, -0349) in `counterparty-rs`.
- Bump `quinn-proto` to 0.11.19, `rustls` to 0.23.46, `rustls-webpki` to 0.103.16 and `webpki-root-certs` to 1.0.10 in `counterparty-client` (RUSTSEC-2026-0338 to -0342, RUSTSEC-2026-0346 to -0349, RUSTSEC-2026-0382, RUSTSEC-2026-0383), and triage the unmaintained `unsafe-libyaml` and standalone `zbus` crates in the audit configuration.
- Bump `tokio` to 1.53.3 in `counterparty-rs` and `counterparty-client` (RUSTSEC-2026-0386).
- Bump `Werkzeug` to 3.1.9 (GHSA-g6x2-hccm-hh4m). The advisory only affects nodes running on Windows.

# Credits

- Ouziel Slama
- Adam Krellenstein
- Dan Anderson
