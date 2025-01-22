# Release Notes - Counterparty Core v10.9.1 (2025-01-22)

This is a small release that includes numerous bug and stability fixes, as well as a major refactor of the codebase in the name of improving testability. In particular, there was a bug in the Bitcoin fee calculation algorithm released as part of v10.9.0 which causes `detach` and `move` transactions composed with the API to have a higher fee than they should.


# Upgrading

This release is not a protocol change and upgrading is not mandatory, but it is highly recommended.

IMPORTANT:
- If you are running a version lower than 10.9.0, you must first update to 10.9.0 and only then install v10.9.1.
- If you are running a testnet4 node, you need to rollback to block 64492 manually before starting the server process


# ChangeLog

## Protocol Changes

## Bugfixes

- Fix ignored deprecated parameters in Compose API
- Fix Get Mempool Events By Addresses endpoint for `attach`, `detach` and UTXO `move`
- Retry ten times on telemetry request errors
- Return "not implemented" error when trying to get info about RPS transactions
- Fix typo in `protocol_changes.json' for testnet4
- Fix incorrect fee calculation for `detach` and `move`
- Don't retry to get vin info when parsing the mempool, which can cause nodes to lock up

## Codebase

- Remove all counterparty-wallet functionality
- Split up the test vectors file
- Move Python tests from `counterparty-rs` to `counterparty-core`
- Reorganize files and functions; split too-big files; delete all unused functions
- Remove globals in `lib/util.py` and `ledger.py`
- Use `yoyo` migrations to update the database
- Add stacktrace when warning because of Bitcoin Core errors

## API

- Add the `no_dispense` parameter to allow API clients to bypass the dispense transaction creation even when the destination is a dispenser
- Add the `event_name` parameter to Get Mempool Events By Addresses endpoint
- Have `sat_per_vbyte` parameter accept a float
- Check addresses and hashes format in parameters

## CLI


# Credits

- Ouziel Slama
- Warren Puffet
- Adam Krellenstein
