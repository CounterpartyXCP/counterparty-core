# Release Notes - Counterparty Core v11.0.1 (2025-06-??)
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

## Protocol

- Add backward-compatibility to CBOR format (Sweep, Enhanced Send, Fairminter, Fairmint, Issuance and Broadcast)

## Bugfixes

- No taproot encoding for legacy inputs
- Handle correctly unpack error in issuances

## Codebase

- Add Signet Support

## API

## CLI


# Credits

- Ouziel Slama
- Adam Krellenstein
