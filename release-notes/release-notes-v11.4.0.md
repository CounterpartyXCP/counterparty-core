# Release Notes - Counterparty Core v11.4.0 (TBD)

Counterparty Core v11.4.0 makes State DB rollbacks incremental (#3485), bounds API shutdown and cold startup (#3486), fixes two blind spots in the API watcher's reorganization detection, and puts the address history endpoints back on their indexes.

Until now a Bitcoin reorganization — however shallow — rebuilt the entire State DB. On mainnet a **one-block reorg took ~33 minutes**, during the last ~6 of which the public API returned 5xx, despite the process having ample CPU and memory headroom. The cost had nothing to do with how deep the reorganization was: `rollback_state_db()` deleted the rows of three tables and then re-applied thirteen migrations, each of which dropped its table and repopulated it from the entire ledger history (`parsed_events` alone is a full copy of `messages`).

Rollbacks now revert what the orphaned blocks actually changed instead of re-deriving everything. A one-block reorg touches a handful of rows instead of tens of millions.

Two passes are still re-derived rather than undone, because the data needed to decrement them disappears from the Ledger DB along with the orphaned blocks: `transaction_types_count` (one grouped scan of `transactions`, whenever a rolled back block held a transaction) and `assets_info` (whenever it held an issuance, a burn, a destruction, a sweep or a dividend — which includes every fairmint). They dominate what a reorg now costs, and they are a fraction of the thirteen migrations they replace, but the result is not zero: expect minutes rather than the previous half hour.

The rebuild that remains — at upgrade, and for the deep rollbacks a new release occasionally requires — is no longer silent. It now reports itself: the dedicated health listener starts **before** it, answers `200` on liveness and `503 rebuilding` on readiness throughout, and names the step under way.

# Upgrading

This release performs a **one-time State DB refresh** on first start (`refresh_state_db`), automatically. It takes roughly as long as one of the old reorg rebuilds. There is no ledger reparse and no protocol change.

The refresh is an optimization, not a correctness requirement: it pays the cost of the last full rebuild at a moment you control rather than unpredictably at your next reorg. A State DB that has not been through it is flagged as ineligible for the incremental path and simply takes the old full-rebuild route once, which then flags it as eligible. Nodes therefore converge on the fast path either way — a node upgraded with `--force` (which skips the version check, and so the refresh) is correct, just slower on its first reorg.

**Point your Kubernetes probes at the dedicated health listener before upgrading** (port `4002` on mainnet — `/healthz/live` for liveness, `/healthz/ready` for readiness), if you have not already since v11.3.0. During the refresh the pod reports `200` on liveness and `503 rebuilding` on readiness, so it stays out of rotation and is not restarted. A liveness probe still pointed at the API port would get a connection refusal for the whole refresh and kill the pod, and the next start would begin the work again from zero.

API consumers of the address history endpoints should check the **Address history endpoints** section below before upgrading: `/v2/addresses/<address>/sends` and `/sends/<asset>` no longer expose `sort`, `offset` is capped at 10,000 on those routes and on `/credits` and `/debits`, and `result_count` is now `null` on cursor pages rather than recomputed for each one. `openapi.json` has been updated to match.

Clients that compose issuances or fairminters should also expect a new `409` response when the parsed mempool already contains a conflicting asset operation — see **Conflicting pending asset compositions** below.

To upgrade, download the latest version of `counterparty-core` and restart `counterparty-server`.

# Changelog

## Incremental State DB rollback (#3485)

`dbbuilder.rollback_state_db()` now reverts the State DB instead of re-deriving it (`counterpartycore/lib/api/staterollback.py`):

- **Append-only tables** (`parsed_events`, `address_events`, `all_expirations`, `pool_matches`) are pruned by `block_index`.
- **Consolidated tables** (`balances`, `orders`, `dispensers`, `fairminters`, the match tables, the AMM pool tables — one row per object holding its latest version) have the rows touched at or after the rollback point deleted and re-inserted from that object's latest Ledger DB version *strictly below* the rollback point. The block bound matters: when the API watcher reacts to a reorganization the Ledger DB has already rolled back and may have re-parsed part of the new chain, and restoring to the ledger's current tip would leave the State DB ahead of `parsed_events` and cause the forward replay to apply those blocks twice.
- **Counters** are adjusted rather than recomputed from scratch: `events_count` is decremented by the orphaned events, and `transaction_types_count` / `assets_info` / the `fairminters` aggregates are re-derived only when the orphaned blocks actually contained the relevant events.
- Views and indexes are no longer dropped and rebuilt, because the tables they cover are no longer dropped and rebuilt.

A single `logger.info` line now reports what a reorganization cost — how many events and objects were reverted, per table. Previously the 33 minutes were entirely silent at INFO level.

**Fallbacks.** The full rebuild is still used, and is still correct, for a rollback deeper than 1,000 blocks, for the `UPGRADE_ACTIONS` rollbacks (where the derivation rules themselves may have changed between releases, so they call it directly and never consult the fast path), for a State DB that predates this release, and if the incremental path raises for any reason at all — it is an optimization layered over a path that already worked, and a failure degrades to that path instead of stopping the watcher. A rollback target the State DB has not caught up to yet is now a logged no-op rather than a full rebuild that undoes nothing.

**One visible consequence.** State DB listings (`/v2/orders`, `/v2/dispensers`, `/v2/balances`, …) are ordered and paginated by `rowid` by default. The full rebuild rewrote every table, so it re-canonicalized that order on each reorg; the incremental path re-inserts only the reverted objects, which therefore move to the front of the default `DESC` listing. The rows and their contents are identical — only their relative order differs, and only for objects a reorg touched. An in-flight cursor should be restarted after a reorg, as before.

**Verification.** The incremental path is covered by differential tests that roll a fixture back to six different points — from a single active block up to essentially its whole history — and assert, table by table, that the result is identical to a from-scratch rebuild against the same rolled-back ledger, and that a rollback followed by the watcher's forward replay reproduces the State DB exactly. Every optional pass in the rollback (the counters, the `assets_info` re-derivation, the `fairminters` aggregates, the block bound on the ledger lookups) was checked by mutation: removing it makes those tests fail.

## A rebuild that reports itself (#3485)

Every remaining State DB build, refresh or full rollback now publishes its progress (`counterpartycore/lib/api/dbstatus.py`), and two consumers read it:

- **The health listener starts first.** It used to be created after the migration/rebuild block, so for the tens of minutes that block runs there was no socket to probe at all — liveness got a connection refusal, Kubernetes killed the pod mid-rebuild, and the restart began again from zero. It is now started before that block (the WSGI task dispatcher is attached later, once the worker pool exists; until then the pool gauges simply read as unavailable).
- **`rebuilding` is a distinct readiness state.** `/healthz/ready` returns `503` with `reason: "rebuilding"` and a `rebuild` object naming the operation, the current step and the elapsed time; `/healthz/metrics` carries the same. It takes precedence over the lag signal, which reads from tables that are being dropped and repopulated and would otherwise report a misleading `behind_backend`. Liveness stays `200` throughout — the process is healthy and working.
- **Each migration is logged at INFO, with its duration.** Previously the whole rebuild logged nothing above DEBUG, which is why the 33 minutes in the incident report were indistinguishable from a hang.

The health sampler also reopens its own State DB connection after a rebuild: `build_state_db()` unlinks and recreates the file, so a connection held across it would have reported a frozen block height for the rest of the process's life.

**On serving from a second State DB while one is rebuilt** (suggestion 2 in the issue): not implemented, and we think it should not be. Once rollbacks are incremental, a full rebuild only happens at startup, before any listener exists — there are no readers to keep serving. The atomic-swap machinery (a second file, connection-pool epoch invalidation, a swap under live readers) would carry real risk for a case that no longer arises, whereas a correct `rebuilding` readiness state removes the pod from rotation and explains why, which is what suggestion 3 was really after.

## API shutdown and cold startup (#3486)

A GKE node upgrade found the other half of the same problem: the API child took longer than the parent's ten-second grace period to exit and was force-killed, and its next start then spent minutes initializing the API watcher — a real outage on a singleton.

Profiling an isolated disk cloned from the mainnet snapshot put almost all of that startup cost in one query. `parsed_events` carries an index on `event` and a unique index on `event_index`; asked for the latest `BLOCK_PARSED` row by `event_index`, SQLite picked the `event` index and built a temporary B-tree to sort every `BLOCK_PARSED` row ever written, to return one. That plan cost **132 seconds** on a cold mainnet State DB, on a path that runs at every API process start. Three queries used it — `get_last_block_parsed`, `check_reorg` (which also runs on every reorganization check in steady state) and `search_matching_event` — and all three now force the event-index index instead, so SQLite reverse-scans from the newest event and stops as soon as the `LIMIT` is satisfied. The `ORDER BY` is unchanged, so the ordering semantics are identical; on the same snapshot the watcher now initializes in **0.01 seconds**. `search_matching_event` gains a second benefit: it can now stop after the first few blocks of a shallow reorg instead of sorting the full history before it starts looking.

The shutdown path is bounded rather than hopeful:

- **Blocking reads are interrupted.** The API watcher and the node-status checker both spent shutdown inside a SQLite read that no `stop_event` could reach. `stop()` now calls `interrupt()` on their connections from the stopping thread, and the threads treat `apsw.InterruptError` as a clean exit when they are already stopping (and re-raise it otherwise). Writes are unaffected: every one runs inside a savepoint, so an interrupted event parse rolls back whole.
- **One budget, armed once, shared by everything.** Health listener, WSGI server, watcher and Gunicorn worker cleanup draw sub-deadlines from a single eight-second budget that starts when the shutdown is first initiated — not one budget per component, and not a fresh one for the `finally` block after the watchdog thread already spent time in its own stop. Steps that run one after another split what is left rather than sharing a deadline, so a slow first step cannot leave the next one with a zero-second grace period.
- **The bounded joins actually bound.** The watcher and node-status threads are now daemons. A non-daemon thread that outlives its join still blocks interpreter shutdown, so before this the timeout logged a warning and the process hung anyway — precisely the failure being fixed.
- **Gunicorn worker cleanup terminates.** `kill_all_workers()` waited for workers to exit in an unbounded loop; it now escalates to `SIGKILL` at its deadline. Operators running `--wsgi-server gunicorn` (not the default) should know that this bounds the worker drain window to the WSGI server's share of the budget rather than Gunicorn's own `graceful_timeout`: a request still in flight when that share runs out is dropped. Exiting inside the parent's ten seconds is the constraint the budget exists to satisfy, and it cannot also accommodate a ten-second drain.
- **The parent reports what happened.** The API child's stop is timed, the forced kill is itself bounded and followed by a second join, and a process that survives even that is logged at `CRITICAL` instead of being reported as stopped.

Startup diagnostics were added for the parts that remain slow: `apply_outstanding_migration` now logs each phase separately — backend open (which is where WAL recovery lands), migration discovery with the pending count, application, and connection close — along with the WAL size before and after. On the incident node these are what distinguish a multi-minute WAL recovery from a multi-minute migration.

## Reorganization detection

Three ways for the Ledger DB to change branch under the API watcher went undetected. All three are fixed in `counterpartycore/lib/api/apiwatcher.py`.

**A reorganization at the tip.** `check_reorg()` compared the block *before* the last one the State DB had parsed against the Ledger DB (`LIMIT 1 OFFSET 1`). That makes the shallowest and by far the most common reorganization invisible: when the tip block is replaced by another at the same height, the only parsed event whose hash changed is the one the comparison steps over. The watcher then appended the next block of the new branch on top of the orphaned one, and the State DB carried an event that no longer exists in the ledger until something deeper reorganized. The comparison now starts at the last parsed event, and `search_matching_event()` walks back from it rather than from the one below. Comparing the newest row cannot produce a false positive: the State DB only ever copies events the Ledger DB has committed, so the hash at that `message_index` differs only if the ledger really did roll back.

**A reorganization while the watcher is busy.** The check ran only once the watcher had nothing left to parse, and then at most once every five seconds. A rollback that lands while it is still replaying a backlog — or in the middle of the block it is parsing — was therefore acted on only after it next ran out of events, and every event appended in between was derived from the new branch and written on top of state derived from the old one. The check is now keyed on SQLite's `PRAGMA data_version`, which the pager bumps whenever another connection commits: an exact "the ledger moved" signal for the watcher's read-only connection. It costs less than the timer it replaces rather than more — at the tip, where the watcher spends nearly all of its time polling every 100 ms, the counter is unchanged and the two index lookups are skipped entirely. The five-second interval is kept as a floor, so detection never rests on the counter alone.

**A reorganization inside the block being parsed.** The same comparison looked only at `BLOCK_PARSED` rows, so it compared the last *block* the State DB had parsed rather than the last *event*. The watcher advances one event at a time (`get_next_event_to_parse()` orders by `message_index`, not by block), so between two blocks it sits with part of a block copied and that block's `BLOCK_PARSED` not yet written — briefly at the tip, and for the whole of a catch-up. A rollback landing in that window left the last `BLOCK_PARSED` — the *previous* block's, which the reorganization never touched — matching, so the check passed while the State DB held orphaned events of the block it was in the middle of, and the mutations they had already applied to the state tables. Nothing repaired it afterwards: every `BLOCK_PARSED` compared from then on came from the new branch and matched. The comparison now takes the last parsed row whatever its type; `search_matching_event()` keeps its `BLOCK_PARSED` filter, since what it looks for is the rollback *target*, which is a block index.

Detecting that case is only half of it. A reorganization caught mid-block targets `last_block_parsed + 1`, and `staterollback.rollback_reason()` measured a target against the last block *completed* — so it read the orphaned rows of the block in progress as sitting below the target, answered "nothing to roll back", and left them in place along with the mutations they had applied. It now measures against the last block *touched* (`apiwatcher.get_last_block_touched()`), the block index of the last event copied whether or not its `BLOCK_PARSED` is written, so a half-copied block is undone rather than dismissed. The incremental rollback itself already handled a partial block — it deletes on `block_index >=` and recomputes the cached tip — so nothing else had to change.

`check_reorg()` now also reports when it found the ledger on another branch, and both loops discard the event they were holding when it did: that event was selected against the branch the rollback has just undone.

## A watcher that stops on an error now says so

The API watcher thread is what advances the State DB, and nothing restarts it. An unexpected error inside it was re-raised into `threading.excepthook`, which writes to stderr rather than to the log — so the thread died with its traceback going nowhere, and the process went on serving a State DB frozen at whatever block it had reached, as if nothing had happened.

Such a failure is now logged at `CRITICAL` with its traceback, and `/healthz/ready` returns `503` with `reason: "watcher_stopped"` from that moment. Previously the only symptom was the lag signal drifting past the ready threshold minutes later — and on an `--api-only` node, which does not compare itself to the backend tip, never at all. Liveness deliberately stays `200`: the process is internally alive, and the remedy is to shed traffic and page an operator, not to have Kubernetes kill a pod mid-request.

## Packaged OpenAPI document (#3495)

The installed wheel now includes `openapi.json`. Previously `/v2/openapi.json`
worked from a source checkout but returned `500` from the official container:
the handler walked four directories upward from `site-packages`, where the
repository-root file does not exist. The API now resolves the packaged resource
and retains a source-tree fallback for editable development installs.

## Address history endpoints

`/v2/addresses/<address>/credits`, `/debits`, `/sends` and `/sends/<asset>` match an address against two or four columns, each of which already has its own index. Neither plan SQLite has for the resulting `OR` predicate followed by `ORDER BY rowid DESC LIMIT` is bounded by the page size. A reverse full-table scan — the right plan only for an address whose newest row sits near the tip — reads millions of unrelated rows before reaching the first match of an address whose history is short or old. The alternative, a multi-index `OR`, does use every index but then has to sort the address's *entire* history to honour the ordering, so a busy address pays for all of it to return one page.

Each `OR` branch is now resolved through its own index (`INDEXED BY`) and cut to a single page-sized slice before the branches are merged on `rowid`. The bound is exact rather than approximate — the global top *K* distinct rows must appear in the top *K* of at least one branch — and it is structural rather than another bet on the planner: however long the address's history, the page is selected from at most four page-sized slices instead of from the whole history.

Three request shapes that defeated the bound are now rejected or narrowed on these four routes:

- **`offset` is capped at 10,000** (and negative offsets, previously treated as `0`, are rejected). Deep offset pagination has to materialize and discard every skipped row; past that point, use `cursor`.
- **`sort` has been withdrawn** from `/sends` and `/sends/<asset>` by address. A global sort over an arbitrary column cannot be bounded by the per-branch slice above, so rather than accept the parameter and always fail, these routes no longer advertise it: it is gone from their signature and from `openapi.json`, and passing it now returns `400 Unrecognized parameter(s): sort`. Use cursor pagination. This matches how `/v2/addresses/balances` already handles a `sort` it cannot honour.
- **Repeated `send_type` members are deduplicated** and unknown ones rejected. `send_type=send,send,send,…` previously amplified into one union branch per repetition.

The exact result count is computed on the initial page and on offset pages only; on cursor pages `result_count` is `null`. Counting is precisely what the bound above cannot help with — it has to touch every matching row — so later cursor pages stay bounded. The count itself no longer reuses the ordered union either: it lets SQLite combine the address indexes directly, which is substantially cheaper for busy addresses.

## Conflicting pending asset compositions

Issuance and fairminter composition only ever validated against confirmed state, so two transactions created seconds apart could both compose successfully and only one of them could ever be valid — the second was broadcast, paid its fee and was rejected by the parser.

Composing an issuance or a fairminter now returns **`409`** when Counterparty's parsed mempool already holds a conflicting asset creation, ownership transfer, lock or reset, or an active fairminter for the same asset. Compatible valid reissuances stay composable, unless their cumulative pending quantity could overflow the maximum supply.

The check runs twice, because the mempool moves while a composition is being assembled: once up front, and again after the selected UTXOs have been atomically reserved (or, for message-only composition, before the data is returned). Confirmed state is re-read on that second pass as well. A composition that fails it releases its UTXO reservation rather than leaving the inputs locked, and any message bytes refreshed by the second pass are the ones used for the returned transaction.

`validate=false` remains the explicit advanced-user override and skips both passes.

## State DB / Ledger DB consistency fixes

The differential tests above surfaced three ways in which a State DB maintained by the event stream drifted from one built from scratch. All three are fixed in `apiwatcher.update_balances()`, and the one-time refresh normalizes existing rows:

- `balances.block_index` and `balances.tx_index` were never written by the event stream, so every balance changed since the last full build carried a stale (or `NULL`) value. This is also what the incremental rollback uses to find which balances an orphaned block touched.
- `balances.asset_longname` was `NULL` for every balance row first created by the event stream, while the same row on a freshly built node carried the real longname.
- A zero-quantity `CREDIT`/`DEBIT` was skipped entirely, where the parser still appends a `balances` row for it (bumping that row's block and transaction index). An existing balance row is now always updated, whatever the quantity, and a zero-quantity debit against a non-existent balance still writes nothing — matching `ledger.events.remove_from_balance()`.

## Refactoring

- The rules for projecting a Ledger DB row into its State DB counterpart — decoding the compact `asset_index` / `address_id` / `(utxo_tx_hash, utxo_vout)` representations — now live in one place, `counterpartycore/lib/api/statetables.py`, shared by the build path (migrations `0004`, `0006`, `0014`) and the rollback path. Two independent copies of these rules would drift, and drift here is a silent divergence no API response would reveal.
- New State DB migration `0016` adds the missing `block_index` indexes on `addresses`, `rps` and `rps_matches`.

## Security

- Bumped `h2` to 0.4.19 in both Rust lockfiles for **RUSTSEC-2026-0258** ("h2 unbounded empty DATA frames"). `counterparty-rs` carried 0.4.8 and `counterparty-client` 0.4.15; the advisory requires >= 0.4.16.
