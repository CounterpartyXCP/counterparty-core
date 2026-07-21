# Release Notes - Counterparty Core v11.0.3 (2025-10-27)

This is a minor release that addresses three bugs in Counterparty Core: one in the caching of issuance transactions which can lead to mismatches in consensus hashes across nodes, and two bugs in the API (including another one also related to caching). All users should upgrade as soon as possible.

# Upgrading

**Upgrade Instructions:**

To upgrade, download the latest version of `counterparty-core` and restart `counterparty-server`. An reparse to block 911,955 to correct the transaction cache will occur automatically.

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

## Bugfixes

- Fix get events by addresses endpoint
- Exclude `/v2/addresses/mempool` from cache
- Don't cache invalid issuances

## Codebase


## API


## CLI

# Credits

- Ouziel Slama
- Adam Krellenstein
