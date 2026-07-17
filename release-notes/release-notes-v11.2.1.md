# Release Notes - Counterparty Core v11.2.1 (2026-07-??)

Counterparty Core v11.2.1 is an operational hardening release addressing the root causes of the 2026-07-15 production incident, in which a small number of expensive public API requests against a degraded Bitcoin backend exhausted the API worker pools. There are **no protocol changes** and no database migration; the upgrade is a plain restart.

# Upgrading

**This is not a protocol upgrade.** There is no activation block and no reparse or migration.

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

## API Changes

- A slow or unreachable Bitcoin backend now surfaces to API clients as a retryable **HTTP 503** (`BitcoindRPCError`, previously `400`) (#3459).

## Security / Hardening

- **Bound Bitcoin backend RPC retries** (#3459). `getrawtransaction_batch()` bypassed the no-retry guard used for API requests and fell through to an unbounded `while True` retry loop, so a degraded backend made compose and v1 requests retry forever, pinning worker threads until the pool was exhausted (the `(Attempt: N)` log lines from the incident). The retry decision is now centralized in `skip_rpc_retry()` and applied to both the single-call and batch paths, so API requests never enter the unbounded loop; `rpc_call` also bails out defensively in an API context. A configurable connect timeout fails an unreachable backend's TCP connect quickly instead of hanging for the full read timeout, and the parser's flat retry sleep is replaced with jittered exponential backoff so many nodes recovering from the same outage don't reconnect in lockstep. **The parser/indexing path is unchanged** — it still retries an unavailable backend indefinitely, because skipping a VIN would fork the ledger.

## Configuration

- `--backend-connect-timeout` / `BACKEND_CONNECT_TIMEOUT` (default `5` seconds) — TCP connect timeout for backend RPC (#3459).

# Credits

- Ouziel Slama
- Adam Krellenstein
