# Release Notes - Counterparty Core v11.0.5 (TBD)

# ChangeLog

## Features

- Support multiple Electrs backends with automatic failover on connection, timeout, or HTTP errors; `--electrs-url` can now be specified multiple times
- Default mainnet Electrs backends to both `blockstream.info` and `mempool.space`
- Print a startup warning when using default Electrs URLs (not recommended for production)
