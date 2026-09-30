# Release Notes - Counterparty Core v11.5.0 (2026-09-30)

This is a security release that fixes a vulnerability allowing an attacker to sweep the assets of any address that pays them plain BTC. It introduces one protocol change and changes how taproot-encoded transactions are composed and signed. It also includes reliability fixes for mempool parsing and API startup.

**All node operators must upgrade before mainnet block 969,320, expected around 15:00 UTC on 2026-09-30, about two hours after this release. A node still running v11.4.0 when that block is mined will diverge from the network. Wallets that use `encoding=taproot` must be updated to sign the reveal transaction themselves; until then their taproot-encoded transactions are rejected.**

# Upgrading

To upgrade, download the latest version of `counterparty-core` and restart `counterparty-server`.

**No reparse is required, but the first start rebuilds the State DB. Allow approximately 30 minutes on mainnet, during which the API is unavailable.** The Ledger DB itself is left alone when the node upgrades before the activation height, which is the expected case: the rule activates ahead of every chain tip, so there is nothing to undo. A node that stayed on v11.4.0 past the activation height is rolled back to it and re-parses those blocks with the new rule, so that every node agrees on the ledger.

For Kubernetes deployments, the dedicated health listener (`/healthz/live` and `/healthz/ready`, port `4002` by default on mainnet) reports the rebuild as in v11.4.0: liveness returns `200` and readiness returns `503 rebuilding`.

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

The v11.4.0 bootstrap snapshots remain valid and are selected automatically by `counterparty-server bootstrap`; a freshly bootstrapped node goes through the State DB rebuild described above on its first start.

The protocol change activates at the following block heights, the blocks each chain is expected to reach at 15:00 UTC on 2026-09-30:

| Network | `require_reveal_source_signature` |
| --- | ---: |
| Mainnet | 969,320 |
| Testnet3 | 5,151,805 |
| Testnet4 | 154,564 |
| Signet | 324,359 |

It is enabled from block 0 on regtest.

# The vulnerability

A Counterparty message carried by a taproot envelope is published in two steps: a *commit* transaction pays a P2TR output whose script tree holds the envelope, and a *reveal* transaction spends that output through the envelope leaf. The parser recognised a reveal by its shape alone (an `OP_RETURN CNTRPRTY` output and a three-element witness on the first input) and attributed the message to the address that funded the commit transaction.

Nothing tied that address to the envelope. An attacker could publish a P2TR address whose hidden leaf carried a `sweep` of all balances and asset ownerships, have a victim pay ordinary BTC to it, and then spend the payment in a reveal that Counterparty attributed to the victim. The victim never signed anything related to Counterparty, and the malicious script was invisible in the address they paid. A P2WSH output with a three-element witness worked the same way, without any real signature at all. The attack was confirmed on regtest against v11.3.0; the same code paths are active on mainnet since the activation of `taproot_support` at block 902,000.

Until the activation height is reached, users should avoid paying BTC to unknown P2TR or P2WSH addresses from an address that holds Counterparty assets or XCP.

# ChangeLog

## Security

- Fix the attribution of inscription reveal transactions, which allowed an attacker to attach an arbitrary Counterparty message, including a `sweep`, to any address that paid plain BTC to an attacker-supplied P2TR or P2WSH address (GHSA-q27c-r246-f6qw).

## Protocol

- Require inscription reveals to be signed by their source (`require_reveal_source_signature`). From the activation heights above, a reveal is attributed to the address that funded its commit only when all of the following hold: the output it spends is a P2TR output; the witness is a tapscript spend of that output whose control block commits the leaf to the output key under leaf version `0xc0`; the leaf is a canonical envelope, `OP_FALSE OP_IF <pushes only> OP_ENDIF <32-byte key> OP_CHECKSIG` and nothing else; and that key is a key of the source address. Bitcoin's own script validation then guarantees that the source signed the message. A P2WPKH, P2SH-P2WPKH or P2PKH source authorises with the key hashing to its address; a P2TR source with its output key or with a BIP86 internal key. Any other reveal is ignored as a non-Counterparty transaction, with a warning in the logs. The rule is implemented once, in `counterparty-rs/src/reveal.rs`. It cannot be applied to earlier blocks: every commit/reveal composed before this release closes its envelope with a throwaway key rather than the source key.

## API

- **Breaking:** `compose` with `encoding=taproot` no longer signs the reveal transaction. The node does not hold the source key, so `signed_reveal_rawtransaction` is removed. The result now carries the unsigned reveal in `reveal_rawtransaction`, plus everything needed to sign it: `envelope_script`, `reveal_control_block`, `reveal_pubkey` (the x-only key that closes the envelope), `reveal_lock_scripts` and `reveal_inputs_values` (the commit output the reveal spends). Wallets must add the witness `<signature> <envelope_script> <reveal_control_block>` to the reveal, signing the envelope leaf (BIP342 script path, `SIGHASH_DEFAULT` or `SIGHASH_ALL`) with the private key of `reveal_pubkey`, then broadcast the commit followed by the reveal.
- The envelope is closed by the source key. Pass the source public key as `multisig_pubkey` (compressed or x-only); it is otherwise looked up in the source's transactions. A P2TR source without a known key falls back to its output key, which the wallet signs for with its BIP86-tweaked private key. `taproot` encoding now requires a P2WPKH or P2TR source.
- `compose` rejects a `multisig_pubkey` that is not a key of the source address, and the composed commit, envelope and reveal are cross-checked against the source before being returned.

## Reliability

- Fix missing mempool transactions or parent lookups blocking confirmed-block processing indefinitely. Failed mempool batches roll back without marking their transactions unsupported.
- Report mempool parsing that makes no progress for two minutes through the liveness health check, allowing supervisors to restart the node. Confirmed-block processing, startup and State DB rebuilds do not trigger this safeguard. Mempool support remains enabled.
- Refuse to start the API when stored ledger or transaction-list hashes disagree with known checkpoints, including in API-only mode. Report the mismatching checkpoint and recovery guidance without automatically changing ledger data.

## Client

- `counterparty-client` signs the reveal transaction of a taproot-encoded compose with the source key, after checking that the commit output commits to the returned envelope under that key, instead of broadcasting a server-signed reveal.

## Codebase

- Add `require_reveal_source_signature` unit tests for the Rust rule, the Python parser wiring and the composer, and replay the reported attack in the regtest taproot suite.
- Bump `Flask-HTTPAuth` to 4.8.1 (GHSA-p44q-vqpr-4xmg, CVE-2026-34531). The API only uses `HTTPBasicAuth`, which is not affected.

# Credits

- Ouziel Slama
- Dan Anderson (vulnerability report, XCP Wallet)
