# Release Notes - Counterparty Core v10.10.1 (2025-03-03)

This release includes two major improvements to the Counterparty Core codebase: (1) faster and more reliable node shutdown, (2) ~40% faster initial node catchup. It also includes a number of usability improvements to the API and CLI, as well as bugfixes.

# Upgrading

**Breaking Changes:**
The commands `get_asset_names` and `get_asset_longnames` have been removed from API v1, as they are buggy and extremely non-performant. If you have been using these endpoints, you should migrate to `/v2/assets`.

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

- Handle subprocess errors correctly when bootstrapping
- Fix `getrawtransaction_batch()` for batches greater than `config.MAX_RPC_BATCH_SIZE`
- Improve error handling for when a port in use
- Fix ungraceful ZeroMQ failure
- Fix Conservation Check failing ungracefully
- Implement cleaner Gunicorn shutdown
- Fix ungraceful Waitress shutdown
- Handle RSFetcher version mismatch error correctly
- Handle Counterparty Server version checking errors correctly
- Fix the handling of `TypeError` in API calls

## Codebase

- Tweak logging during Bitcoin Core catch up
- Batch `getrawtransaction` for `get_vin_info()`
- Create events indexes after catch up rather than before
- Make RPC calls to get transaction input info with RSFetcher
- Make RSFetcher compatible with HTTPS
- Fix all code scanner alerts (Bandit, CodeQL, Pylint)
- Only print debug messages about Counterparty being behind Bitcoin Core every 10 seconds
- Add missing indexes to the `sends` table

## API

- Check balances when composing `detach` transaction
- Add a `show_unconfirmed` parameter for Get Transactions endpoints
- Add a `count_confirmed` parameter for Get Transactions Count endpoints
- Add a `X-LEDGER-STATE` header to all API responses
- Add a `ledger_state` field in API v2 root endpoint
- Remove `get_asset_names` and `get_asset_longnames` commands from API v1

## CLI

- Accept `--catch-up` flag before the command
- Add Locust runner to test local node performance (`python3 counterpartycore/test/integration/locustrunner.py` will start the Locust web UI on http://localhost:8089/)
- Add `--profile` flag that enables cProfile during catchup and dumps results to the console when complete
- Add `--rebuild` command to re-sync from scratch and then stop the server
- Add memory database cache for `address_events` table

# Credits

- Ouziel Slama
- Adam Krellenstein
