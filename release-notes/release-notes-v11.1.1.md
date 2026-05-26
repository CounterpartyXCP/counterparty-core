# Release Notes - Counterparty Core v11.1.1 (2026-06-??)


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

- Add **fairmint pool seeding** behind a new `fairmint_pool` gate: `compose_fairminter` accepts two new optional fields — `pool_quantity` (tokens to reserve for the AMM pool) and `lp_asset` (numeric asset to use as LP token, auto-generated if omitted) — which, when the fairminter closes at soft cap, automatically creates a constant-product AMM pool seeded with `pool_quantity` of the minted asset and the corresponding XCP proceeds; `hard_cap` must equal `existing_supply + premint_quantity + pool_quantity + soft_cap` (all mintable supply is reserved for buyers or the pool), `burn_payment` is disallowed, and the issuer must hold sufficient XCP to cover the pool-deposit gas fee at compose time; pool creation is deferred to the `after_block` hook so it is gated on the same block as fairminter close; the LP token is earmarked against the active fairminter to prevent griefing.

## Bugfixes

- Close fairminter when hard cap is hit after the soft-cap deadline has passed
- Fix stale-row lookup in `get_fairminters_by_soft_cap_deadline` (was returning superseded rows)

## API

- Expose `lp_asset` field in `compose_fairminter` endpoint; extend `fairminters` table with `pool_quantity` and `lp_asset` columns

## Codebase

# Credits

- Ouziel Slama
- Dan Anderson
- Adam Krellenstein
