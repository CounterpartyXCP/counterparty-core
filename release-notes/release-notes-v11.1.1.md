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

## API Breaking Changes

- **Unknown query parameters are now rejected** with a `400` error instead of being silently ignored; each route only accepts its own documented parameters.
- **Stricter parameter validation**: booleans, enums, dust sizes, fees, `confirmation_target` (1–1008), `utxo_value`, `more_outputs`/`inputs_set` values, duplicate or out-of-range UTXOs, dispense quantity and memo types are now validated. Previously-tolerated invalid values now return a clean `400` instead of being coerced or causing a `500`.
- **`compose/dispense` response change**: in the returned `params`, `source` is renamed to `address` and `destination` to `dispenser`, and `quantity_normalized` is added.
- The non-functional `sort` parameter was removed from the multi-address balances route (`/v2/addresses/<addresses>/balances`).

## Protocol Changes

The activation block height is not yet set (placeholder `9999999`):

- `sweep_skip_zero_balances`: sweeps no longer include zero-quantity balances, the anti-spam fee is computed only over the balances/ownerships selected by the sweep `flags`, and an empty sweep is no longer charged the legacy flat fee.
- `issuance_callable_lock_fix`: removes the obsolete "cannot change callability / advance call date / reduce call price" reissuance restrictions (the `issuance_callability_parameters_removal` guard is preserved).
- `multisig_utxo_addresses`: bare multisig (P2MS) UTXOs now resolve to an address instead of failing with "vout does not have an address".
- `fix_fairminter_commission_minimum`: rejects a `minted_asset_commission` between 0 and 0.0000001 (which would round to zero).

## Bugfixes

- Fix `connection_count` leak in `APSWConnectionPool` causing `MAINPROCESS_POOL` to exhaust over time (per-request threads in APIv1 left cached connections counted forever)
- Don't charge an oracle fee when closing a dispenser
- Preserve subasset longname case in balance lookups and sort balances by `asset` using the subasset longname
- Resolve subasset longnames when composing fairmints
- Fix MPMA sends: correct per-asset balance accumulation, byte-accurate text-memo length encoding, require a destination per asset, and reject duplicate asset/destination pairs
- Fix holder/supply consolidation that skipped deduplication (`id` used instead of the record key)
- Default a missing bet `target_value` to zero and clarify BTC dividend "below dust" errors

## API

- New routes: `GET /v2/addresses/<address>` (and `/options`), `GET /v2/addresses/<address>/dispensers/source` and `/dispensers/origin`, `GET /v2/bitcoin/transactions/<tx_hash>/info`, and `POST /v2/compose/detach` (detach assets from several UTXOs at once)
- `sort` parameter support added to the sends, issuances, dispenses, broadcasts and dividends routes, with sortable fields documented per route
- Compose responses now include `xcp_fee` (dividend, sweep, pooldeposit, poolwithdraw, attach); order and order-match results include `market_price_normalized`
- New compose aliases `message_only` (for `return_only_data`) and `custom_inputs` (deprecated, for `inputs_set`); segwit outputs now use a dedicated `segwit_dust_size`
- Enum parameters accept comma-separated values, and dispenser `status` accepts numeric values
- `/v2/transactions/info` recovers source/destination/amount for BTC-only transactions even without prevouts
- Add `Cache-Control` headers and a `--disable-api-cache` flag, add API error context to Sentry reports, format IPv6 Gunicorn bind addresses, and report invalid transaction status and empty sweeps clearly
- Documentation: API response codes, Counterparty transaction data format, the `messages` table, and sortable route fields

## Codebase

- Fix intermittent BIP143 signature mismatches in regtest by broadcasting tx1 before signing tx2, so the wallet sees tx1's UTXOs in its mempool view
- Add a `bootstrap-once` catch-up mode (downloads the bootstrap only when no database exists)
- Re-enable the profiler on Python 3.12, skip the count query for single-row selects, and normalize null transaction `btc_amount` to `0`
- Update Python dependencies: Flask 3.0.0→3.1.3, pytest 7.4.4→9.0.3, requests 2.32.4→2.33.0, Werkzeug 3.1.4→3.1.6, itsdangerous 2.1.2→2.2.0
- Update Rust dependencies: openssl 0.10.79→0.10.80, openssl-sys 0.9.115→0.9.116

# Credits

- Ouziel Slama
- Dan Anderson
- Adam Krellenstein
- caydyan
