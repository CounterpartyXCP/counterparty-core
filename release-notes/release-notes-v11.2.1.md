# Release Notes - Counterparty Core v11.2.1 (2026-07-??)

Counterparty Core v11.2.1 is an operational hardening release addressing the root causes of the 2026-07-15 production incident, in which a small number of expensive public API requests against a degraded Bitcoin backend exhausted the API worker pools and took `/v2/healthz` down with them. It also lands a **staged protocol change** — a correction to the Bitcoin miner-fee calculation (#3458) — that is dormant on mainnet (no activation height is scheduled yet) and has no consensus effect in this release. There is no database migration, and the upgrade is a plain restart.

The most visible behavioral change is that the **legacy v1 JSON-RPC API is now disabled by default** — operators who still rely on it must opt back in with `--enable-api-v1`.

A dedicated health-check listener now runs on its own port (default: API port + 2 → `4002` on mainnet). Kubernetes/orchestrator probes should be repointed to `/healthz/live` and `/healthz/ready` on that port.

# Upgrading

**No protocol change activates in this release.** The staged fee-calculation correction (#3458) has no mainnet activation height yet, so there is no activation block, no reparse and no migration.

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

If you serve clients through the v1 `/api/` JSON-RPC endpoint, add `--enable-api-v1` (available on `server.conf` too) before upgrading, or those requests will now return `404`.

The new health server listens on its own port (default: API port + 2 → `4002` on mainnet); `docker-compose.yml` already exposes it. Repoint orchestrator liveness/readiness probes to `/healthz/live` and `/healthz/ready` on that port. The legacy in-API `/healthz` and `/v2/healthz` keep working.

# ChangeLog

## Health Checks

- **Isolate health checks from API worker saturation** (#3460). `/v2/healthz` was served by the same Waitress worker pool as public traffic, so during the incident it queued behind expensive requests (7–20s responses) and Kubernetes removed both live pods from service. It also made an unbounded live `getblockcount` RPC in the request path. A new dedicated health-check listener (`lib/api/healthz_server.py`, a `ThreadingHTTPServer` on its own socket and thread pool) serves probes from an in-memory snapshot maintained by a background sampler — no DB, no RPC, no locks in the request path:
  - `GET /healthz/live` — **liveness**: `200` unless the sampler heartbeat is stale (a genuine deadlock). A busy-but-alive pod is never restarted.
  - `GET /healthz/ready` — **readiness**: `503` when the ledger is behind the backend, or when the worker pool has stayed saturated past a grace period (load shed), with hysteresis to avoid flapping.
  - `GET /healthz` — alias of readiness.
  - `GET /healthz/metrics` — worker gauges (busy/idle/total), queue depth and head wait, saturation duration, and health-handler latency for alerting.

  The unbounded live `getblockcount()` was removed from the legacy `healthz_light` handler (it now uses the cached backend block count). The listener degrades gracefully on gunicorn/werkzeug (readiness still works; only the waitress-specific saturation axis and gauges are unavailable).

  **Operational follow-up:** Kubernetes manifests must repoint liveness/readiness to the new endpoints and port (deployment repo: UnspendableLabs/Infrastructure#252). Readiness shedding under saturation could in principle remove both pods at once — mitigated by the ledger-lag axis being primary plus a conservative grace/hysteresis, and the saturation axis can be disabled with `--healthz-saturation-grace 0`.

## API Changes

- **Legacy v1 API disabled by default** (#3462). The v1 JSON-RPC endpoint (`/`, `/api/`, `/rpc/`, `/v1/`) exposes an outsized DoS surface — cheap POST requests can trigger expensive database work and large Bitcoin RPC fan-out, and because the operation is encoded in the JSON body, path-based rate limiting can't tell cheap methods from expensive ones. It is now off by default for both new and upgraded deployments (`config.ENABLE_API_V1 = False`). Operators who need compatibility re-enable it with the explicit `--enable-api-v1` flag, which emits a prominent startup warning describing the risk. The standalone v1 server and the v2 proxy routes are both gated; when disabled, v1 requests hit the cheap `404` handler and are dropped from the `/v2/routes` listing. **v2 is unaffected.**
- A slow or unreachable Bitcoin backend now surfaces to API clients as a retryable **HTTP 503** (`BitcoindRPCError`, previously `400`) (#3459).
- A single request that exceeds the new per-request backend RPC fan-out budget is rejected with a clear **HTTP 400** naming the limit and the `inputs_set` escape hatch (#3461).

## Security / Hardening

- **Bound Bitcoin backend RPC retries** (#3459). `getrawtransaction_batch()` bypassed the no-retry guard used for API requests and fell through to an unbounded `while True` retry loop, so a degraded backend made compose and v1 requests retry forever, pinning worker threads until the pool was exhausted (the `(Attempt: N)` log lines from the incident). The retry decision is now centralized in `skip_rpc_retry()` and applied to both the single-call and batch paths, so API requests never enter the unbounded loop; `rpc_call` also bails out defensively in an API context. A configurable connect timeout fails an unreachable backend's TCP connect quickly instead of hanging for the full read timeout, and the parser's flat retry sleep is replaced with jittered exponential backoff so many nodes recovering from the same outage don't reconnect in lockstep. **The parser/indexing path is unchanged** — it still retries an unavailable backend indefinitely, because skipping a VIN would fork the ledger.

- **Bound per-request backend RPC fan-out** (#3461). `/v2/transactions/info`, `/v2/transactions/<tx_hash>/info` (one `getrawtransaction` per input) and `/v2/addresses/<address>/compose/*` (one lookup per UTXO) could each generate unbounded backend fan-out — ~25–30k `getrawtransaction` calls per replica in five minutes during the incident. A per-request budget (`API_MAX_BACKEND_RPC_CALLS`, default `1000`) counts every actual backend call at the HTTP chokepoints and rejects over-budget requests. Cached lookups (via `getrawtransaction`'s `lru_cache`) are free, and legitimate pagination is untouched. The budget is armed **only** for API requests, so parser threads never see it — bounding the parser would corrupt consensus.

## Protocol

- **Correct the Bitcoin transaction fee calculation** (#3458). The Rust parser stopped walking a transaction's outputs at the first ordinary output after the Counterparty data (normally the change output), so any *further* outputs were dropped from the Bitcoin miner fee (`fee`) recorded for the transaction — e.g. `1db7a85e9bbbcd9f60a62411e94f1ae8d3851642d0e3ca73e095d522bf234293` was recorded as paying 19,388,665 sats while its inputs minus *all* outputs is 46,970 sats. Because `fee` participates in the `txlist_hash` consensus, the correction is gated behind a new `correct_transaction_fee` protocol-change height. **The mainnet, testnet3 and testnet4 activation heights are placeholders** — the change is dormant and has no consensus effect until a height is scheduled in a future release; regtest and signet enable it immediately. Only the recorded fee changes: destinations, dispensed amounts and data are untouched.

## Tools

- **New command-line client (`xcp`), beta** (#3127). This release introduces `counterparty-client/`, a standalone Rust CLI (binaries `xcp` and `counterparty-client`) that composes, signs and broadcasts Counterparty transactions against an API server using a local, `cocoon`-encrypted wallet (password held in the OS keyring). It exposes the full v2 API as commands, defaults to the official public HTTPS endpoints for mainnet/signet/testnet4 (regtest → `localhost`), and converts `wallet transaction` amounts to satoshis based on each asset's divisibility (raw `api compose_*` still expects satoshis). Build it from source — `cd counterparty-client && cargo build --release` — see [its README](../counterparty-client/README.md). For automation, CI and headless servers it supports a non-interactive password (`XCP_WALLET_PASSWORD`) and a `-y`/`--yes` flag that skips the broadcast confirmation. A regtest CI job now runs a full **fund → compose → sign → broadcast → accept** end-to-end test that drives the `xcp` binary and signs with the client's own signer against a live `counterparty-server`. It is **beta**: prefer signet/testnet4/regtest before using it with mainnet funds, and **back up your keys** — a new address prints its BIP39 recovery phrase only once (and any key can be exported with `wallet export_address`); the encrypted `wallet.db` is the only other copy.

## Configuration

- `--enable-api-v1` (off by default) — re-enable the legacy v1 JSON-RPC API (#3462).
- `--healthz-port` (default: API port + 2) — port for the dedicated health-check listener (#3460).
- `--no-healthz-server` — disable the dedicated health-check listener (#3460).
- `--healthz-saturation-grace` (default `5` seconds; `0` disables the saturation axis of readiness) (#3460).
- `--backend-connect-timeout` / `BACKEND_CONNECT_TIMEOUT` (default `5` seconds) — TCP connect timeout for backend RPC (#3459).
- `--api-max-backend-rpc-calls` / `API_MAX_BACKEND_RPC_CALLS` (default `1000`, `0` = unlimited) — per-request backend RPC fan-out budget (#3461).

# Credits

- Ouziel Slama
- Dan Anderson
- Adam Krellenstein
