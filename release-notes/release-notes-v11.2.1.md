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

- A single request that exceeds the new per-request backend RPC fan-out budget is rejected with a clear **HTTP 400** naming the limit and the `inputs_set` escape hatch (#3461).

## Security / Hardening

- **Bound per-request backend RPC fan-out** (#3461). `/v2/transactions/info`, `/v2/transactions/<tx_hash>/info` (one `getrawtransaction` per input) and `/v2/addresses/<address>/compose/*` (one lookup per UTXO) could each generate unbounded backend fan-out — ~25–30k `getrawtransaction` calls per replica in five minutes during the incident. A per-request budget (`API_MAX_BACKEND_RPC_CALLS`, default `1000`) counts every actual backend call at the HTTP chokepoints and rejects over-budget requests. Cached lookups (via `getrawtransaction`'s `lru_cache`) are free, and legitimate pagination is untouched. The budget is armed **only** for API requests, so parser threads never see it — bounding the parser would corrupt consensus.

## Configuration

- `--api-max-backend-rpc-calls` / `API_MAX_BACKEND_RPC_CALLS` (default `1000`, `0` = unlimited) — per-request backend RPC fan-out budget (#3461).

# Credits

- Ouziel Slama
- Adam Krellenstein
