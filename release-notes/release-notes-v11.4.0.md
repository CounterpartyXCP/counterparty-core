# Release Notes - Counterparty Core v11.4.0 (TBD)

Counterparty Core v11.4.0 is a **security release**. It fixes a family of remotely triggerable chain-halt vulnerabilities reported privately as [GHSA-pmfx-7qj5-fx6c](https://github.com/CounterpartyXCP/counterparty-core/security/advisories/GHSA-pmfx-7qj5-fx6c), plus a silent ledger-fork vector in how the source of an inscription reveal transaction is resolved. Each halt vector let an unprivileged attacker stop **every node on the network** at the same block for the price of one or two ordinary transactions, and a halted node restarts onto the same poisoned block and halts again.

**All node operators should upgrade immediately.**

The release also carries one **protocol change** — `reject_non_finite_broadcast`, the root-cause fix for the halt family — scheduled to activate at mainnet block **966,200**, the same activation height as the fee correction shipped in v11.3.0. Nodes that have not upgraded by that block will diverge from consensus. There is no database migration and no reparse; the upgrade is a plain restart.

# Upgrading

**This release includes a protocol change** — `reject_non_finite_broadcast` — activating at block **966,200** on mainnet (approximately September 9, 2026), block 5,166,000 on testnet3, block 153,700 on testnet4 and block 321,300 on signet. **All nodes must upgrade before the activation block.** The change applies from the activation block forward, so there is no reparse and no migration.

The security fixes themselves are ungated and take effect as soon as you restart: a transaction that reaches any of them raises on v11.3.0 and earlier, so no historical block can contain one that was ever parsed successfully, and broadening the handling changes no historical state.

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

## Security

- **Fix an RPC-dependent `source` for inscription reveal transactions** (GHSA-pmfx-7qj5-fx6c). The source of a reveal transaction is one hop further back than an ordinary input: the output that funded the *commit* transaction, not the commit output the reveal spends. The Rust deserializer performs that rewrite and hands the result back as `vin["info"]` — but it fetched the two prevouts with `unwrap_or_default()`, so an RPC failure degraded silently in two different ways. If the first batch call failed, `info` came back empty and the Python fallback resolved the input *normally*, yielding the commit output's address. If only the second call failed, `info` came back **populated with the wrong output**, which nothing downstream could detect. Either way that node computed a different `source` **and a different `fee`** than every node whose RPC succeeded — a silent, permanent ledger fork, on a live code path (reveal transactions have been parsed since `taproot_support` at block 902,000).

  The commit-parent lookup is now all-or-nothing: on any failure the deserializer records no commit parent and leaves *every* input unresolved, never a partial result. Clearing all of them matters — with no commit parent recorded, an input that also spends the funding transaction would be resolved at its own output index while a healthy node resolves it at the commit parent's. The Python fallback (`get_reveal_prevouts()`) then reproduces the same two-hop resolution — including the deserializer's treatment of that extra input — so both paths agree, and it takes precedence over any `vin["info"]` the deserializer did return, so the two sides cannot drift even if the all-or-nothing invariant is ever broken. If the backend really is unavailable it raises `BitcoindRPCError` and halts, as the parser already does for any unresolvable prevout, instead of guessing. The block is rolled back atomically and retried, so a transient blip cannot corrupt the ledger.

  No activation gate: the canonical ledger is the one produced when the RPC succeeds, and that path is unchanged. The fix only stops a node whose backend hiccuped from silently diverging from it.

- **Fix seven remotely triggerable chain-halt vulnerabilities** (GHSA-pmfx-7qj5-fx6c, reported privately). Each of these let an unprivileged attacker halt **every** node on the network at the same block, for the price of one or two ordinary transactions, by making block ingestion raise an exception type nothing catches. Two architectural facts made the class fatal: `parse_tx()` wraps any handler exception into `ParseTransactionError` and `parse_block()` deliberately re-raises it, while at the parse level `get_tx_info()` caught only `DecodeError`/`BTCOnlyError` and `list_tx()` had no handler at all. A halted node restarts onto the same poisoned block and halts again.

  - **`None` element in `potential_dispensers`** — the Rust deserializer's short-data early return in `parse_vout()` emitted a `None` dispenser slot, which PyO3 hands to Python as a genuine `None` list element; `get_dispensers_tx_info()` (reached by the live dispense-prefix route since `enable_dispense_tx`) and `get_dispensers_outputs()` subscripted it. Cost: one dust output. The Rust side now always returns a structurally complete slot, and both Python consumers skip `None` elements.
  - **Zero-price oracle dispenser** — a broadcast with `value = 0` is valid, and `dispenser.validate()` rejected only `last_price is None`, so opening an oracle dispenser on such a feed reached `mainchainrate / 0`. `validate()` now reports a problem for a zero price, matching the `last_price == 0` guard `is_dispensable()` already had (dead code since `disable_vanilla_btc_dispense`). Scoped to opening and refilling, the only actions that compute an oracle fee: a close never divides by the price, so flagging it there would turn a close that succeeds today into an invalid transaction.
  - **NULL `fee_fraction_int`** — `calculate_oracle_fee()` computed `last_fee / config.UNIT` on a NULL fee fraction (stored by a "lock" broadcast, by a NaN CBOR float, or by the out-of-range clamp). It now reads a missing fee fraction as zero, like `bet.get_fee_fraction()` already did.
  - **NULL broadcast `text`** — `get_oracle_last_price()` called `.split()` on the NULL `text` of a locked feed, so a single "lock" broadcast on an oracle address halted every node that later touched that oracle.
  - **NaN `minted_asset_commission`** — `D(float("nan"))` is `Decimal("NaN")`, and any ordering comparison against it raises `decimal.InvalidOperation` (an `ArithmeticError`, so no existing net applied) inside `fairminter.validate()`, before any DB access. **One** ordinary transaction was enough. NaN is now reported as a validation problem; `±inf`, which never crashed, keeps its historical status string.
  - **NULL broadcast timestamp** — `bet.validate()` compared `broadcasts[-1]["timestamp"] >= deadline` against a NULL left by a NaN-timestamp broadcast. `bet.parse()` wraps only the `price()` call, so unlike `broadcast.parse()` it had no `broadcast_safe_validate`-style net.
  - **Int-typed asm elements** — the Rust `script_to_asm()` renders a *pushed* `0xae` byte identically to the `OP_CHECKMULTISIG` opcode, so `script.script_to_asm()` rewrote `asm[0]`/`asm[-2]` into Python ints for a push-only, relay-standard scriptSig such as `OP_0 OP_0 <push 0xae>`; `get_der_signature_sighash_flag()` then evaluated `value[:-1]` on an int. This ran for every data-carrying transaction with no protocol gate, and the relay-standard variant also killed the mempool watcher before confirmation. The flag reader now type-checks its argument.
  - **`MultiSigAddressError` escaping `get_tx_info()`** — a bare-multisig prevout with `m` outside 1..3 made source resolution raise an `AddressError`, which is not a `DecodeError`, straight through `list_tx()`.

  `get_tx_info()` now also carries a general safety net: exception types that mean "these bytes are not a well-formed Counterparty transaction" (`TypeError`, `ValueError`, `ArithmeticError`, `LookupError`, `AttributeError`, `struct.error`, `AddressError`) are logged and treated as non-Counterparty instead of escaping. This is deliberately an allow-list of *data* errors, not a bare `except Exception`: `BitcoindRPCError` and database errors still propagate, because silently dropping a confirmed transaction whose prevout could not be fetched would fork the ledger permanently (block 510556). The net is scoped to code that derives from the transaction bytes: the ledger reads on either side of it (`get_utxos_info()`, the UTXO-balances cache update) sit outside it, and the one inside it (`is_dispensable()`) re-raises data errors as `DatabaseError` so they halt rather than being absorbed.

  **None of these guards need an activation gate.** A transaction that reaches any of them raises on current code, so every node halts on it, so no historical block can contain one that was ever parsed successfully. Only the root-cause fix below changes the status of a parse that succeeds today.

  The `fuzz_cbor_test.py` harness excluded NaN and infinity from its float strategy — which is precisely why this family went unnoticed — and now includes them. A dedicated regression suite lives in `counterpartycore/test/units/parser/chain_halt_test.py`.

## Protocol

- **Reject non-finite numbers in broadcasts** (`reject_non_finite_broadcast`, GHSA-pmfx-7qj5-fx6c). Since `taproot_support`, broadcasts are CBOR-decoded, which admits float64 — including **NaN**. `broadcast.validate()` deliberately performs no numeric type check, every comparison against NaN is `False`, so a NaN field validated as `"valid"`; sqlite3 then bound it as **NULL**, and the poisoned row halted every consumer that read it back (the oracle-dispenser and bet failures above). A broadcast carrying a non-finite `timestamp`, `value` or `fee_fraction_int` is now marked invalid, so no new poisoned row can be stored. This flips the status of parses that currently succeed, hence the gate: mainnet block **966,200**, testnet3 5,166,000, testnet4 153,700, signet 321,300. The downstream guards listed under Security are ungated and remain the load-bearing fix for rows predating the activation.

- **`ordinals_metadata_support` heights corrected to match the code.** The gate is enforced by the Rust deserializer only (`Heights::new` in `counterparty-rs/src/indexer/config.rs`); nothing in Python reads it. The v11.1.0 release pass bumped the `protocol_changes.json` heights along with every other pending change, but `config.rs` was never updated — so the JSON has been advertising an activation (mainnet 952,800) that never happened, while signet and regtest have had the feature on since block 0. The JSON now states what the code actually enforces. **Scheduling a real activation means changing both files**; signet and regtest must stay at 0 because their bootstrap snapshots depend on it.

# Credits

- Ouziel Slama
- Dan Anderson
- Adam Krellenstein
- @john-a-zoidburg (vulnerability report)
