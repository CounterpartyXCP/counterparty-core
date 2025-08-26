# Release Notes - Counterparty Core v11.0.0 (2025-03-??)

This version is a small-ish release. Most importantly, it fixed a regression in transaction handling where empty descriptions could be incorrectly encoded into issuance transactions of various types (including locking, e.g.) and addressed a bug whereby using the `verbose=true` parameter could cause the node API to hang.This version also introduces a persisted transaction validity flag, new API filters, and proper JSON booleans in responses, improving clarity and queryability; it also (finally) adds Bitcoin Core cookie authentication (which is now the recommended method). Finally, the official Docker image has been updated to use Alpine rather than Ubuntu, which reduces the image size from 1.1 GB to 126 MB.


# Upgrading

**Upgrade Instructions:**

Note: A full reparse is required iff you would like to use the new `valid` parameter to retrieve transactions with the API. Existing databases will show `valid=null` for historical transactions until re-parsed.

⚠️ There is a **breaking API change**: API booleans `divisible`, `locked`, `reset`, and `callable` now return proper JSON booleans (`true`/`false`) instead of integers.

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

## Bugfixes

- Fix regression in issuance handling where empty descriptions could be incorrectly encoded.
- Fix `mime_type` field in `assets_info` table
- Fix API issue when unpacking old transactions
- Remove unnecessary `logger.error` from Enhanced Send unpacking
- Fix typo in `docker-compose.yml
- Fix give/get_price in orders API
- Fix bootstrap: exit with error when a subprocess fails
- Disable taproot encoding for legacy source

## Codebase

- Add `current_commit` tag in Sentry reports and JSON logs
- Add `transactions_status` table filled by the `parse()` functions of each contract

## API

- Fix boolean fields in issuances API
- Add `current_commit` field in API root endpoint
- Add `valid` parameter for transactions endpoints
- Optimize the Get Balances by Addresses endpoint

## CLI

- Use Alpine Linux instead of Ubuntu for Docker image and employ a multi-stage build
- Report a cleaner error on an unknown CLI argument
- Report a specific message when Bitcoin Core has not yet reached the first Counterparty block
- Add `--backend-cookie-file` flag to connect to Bitcoin Core with cookie (recommended)
- Improve bootstrap and subprocess error handling.

# Credits

- Ouziel Slama
- Adam Krellenstein
