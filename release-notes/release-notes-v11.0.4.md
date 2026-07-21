# Release Notes - Counterparty Core v11.0.4 (2026-01-20)

This release fixes a bug in UTXO balances cache rebuilding that caused some `utxomove` transactions to go undetected after a node restart. It also delivers significant performance improvements: startup time has been reduced from 8+ minutes to 33 seconds, and Kubernetes shutdown time from 182 seconds to 21 seconds. New CLI options (`--db-connection-pool-size`, `--db-max-connections`, `--memory-profile`) provide better control over database connections and memory monitoring. The API has been optimized with new indexes and faster case-insensitive asset queries. Additionally, the `sat_per_vbyte` parameter now supports sub-1 sat/vByte values (e.g., 0.5) for lower-fee transactions when network conditions permit. A rollback to block 926,807 will occur automatically on mainnet.

# Upgrading

**Upgrade Instructions:**

To upgrade, download the latest version of `counterparty-core` and restart `counterparty-server`. A rollback to block 926,807 will occur automatically on mainnet.

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

## Features

- Support sub-1 sat/vByte fee rates (e.g., 0.5 sat/vByte) for transaction composition

## Bugfixes

- Fix `current_commit` in API root
- Fix reorg edge case
- Fallback to RPC when `getzmqnotifications` RPC call is not available
- Fix RSFetcher restart
- Fix state.db reorg
- Fix UTXO cache building
- Fix `next_cursor` in API results when `sort` is provided
- Fix DB config params not being passed to API subprocess (caused connection pool contention)
- Fix connection leak on pooled connection validation failure
- Fix RSFetcher restart delay when recovering from errors

## Codebase

- Increase BURN_END_TESTNET3 to 99999999
- Add graceful SIGTERM handling for Kubernetes deployments (shutdown time: 182s → 21s)
- Improve Docker build caching for Rust components
- Add block parsing timing instrumentation at debug level
- Update Werkzeug to 3.1.4
- Update PyO3 to 0.24.1
- Eliminate 8-minute startup delay by storing event column in address_events table (startup time: 8+ min → 33s)
- Add checkpoint for block 932500
- Add interruptible sleep in Bitcoin core client for clean shutdown

## Performance & Memory

- Add configurable database connection pool limits (`--db-connection-pool-size`, `--db-max-connections`)
- Add connection pool instrumentation (POOL_STATS logging every 60s with peak tracking and contention warnings)
- Add memory profiler for monitoring cache sizes and process memory (`--memory-profile`, lightweight with no tracemalloc)
- Convert NotSupportedTransactionsCache from O(n) list to O(1) set for faster lookups (backup file limit removed; cache cleared on rollback)
- AssetCache loads all assets at startup (~70MB for 246k assets)
- UTXOBalancesCache now cleans up spent UTXOs after each block to prevent unbounded memory growth
- Improve RSFetcher restart logic

## API

- Fix slow asset lookups by using `COLLATE NOCASE` instead of `UPPER()` for case-insensitive queries
- Add performance indexes for `assets_info`, `balances`, and `dispensers` tables
- Optimize list deduplication in verbose mode using sets
- Fix `get_balances_by_address_and_asset` endpoint

## CLI

- Add `--db-connection-pool-size` to configure connection pool size (default: 10)
- Add `--db-max-connections` to limit total database connections across threads (default: 50, 0=unlimited)
- Add `--memory-profile` to enable periodic memory usage logging

# Credits

- Ouziel Slama
- Adam Krellenstein
