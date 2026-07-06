# Release Notes - Counterparty Core v11.2.0 (2026-07-07)


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

The Ledger DB is automatically compacted on first start of v11.2.0 (migration `0010.compact_hash_storage`); this migration rewrites hash columns and runs `VACUUM`, so the first startup may take noticeably longer on large databases.

# ChangeLog

## API Breaking Changes

- **Unknown query parameters are now rejected** with a `400` error instead of being silently ignored; each route only accepts its own documented parameters.
- **Stricter parameter validation**: booleans, enums, dust sizes, fees, `confirmation_target` (1–1008), `utxo_value`, `more_outputs`/`inputs_set` values, duplicate or out-of-range UTXOs, dispense quantity and memo types are now validated. Previously-tolerated invalid values now return a clean `400` instead of being coerced or causing a `500`.
- **`compose/dispense` response change**: in the returned `params`, `source` is renamed to `address` and `destination` to `dispenser`, and `quantity_normalized` is added.
- The non-functional `sort` parameter was removed from the multi-address balances route (`/v2/addresses/<addresses>/balances`).

## Protocol Changes

The activation block heights are `960000` (mainnet), `5057500` (testnet3), `146200` (testnet4) and `315100` (signet) — targeting roughly 2026-07-27; the one exception is `fairmint_pool`, which is also active on signet from genesis (`signet_block_index: 0`) for testing:

- `sweep_skip_zero_balances`: sweeps no longer include zero-quantity balances, the anti-spam fee is computed only over the balances/ownerships selected by the sweep `flags`, and an empty sweep is no longer charged the legacy flat fee.
- `issuance_callable_lock_fix`: removes the obsolete "cannot change callability / advance call date / reduce call price" reissuance restrictions (the `issuance_callability_parameters_removal` guard is preserved).
- `multisig_utxo_addresses`: bare multisig (P2MS) UTXOs now resolve to an address instead of failing with "vout does not have an address".
- `fix_fairminter_commission_minimum`: rejects a `minted_asset_commission` between 0 and 0.0000001 (which would round to zero).
- Add **fairmint pool seeding** behind a new `fairmint_pool` gate: `compose_fairminter` accepts two new optional fields — `pool_quantity` (tokens to reserve for the AMM pool) and `lp_asset` (numeric asset to use as LP token, auto-generated if omitted) — which, when the fairminter closes at soft cap, automatically creates a constant-product AMM pool seeded with `pool_quantity` of the minted asset and the corresponding XCP proceeds; `hard_cap` must equal `existing_supply + premint_quantity + pool_quantity + soft_cap` (all mintable supply is reserved for buyers or the pool), `burn_payment` is disallowed, and the issuer must hold sufficient XCP to cover the pool-deposit gas fee at compose time; pool creation is deferred to the `after_block` hook so it is gated on the same block as fairminter close; the LP token is earmarked against the active fairminter to prevent griefing.
- `fix_pool_deposit_product_overflow`: removes a redundant `quantity_a * quantity_b > MAX_INT` overflow check in `pooldeposit.validate()` that rejected otherwise-valid large AMM deposits — it capped each side of a balanced divisible pair at `floor(sqrt(MAX_INT))` raw units (~30.37 divisible units) even when both quantities, the minted LP amount, balances, and stored reserves were each individually valid (#3324).
- `fix_pool_best_price_routing`: fixes AMM best-price routing under integer pool math. `compute_pool_input_for_target_price()` solved a continuous-price quadratic while execution floors the pool output to an integer (`compute_pool_output`), so a pool fill that was actually cheaper than the next book order could floor to zero output and send the taker to the worse book order (and misroute in the other direction); routing is now consistent with the integer execution (#3325).
- `enforce_utxo_vout_max`: a `tx_hash:vout` UTXO reference whose `vout` exceeds `0xFFFFFFFF` (4294967295) is no longer recognized as a valid UTXO format. UTXO-format detection routes a transaction's attach/detach and debit/credit classification, so this is a consensus change; before activation the legacy behavior is kept (any non-negative integer vout that round-trips through `str(int(...))` is accepted).

## Performance

- Compact hash storage in the Ledger DB: transaction hashes, block hashes and other fixed-size hex strings are now stored as raw 32-byte BLOBs instead of 64-char hex strings, cutting hash-column storage roughly in half. A new migration (`0010.compact_hash_storage`) rewrites all affected tables and runs `VACUUM` afterwards; a new `hashcodec` module handles encoding/decoding transparently so the rest of the codebase is unaffected.
- Composite match-ID normalization (folded into `0010.compact_hash_storage`): the 129-char `tx0hash_tx1hash` TEXT match id is replaced by an integer `(tx0_index, tx1_index)` foreign-key pair on `order_matches`, `bet_matches`, `rps_matches`, the three `*_match_expirations` tables, `bet_match_resolutions`, `btcpays` and `rpsresolves`. The textual `id` / `*_match_id` is reconstructed on read at the API and consensus boundaries, so the public API surface and the consensus hashes are unchanged.
- Asset normalization (folded into `0010.compact_hash_storage`): the `assets` table gains a compact, sequentially-assigned `asset_index INTEGER PRIMARY KEY` surrogate, and every asset-name TEXT column (`asset`, `give_asset`, `get_asset`, `forward_asset`, `backward_asset`, `dividend_asset`, `asset_parent`, `asset_a`, `asset_b` on `balances`, `credits`, `debits`, `sends`, `orders`, `order_matches`, `issuances`, `dividends`, `dispensers`, `dispenses`, `dispenser_refills`, `fairminters`, `fairmints`, `destructions`, `pools`, `pool_deposits`, `pool_withdrawals`, `pool_matches`) is replaced by the compact integer `asset_index` foreign key — 1–3 bytes per reference instead of the full asset name. The protocol `assets.asset_id` and `lp_asset` columns stay TEXT. The asset name is transparently restored on read (the `rowtracer` decodes `asset_index` → name) and re-encoded on write, so consensus hashes and the public API (which still returns/filters by asset name) are unchanged. The State DB keeps asset names (the consolidation decodes index → name while the Ledger DB is attached). Note: invalid records referencing a never-registered asset store `NULL`.
- Address normalization (folded into `0010.compact_hash_storage`): a new `address_list(address_id INTEGER PRIMARY KEY, address TEXT UNIQUE)` table assigns every distinct address a compact id, and every address TEXT column (`source`, `destination`, `address`, `source_address`, `destination_address`, `issuer`, `feed_address`, `tx0_address`, `tx1_address`, `winner`, `oracle_address`, `origin`, `last_status_tx_source`, `utxo_address` across the ledger tables) is replaced by the compact integer `address_id` foreign key. The address string is transparently restored on read (the `rowtracer` decodes `address_id` → address) and re-encoded on write, so consensus hashes and the public API (which still returns/filters by address) are unchanged. The State DB keeps addresses as strings (the consolidation decodes id → address while the Ledger DB is attached). The existing `addresses` options-history table is preserved; its `address` column is FK'd onto `address_list`. `mempool.addresses` (a comma-separated list) and `mempool_transactions` are left as TEXT.
- UTXO column compaction (folded into `0010.compact_hash_storage`): the `utxo TEXT` column (`tx_hash:vout`, ~67 chars) on `balances`, `credits` and `debits` is replaced by a compact `(utxo_tx_hash BLOB(32), utxo_vout INTEGER)` pair (~36 bytes). The `tx_hash` is stored as a raw BLOB rather than a `tx_index` foreign key because an attached UTXO may reference any valid bitcoin transaction (not only Counterparty transactions). The `utxo` string is transparently reconstructed on read by the `rowtracer`, so consensus hashes and the public API are unchanged.

## Bugfixes

- Close fairminter when hard cap is hit after the soft-cap deadline has passed
- Close non-pool fairminter when hard cap is hit before the soft-cap deadline (was leaving the fairminter open after escrow distribution)
- Fix stale-row lookup in `get_fairminters_by_soft_cap_deadline` (was returning superseded rows)
- Fix `connection_count` leak in `APSWConnectionPool` causing `MAINPROCESS_POOL` to exhaust over time (per-request threads in APIv1 left cached connections counted forever)
- Fix `NotSupportedTransactionsCache` unbounded growth: the in-memory cache of not-supported transactions grew without limit (reaching hundreds of MB) and was rewritten to disk and reloaded across restarts; it is now size-bounded and no longer persisted on every update (#3397)
- Don't charge an oracle fee when closing a dispenser
- Preserve subasset longname case in balance lookups and sort balances by `asset` using the subasset longname
- Resolve subasset longnames when composing fairmints
- Fix MPMA sends: correct per-asset balance accumulation, byte-accurate text-memo length encoding, require a destination per asset, and reject duplicate asset/destination pairs
- Fix holder/supply consolidation that skipped deduplication (`id` used instead of the record key)
- Default a missing bet `target_value` to zero and clarify BTC dividend "below dust" errors
- Consensus safety — halt instead of silently dropping a confirmed transaction when VIN/prevout resolution fails: a transient Bitcoin RPC failure while fetching a prevout now surfaces as `BitcoindRPCError` (retried, and ultimately halting catch-up) instead of being swallowed into a dropped transaction, which could permanently fork the ledger (observed at block 510556); the batch RPC path now also retries `502`/`504` and matches responses by `id`
- Consensus safety — don't write a non-deterministic `utxo_address` on a transient RPC failure: `safe_get_utxo_address` returns `"unknown"` only for the deterministic address-less case (a resolvable output with no decodable address, which is canonical consensus history), while a transient RPC fetch failure now raises `BitcoindRPCError` and propagates. Previously a transient failure was indistinguishable from a genuinely address-less output and could poison `utxo_address`, forking consensus (observed on signet at block 267825)
- Consensus safety — gate the `get_vin_info_legacy` (RPC-fallback) `is_segwit` computation on `fix_is_segwit`: the fallback path derived `is_segwit` from the prevout's own script ungated, applying the block-902000 `fix_is_segwit` behavior early and mis-encoding a bech32 source as base58 on that path (fork at block 832867); it now follows the parent-transaction-segwit rule gated at the same height as the main path
- Stop reporting shutdown interrupts as errors: when the server is stopping, `RawMempoolParser.stop()` calls `db.interrupt()` on the connection shared with the blockchain watcher, aborting any in-flight parse as `ParseTransactionError("interrupted")`; the watcher now treats this as expected teardown noise (logged at debug) instead of logging an error, paging Sentry, and forcing a "fail loud" restart

- Expose a unique `credit_index` / `debit_index` field on `credits` / `debits` rows. Identical rows can be written within a single transaction (e.g. an MPMA send or a dividend crediting the same address+asset more than once), making them byte-identical and indistinguishable to API consumers; the new field carries the row's stable unique id so they can be told apart (#3320)

- Expose `lp_asset` field in `compose_fairminter` endpoint; extend `fairminters` table with `pool_quantity` and `lp_asset` columns

- New routes: `GET /v2/addresses/<address>` (and `/options`), `GET /v2/addresses/<address>/dispensers/source` and `/dispensers/origin`, `GET /v2/bitcoin/transactions/<tx_hash>/info`, and `POST /v2/compose/detach` (detach assets from several UTXOs at once)
- `sort` parameter support added to the sends, issuances, dispenses, broadcasts and dividends routes, with sortable fields documented per route
- Compose responses now include `xcp_fee` (dividend, sweep, pooldeposit, poolwithdraw, attach); order and order-match results include `market_price_normalized`
- New compose aliases `message_only` (for `return_only_data`) and `custom_inputs` (deprecated, for `inputs_set`); segwit outputs now use a dedicated `segwit_dust_size`
- Enum parameters accept comma-separated values, and dispenser `status` accepts numeric values
- `/v2/transactions/info` recovers source/destination/amount for BTC-only transactions even without prevouts
- Add `Cache-Control` headers and a `--disable-api-cache` flag, add API error context to Sentry reports, format IPv6 Gunicorn bind addresses, and report invalid transaction status and empty sweeps clearly
- Add `--api-cache-size N` (config `API_CACHE_SIZE`, default `1000` — unchanged behavior) to bound the API response cache (`BLOCK_CACHE`) by entry count instead of the old hardcoded 1000-entry cap; lowering it caps the API process's resident memory (trading a small tail-latency increase for a bounded working set), `0` effectively disables caching (#3443)
- Documentation: API response codes, Counterparty transaction data format, the `messages` table, and sortable route fields

## Codebase

- Fix intermittent BIP143 signature mismatches in regtest by broadcasting tx1 before signing tx2, so the wallet sees tx1's UTXOs in its mempool view
- Add a `bootstrap-once` catch-up mode (downloads the bootstrap only when no database exists)
- Re-enable the profiler on Python 3.12, skip the count query for single-row selects, and normalize null transaction `btc_amount` to `0`
- Serve the `result_count` of `/v2/events` and `/v2/events/<event>` from the pre-aggregated `events_count` table instead of a full `messages` table scan (turning a ~222ms count on every cache-miss request into a sub-millisecond aggregate); the public query parameters are unchanged
- Cache the enriched, ready-to-serve API response in `BLOCK_CACHE` instead of the raw `QueryResult`, so a cache *hit* now skips the per-row verbose enrichment (`inject_details`) and its DB lookups that previously re-ran on **every** request — collapsing the repeated-request cost that dominated the heavy-endpoint latency tail (production p95/p99). API output and status codes are byte-identical (enrichment still runs once per cache miss, outside the function-call `try`, so error semantics are unchanged); cache entries are now larger (enriched payloads), so `--api-cache-size`/`API_CACHE_SIZE` should be sized accordingly (#3444)
- Add `--api-cache-max-rows N` (config `API_CACHE_MAX_ROWS`, default `50000`; `0` disables the row bound) to bound the API response cache (`BLOCK_CACHE`) by **total rows** in addition to the entry count (`--api-cache-size`). An entry-count cap alone forces a memory↔hit-rate tradeoff (a small cap lowers the hit rate, roughly doubling p95/p99 on real traffic); since most cached responses are tiny, a row budget caps memory (driven by the few large result sets) while letting thousands of small entries stay cached — bounded memory without sacrificing hit rate. Row sizing is an O(1) proxy (result-list length, not byte sizing, to keep the cache-miss path cheap) and the entry-count cap remains a backstop; the running total is updated lock-free across the API worker threads, so the budget is approximate but self-healing (over-counts evict slightly early, under-counts are bounded by the entry cap). The worst single cached entry is `API_LIMIT_ROWS` rows. (#3445)
- Migrate the API documentation from Apiary (being retired by Oracle) to OpenAPI 3.1 rendered with Scalar on GitHub Pages: `genapidoc.py` now emits `openapi.json` from the same regtest-driven workflow, and contract testing moves from `dredd` to `schemathesis` (#3401)
- Add a `--memory-profile-tracemalloc` flag and track `backend.bitcoind` caches in the memory profiler (#3397)
- Update Python dependencies: Flask 3.0.0→3.1.3, pytest 7.4.4→9.0.3, requests 2.32.4→2.33.0, Werkzeug 3.1.4→3.1.6, itsdangerous 2.1.2→2.2.0
- Update Rust dependencies: openssl 0.10.79→0.10.81, openssl-sys 0.9.115→0.9.117, pyo3 0.24.2→0.25.1 (migrate `IntoPy`/`into_py` to the `IntoPyObject` API, since the old trait was removed in pyo3 0.25)

# Credits

- Ouziel Slama
- Dan Anderson
- Adam Krellenstein
- caydyan
