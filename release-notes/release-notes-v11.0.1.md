# Release Notes - Counterparty Core v11.0.0 (2025-03-??)


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

# ChangeLog

## Bugfixes

## Codebase

- Add `current_commit` tag in Sentry reports and JSON logs

## API

- Add `current_commit` field in API root endpoint

## CLI

- New Docker image based on Alpine Linux and using multi stage building 
- Cleaner error on unknown CLI argument
- Add `--backend-cookie-file` flag to connect to Bitcoin Core with cookie

# Credits

- Ouziel Slama
- Adam Krellenstein
