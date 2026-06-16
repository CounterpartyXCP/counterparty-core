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

The Ledger DB is automatically compacted on first start of v11.1.1 (migration `0010.compact_hash_storage`); this migration rewrites hash columns and runs `VACUUM`, so the first startup may take noticeably longer on large databases.

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
- Add **fairmint pool seeding** behind a new `fairmint_pool` gate: `compose_fairminter` accepts two new optional fields — `pool_quantity` (tokens to reserve for the AMM pool) and `lp_asset` (numeric asset to use as LP token, auto-generated if omitted) — which, when the fairminter closes at soft cap, automatically creates a constant-product AMM pool seeded with `pool_quantity` of the minted asset and the corresponding XCP proceeds; `hard_cap` must equal `existing_supply + premint_quantity + pool_quantity + soft_cap` (all mintable supply is reserved for buyers or the pool), `burn_payment` is disallowed, and the issuer must hold sufficient XCP to cover the pool-deposit gas fee at compose time; pool creation is deferred to the `after_block` hook so it is gated on the same block as fairminter close; the LP token is earmarked against the active fairminter to prevent griefing.

## Performance

- Compact hash storage in the Ledger DB: transaction hashes, block hashes and other fixed-size hex strings are now stored as raw 32-byte BLOBs instead of 64-char hex strings, cutting hash-column storage roughly in half. A new migration (`0010.compact_hash_storage`) rewrites all affected tables and runs `VACUUM` afterwards; a new `hashcodec` module handles encoding/decoding transparently so the rest of the codebase is unaffected.
- Composite match-ID normalization (folded into `0010.compact_hash_storage`): the 129-char `tx0hash_tx1hash` TEXT match id is replaced by an integer `(tx0_index, tx1_index)` foreign-key pair on `order_matches`, `bet_matches`, `rps_matches`, the three `*_match_expirations` tables, `bet_match_resolutions`, `btcpays` and `rpsresolves`. The textual `id` / `*_match_id` is reconstructed on read at the API and consensus boundaries, so the public API surface and the consensus hashes are unchanged.
- Asset normalization (folded into `0010.compact_hash_storage`): the `assets` table gains a compact, sequentially-assigned `asset_index INTEGER PRIMARY KEY` surrogate, and every asset-name TEXT column (`asset`, `give_asset`, `get_asset`, `forward_asset`, `backward_asset`, `dividend_asset`, `asset_parent`, `asset_a`, `asset_b` on `balances`, `credits`, `debits`, `sends`, `orders`, `order_matches`, `issuances`, `dividends`, `dispensers`, `dispenses`, `dispenser_refills`, `fairminters`, `fairmints`, `destructions`, `pools`, `pool_deposits`, `pool_withdrawals`, `pool_matches`) is replaced by the compact integer `asset_index` foreign key — 1–3 bytes per reference instead of the full asset name. The protocol `assets.asset_id` and `lp_asset` columns stay TEXT. The asset name is transparently restored on read (the `rowtracer` decodes `asset_index` → name) and re-encoded on write, so consensus hashes and the public API (which still returns/filters by asset name) are unchanged. The State DB keeps asset names (the consolidation decodes index → name while the Ledger DB is attached). Note: invalid records referencing a never-registered asset store `NULL`.

## Bugfixes

- Close fairminter when hard cap is hit after the soft-cap deadline has passed
- Close non-pool fairminter when hard cap is hit before the soft-cap deadline (was leaving the fairminter open after escrow distribution)
- Fix stale-row lookup in `get_fairminters_by_soft_cap_deadline` (was returning superseded rows)
- Fix `connection_count` leak in `APSWConnectionPool` causing `MAINPROCESS_POOL` to exhaust over time (per-request threads in APIv1 left cached connections counted forever)
- Don't charge an oracle fee when closing a dispenser
- Preserve subasset longname case in balance lookups and sort balances by `asset` using the subasset longname
- Resolve subasset longnames when composing fairmints
- Fix MPMA sends: correct per-asset balance accumulation, byte-accurate text-memo length encoding, require a destination per asset, and reject duplicate asset/destination pairs
- Fix holder/supply consolidation that skipped deduplication (`id` used instead of the record key)
- Default a missing bet `target_value` to zero and clarify BTC dividend "below dust" errors

- Expose a unique `credit_index` / `debit_index` field on `credits` / `debits` rows. Identical rows can be written within a single transaction (e.g. an MPMA send or a dividend crediting the same address+asset more than once), making them byte-identical and indistinguishable to API consumers; the new field carries the row's stable unique id so they can be told apart (#3320)

- Expose `lp_asset` field in `compose_fairminter` endpoint; extend `fairminters` table with `pool_quantity` and `lp_asset` columns

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
- Update Rust dependencies: openssl 0.10.79→0.10.81, openssl-sys 0.9.115→0.9.117, pyo3 0.24.2→0.25.1 (migrate `IntoPy`/`into_py` to the `IntoPyObject` API, since the old trait was removed in pyo3 0.25)

# Credits

- Ouziel Slama
- Dan Anderson
- Adam Krellenstein
- caydyan
