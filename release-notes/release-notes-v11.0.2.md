# Release Notes - Counterparty Core v11.0.0 (2025-03-??)

This version is a small-ish release. Most importantly, it fixed a regression in transaction handling where empty descriptions could be incorrectly encoded into issuance transactions of various types (including locking, e.g.) and addressed a bug whereby using the `verbose=true` parameter could cause the node API to hang. This version also introduces a transaction validity flag and new API filters, improving clarity and queryability; it (finally) adds Bitcoin Core cookie authentication (which is now the recommended method) and updates the official Docker image to use Alpine rather than Ubuntu, which reduces the image size from 1.1 GB to 126 MB.


# Upgrading

NOTE: A full database rebuild is required iff you would like to use the new `valid` parameter to retrieve transactions with the API. Existing databases will show `valid=null` for historical transactions until re-parsed.

NOTE: There was another accidental regression in v11.01: API booleans `divisible`, `locked`, `reset`, and `callable` have been returning integers instead of proper JSON booleans (`true`/`false`). This regression has been reverted in v11.0.2.

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

# ChangeLog

## Bugfixes

- Fix regression in issuance handling where empty descriptions could be incorrectly encoded
- Fix `mime_type` field in `assets_info` table
- Fix API issue when unpacking old transactions
- Fix a typo in `docker-compose.yml
- Fix give/get_price in orders API
- Fix bootstrap: exit with error when a subprocess fails
- Fix `UTXOBalancesCache` initialization: restore also invalid `attach`
- Remove unnecessary `logger.error` calls from Enhanced Send unpacking
- Disable Taproot encoding for legacy sources

## Codebase

- Add `current_commit` tag in Sentry reports and JSON logs
- Add `transactions_status` table filled by the `parse()` functions of each contract
- Update the `testnet4`, `signet` and `mainnet` checkpoints

## API

- Fix boolean fields in issuances API
- Add `current_commit` field in API root endpoint
- Add `valid` parameter for transactions endpoints
- Optimize the Get Balances by Addresses endpoint

## CLI

- Use Alpine Linux instead of Ubuntu for Docker image and employ a multi-stage build
- Throw a cleaner error on an unknown CLI argument
- Report when Bitcoin Core has not yet reached the first Counterparty block
- Add `--backend-cookie-file` flag to connect to Bitcoin Core with cookie (recommended)
- Improve bootstrap and subprocess error handling

# Credits

- Ouziel Slama
- Adam Krellenstein
