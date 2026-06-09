# Release Notes - Counterparty Core v11.2.0 (2026-??-??)

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

## Protocol Changes

- `forbid_lp_token_destroy`: AMM LP tokens are redeem-only. Destroying an LP token is rejected (liquidity must be withdrawn via `poolwithdraw`, which returns the underlying reserves), and a pool that somehow holds reserves with zero LP supply can no longer be restarted by a new deposit.

## Bugfixes

## API

## Codebase

# Credits

- Adam Krellenstein
