# Release Notes - Counterparty Core v10.7.4 (2024-12-09)

This is a hotfix release that addresses a deterministic node crash due to the fact that Enhanced Sends and MPMAs weren't setting the `msg_index` value correctly. This bug was triggered by a UTXO send and an Enhanced Send being combined in a single Bitcoin transaction. All node operators should upgrade immediately.

# Upgrading

This upgrade is required to address a critical protocol-level  bug. No reparse is necessary.


# ChangeLog

## Protocol Changes

## Bugfixes

- Ensure `msg_index` value is set for Enhanced Send
- Ensure `msg_index` is unique for MPMA

## Codebase

## API

## CLI


# Credits

* Ouziel Slama
