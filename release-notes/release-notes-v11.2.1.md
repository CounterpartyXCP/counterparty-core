# Release Notes - Counterparty Core v11.2.1 (2026-07-??)

Counterparty Core v11.2.1 is an operational hardening release addressing the root causes of the 2026-07-15 production incident, in which a small number of expensive public API requests against a degraded Bitcoin backend exhausted the API worker pools. There are **no protocol changes** and no database migration; the upgrade is a plain restart.

The most visible behavioral change is that the **legacy v1 JSON-RPC API is now disabled by default** — operators who still rely on it must opt back in with `--enable-api-v1`.

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

If you serve clients through the v1 `/api/` JSON-RPC endpoint, add `--enable-api-v1` (available on `server.conf` too) before upgrading, or those requests will now return `404`.

# ChangeLog

## API Changes

- **Legacy v1 API disabled by default** (#3462). The v1 JSON-RPC endpoint (`/`, `/api/`, `/rpc/`, `/v1/`) exposes an outsized DoS surface — cheap POST requests can trigger expensive database work and large Bitcoin RPC fan-out, and because the operation is encoded in the JSON body, path-based rate limiting can't tell cheap methods from expensive ones. It is now off by default for both new and upgraded deployments (`config.ENABLE_API_V1 = False`). Operators who need compatibility re-enable it with the explicit `--enable-api-v1` flag, which emits a prominent startup warning describing the risk. The standalone v1 server and the v2 proxy routes are both gated; when disabled, v1 requests hit the cheap `404` handler and are dropped from the `/v2/routes` listing. **v2 is unaffected.**

## Configuration

- `--enable-api-v1` (off by default) — re-enable the legacy v1 JSON-RPC API (#3462).

# Credits

- Ouziel Slama
- Adam Krellenstein
