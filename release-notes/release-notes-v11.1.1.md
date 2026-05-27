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

## Protocol Changes

## Performance

- Compact hash storage in the Ledger DB: transaction hashes, block hashes and other fixed-size hex strings are now stored as raw 32-byte BLOBs instead of 64-char hex strings, cutting hash-column storage roughly in half. A new migration (`0010.compact_hash_storage`) rewrites all affected tables and runs `VACUUM` afterwards; a new `hashcodec` module handles encoding/decoding transparently so the rest of the codebase is unaffected.

## Bugfixes

## API

## Codebase

- Fix intermittent BIP143 signature mismatches in regtest by broadcasting tx1 before signing tx2, so the wallet sees tx1's UTXOs in its mempool view
- Update Python dependencies: Flask 3.0.0→3.1.3, pytest 7.4.4→9.0.3, requests 2.32.4→2.33.0, Werkzeug 3.1.4→3.1.6, itsdangerous 2.1.2→2.2.0
- Update Rust dependencies: openssl 0.10.79→0.10.80, openssl-sys 0.9.115→0.9.116

# Credits

- Ouziel Slama
- Dan Anderson
- Adam Krellenstein
