# Release Notes - Counterparty Core v10.4.4 (2024-10-??)


# Upgrading


# ChangeLog

## Bugfixes

- Properly handle invalid scripts in outputs
- Bump Minimum Version to v10.4.4 for Block Index >= 866,000
- Fix `last_block` in `get_running_info` command (API v1)

## Codebase


## API

- Add Gunicorn support

## CLI

- Add `wsgi-server` (`werkzeug` or `gunicorn`) and `gunicorn-workers` flags
- Enable Sentry Caches and Queries pages
- Add `network` Sentry tag (`mainnet`, `testnet` or `regtest`)

# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
