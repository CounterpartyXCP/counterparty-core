# Release Notes - Counterparty Core v11.0.1 (2025-06-10)

This release is a patch on the v11.0.0 protocol upgrade with the same activation block (902,000). It allows for backwards-compatibility in the transaction encoding format so that CBOR is no longer required for transaction data packing. It also adds support for Bitcoin `signet` and fixes a few bugs---including one critical bug in the new issuance decoding logic.

NOTE: If a CBOR transaction is incorrectly constructed so that it is invalid, it will be parsed automatically with the original transaction decoding logic, which may lead to unpredictable results.


# Upgrading

**Upgrade Instructions:**

**This release is a protocol upgrade. All nodes must upgrade by block 902000.**

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

## Protocol

- Add backward-compatibility to CBOR format (Enhanced Send, Sweep, Fairminter, Fairmint, Issuance and Broadcast)

## Bugfixes

- No Taproot encoding for legacy inputs
- Handle unpack error for issuances correctly

## Codebase

- Add `signet` Support

## API

## CLI


# Credits

- Ouziel Slama
- Adam Krellenstein
