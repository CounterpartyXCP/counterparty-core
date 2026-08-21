# Release Notes - Counterparty Core v11.3.0 (2026-08-16)

Counterparty Core v11.3.0 is an operational hardening release addressing the root causes of the 2026-07-15 production incident, in which a small number of expensive public API requests against a degraded Bitcoin backend exhausted the API worker pools and took `/v2/healthz` down with them. It also includes a **protocol change** — a correction to the Bitcoin miner-fee calculation (#3458) — scheduled to activate at mainnet block **966,200** (approximately September 9, 2026). This is a mandatory upgrade before that block. There is no database migration, and the upgrade is a plain restart.

The most visible behavioral change is that the **legacy v1 JSON-RPC API is now disabled by default** — operators who still rely on it must opt back in with `--enable-api-v1`.

A dedicated health-check listener now runs on its own port (default: API port + 2 → `4002` on mainnet). Kubernetes/orchestrator probes should be repointed to `/healthz/live` and `/healthz/ready` on that port.

# Upgrading

**This release includes a protocol change** — the fee-calculation correction (#3458) — activating at block **966,200** on mainnet (approximately September 9, 2026), block 5,166,000 on testnet3 and block 153,700 on testnet4 (it is already active on signet and regtest). **All nodes must upgrade before the activation block.** The change applies from the activation block forward, so there is no reparse and no migration.

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
- **`max_mint_per_address` and `pool_quantity` are now normalized** (#3474). Under `verbose=true`, these were the only two asset-denominated quantities on a fairminter that never got a `_normalized` companion — every neighbour on the same row (`hard_cap`, `soft_cap`, `max_mint_per_tx`, `premint_quantity`, …) already had one. They are now normalized against the fairminter's own `asset_info`, wherever the fields appear (`/v2/fairminters`, and the `params` / `unpacked_data` of compose and transaction responses). The change is purely additive — no field is renamed, removed or changed in value — so clients reading base units are unaffected. Note that `max_mint_per_address_normalized` is *absent* (rather than null) on fairminters that set no per-address limit, since the underlying column is nullable.

## Security / Hardening

- **Fix an RPC-dependent `source` for inscription reveal transactions** (GHSA-pmfx-7qj5-fx6c). The source of a reveal transaction is one hop further back than an ordinary input: the output that funded the *commit* transaction, not the commit output the reveal spends. The Rust deserializer performs that rewrite and hands the result back as `vin["info"]` — but it fetched the two prevouts with `unwrap_or_default()`, so an RPC failure degraded silently in two different ways. If the first batch call failed, `info` came back empty and the Python fallback resolved the input *normally*, yielding the commit output's address. If only the second call failed, `info` came back **populated with the wrong output**, which nothing downstream could detect. Either way that node computed a different `source` **and a different `fee`** than every node whose RPC succeeded — a silent, permanent ledger fork, on a live code path (reveal transactions have been parsed since `taproot_support` at block 902,000).

  The commit-parent lookup is now all-or-nothing: on any failure the deserializer records no commit parent and leaves the input unresolved, never a partial result. The Python fallback (`get_reveal_prevouts()`) then reproduces the same two-hop resolution — including the deserializer's treatment of any *other* input that happens to spend the same funding transaction — so both paths agree; and if the backend really is unavailable it raises `BitcoindRPCError` and halts, as the parser already does for any unresolvable prevout, instead of guessing. The block is rolled back atomically and retried, so a transient blip cannot corrupt the ledger.

  No activation gate: the canonical ledger is the one produced when the RPC succeeds, and that path is unchanged. The fix only stops a node whose backend hiccuped from silently diverging from it.

- **Fix seven remotely triggerable chain-halt vulnerabilities** (GHSA-pmfx-7qj5-fx6c, reported privately). Each of these let an unprivileged attacker halt **every** node on the network at the same block, for the price of one or two ordinary transactions, by making block ingestion raise an exception type nothing catches. Two architectural facts made the class fatal: `parse_tx()` wraps any handler exception into `ParseTransactionError` and `parse_block()` deliberately re-raises it, while at the parse level `get_tx_info()` caught only `DecodeError`/`BTCOnlyError` and `list_tx()` had no handler at all. A halted node restarts onto the same poisoned block and halts again.

  - **`None` element in `potential_dispensers`** — the Rust deserializer's short-data early return in `parse_vout()` emitted a `None` dispenser slot, which PyO3 hands to Python as a genuine `None` list element; `get_dispensers_tx_info()` (reached by the live dispense-prefix route since `enable_dispense_tx`) and `get_dispensers_outputs()` subscripted it. Cost: one dust output. The Rust side now always returns a structurally complete slot, and both Python consumers skip `None` elements.
  - **Zero-price oracle dispenser** — a broadcast with `value = 0` is valid, and `dispenser.validate()` rejected only `last_price is None`, so opening an oracle dispenser on such a feed reached `mainchainrate / 0`. `validate()` now reports a problem for a zero price, matching the `last_price == 0` guard `is_dispensable()` already had (dead code since `disable_vanilla_btc_dispense`).
  - **NULL `fee_fraction_int`** — `calculate_oracle_fee()` computed `last_fee / config.UNIT` on a NULL fee fraction (stored by a "lock" broadcast, by a NaN CBOR float, or by the out-of-range clamp). It now reads a missing fee fraction as zero, like `bet.get_fee_fraction()` already did.
  - **NULL broadcast `text`** — `get_oracle_last_price()` called `.split()` on the NULL `text` of a locked feed, so a single "lock" broadcast on an oracle address halted every node that later touched that oracle.
  - **NaN `minted_asset_commission`** — `D(float("nan"))` is `Decimal("NaN")`, and any ordering comparison against it raises `decimal.InvalidOperation` (an `ArithmeticError`, so no existing net applied) inside `fairminter.validate()`, before any DB access. **One** ordinary transaction was enough. NaN is now reported as a validation problem; `±inf`, which never crashed, keeps its historical status string.
  - **NULL broadcast timestamp** — `bet.validate()` compared `broadcasts[-1]["timestamp"] >= deadline` against a NULL left by a NaN-timestamp broadcast. `bet.parse()` wraps only the `price()` call, so unlike `broadcast.parse()` it had no `broadcast_safe_validate`-style net.
  - **Int-typed asm elements** — the Rust `script_to_asm()` renders a *pushed* `0xae` byte identically to the `OP_CHECKMULTISIG` opcode, so `script.script_to_asm()` rewrote `asm[0]`/`asm[-2]` into Python ints for a push-only, relay-standard scriptSig such as `OP_0 OP_0 <push 0xae>`; `get_der_signature_sighash_flag()` then evaluated `value[:-1]` on an int. This ran for every data-carrying transaction with no protocol gate, and the relay-standard variant also killed the mempool watcher before confirmation. The flag reader now type-checks its argument.
  - **`MultiSigAddressError` escaping `get_tx_info()`** — a bare-multisig prevout with `m` outside 1..3 made source resolution raise an `AddressError`, which is not a `DecodeError`, straight through `list_tx()`.

  `get_tx_info()` now also carries a general safety net: exception types that mean "these bytes are not a well-formed Counterparty transaction" (`TypeError`, `ValueError`, `ArithmeticError`, `LookupError`, `AttributeError`, `struct.error`, `AddressError`) are logged and treated as non-Counterparty instead of escaping. This is deliberately an allow-list of *data* errors, not a bare `except Exception`: `BitcoindRPCError` and database errors still propagate, because silently dropping a confirmed transaction whose prevout could not be fetched would fork the ledger permanently (block 510556).

  **None of these guards need an activation gate.** A transaction that reaches any of them raises on current code, so every node halts on it, so no historical block can contain one that was ever parsed successfully. Only the root-cause fix below changes the status of a parse that succeeds today.

  The `fuzz_cbor_test.py` harness excluded NaN and infinity from its float strategy — which is precisely why this family went unnoticed — and now includes them. A dedicated regression suite lives in `counterpartycore/test/units/parser/chain_halt_test.py`.


- **Bound Bitcoin backend RPC retries** (#3459). `getrawtransaction_batch()` bypassed the no-retry guard used for API requests and fell through to an unbounded `while True` retry loop, so a degraded backend made compose and v1 requests retry forever, pinning worker threads until the pool was exhausted (the `(Attempt: N)` log lines from the incident). The retry decision is now centralized in `skip_rpc_retry()` and applied to both the single-call and batch paths, so API requests never enter the unbounded loop; `rpc_call` also bails out defensively in an API context. A configurable connect timeout fails an unreachable backend's TCP connect quickly instead of hanging for the full read timeout, and the parser's flat retry sleep is replaced with jittered exponential backoff so many nodes recovering from the same outage don't reconnect in lockstep. **The parser/indexing path is unchanged** — it still retries an unavailable backend indefinitely, because skipping a VIN would fork the ledger.

- **Bound per-request backend RPC fan-out** (#3461). `/v2/transactions/info`, `/v2/transactions/<tx_hash>/info` (one `getrawtransaction` per input) and `/v2/addresses/<address>/compose/*` (one lookup per UTXO) could each generate unbounded backend fan-out — ~25–30k `getrawtransaction` calls per replica in five minutes during the incident. A per-request budget (`API_MAX_BACKEND_RPC_CALLS`, default `1000`) counts every actual backend call at the HTTP chokepoints and rejects over-budget requests. Cached lookups (via `getrawtransaction`'s `lru_cache`) are free, and legitimate pagination is untouched. The budget is armed **only** for API requests, so parser threads never see it — bounding the parser would corrupt consensus.

## Protocol

- **Reject non-finite numbers in broadcasts** (`reject_non_finite_broadcast`, GHSA-pmfx-7qj5-fx6c). Since `taproot_support`, broadcasts are CBOR-decoded, which admits float64 — including **NaN**. `broadcast.validate()` deliberately performs no numeric type check, every comparison against NaN is `False`, so a NaN field validated as `"valid"`; sqlite3 then bound it as **NULL**, and the poisoned row halted every consumer that read it back (the oracle-dispenser and bet failures above). A broadcast carrying a non-finite `timestamp`, `value` or `fee_fraction_int` is now marked invalid, so no new poisoned row can be stored. This flips the status of parses that currently succeed, hence the gate: mainnet block **966,200**, testnet3 5,166,000, testnet4 153,700, signet 321,300. The downstream guards listed under Security are ungated and remain the load-bearing fix for rows predating the activation.

- **`ordinals_metadata_support` heights corrected to match the code.** The gate is enforced by the Rust deserializer only (`Heights::new` in `counterparty-rs/src/indexer/config.rs`); nothing in Python reads it. The v11.1.0 release pass bumped the `protocol_changes.json` heights along with every other pending change, but `config.rs` was never updated — so the JSON has been advertising an activation (mainnet 952,800) that never happened, while signet and regtest have had the feature on since block 0. The JSON now states what the code actually enforces. **Scheduling a real activation means changing both files**; signet and regtest must stay at 0 because their bootstrap snapshots depend on it.

- **Correct the Bitcoin transaction fee calculation** (#3458). The Rust parser stopped walking a transaction's outputs at the first ordinary output after the Counterparty data (normally the change output), so any *further* outputs were dropped from the Bitcoin miner fee (`fee`) recorded for the transaction — e.g. `1db7a85e9bbbcd9f60a62411e94f1ae8d3851642d0e3ca73e095d522bf234293` was recorded as paying 19,388,665 sats while its inputs minus *all* outputs is 46,970 sats. Because `fee` participates in the `txlist_hash` consensus, the correction is gated behind the `correct_transaction_fee` protocol-change height: mainnet block **966,200** (~September 9, 2026), testnet3 block 5,166,000, testnet4 block 153,700; regtest and signet enable it immediately. Only the recorded fee changes: destinations, dispensed amounts and data are untouched.

## Tools

- **New command-line client (`xcp`), beta** (#3127). This release introduces `counterparty-client/`, a standalone Rust CLI (binaries `xcp` and `counterparty-client`) that composes, signs and broadcasts Counterparty transactions against an API server using a local, `cocoon`-encrypted wallet (password held in the OS keyring). It exposes the full v2 API as commands, defaults to the official public HTTPS endpoints for mainnet/signet/testnet4 (regtest → `localhost`), and converts `wallet transaction` amounts to satoshis based on each asset's divisibility (raw `api compose_*` still expects satoshis). Build it from source — `cd counterparty-client && cargo build --release` — see [its README](../counterparty-client/README.md). For automation, CI and headless servers it supports a non-interactive password (`XCP_WALLET_PASSWORD`) and a `-y`/`--yes` flag that skips the broadcast confirmation — but only for a transaction the client could fully verify against your request: it never auto-confirms one it could not independently check (an unverifiable transaction type, an asset it could not resolve offline, or a fee it could not bound), so a compromised server cannot slip such a transaction past unattended automation. A regtest CI job now runs a full **fund → compose → sign → broadcast → accept** end-to-end test that drives the `xcp` binary and signs with the client's own signer against a live `counterparty-server`. It is **beta**: prefer signet/testnet4/regtest before using it with mainnet funds, and **back up your keys** — a new address prints its BIP39 recovery phrase only once (and any key can be exported with `wallet export_address`); the encrypted `wallet.db` is the only other copy.

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
