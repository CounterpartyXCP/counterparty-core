# Release Notes - Counterparty Core v11.0.0 (2025-03-??)


# Upgrading

**Upgrade Instructions:**

Note: A full reparse is optionally required if you want to use the new `valid` parameter to retrieve transactions with the API

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

- Fix `mime_type` field in `assets_info` table
- Fix issuance composition when description is None
- Fix API issue when unpacking old transactions
- Remove unnecessary `logger.error` from Enhanced Send unpacking
- Fix typo in docker-compose.yml
- Fix give/get_price in orders API
- Fix boolean fields in issuances API
- Fix bootstrap: exit with error when a subprocess fails

## Codebase

- Add `current_commit` tag in Sentry reports and JSON logs
- Add `transactions_status` table filled by the `parse()` functions of each contract

## API

- Add `current_commit` field in API root endpoint
- Add `valid` parameter for transactions endpoints

## CLI

- New Docker image based on Alpine Linux and using multi stage building 
- Cleaner error on unknown CLI argument
- Add `--backend-cookie-file` flag to connect to Bitcoin Core with cookie

# Credits

- Ouziel Slama
- Adam Krellenstein
