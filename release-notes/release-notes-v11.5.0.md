# Release Notes - Counterparty Core v11.5.0 (2026-09-28)

This is a security release that fixes a vulnerability allowing an attacker to sweep the assets of any address that pays them plain BTC. It introduces one protocol change and changes how taproot-encoded transactions are composed and signed.

**All node operators should upgrade immediately. The protocol change activates at the block height each chain had reached when this release was published (mainnet block 968,846), so it is already in force; nodes that upgrade later roll back to that height automatically. Wallets that use `encoding=taproot` must be updated to sign the reveal transaction themselves; until then their taproot-encoded transactions are rejected.**

# Upgrading

To upgrade, download the latest version of `counterparty-core` and restart `counterparty-server`.

**No reparse is required. On first start the node rolls the Ledger DB back to the activation height, re-parses the blocks mined since the release and rebuilds the State DB. Allow approximately 30 minutes on mainnet, during which the API is unavailable.** The rollback re-parses with the new rule the blocks that a v11.4.0 node may have parsed with the old one, so that every node agrees on the ledger. The State DB rebuild runs even when the node has not yet reached the activation height, for example after a bootstrap.

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

The protocol change activates at the following block heights, the heights of each chain at the time of the release:

| Network | `require_reveal_source_signature` |
| --- | ---: |
| Mainnet | 968,846 |
| Testnet3 | 5,151,305 |
| Testnet4 | 154,138 |
| Signet | 323,915 |

It is enabled from block 0 on regtest.

# The vulnerability

A Counterparty message carried by a taproot envelope is published in two steps: a *commit* transaction pays a P2TR output whose script tree holds the envelope, and a *reveal* transaction spends that output through the envelope leaf. The parser recognised a reveal by its shape alone (an `OP_RETURN CNTRPRTY` output and a three-element witness on the first input) and attributed the message to the address that funded the commit transaction.

Nothing tied that address to the envelope. An attacker could publish a P2TR address whose hidden leaf carried a `sweep` of all balances and asset ownerships, have a victim pay ordinary BTC to it, and then spend the payment in a reveal that Counterparty attributed to the victim. The victim never signed anything related to Counterparty, and the malicious script was invisible in the address they paid. A P2WSH output with a three-element witness worked the same way, without any real signature at all. The attack was confirmed on regtest against v11.3.0; the same code paths are active on mainnet since the activation of `taproot_support` at block 902,000.

Until the network has upgraded, users should avoid paying BTC to unknown P2TR or P2WSH addresses from an address that holds Counterparty assets or XCP.

# ChangeLog

## Security

- Fix the attribution of inscription reveal transactions, which allowed an attacker to attach an arbitrary Counterparty message, including a `sweep`, to any address that paid plain BTC to an attacker-supplied P2TR or P2WSH address (GHSA-q27c-r246-f6qw).

## Protocol

- Require inscription reveals to be signed by their source (`require_reveal_source_signature`). From the activation heights above, a reveal is attributed to the address that funded its commit only when all of the following hold: the output it spends is a P2TR output; the witness is a tapscript spend of that output whose control block commits the leaf to the output key under leaf version `0xc0`; the leaf is a canonical envelope, `OP_FALSE OP_IF <pushes only> OP_ENDIF <32-byte key> OP_CHECKSIG` and nothing else; and that key is a key of the source address. Bitcoin's own script validation then guarantees that the source signed the message. A P2WPKH, P2SH-P2WPKH or P2PKH source authorises with the key hashing to its address; a P2TR source with its output key or with a BIP86 internal key. Any other reveal is ignored as a non-Counterparty transaction, with a warning in the logs. The rule is implemented once, in `counterparty-rs/src/reveal.rs`. It cannot be applied to earlier blocks: every commit/reveal composed before this release closes its envelope with a throwaway key rather than the source key.

## API

- **Breaking:** `compose` with `encoding=taproot` no longer signs the reveal transaction. The node does not hold the source key, so `signed_reveal_rawtransaction` is removed. The result now carries the unsigned reveal in `reveal_rawtransaction`, plus everything needed to sign it: `envelope_script`, `reveal_control_block`, `reveal_pubkey` (the x-only key that closes the envelope), `reveal_lock_scripts` and `reveal_inputs_values` (the commit output the reveal spends). Wallets must add the witness `<signature> <envelope_script> <reveal_control_block>` to the reveal, signing the envelope leaf (BIP342 script path, `SIGHASH_DEFAULT` or `SIGHASH_ALL`) with the private key of `reveal_pubkey`, then broadcast the commit followed by the reveal.
- The envelope is closed by the source key. Pass the source public key as `multisig_pubkey` (compressed or x-only); it is otherwise looked up in the source's transactions. A P2TR source without a known key falls back to its output key, which the wallet signs for with its BIP86-tweaked private key. `taproot` encoding now requires a P2WPKH or P2TR source.
- `compose` rejects a `multisig_pubkey` that is not a key of the source address, and the composed commit, envelope and reveal are cross-checked against the source before being returned.

## Client

- `counterparty-client` signs the reveal transaction of a taproot-encoded compose with the source key, after checking that the commit output commits to the returned envelope under that key, instead of broadcasting a server-signed reveal.

## Codebase

- Add `require_reveal_source_signature` unit tests for the Rust rule, the Python parser wiring and the composer, and replay the reported attack in the regtest taproot suite.

# Credits

- Ouziel Slama
- Dan Anderson (vulnerability report, XCP Wallet)
